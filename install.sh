#!/usr/bin/env bash

# Create the backup directory if it doesn't exist
install_backup_dir="${HOME}/dotfiles/backups/${LOGNAME}/$(date +%Y-%m-%d)"

mkdir -p "${install_backup_dir}"
echo "Backup dir created"

# dotfiles directory
dotfiles_dir="${HOME}/dotfiles"

# Back up a pre-existing real file/dir (moved into the dated backup dir),
# then symlink src to target. Missing src is skipped.
link_file() {
    local src="$1" target="$2" backup_subdir="${3:-.}" name
    name="$(basename "$target")"

    if [[ ! -e "$src" ]]; then
        echo "Skipping ${name} (not found: $src)"
        return
    fi

    mkdir -p "$(dirname "$target")"

    if [[ -e "$target" && ! -L "$target" ]]; then
        mkdir -p "${install_backup_dir}/${backup_subdir}"
        if mv "$target" "${install_backup_dir}/${backup_subdir}/"; then
            echo "Backed up ${name}"
        else
            echo "Warning: could not back up ${name}, skipping link" >&2
            return
        fi
    fi

    if ln -sfn "$src" "$target"; then
        echo "Linked ${name} -> ${src#"${dotfiles_dir}"/}"
    else
        echo "Warning: failed to link ${name}" >&2
    fi
}

# Migrate the pre-move secrets file before anything links or sources it.
if [[ -f "${dotfiles_dir}/.private" && ! -f "${dotfiles_dir}/shell/private" ]]; then
    mv "${dotfiles_dir}/.private" "${dotfiles_dir}/shell/private"
    echo "Moved .private -> shell/private"
fi

# Shell config: lives in shell/ without a leading dot, linked into $HOME with one.
# path.sh is sourced by the others, not linked.
shell_files=(zshenv zprofile zshrc zprompt bashrc bash_profile bash_prompt aliases prompt_common private)

for file in "${shell_files[@]}"; do
    link_file "${dotfiles_dir}/shell/${file}" "${HOME}/.${file}"
done

# Still at the repo root
for file in gitconfig netrc npmrc; do
    link_file "${dotfiles_dir}/.${file}" "${HOME}/.${file}"
done

# Machine profile from shell/private ("work" or "home"; ZED_PROFILE/CLAUDE_PROFILE are legacy fallbacks)
[[ -f "${dotfiles_dir}/shell/private" ]] && source "${dotfiles_dir}/shell/private"
profile="${PROFILE:-${CLAUDE_PROFILE:-${ZED_PROFILE:-home}}}"

# App configs
link_file "${dotfiles_dir}/settings/ghostty/config.ghostty" \
    "${HOME}/Library/Application Support/com.mitchellh.ghostty/config.ghostty" ghostty

link_file "${dotfiles_dir}/settings/sublime-merge/Preferences.sublime-settings" \
    "${HOME}/Library/Application Support/Sublime Merge/Packages/User/Preferences.sublime-settings" sublime-merge

if command -v zed >/dev/null 2>&1; then
    link_file "${dotfiles_dir}/settings/zed/settings-${profile}.json" "${HOME}/.config/zed/settings.json" .config/zed
else
    echo "Zed is not installed. Skipping Zed settings."
fi

# glab: local/ is gitignored and owned by glab (it holds the hostname, username
# and glab's in-place rewrites). Seed the prefs once; `glab auth login` writes
# the host block itself, so there is nothing to generate here.
mkdir -p "${dotfiles_dir}/settings/glab/local"
link_file "${dotfiles_dir}/settings/glab/aliases.yml" "${dotfiles_dir}/settings/glab/local/aliases.yml" glab
[[ -f "${dotfiles_dir}/settings/glab/local/config.yml" ]] || \
    cp "${dotfiles_dir}/settings/glab/config.yml" "${dotfiles_dir}/settings/glab/local/config.yml"

# macOS system settings
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Dock
  dock_before=$(defaults export com.apple.dock - 2>/dev/null | md5 -q)
  defaults write com.apple.dock "autohide-delay" -float "0"
  defaults write com.apple.dock "static-only" -bool "true"
  defaults write com.apple.dock autohide -bool true
  defaults write com.apple.dock launchanim -bool false
  defaults write com.apple.dock show-recents -bool false
  dock_after=$(defaults export com.apple.dock - 2>/dev/null | md5 -q)
  [[ "$dock_before" != "$dock_after" ]] && killall Dock

  # Finder
  finder_before=$(defaults export com.apple.finder - 2>/dev/null | md5 -q)
  global_ext_before=$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)
  defaults write com.apple.finder ShowPathbar -bool true
  defaults write com.apple.finder ShowStatusBar -bool true
  defaults write NSGlobalDomain AppleShowAllExtensions -bool true
  finder_after=$(defaults export com.apple.finder - 2>/dev/null | md5 -q)
  global_ext_after=$(defaults read NSGlobalDomain AppleShowAllExtensions 2>/dev/null)
  if [[ "$finder_before" != "$finder_after" || "$global_ext_before" != "$global_ext_after" ]]; then
    killall Finder
  fi

  # Keyboard
  defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
  defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

  # Trackpad — tap to click
  defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
  defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true

  # Screenshots
  mkdir -p "${HOME}/Screenshots"
  screencapture_before=$(defaults read com.apple.screencapture location 2>/dev/null)
  defaults write com.apple.screencapture location -string "${HOME}/Screenshots"
  screencapture_after=$(defaults read com.apple.screencapture location 2>/dev/null)
  # SystemUIServer caches this value; without a restart the write is ignored
  [[ "$screencapture_before" != "$screencapture_after" ]] && killall SystemUIServer

  # Display dimming
  # sudo pmset -a lessbright 0 # rollback - sudo pmset -b lessbright 1
fi

# install Homebrew packages from Brewfile
if command -v brew &>/dev/null && [[ -f "${dotfiles_dir}/Brewfile" ]]; then
  brew bundle install --file="${dotfiles_dir}/Brewfile" --no-upgrade || echo "Warning: brew bundle had errors" >&2
fi

# Claude Code config (settings.json selected by profile)
claude_dir="${HOME}/.claude"

for file in CLAUDE.md statusline-command.sh keybindings.json; do
    link_file "${dotfiles_dir}/settings/claude/${file}" "${claude_dir}/${file}" claude
done
link_file "${dotfiles_dir}/settings/claude/settings-${profile}.json" "${claude_dir}/settings.json" claude
for dir in skills rules hooks; do
    link_file "${dotfiles_dir}/settings/claude/${dir}" "${claude_dir}/${dir}" claude
done
echo "Claude Code config linked (profile: ${profile})"

# Obsidian settings (vault paths defined in .private)
if [[ ${#OBSIDIAN_VAULTS[@]} -gt 0 ]]; then
    for vault_path in "${OBSIDIAN_VAULTS[@]}"; do
        if [[ -d "$vault_path" ]]; then
            link_file "${dotfiles_dir}/settings/obsidian/default" "${vault_path}/.obsidian" "obsidian/$(basename "$vault_path")"
        else
            echo "Obsidian vault not found: $vault_path, skipping"
        fi
    done
else
    echo "No OBSIDIAN_VAULTS defined in .private, skipping Obsidian setup"
fi
