# Dotfiles

Config files and settings for macOS (primary) and Linux.
Based on [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) and [CoreyMSchafer/dotfiles](https://github.com/CoreyMSchafer/dotfiles)

## Setup

```bash
git clone git@github.com:ptrpl4/dotfiles.git ~/dotfiles && cd ~/dotfiles
touch shell/private   # machine-specific config, see below
make install
```

### `shell/private` variables

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

Files live in `shell/` without a leading dot; `install.sh` links `shell/zshrc` →
`~/.zshrc` and so on. Which file a setting belongs in is decided by when the
shell reads it, not by topic.

| File | Read by | Holds |
|---|---|---|
| `path.sh` | sourced by the others | **every** PATH entry |
| `zshenv` | every zsh, including `zsh -c` | sources `path.sh`; minimal and silent |
| `zprofile` | login zsh, **after** `path_helper` | re-sources `path.sh`; `EDITOR` |
| `zshrc` | interactive zsh | history, `setopt`, completions, prompt, aliases |

PATH is built in one place so interactive shells, `zsh -c`, Makefiles and agent
tooling all agree. `path_helper` (run by `/etc/zprofile`) rebuilds PATH from
`/etc/paths` + `/etc/paths.d/*` and appends the old value, which cuts both ways:
`zshenv` entries get demoted to the tail in login shells, and `/etc/paths.d`
tools are absent from non-login ones. Hence `zprofile` re-sources, and those
entries are re-added in `path.sh`.

The `bash*` files are a compatibility shim for agent tooling and bash-login
hosts, not part of the setup.

Installers append to whichever rc file they pick and win by running last. Move
the line into `path.sh` if it should also reach non-interactive shells.

### Troubleshooting

- Check `~/dotfiles/backups` — previous versions of overwritten files are saved there
- A tool missing in a Makefile, editor terminal or agent shell → add it to `shell/path.sh`, not to a per-shell file
- Verify a shell change in a clean shell: `env -i HOME="$HOME" TERM=xterm zsh -lc 'print -l $path'`. Use `-c` / `-ic` for the non-login and interactive paths
- Config change stopped tracking? `readlink ~/.zshrc` — an installer that writes-temp-then-renames replaces the symlink with a regular file
- Aliases are interactive-only, so anything defined in `shell/aliases` or `shell/private` is absent from scripts and agent shells
- `n` comes from the Brewfile but installs no Node runtime — `sudo n lts` once on a new machine. No `N_PREFIX` is set, so runtimes land in `/usr/local/bin`, already on PATH via `/etc/paths`

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
