---
paths:
  - "**/*.sh"
  - "**/.aliases"
  - "**/.bashrc"
  - "**/.bash_profile"
  - "**/.bash_prompt"
  - "**/.zshrc"
  - "**/.zprofile"
  - "**/.zshenv"
  - "**/.zprompt"
  - "**/.prompt_common"
---

# Shell File Rules

## Style

- Use `bash` for scripts, `zsh` for interactive config
- Prefer functions over aliases when the body uses `$()` or arguments
- Quote all variable expansions: `"$var"`, `"$(cmd)"`
- Use `[[ ]]` in zsh/bash, `[ ]` only for POSIX sh compatibility
- Use `local` for all function-scoped variables

## Startup order

Verified against `man zshall` (STARTUP/SHUTDOWN FILES), `man bash` (INVOCATION),
and this machine's `/etc/*` files.

**zsh** — `/etc/zshenv` → `~/.zshenv` → *[login]* `/etc/zprofile` → `~/.zprofile`
→ *[interactive]* `/etc/zshrc` → `~/.zshrc` → *[login]* `/etc/zlogin`.
On macOS `/etc/zshenv` and `/etc/zlogin` do not exist; `/etc/zprofile` only sets a
`LANG` default and runs `path_helper`.

**bash** — reads `~/.bashrc` in exactly three cases: interactive shells, login
shells via `~/.bash_profile` (`bash -l`, `bash -lc`), and `ssh host 'cmd'` when
bash is the login shell (stdin is a socket). It does **not** read it for `bash -c`
or `make`. `BASH_ENV` applies only to non-interactive shells and is not inherited
into `make`, so it is not a usable substitute. There is no bash equivalent of
`.zshenv` — accept the gap rather than papering over it.

## Where things belong

| Goes in | What |
|---|---|
| `.zshenv` | env that every zsh needs — `N_PREFIX`, PATH entries for non-login shells. Keep small; `zsh -f` skips it |
| `.zprofile` | only what must run **after** `path_helper` (see below) |
| `.zshrc` | anything interactive: history, `setopt`, `compinit`/`fpath`, prompt, aliases |
| `.bashrc` above the guard | bash env/PATH |
| `.bashrc` below the guard | history, prompt, completions |

## PATH and `path_helper`

`/etc/zprofile` (zsh login) and `/etc/profile` (bash login) both run
`/usr/libexec/path_helper`. It does **not** prepend: it rebuilds PATH from
`/etc/paths` + `/etc/paths.d/*`, then appends whatever was already there. So
anything set in `.zshenv` lands at the *tail* in login shells.

- A directory that must outrank the system dirs has to be re-prepended in
  `.zprofile`, which runs after `path_helper`. Only `n` needs this; podman is in
  `/etc/paths.d` and nothing competes with it
- zsh: `typeset -U path PATH` + prepend = move-to-front, since `-U` keeps the
  first occurrence and drops the demoted duplicate
- bash has no `typeset -U`. A PATH helper must **remove-then-add**, never
  "skip if already present" — in a login shell `path_helper` has already inserted
  `/opt/homebrew/bin` mid-PATH, and skipping strands it behind `/usr/local/bin`
- Guard `$VAR/bin` tests with `-n`: unset `N_PREFIX` turns `[[ -d "$N_PREFIX/bin" ]]`
  into `[[ -d "/bin" ]]`, which is true and puts `/bin` at the head of PATH

## Gotchas

- **Never `export PS1`/`PS2`.** An exported `PS1` renders as literal zsh escapes in
  interactive bash children, and defeats the `[ -z "$PS1" ] && return` guard that
  both this machine's `/etc/bashrc` and Debian's `/etc/bash.bashrc` open with
- `/etc/zshrc` runs `disable log`, but it is interactive-only — in a
  non-interactive zsh the `log` builtin shadows `/usr/bin/log`
- Prompt hooks: use `add-zsh-hook precmd fn` and append to `PROMPT_COMMAND`.
  Plain `precmd() {...}` / `PROMPT_COMMAND=...` get silently clobbered by direnv,
  zoxide, atuin, mise
- `tput` in a prompt file errors when `TERM` is unset; keep it below the
  interactive guard
- Two bash binaries exist here: `/bin/bash` 3.2.57 (Apple) and
  `/opt/homebrew/bin/bash` 5.x. Test PATH changes against both
- Verify shell startup with `env -i HOME="$HOME" TERM=xterm zsh -lc '...'` so
  nothing leaks in from the parent shell. Use `-lc` / `-c` / `-ic` to hit login,
  non-login, and interactive paths separately
