# Global Rules

## Meta
- These rules override default behavior. If one conflicts with the task, surface it immediately — do not attempt the task first

## Commits & Git
- Never add `Co-Authored-By` lines — this overrides the harness default, which adds them
- Never commit or push without approval; keep subject lines short

## Communication & Output
- Write impersonally — never "you"/"your" for code, configs, or the project ("the config", not "your config")
- No emoji unless the task itself involves them
- Number any list of options so they can be referenced by number
- Broad or ambiguous request → ask one focused clarifying question before starting, with scope options if useful
- Do not create doc/README files without asking first
- End sessions that involved real decisions with a short summary of what's worth remembering

## Code Changes
- Show the plan before touching more than one file or rewriting more than ~20 lines — wait for confirmation
- If the plan turns out wrong mid-execution, stop and re-confirm rather than self-correct silently
- Check for existing linter/formatter config before assuming style

## ENV
- Package manager: follow the `packageManager` field or lock files
- Bash tool runs through **zsh** — watch for builtins shadowing binaries (`log` → call `/usr/bin/log`)
- BSD userland: `sed -i ''` (empty arg), `sed -E` not `-r`, `stat -f` not `-c`, no `date -d`, no `find -printf`; GNU only as `gdate`/`gstat`. `launchctl` not `systemctl`, `lsof -i -P` not `ss`, `open` not `xdg-open`, `shasum` not `sha256sum`, no `/proc`
- Bash-tool `grep`/`find` are ugrep-backed shims so `-P` works; `/usr/bin/grep` is BSD and has no `-P` — don't rely on it in scripts
- Homebrew prefix is `/opt/homebrew`
- Terminal host is Zed's integrated terminal or Ghostty; `EDITOR` is `zed --wait`, so editor-opening commands block until the tab closes — prefer `git commit -m`, `GIT_EDITOR=true`
- macOS TCC: touching `~/Desktop`, `~/Documents`, `~/Downloads`, `~/Library`, `~/Pictures` pops a GUI dialog attributed to the host app and invisible from the terminal — exclude those paths from `find`/`grep` sweeps
- All PATH construction is in `~/dotfiles/shell/path.sh`, sourced by every shell — add entries there, never to a per-shell rc file
- PATH is frozen per session: the Bash tool replays `~/.claude/shell-snapshots/snapshot-bash-*.sh`, which ends in a literal `export PATH=…` captured at session start. A newly added PATH entry needs a restarted session; switching versions in place (`n <ver>`) works fine
- **No aliases** — the snapshot opens with `unalias -a`, so nothing from `shell/aliases` or `shell/private` exists here. Notably `docker` is an alias to podman and no Docker binary is installed, so call `podman` directly and don't assume Docker compose/buildx/socket semantics
- `~/dotfiles/bin` is first on PATH — the right place for shims and small CLIs, and unlike an alias it survives into this shell
- If an installed tool seems missing, check `~/dotfiles/shell/path.sh`; don't assume a given tool is present on this machine

## Claude config
- `~/.claude/{CLAUDE.md,settings.json,keybindings.json,statusline-command.sh}` and `hooks/`, `rules/`, `skills/` are symlinks into `~/dotfiles/settings/claude/`. Editing tools refuse to write through symlinks — edit the real target; changes surface as `~/dotfiles` git changes
- `rules/*.md` load by `paths:` frontmatter globs — unscoped rules belong in this file instead
- Suggest a project `.claude/settings.json` allow-list on first session, or once the same command is approved twice; remind to gitignore `settings.local.json` if it holds machine paths

## Skills
- Available via `/skill-name`; check `work-*` skills first for work tasks
