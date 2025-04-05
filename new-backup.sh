#!/usr/bin/env bash

current_date=$(date +%Y-%m-%d)
backup_dir="${HOME}/dotfiles/backups/${LOGNAME}/${current_date}"
apps_backup_file="apps.txt"
bin_backup_file="bin.txt"
opt_backup_file="opt.txt"
brew_backup_file="brew.txt"
apt_backup_file="apt.txt"
adguard_backup_dir="adguard"

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

    # AdGuard backup (Linux)
    mkdir -p "${backup_dir}/${adguard_backup_dir}"

    # Check for AdGuard Home installation in system directory
    if sudo test -d "/opt/AdGuardHome"; then
        echo "Found AdGuard Home installation, backing up configuration..."

        # Backup only AdGuardHome.yaml configuration file with sudo
        if sudo test -f "/opt/AdGuardHome/AdGuardHome.yaml"; then
            # Copy just the yaml file
            sudo cp "/opt/AdGuardHome/AdGuardHome.yaml" "${backup_dir}/${adguard_backup_dir}/"

            # Fix ownership
            sudo chown "$(whoami):$(id -gn)" "${backup_dir}/${adguard_backup_dir}/AdGuardHome.yaml"
            echo "AdGuardHome.yaml configuration backed up"
        else
            echo "Warning: AdGuardHome.yaml not found, skipping configuration backup"
        fi
    fi

    echo "Linux backup successful"
else
    echo "Unsupported operating system: $OSTYPE"
fi

# TODO add pihole
