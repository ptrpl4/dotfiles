---
paths:
  - "**/*.sh"
  - "**/shell/*"
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
| `path.sh` | **every** PATH entry, plus any env PATH depends on |
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
- Removal must loop: `${p//":$1:"/:}` consumes the shared separator, so one pass
  turns `:a:a:` into `:a:` and strands a duplicate. `typeset -U` masks this in
  zsh only
- For future entries: guard any `$VAR/bin` with `-n "$VAR"` — unset,
  `[ -d "$VAR/bin" ]` tests `/bin` and puts it at the head
- Keg-only Homebrew formulae need their `libexec/bin` for the unversioned name.
  Deliberately not done for python: `python3`/`pip3` come from
  `/opt/homebrew/bin` and bare `python`/`pip` are not wanted

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
- Prefer prompt escapes to forks: `%D{%H:%M}`/`\A`, `%(?..)`, `%(1j..)`/`\j`
  replace `date`, an exit-code hook and a `jobs` pipeline at zero cost
- Colour must be width-marked or the line wraps early and redraws wrong. `%{ %}`
  and `\[ \]` only work on text the shell expanded itself — raw escapes reaching
  PS1 through `$(...)` are counted as printable. Build PS1 in `precmd` for zsh,
  and use `\001`/`\002` in bash, which processes `\[ \]` *before* command
  substitution
- Write colour as a literal SGR (`%{\e[90m%}`), not `%F{8}`: `%F` resolves
  through terminfo, so at 8 colours it silently degrades to `%f`, and with no
  terminfo entry at all (`xterm-ghostty`) it emits a bare `\e[38m`
- `%`-escape anything interpolated into a zsh prompt (`${var//\%/%%}`) — a
  branch named `100%off` otherwise injects prompt escapes
- `tput` errors when `TERM` is unset; keep it below the interactive guard
- Git in a prompt: `for-each-ref` reads refs only and is flat in worktree size.
  `git status` looks cheaper but refreshes the index — ~12 ms warm, ~290 ms on a
  2500-file repo with stale stat data, i.e. right after a checkout or build.
  `%(upstream:track)` is not localised, so parsing `ahead`/`behind` is safe
- Verify with `env -i HOME="$HOME" TERM=xterm zsh -lc '...'` so nothing leaks in
  from the parent. `-lc` / `-c` / `-ic` hit login, non-login, interactive. None
  of them render a prompt — to see PS1 as precmd builds it, drive a real
  interactive shell: `printf 'exit\n' | script -q out.log zsh -li`
