---
paths:
  - "**/*.sh"
  - "shell/*"
  - "**/.zshrc"
  - "**/.zprofile"
  - "**/.zshenv"
---

# Shell File Rules

## Style

- `bash` for scripts, `zsh` for interactive config
- Prefer functions over aliases when the body uses `$()` or arguments
- Quote all expansions: `"$var"`, `"$(cmd)"`. `local` for function-scoped vars
- `[[ ]]` in zsh/bash, `[ ]` only where POSIX sh matters

## Startup order

`/etc/zshenv` → `~/.zshenv` → *[login]* `/etc/zprofile` → `~/.zprofile` →
*[interactive]* `/etc/zshrc` → `~/.zshrc` → *[login]* `/etc/zlogin`.
On macOS `/etc/zshenv` and `/etc/zlogin` don't exist; `/etc/zprofile` sets a
`LANG` default and runs `path_helper`.

## Where things belong

Config lives in `~/dotfiles/shell/` without a leading dot; `install.sh` links
`shell/zshrc` → `~/.zshrc` and so on.

| Goes in | What |
|---|---|
| `path.sh` | **every** PATH entry, plus env PATH depends on (`N_PREFIX`) |
| `zshenv` | env every zsh needs. Small and silent; `zsh -f` skips it |
| `zprofile` | only what must run **after** `path_helper` |
| `zshrc` | interactive: history, `setopt`, `compinit`/`fpath`, prompt, aliases |

The `bash*` files are a compatibility shim for agent tooling and bash-login
hosts. Nothing belongs there that isn't already in `path.sh`.

## PATH

Everything is in `path.sh`, sourced by `zshenv` and again by `zprofile`.
Sourcing runs it; helpers are remove-then-add, so re-sourcing re-asserts order
instead of duplicating. Add entries there — anything added to `zshrc` alone is
invisible to `zsh -c`, Makefiles, and agent tooling.

It's shared, so no zsh-only syntax (arrays, `typeset -U`), and it runs on every
zsh, so use parameter expansion over forking `sed`.

`path_helper` (from `/etc/zprofile`) does **not** prepend: it rebuilds PATH from
`/etc/paths` + `/etc/paths.d/*`, then appends the old value.

- So `zshenv` entries land at the *tail* in login shells → `zprofile` re-sources
- And `/etc/paths.d` tools are missing entirely from **non**-login shells →
  re-add them in `path.sh` so every shell agrees
- Helpers must **remove-then-add**, never skip-if-present: `path_helper` has
  already put `/opt/homebrew/bin` mid-PATH, and skipping strands it there
- Guard `$VAR/bin` with `-n` — unset `N_PREFIX` turns `[ -d "$N_PREFIX/bin" ]`
  into `[ -d "/bin" ]`, putting `/bin` at the head
- Keg-only Homebrew formulae need their `libexec/bin` for the unversioned name

### Installers that edit rc files

They append `export PATH=` to some rc file and win by running last — usually
correct. Hoist the line into `path.sh` if it should reach non-interactive shells.

The rc files are symlinks into the repo, so the write style matters: `>>` follows
the link and shows as a git diff; BSD `sed -i` refuses outright; **write-temp-
then-`mv` replaces the symlink with a regular file** and the repo copy goes
stale. `readlink ~/.zshrc` if a config change stops tracking.

## Gotchas

- **Never `export PS1`/`PS2`.** Prompts are shell-local: an exported `PS1` renders
  as literal escapes in child shells of another flavour, and defeats the
  `[ -z "$PS1" ] && return` guard that system rc files open with
- `/etc/zshrc` runs `disable log`, but interactive-only — in a non-interactive
  zsh the `log` builtin shadows `/usr/bin/log`
- Prompt hooks: `add-zsh-hook precmd fn`, and append to `PROMPT_COMMAND`. Plain
  `precmd() {...}` / `PROMPT_COMMAND=...` get clobbered by direnv, zoxide, mise
- `tput` errors when `TERM` is unset; keep it below the interactive guard
- Verify with `env -i HOME="$HOME" TERM=xterm zsh -lc '...'` so nothing leaks in
  from the parent. `-lc` / `-c` / `-ic` hit login, non-login, interactive
