#!/usr/bin/env bash


# Create the backup directory if it doesn't exist
current_date=$(date +%Y-%m-%d)
backup_dir="${HOME}/dotfiles/backups/${LOGNAME}/${current_date}"

mkdir -p "${backup_dir}"
mkdir -p "${backup_dir}/obsidian"
echo "Backup dir created /dotfile/backups"

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
        echo "Backing up $file to ${backup_dir}"
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
mkdir -p "${backup_dir}/.config/zed" && \
cp "${HOME}/.config/zed/settings.json" "${backup_dir}/.config/zed" && \
ln -sf "${HOME}/dotfiles/settings/zed/settings.json" "${HOME}/.config/zed/settings.json"

# Apply sysstem settings

# !todo-macos-check

# fix dock
defaults write com.apple.dock "autohide-delay" -float "0"
defaults write com.apple.dock "static-only" -bool "true"
killall Dock

# disable display dimming
sudo pmset -a lessbright 0
# rollback
# sudo pmset -b lessbright 1
# or settings/battery/options

# prototype for obsidian
# mkdir -p "${backup_dir}/.obsidian" && \
# cp "${HOME}/${obsidian_project_dir}/.obsidian" "${backup_dir}/${obsidian_project_dir}/.obsidian" && \
# ln -sf "${HOME}/dotfiles/settings/obsidian/project/.obsidian" "${HOME}/.obsidian"

# woraround for obsidian
# cd to vault dir
# make project dir and symlink
# mkdir -p "${HOME}/dotfiles/backups/obsidian/$(basename "$PWD")/.obsidian" \
# && mv ".obsidian" "${HOME}/dotfiles/backups/obsidian/$(basename "$PWD")/" \
# && ln -sf "${HOME}/dotfiles/settings/obsidian/$(basename "$PWD")/.obsidian" "./.obsidian"

# maybe add ${HOME}/.config to backup?


# Purpose of configuration files
## zshrc uses zprompt, aliases, private
## zprompt uses shared_prompt
## bashrc uses bash_prompt, aliases, private
### zprompt
#### shared_prompt
### aliases
### private

###
# todo make aliases private => shared_
