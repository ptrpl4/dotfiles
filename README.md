# Dotfiles

Config files and settings for macOS (primary) and Linux.
Based on [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) and [CoreyMSchafer/dotfiles](https://github.com/CoreyMSchafer/dotfiles)

## Setup

```bash
git clone git@github.com:ptrpl4/dotfiles.git ~/dotfiles && cd ~/dotfiles
touch .private   # machine-specific config, see below
./install.sh
```

### `.private` variables

```bash
# Zed editor profile: "work" or "home" (defaults to "home")
ZED_PROFILE="home"

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

### Troubleshooting

- Check `~/dotfiles/backups` — previous versions of overwritten files are saved there
- NVM and Docker are expected to be installed

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

## TODO

- [ ] Add `make help` target
- [ ] Add restore script (`brew bundle install`, etc.)
- [ ] Add syncing settings backup

## Prompt

**Features:**
- Git branch with sync status (✓ synced, ↑ ahead, ↓ behind)
- Command execution time (if > 1s)
- Auto-adaptive colors (switches with terminal theme)
