#!/usr/bin/env bash


# Create the backup directory if it doesn't exist
current_date=$(date +%Y-%m-%d)
backup_dir="${HOME}/dotfiles/backups/${LOGNAME}/${current_date}"

mkdir -p "${backup_dir}"
mkdir -p "${backup_dir}/obsidian"
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

# apply Rectanlnge settings
mkdir -p ~/Library/Application\ Support/Rectangle && cp settings/RectangleConfig.json ~/Library/Application\ Support/Rectangle/RectangleConfig.json

# link Zed settings
if command -v zed >/dev/null 2>&1; then
  echo "Zed detected. Proceeding with settings handling."

  if [ -f "${HOME}/.config/zed/settings.json" ]; then
    echo "Backing up Zed settings"
    mkdir -p "${backup_dir}/.config/zed" && \
    cp "${HOME}/.config/zed/settings.json" "${backup_dir}/.config/zed/"
  else
    echo "No Zed settings.json found; skipping backup."
  fi

  ln -sf "${HOME}/dotfiles/settings/zed/settings.json" "${HOME}/.config/zed/settings.json" && \
  echo "Zed symlink created"
else
  echo "Zed is not installed. Skipping Zed settings backup and symlink."
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

# Apply sysstem settings

# !todo-macos-check

# fix dock
defaults write com.apple.dock "autohide-delay" -float "0"
defaults write com.apple.dock "static-only" -bool "true"
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock launchanim -bool false
killall Dock

# disable display dimming
sudo pmset -a lessbright 0 # rollback - sudo pmset -b lessbright 1

# prototype for obsidian
# mkdir -p "${backup_dir}/.obsidian" && \
# cp "${HOME}/${obsidian_project_dir}/.obsidian" "${backup_dir}/${obsidian_project_dir}/.obsidian" && \
# ln -sf "${HOME}/dotfiles/settings/obsidian/project/.obsidian" "${HOME}/.obsidian"

# workaround for obsidian
# cd to vault dir
# make project dir and symlink
# mkdir -p "${HOME}/dotfiles/backups/obsidian/$(basename "$PWD")/.obsidian" \
# && mv ".obsidian" "${HOME}/dotfiles/backups/obsidian/$(basename "$PWD")/" \
# && ln -sf "${HOME}/dotfiles/settings/obsidian/$(basename "$PWD")/.obsidian" "./.obsidian"

# maybe add ${HOME}/.config to backup?
