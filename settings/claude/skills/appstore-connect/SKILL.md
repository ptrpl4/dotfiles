---
name: appstore-connect
description: Work with App Store Connect using official Apple tools only (ASC API key + xcrun altool + notarytool). Query build/processing status, validate and upload builds (iOS/macOS/tvOS) to TestFlight, create device-free distribution provisioning profiles, notarize macOS artifacts, diagnose signing/validation failures, and — behind an explicit confirmation gate — submit builds for App Store review. Use whenever a task involves uploading to TestFlight, checking whether a build landed, App Store Connect API/JWT, notarization, provisioning profiles, or code-signing for distribution.
---

# App Store Connect (official tools only)

No third-party tooling (no fastlane / Transporter GUI). Everything runs on the
App Store Connect API key + tools bundled with Xcode (`xcrun altool`,
`xcrun notarytool`) + `openssl`/`curl`/`python3` from the base system.

## Prerequisites (one-time, done by a human)

An **App Store Connect API key** must exist. Create it in App Store Connect →
Users and Access → Integrations → App Store Connect API → generate a **Team key**
(App Manager role). This is the only manual setup and cannot be automated.

- Save the `.p8` to `~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8`
  (the location `altool`/`notarytool` auto-discover). The `.p8` is downloadable
  once.
- The **Key ID** is the `<KEYID>` in that filename.
- The **Issuer ID** (a UUID, low-sensitivity, not a secret) goes in the project's
  `.env` as `ISSUER_ID=…`, or `~/.appstoreconnect/issuer_id`, or `$ASC_ISSUER_ID`.

If the key is missing, stop and ask the human to create it — do not attempt any
workaround.

## Config resolution

`scripts/asc.py` finds credentials automatically:
- **Key ID** — `$ASC_KEY_ID`, else the single `AuthKey_*.p8` in the keys dir.
- **Issuer ID** — `$ASC_ISSUER_ID` / `$ISSUER_ID`, else `ISSUER_ID=` in `./.env`,
  else `~/.appstoreconnect/issuer_id`.

Run `asc.py` from the project root so it picks up `./.env`.

## Secrets — hard rules

- NEVER print, log, echo, or commit the `.p8`, any app-specific password, or the
  contents of `.env`. Reference secrets only by variable/path.
- `.env` and `.p8` stay git-ignored. If `.env` is not ignored, fix that first.
- The Issuer ID and Key ID are low-sensitivity identifiers; showing them is fine.
- `asc.py token` prints a live 10-minute bearer JWT. It is a credential — use it
  for ad-hoc `curl` only; never log or commit it.

## The helper: `scripts/asc.py` (read + create-profile only)

Python stdlib only; signs a 10-minute ES256 JWT via `openssl` and calls the REST
API. It NEVER uploads, notarizes, submits, registers devices, or deletes.

```
python3 scripts/asc.py apps                     # id | bundleId | name
python3 scripts/asc.py builds <appId|bundleId>  # platform, version, processingState
python3 scripts/asc.py wait   <appId|bundleId>  # poll until nothing PROCESSING
python3 scripts/asc.py wait   <appId|bundleId> --build 32 --count 3  # wait for a SPECIFIC build to appear AND go VALID (use after an upload; bare wait can false-"done" off older builds)
python3 scripts/asc.py certs                     # signing certificates
python3 scripts/asc.py profiles                  # provisioning profiles
python3 scripts/asc.py bundleids                 # bundle IDs
python3 scripts/asc.py token                     # a fresh JWT for ad-hoc curl
python3 scripts/asc.py create-profile --name "X tvOS AppStore" \
        --type TVOS_APP_STORE --bundle-id ptrpl4.X [--certs all]
```

`--upload-app` is deprecated in newer altool in favour of `--upload-package`;
`--upload-app` still works today. Prefer whichever the installed Xcode accepts.

## Capabilities & guardrails

**MAY do freely (safe / reversible / diagnostic):**
1. Query anything (apps, builds, processing state, certs, profiles, bundle IDs).
2. `--validate-app` then upload builds to App Store Connect, then poll to VALID.
3. Create **distribution** provisioning profiles (device-free) when an archive
   needs one.
4. Notarize + staple macOS artifacts.
5. Diagnose signing/validation failures and propose the exact fix.

