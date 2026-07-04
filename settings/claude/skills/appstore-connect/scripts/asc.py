#!/usr/bin/env python3
"""App Store Connect helper — official-tools-only, Python stdlib only.

Auth uses an App Store Connect API key (.p8 + Key ID + Issuer ID). This script
NEVER prints the private key or any secret. It signs a short-lived ES256 JWT
(via openssl) and calls the ASC REST API with urllib.

Config resolution (no secrets on the command line):
  Key ID     : $ASC_KEY_ID, else the single AuthKey_<ID>.p8 in the keys dir.
  Issuer ID  : $ASC_ISSUER_ID or $ISSUER_ID, else ISSUER_ID= in ./.env,
               else ~/.appstoreconnect/issuer_id.
  Private key: ~/.appstoreconnect/private_keys/AuthKey_<Key ID>.p8

Subcommands:
  token                         print a fresh JWT (for ad-hoc curl)
  apps                          list apps (id | bundleId | name)
  builds <app-id|bundleId>      recent builds: platform, version, processingState
  wait <app-id> [--build N [--count K]] [--timeout S]
                                poll builds until settled (default 1800s). With
                                --build, wait for that CFBundleVersion to appear AND
                                reach VALID on --count platforms (default 1) — avoids
                                a false "done" off older builds right after an upload.
  certs                         list certificates (id | type | name | expiry)
  profiles                      list provisioning profiles
  bundleids                     list bundle IDs (id | platform | identifier)
  create-profile --name N --type T --bundle-id BID [--certs all|id,id]
                                create a distribution profile; save + install the
                                .mobileprovision. T is e.g. IOS_APP_STORE,
                                TVOS_APP_STORE, MAC_APP_STORE. --certs defaults to
                                all DISTRIBUTION certs so the local key matches one.

This script does NOT upload builds, notarize, submit for review, register
devices, or delete anything — those are done with xcrun altool / notarytool per
SKILL.md, or are intentionally out of scope.
"""

import sys, os, json, time, base64, subprocess, glob, argparse, plistlib
import urllib.request, urllib.error

API = "https://api.appstoreconnect.apple.com"
KEYS_DIR = os.path.expanduser("~/.appstoreconnect/private_keys")


def die(msg):
    sys.stderr.write("error: %s\n" % msg)
    sys.exit(1)


def find_key_id():
    kid = os.environ.get("ASC_KEY_ID")
    if kid:
        return kid
    matches = glob.glob(os.path.join(KEYS_DIR, "AuthKey_*.p8"))
    if len(matches) == 1:
        base = os.path.basename(matches[0])
        return base[len("AuthKey_"):-len(".p8")]
    if not matches:
        die("no AuthKey_*.p8 in %s (create an ASC API key first)" % KEYS_DIR)
    die("multiple keys found; set ASC_KEY_ID to choose one")


def find_issuer_id():
    for var in ("ASC_ISSUER_ID", "ISSUER_ID"):
        if os.environ.get(var):
            return os.environ[var]
    if os.path.exists(".env"):
        with open(".env") as f:
            for line in f:
                line = line.strip()
                if line.startswith("ISSUER_ID="):
                    return line.split("=", 1)[1].strip()
    path = os.path.expanduser("~/.appstoreconnect/issuer_id")
    if os.path.exists(path):
        return open(path).read().strip()
    die("Issuer ID not found (set ASC_ISSUER_ID or add ISSUER_ID= to ./.env)")


def b64u(b):
    return base64.urlsafe_b64encode(b).rstrip(b"=")


def der_to_raw(der):
    # ASN.1 SEQUENCE { INTEGER r, INTEGER s } -> raw 64-byte r||s
    if der[0] != 0x30:
        die("unexpected ECDSA signature encoding")
    idx = 2
    if der[1] & 0x80:
        idx = 2 + (der[1] & 0x7F)

    def read_int(i):
        assert der[i] == 0x02
        ln = der[i + 1]
        val = der[i + 2:i + 2 + ln]
        return val.lstrip(b"\x00").rjust(32, b"\x00"), i + 2 + ln

    r, idx = read_int(idx)
    s, idx = read_int(idx)
    return r + s


