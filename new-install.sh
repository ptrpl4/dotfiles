current_date=$(date +%Y-%m-%d)

# Define backup dir
backupdir="${HOME}/dotfiles/backups/${current_date}"

# Create the backup directory if it doesn't exist
mkdir -p "${backupdir}"
echo "Backup dir created /dotfile/backups"

# list of files/folders to symlink in ${homedir}
files=(zshrc zprompt zprofile bashrc bash_prompt bash_profile aliases private)

for file in "${files[@]}"; do
    # Check if the file already exists in the home directory
    if [ -e "${HOME}/.${file}" ]; then
        echo "Backing up $file to ${backupdir}"
        # Backup the file to the backup directory
        cp "${HOME}/.${file}" "${backupdir}/"
    fi

    # echo "Creating symlink to $file in home directory"
    # # Create the symlink
    # ln -sf "${dotfiledir}/.${file}" "${HOME}/.${file}"
done
