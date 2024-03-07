#!/usr/bin/env zsh


# Create the backup directory if it doesn't exist
current_date=$(date +%Y-%m-%d)
backup_dir="${HOME}/dotfiles/backups/${current_date}"

mkdir -p "${backup_dir}"
echo "Backup dir created /dotfile/backups"


# List of files/folders to symlink in ${HOME}
files=(zshrc zprompt zprofile bashrc bash_prompt bash_profile aliases private)

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

###
# Connection between config files

# zshrc uses zprompt,aliases,private
 # zprompt uses .shared_prompt
# bashrc uses bash_prompt aliases private


###
# todo make aliases private => shared_