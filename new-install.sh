#!/usr/bin/env bash


# Create the backup directory if it doesn't exist
current_date=$(date +%Y-%m-%d)
backup_dir="${HOME}/dotfiles/backups/${LOGNAME}/${current_date}"

mkdir -p "${backup_dir}"
echo "Backup dir created"

# List of files/folders to symlink in ${HOME}
files=(zshrc zprompt zprofile bashrc bash_prompt bash_profile aliases private gitconfig)

# dotfiles directory
dotfile_dir="${HOME}/dotfiles"

# change to the dotfiles directory
echo "Changing to the ${dotfile_dir} directory"
cd "${dotfile_dir}" || exit

for file in "${files[@]}"; do
    # Check if the file already exists in the home directory
    if [ -e "${HOME}/.${file}" ]; then
        echo "Backing up $file"
        # Backup the file to the backup directory
        cp "${HOME}/.${file}" "${backup_dir}/"
    fi

    echo "Creating symlink to $file in home directory"
    # Create the symlink
    ln -sf "${dotfile_dir}/.${file}" "${HOME}/.${file}"
done

# Source .private for machine-specific variables (ZED_PROFILE, OBSIDIAN_VAULTS)
[[ -f "${dotfile_dir}/.private" ]] && source "${dotfile_dir}/.private"

# apply Rectanlnge settings
mkdir -p ~/Library/Application\ Support/Rectangle && cp settings/RectangleConfig.json ~/Library/Application\ Support/Rectangle/RectangleConfig.json

# link Zed settings (profile defined in .private: "work" or "home")
if command -v zed >/dev/null 2>&1; then
  echo "Zed detected. Proceeding with settings handling."

  if [ -f "${HOME}/.config/zed/settings.json" ]; then
    echo "Backing up Zed settings"
    mkdir -p "${backup_dir}/.config/zed" && \
    cp "${HOME}/.config/zed/settings.json" "${backup_dir}/.config/zed/"
  else
    echo "No Zed settings.json found; skipping backup."
  fi

  zed_settings="${dotfile_dir}/settings/zed/settings-${ZED_PROFILE:-home}.json"
  if [[ -f "$zed_settings" ]]; then
    ln -sf "$zed_settings" "${HOME}/.config/zed/settings.json" && \
    echo "Zed symlink created (profile: ${ZED_PROFILE:-home})"
  else
    echo "Zed profile not found: $zed_settings"
  fi
else
  echo "Zed is not installed. Skipping Zed settings."
fi

# link other Run Commands

if [ -f "${HOME}/dotfiles/.netrc" ]; then
  ln -sf ~/dotfiles/.netrc ~/.netrc
else
  echo "~/dotfiles/.netrc does not exist, skipping symlink."
fi

if [ -f "${HOME}/dotfiles/.npmrc" ]; then
  ln -sf ~/dotfiles/.npmrc ~/.npmrc
else
  echo "~/dotfiles/.npmrc does not exist, skipping symlink."
fi

# Apply system settings

# fix dock
defaults write com.apple.dock "autohide-delay" -float "0"
defaults write com.apple.dock "static-only" -bool "true"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock launchanim -bool false
killall Dock

# disable display dimming
sudo pmset -a lessbright 0 # rollback - sudo pmset -b lessbright 1

# link Obsidian settings (vault paths defined in .private)
if [[ ${#OBSIDIAN_VAULTS[@]} -gt 0 ]]; then
  for vault_path in "${OBSIDIAN_VAULTS[@]}"; do
    if [[ -d "$vault_path" ]]; then
      local_obsidian="${vault_path}/.obsidian"

      # Backup existing config if it's not already a symlink
      if [[ -d "$local_obsidian" && ! -L "$local_obsidian" ]]; then
        echo "Backing up Obsidian config for $(basename "$vault_path")"
        mkdir -p "${backup_dir}/obsidian/$(basename "$vault_path")"
        cp -R "$local_obsidian" "${backup_dir}/obsidian/$(basename "$vault_path")/"
        rm -rf "$local_obsidian"
      fi

      ln -sfn "${dotfile_dir}/settings/obsidian/default" "$local_obsidian"
      echo "Obsidian symlink created for $(basename "$vault_path")"
    else
      echo "Obsidian vault not found: $vault_path, skipping"
    fi
  done
else
  echo "No OBSIDIAN_VAULTS defined in .private, skipping Obsidian setup"
fi
