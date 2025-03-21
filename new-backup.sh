#!/usr/bin/env bash


# Create the backup directory if it doesn't exist
current_date=$(date +%Y-%m-%d)
backup_dir="${HOME}/dotfiles/backups/${current_date}"
apps_backup_file="apps.txt"

mkdir -p "${backup_dir}"
echo "Backup dir created /dotfile/backups"

# copy list of installed apps
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Running on macOS
    ls /Applications | cat > "${backup_dir}"/"${apps_backup_file}"
    echo "Application list backed up"
else
    echo "Not running on macOS, skipping application backup"
fi
