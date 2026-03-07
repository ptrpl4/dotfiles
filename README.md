# Readme

This repo contains config files and various settings for my main computer (macOS).
Based on [mathiasbynens/dotfiles](https://github.com/mathiasbynens/dotfiles) and [CoreyMSchafer/dotfiles](https://github.com/CoreyMSchafer/dotfiles)

## Setup

```bash
# copy repo to $HOME folder
git clone git@github.com:ptrpl4/dotfiles.git ~/dotfiles ; cd ~/dotfiles
# create/copy .private file to use it along with publc config
touch .private
# (optional) set Zed profile: "work" or "home" (defaults to "home")
# ZED_PROFILE="home"
# (optional) add Obsidian vault paths to .private
# OBSIDIAN_VAULTS=("$HOME/path/to/vault1" "$HOME/path/to/vault2")
# run install script
./new-install.sh
```

### Setup Troubleshoting

- Check `~/dotfiles/backups` in case of any unexpected issues - it will contain all previous versions of changed files
- Installation expects nvm and Docker on local machine

## Settings Autoapply

1. Terminal (needs relaunch)
2. Rectangle (needs relaunch)

## Prompt

**Features:**
- Git branch with sync status (✓ synced, ↑ ahead, ↓ behind)
- Command execution time (if > 1s)
- Auto-adaptive colors (switches with terminal theme)
