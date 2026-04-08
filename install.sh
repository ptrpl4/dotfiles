#!/usr/bin/env bash

# Create the backup directory if it doesn't exist
install_backup_dir="${HOME}/dotfiles/backups/${LOGNAME}/$(date +%Y-%m-%d)"

mkdir -p "${install_backup_dir}"
echo "Backup dir created"

# List of files/folders to symlink in ${HOME}
files=(zshrc zprompt zprofile zshenv bashrc bash_prompt bash_profile aliases private gitconfig prompt_common)

# dotfiles directory
dotfiles_dir="${HOME}/dotfiles"

for file in "${files[@]}"; do
    if [[ ! -e "${dotfiles_dir}/.${file}" ]]; then
        echo "Skipping $file (not found in dotfiles)"
        continue
    fi

    if [[ -e "${HOME}/.${file}" ]]; then
        echo "Backing up $file"
        cp "${HOME}/.${file}" "${install_backup_dir}/"
    fi

    if ln -sf "${dotfiles_dir}/.${file}" "${HOME}/.${file}"; then
        echo "Linked $file"
    else
        echo "Warning: failed to link $file" >&2
    fi
done

# Source .private for machine-specific variables (ZED_PROFILE, OBSIDIAN_VAULTS)
[[ -f "${dotfiles_dir}/.private" ]] && source "${dotfiles_dir}/.private"

# macOS app settings
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Rectangle
  mkdir -p "${HOME}/Library/Application Support/Rectangle"
  ln -sf "${dotfiles_dir}/settings/rectangle/RectangleConfig.json" "${HOME}/Library/Application Support/Rectangle/RectangleConfig.json"
fi

# link Zed settings (profile defined in .private: "work" or "home")
if command -v zed >/dev/null 2>&1; then
  echo "Zed detected. Proceeding with settings handling."

  if [[ -f "${HOME}/.config/zed/settings.json" ]]; then
    echo "Backing up Zed settings"
    if mkdir -p "${install_backup_dir}/.config/zed"; then
      cp "${HOME}/.config/zed/settings.json" "${install_backup_dir}/.config/zed/"
    else
      echo "Warning: failed to create Zed backup dir" >&2
    fi
  else
    echo "No Zed settings.json found; skipping backup."
  fi

  zed_settings="${dotfiles_dir}/settings/zed/settings-${ZED_PROFILE:-home}.json"
  if [[ -f "$zed_settings" ]]; then
    mkdir -p "${HOME}/.config/zed"
    ln -sf "$zed_settings" "${HOME}/.config/zed/settings.json" && \
    echo "Zed symlink created (profile: ${ZED_PROFILE:-home})"
  else
    echo "Zed profile not found: $zed_settings"
  fi
else
  echo "Zed is not installed. Skipping Zed settings."
fi

# link other Run Commands

if [[ -f "${dotfiles_dir}/.netrc" ]]; then
  ln -sf "${dotfiles_dir}/.netrc" "${HOME}/.netrc"
else
  echo ".netrc not found in dotfiles, skipping"
fi

if [[ -f "${dotfiles_dir}/.npmrc" ]]; then
  ln -sf "${dotfiles_dir}/.npmrc" "${HOME}/.npmrc"
else
  echo ".npmrc not found in dotfiles, skipping"
fi

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
  defaults write com.apple.screencapture location -string "${HOME}/Screenshots"

  # Display dimming
  sudo pmset -a lessbright 0 # rollback - sudo pmset -b lessbright 1
fi

# install Homebrew packages from Brewfile
if command -v brew &>/dev/null && [[ -f "${dotfiles_dir}/Brewfile" ]]; then
  brew bundle install --file="${dotfiles_dir}/Brewfile" --no-upgrade || echo "Warning: brew bundle had errors" >&2
fi

# link Claude Code config
claude_dir="${HOME}/.claude"
mkdir -p "${claude_dir}"
for file in CLAUDE.md statusline-command.sh settings.json keybindings.json; do
  if [[ ! -f "${dotfiles_dir}/settings/claude/${file}" ]]; then
    echo "Skipping Claude ${file} (not found in dotfiles)"
    continue
  fi
  if [[ -f "${claude_dir}/${file}" && ! -L "${claude_dir}/${file}" ]]; then
    echo "Backing up Claude ${file}"
    mkdir -p "${install_backup_dir}/claude"
    cp "${claude_dir}/${file}" "${install_backup_dir}/claude/"
  fi
  ln -sf "${dotfiles_dir}/settings/claude/${file}" "${claude_dir}/${file}"
done

for dir in skills rules; do
  if [[ -d "${claude_dir}/${dir}" && ! -L "${claude_dir}/${dir}" ]]; then
    echo "Backing up Claude ${dir}/"
    mkdir -p "${install_backup_dir}/claude"
    cp -r "${claude_dir}/${dir}" "${install_backup_dir}/claude/"
  fi
  ln -sfn "${dotfiles_dir}/settings/claude/${dir}" "${claude_dir}/${dir}"
done
echo "Claude Code config linked"

# link Obsidian settings (vault paths defined in .private)
if [[ ${#OBSIDIAN_VAULTS[@]} -gt 0 ]]; then
  for vault_path in "${OBSIDIAN_VAULTS[@]}"; do
    if [[ -d "$vault_path" ]]; then
      local_obsidian="${vault_path}/.obsidian"

      # Backup existing config if it's not already a symlink
      if [[ -d "$local_obsidian" && ! -L "$local_obsidian" ]]; then
        obsidian_backup="${install_backup_dir}/obsidian/$(basename "$vault_path")"
        if [[ -d "${obsidian_backup}/.obsidian" ]]; then
          echo "Warning: Obsidian backup already exists for $(basename "$vault_path"), skipping"
        else
          echo "Backing up Obsidian config for $(basename "$vault_path")"
          mkdir -p "${obsidian_backup}"
          mv "$local_obsidian" "${obsidian_backup}/"
        fi
      fi

      ln -sfn "${dotfiles_dir}/settings/obsidian/default" "$local_obsidian"
      echo "Obsidian symlink created for $(basename "$vault_path")"
    else
      echo "Obsidian vault not found: $vault_path, skipping"
    fi
  done
else
  echo "No OBSIDIAN_VAULTS defined in .private, skipping Obsidian setup"
fi
