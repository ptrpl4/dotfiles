# Dotfiles

Config files and settings for macOS (primary) and Linux.
Based on [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) and [CoreyMSchafer/dotfiles](https://github.com/CoreyMSchafer/dotfiles)

## Setup

```bash
git clone git@github.com:ptrpl4/dotfiles.git ~/dotfiles && cd ~/dotfiles
touch .private   # machine-specific config, see below
make install
```

### `.private` variables

```bash
# Machine profile, selects Zed/Claude settings variant: "work" or "home" (defaults to "home")
PROFILE="home"

# Obsidian vault paths for settings sync
OBSIDIAN_VAULTS=("$HOME/path/to/vault1" "$HOME/path/to/vault2")
```

### `.private-gitconfig` (optional)

Override git identity per machine. Included by `.gitconfig` automatically.

```ini
[user]
    name = Work Name
    email = work@company.com
```

### Shell config layout

Which file a setting belongs in is decided by when the shell reads it, not by topic.

| File | Read by | Holds |
|---|---|---|
| `.zshenv` | every zsh, including `zsh -c` | `N_PREFIX`, PATH entries non-login shells need |
| `.zprofile` | login zsh, **after** `path_helper` | re-prepends what `path_helper` demoted |
| `.zshrc` | interactive zsh | history, `setopt`, completions, prompt, aliases |
| `.bashrc` | interactive bash, `bash -l`, `ssh host 'cmd'` | env above the guard, interactive below |

`/etc/zprofile` and `/etc/profile` run `/usr/libexec/path_helper`, which rebuilds
PATH from `/etc/paths` + `/etc/paths.d/*` and appends the existing value — so
`.zshenv` entries land at the tail in login shells. Anything that must outrank the
system directories is re-prepended in `.zprofile`. Currently that is only `n`.

Bash never reads `.bashrc` for `bash -c` or `make`, and has no `.zshenv`
equivalent, so those shells inherit PATH from their parent or get nothing.

### Troubleshooting

- Check `~/dotfiles/backups` — previous versions of overwritten files are saved there
- Node missing in a Makefile or editor terminal → check `.zshenv`, not `.zprofile`
- Verify a shell change in a clean shell: `env -i HOME="$HOME" TERM=xterm zsh -lc 'print -l $path'`
- `docker` is an alias to podman (set in `.private`) — no Docker binary is installed or expected
- `n` comes from the Brewfile, but installs no Node runtime — run `n lts` once on a new machine

## Tools

### `claude-sessions` (`cs`)

Manage Claude Code session files in `~/.claude/projects/`.

```
cs ls                 # list all sessions grouped by project
cs ls --folders       # list projects only (no session detail)
cs thin <n>           # delete sessions with ≤ n user messages
cs clean <days>       # delete sessions older than n days
cs delete <id>        # delete a session by ID (partial match ok)
```

Deleting a session also removes its `~/.claude/file-history/<id>/` directory.

## Prompt

Features:
- Git branch with sync status (✓ synced, ↑ ahead, ↓ behind)
- Auto-adaptive colors (switches with terminal theme)