def make_jwt():
    kid = find_key_id()
    iss = find_issuer_id()
    key_path = os.path.join(KEYS_DIR, "AuthKey_%s.p8" % kid)
    if not os.path.exists(key_path):
        die("private key not found: %s" % key_path)
    header = {"alg": "ES256", "kid": kid, "typ": "JWT"}
    now = int(time.time())
    payload = {"iss": iss, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"}
    signing_input = (b64u(json.dumps(header, separators=(",", ":")).encode())
                     + b"." + b64u(json.dumps(payload, separators=(",", ":")).encode()))
    proc = subprocess.run(["openssl", "dgst", "-sha256", "-sign", key_path],
                          input=signing_input, capture_output=True)
    if proc.returncode != 0:
        die("openssl signing failed: %s" % proc.stderr.decode(errors="replace"))
    sig = der_to_raw(proc.stdout)
    return (signing_input + b"." + b64u(sig)).decode()


def api(method, path, body=None):
    url = path if path.startswith("http") else API + path
    data = json.dumps(body).encode() if body is not None else None
    headers = {"Authorization": "Bearer " + make_jwt()}
    if data is not None:
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req) as r:
            return json.load(r)
    except urllib.error.HTTPError as e:
        detail = e.read().decode(errors="replace")
        die("HTTP %d on %s %s\n%s" % (e.code, method, path, detail))


def get_all(path):
    """Follow pagination, return the concatenated data list plus last 'included'."""
    data, included = [], []
    url = path
    while url:
        d = api("GET", url)
        data += d.get("data", [])
        included = d.get("included", included)
        url = d.get("links", {}).get("next")
    return data, included


# ---- subcommands ---------------------------------------------------------

def cmd_token(_):
    print(make_jwt())


def cmd_apps(_):
    data, _ = get_all("/v1/apps?limit=200&fields[apps]=name,bundleId,sku")
    for a in data:
        at = a["attributes"]
        print("%s | %s | %s" % (a["id"], at["bundleId"], at["name"]))


def resolve_app_id(ref):
    if "." not in ref:  # already an app id
        return ref
    data, _ = get_all("/v1/apps?limit=200&fields[apps]=bundleId")
    for a in data:
        if a["attributes"]["bundleId"] == ref:
            return a["id"]
    die("no app with bundle id %s" % ref)


def _print_builds(app_id):
    d = api("GET", "/v1/builds?filter[app]=%s&limit=15&sort=-uploadedDate"
                   "&fields[builds]=version,processingState,uploadedDate,preReleaseVersion"
                   "&include=preReleaseVersion"
                   "&fields[preReleaseVersions]=platform" % app_id)
    plat = {i["id"]: i["attributes"]["platform"] for i in d.get("included", [])}
    total = d["meta"]["paging"]["total"]
    print("total=%d" % total)
    rows = []
    for b in d.get("data", []):
        rel = (b.get("relationships", {}).get("preReleaseVersion", {}).get("data") or {})
        p = plat.get(rel.get("id"), "?")
        at = b["attributes"]
        print("  %-10s v%-4s %-12s %s" % (p, at["version"], at["processingState"],
                                          at.get("uploadedDate", "")))
        rows.append((p, at["version"], at["processingState"]))
    return rows


def cmd_builds(args):
    _print_builds(resolve_app_id(args.app))


def cmd_wait(args):
    app_id = resolve_app_id(args.app)
    deadline = time.time() + args.timeout
    while True:
        rows = _print_builds(app_id)
        if args.build is not None:
            # Wait for a SPECIFIC build to appear AND settle. Right after an upload the
            # new build has not been ingested yet, so a bare "nothing is PROCESSING"
            # test would falsely report done off the previous (already-VALID) builds.
            matched = [r for r in rows if r[1] == args.build]
            settled = len(matched) >= args.count and all(r[2] != "PROCESSING" for r in matched)
            if matched and settled:
                bad = [r for r in matched if r[2] != "VALID"]
                if bad:
                    print("done: build %s settled but NOT all VALID: %s" % (
                        args.build, ", ".join("%s=%s" % (r[0], r[2]) for r in bad)))
                    sys.exit(2)
                print("done: build %s VALID on %d platform(s)" % (args.build, len(matched)))
                return
        else:
            states = [r[2] for r in rows]
            if states and "PROCESSING" not in states:
                print("done: no builds processing")
                return
        if time.time() > deadline:
            if args.build is not None:
                print("timeout: build %s not VALID on %d platform(s) yet (still "
                      "processing, not ingested, or rejected — check the Apple email)"
                      % (args.build, args.count))
            elif not rows:
                print("timeout: no builds appeared (upload not yet ingested, "
                      "or processing was rejected — check the Apple email)")
            else:
                print("timeout: still processing")
            return
        time.sleep(30)


