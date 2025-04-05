#!/usr/bin/env bash


# Create the backup directory if it doesn't exist
current_date=$(date +%Y-%m-%d)
backup_dir="${HOME}/dotfiles/backups/${LOGNAME}/${current_date}"
apps_backup_file="apps.txt"
bin_backup_file="bin.txt"
opt_backup_file="opt.txt"
brew_backup_file="brew.txt"
apt_backup_file="apt.txt"

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
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Running on Linux
    ls /usr/bin | cat > "${backup_dir}"/"${bin_backup_file}"
    ls /opt | cat > "${backup_dir}"/"${opt_backup_file}"

    # APT (Debian/Ubuntu)
    if command -v apt &> /dev/null; then
        dpkg --get-selections | cat > "${backup_dir}"/"${apt_backup_file}"
        echo "APT packages backed up"
    fi

    echo "Linux backup successful"
else
    echo "Unsupported operating system: $OSTYPE"
fi

# TODO add adguard, pihole
