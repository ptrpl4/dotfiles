#!/usr/bin/env bash


# Create the backup directory if it doesn't exist
current_date=$(date +%Y-%m-%d)
backup_dir="${HOME}/dotfiles/backups/${LOGNAME}/${current_date}"
apps_backup_file="apps.txt"
bin_backup_file="bin.txt"
opt_backup_file="opt.txt"
brew_backup_file="brew.txt"

mkdir -p "${backup_dir}"
echo "Backup dir created in /dotfile/backups"

# copy list of installed apps
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Running on macOS
    ls /Applications | cat > "${backup_dir}"/"${apps_backup_file}"
    ls /usr/local/bin | cat > "${backup_dir}"/"${bin_backup_file}"
    ls /opt | cat > "${backup_dir}"/"${opt_backup_file}"
    brew list --versions | cat > "${backup_dir}"/"${brew_backup_file}"

    echo "Backup successful"
else
    echo "Not running on macOS, skipping application backup"
fi