def cmd_certs(_):
    data, _ = get_all("/v1/certificates?limit=200"
                      "&fields[certificates]=certificateType,displayName,expirationDate")
    for c in data:
        at = c["attributes"]
        print("%s | %s | %s | %s" % (c["id"], at["certificateType"],
                                     at["displayName"], at["expirationDate"]))


def cmd_profiles(_):
    data, _ = get_all("/v1/profiles?limit=200"
                      "&fields[profiles]=name,profileType,profileState,expirationDate")
    for p in data:
        at = p["attributes"]
        print("%s | %s | %s | %s" % (p["id"], at["profileType"],
                                     at["profileState"], at["name"]))


def cmd_bundleids(_):
    data, _ = get_all("/v1/bundleIds?limit=200"
                      "&fields[bundleIds]=identifier,name,platform")
    for b in data:
        at = b["attributes"]
        print("%s | %s | %s" % (b["id"], at["platform"], at["identifier"]))


def cmd_create_profile(args):
    # resolve bundle id resource
    data, _ = get_all("/v1/bundleIds?limit=200&fields[bundleIds]=identifier")
    bid = next((b["id"] for b in data if b["attributes"]["identifier"] == args.bundle_id), None)
    if not bid:
        die("no bundle id resource for %s" % args.bundle_id)
    # resolve certs
    cdata, _ = get_all("/v1/certificates?limit=200&fields[certificates]=certificateType")
    if args.certs == "all":
        cert_ids = [c["id"] for c in cdata if c["attributes"]["certificateType"] == "DISTRIBUTION"]
    else:
        cert_ids = args.certs.split(",")
    if not cert_ids:
        die("no distribution certificates found")
    body = {"data": {
        "type": "profiles",
        "attributes": {"name": args.name, "profileType": args.type},
        "relationships": {
            "bundleId": {"data": {"type": "bundleIds", "id": bid}},
            "certificates": {"data": [{"type": "certificates", "id": c} for c in cert_ids]},
        },
    }}
    d = api("POST", "/v1/profiles", body)
    content = base64.b64decode(d["data"]["attributes"]["profileContent"])
    # Decode once (need the UUID for the filename) via a temp file.
    tmp = os.path.join(os.path.expanduser("~"), ".asc-new.mobileprovision")
    with open(tmp, "wb") as f:
        f.write(content)
    decoded = subprocess.run(["security", "cms", "-D", "-i", tmp],
                             capture_output=True).stdout
    os.remove(tmp)
    p = plistlib.loads(decoded)
    fname = p["UUID"] + ".mobileprovision"
    # Install to both the legacy path and the Xcode 16+ path so any toolchain
    # finds it.
    dirs = ["~/Library/MobileDevice/Provisioning Profiles",
            "~/Library/Developer/Xcode/UserData/Provisioning Profiles"]
    written = []
    for d0 in dirs:
        dest_dir = os.path.expanduser(d0)
        os.makedirs(dest_dir, exist_ok=True)
        dest = os.path.join(dest_dir, fname)
        with open(dest, "wb") as f:
            f.write(content)
        written.append(dest)
    print("created & installed: %s" % p["Name"])
    print("  UUID: %s" % p["UUID"])
    for w in written:
        print("  file: %s" % w)


def main():
    parser = argparse.ArgumentParser(description="App Store Connect helper (official tools only)")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("token").set_defaults(func=cmd_token)
    sub.add_parser("apps").set_defaults(func=cmd_apps)
    b = sub.add_parser("builds"); b.add_argument("app"); b.set_defaults(func=cmd_builds)
    w = sub.add_parser("wait"); w.add_argument("app"); w.add_argument("--timeout", type=int, default=1800)
    w.add_argument("--build", help="wait for this CFBundleVersion to appear AND reach VALID (avoids a false 'done' off older builds right after upload)")
    w.add_argument("--count", type=int, default=1, help="how many platforms of --build must be VALID before done (e.g. 3 for iOS+macOS+tvOS)")
    w.set_defaults(func=cmd_wait)
    sub.add_parser("certs").set_defaults(func=cmd_certs)
    sub.add_parser("profiles").set_defaults(func=cmd_profiles)
    sub.add_parser("bundleids").set_defaults(func=cmd_bundleids)
    cp = sub.add_parser("create-profile")
    cp.add_argument("--name", required=True)
    cp.add_argument("--type", required=True)
    cp.add_argument("--bundle-id", required=True)
    cp.add_argument("--certs", default="all")
    cp.set_defaults(func=cmd_create_profile)
    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