**MUST stop and get explicit confirmation before (outward-facing / high-stakes):**
1. **Submitting a build for App Store review** or **releasing to production** —
   confirm every time, naming the exact app + build + version.
2. Anything that changes what end users receive.

**MUST NOT do (out of scope / destructive):**
1. Delete any ASC resource (profiles, certs, builds).
2. Register devices — never; it is also the wrong fix for tvOS (see below).
3. Manage users, pricing, agreements, or store metadata.
4. Edit committed project files (pbxproj / Info.plist / entitlements) or create
   profiles without first showing the change and getting approval
   (propose-then-apply).

## Recipe — upload a build to TestFlight

1. Have an App Store `.ipa`/`.pkg` (archive + `-exportArchive` with method
   `app-store-connect`).
   The `altool`/`notarytool` commands below need `$ISSUER_ID` in the shell.
   Keep `.env` shell-sourceable — quote any value with a space
   (`NAME="Peter E"`) — then source it:
   ```
   set -a; source .env; set +a
   ```
2. Validate (cheap, catches real errors before wasting an upload):
   ```
   xcrun altool --validate-app -f "App.ipa" -t ios \
     --apiKey <KEYID> --apiIssuer "$ISSUER_ID"
   ```
   `-t` is `ios` | `macos` | `tvos`. For `.pkg` use `-t macos`.
   Proceed only on "VERIFY SUCCEEDED with no errors".
3. Upload:
   ```
   xcrun altool --upload-app -f "App.ipa" -t ios \
     --apiKey <KEYID> --apiIssuer "$ISSUER_ID"
   ```
   "UPLOAD SUCCEEDED" + a Delivery UUID means it left your machine — that's
   transport only, not server-side acceptance. Processing then takes ~5–15 min.
4. Confirm it landed in the App Store Connect / TestFlight web UI. If the build
   never appears there, processing was rejected — Apple emails the reason.

## Recipe — device-free tvOS (and any App Store) archive

tvOS automatic signing demands a **tvOS Development** profile, which needs a
registered device. Do NOT register a device. Instead sign the archive directly
with an **App Store distribution** profile (needs no devices on any platform):

1. Create profiles for the app and every embedded extension:
   ```
   python3 scripts/asc.py create-profile --name "App tvOS AppStore" \
     --type TVOS_APP_STORE --bundle-id <app.bundle.id>
   python3 scripts/asc.py create-profile --name "Ext tvOS AppStore" \
     --type TVOS_APP_STORE --bundle-id <ext.bundle.id>
   ```
   (`--certs all` — the default — includes every unified **Apple Distribution**
   cert so the local keychain identity matches one. This is correct for
   `IOS_APP_STORE`/`TVOS_APP_STORE`. For `MAC_APP_STORE` pass `--certs` explicitly
   with the Mac App Distribution cert id — the `all` filter does not select it.)
   The command installs each `.mobileprovision`.
2. Propose SDK-scoped manual signing per target so iOS/macOS automatic signing is
   untouched (show the diff, apply on approval):
   ```
   "CODE_SIGN_IDENTITY[sdk=appletvos*]" = "Apple Distribution";
   "CODE_SIGN_STYLE[sdk=appletvos*]" = Manual;
   "PROVISIONING_PROFILE_SPECIFIER[sdk=appletvos*]" = "App tvOS AppStore";
   ```
3. Archive + export with an ExportOptions.plist whose `provisioningProfiles` maps
   each bundle id to its profile name, `signingStyle` manual, method
   `app-store-connect`.

Known tvOS validation gotcha: an app extension binary must declare
`UIRequiredDeviceCapabilities = [arm64]` in its `Info.plist` (safe on iOS,
ignored on macOS). `--validate-app` reports this as error 90502 if missing.

## Recipe — macOS notarization (non-TestFlight distribution)

`altool` no longer notarizes (removed Nov 2023). Use `notarytool` with the same
key:
```
xcrun notarytool submit "App.zip" --key ~/.appstoreconnect/private_keys/AuthKey_<KEYID>.p8 \
  --key-id <KEYID> --issuer "$ISSUER_ID" --wait
xcrun stapler staple "App.app"
```

## Recipe — submit for review (CONFIRMATION GATE)

Only after an explicit human "yes" naming the app, build, and version. Use the
`/v1/reviewSubmissions` + `/v1/reviewSubmissionItems` flow (or ask the human to
do it in the web UI). Never submit as a side effect of another task.
