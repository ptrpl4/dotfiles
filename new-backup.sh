#!/usr/bin/env bash
#
# new-backup.sh - Backup system configurations and installed applications
# This script creates backups of installed applications and configurations on macOS and Linux systems.

# Constants
readonly BACKUP_DATE=$(date +%Y-%m-%d)
readonly BACKUP_DIR="${HOME}/dotfiles/backups/${LOGNAME}/${BACKUP_DATE}"
readonly APPS_FILE="apps.txt"
readonly BIN_FILE="bin.txt"
readonly OPT_FILE="opt.txt"
readonly BREW_FILE="brew.txt"
readonly APT_FILE="apt.txt"
readonly ADGUARD_DIR="adguard"

# Create backup directory
mkdir -p "${BACKUP_DIR}"
echo "Backup dir created in ${BACKUP_DIR}"

# Function to backup directory listings
backup_directory_listing() {
  local dir="$1"
  local output_file="$2"

  if [[ -d "$dir" ]]; then
    ls "$dir" > "$output_file"
  fi
}

# Function to backup file with optional sudo
backup_file() {
  local src="$1"
  local dest_dir="$2"
  local needs_sudo="${3:-false}"

  if [[ "$needs_sudo" == "true" ]]; then
    if sudo test -f "$src"; then
      sudo cp "$src" "$dest_dir/"
      sudo chown "$(whoami):$(id -gn)" "$dest_dir/$(basename "$src")"
      echo "Backed up $src"
    else
      echo "Warning: $src not found, skipping"
    fi
  else
    if [[ -f "$src" ]]; then
      cp "$src" "$dest_dir/"
      echo "Backed up $src"
    fi
  fi
}

# copy list of installed apps
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Running on macOS
  backup_directory_listing "/Applications" "${BACKUP_DIR}/${APPS_FILE}"
  backup_directory_listing "/usr/local/bin" "${BACKUP_DIR}/${BIN_FILE}"
  backup_directory_listing "/opt" "${BACKUP_DIR}/${OPT_FILE}"

  if command -v brew &> /dev/null; then
    brew list --versions > "${BACKUP_DIR}/${BREW_FILE}"
  fi

  echo "Backup successful"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Running on Linux
  backup_directory_listing "/usr/bin" "${BACKUP_DIR}/${BIN_FILE}"
  backup_directory_listing "/opt" "${BACKUP_DIR}/${OPT_FILE}"

  # APT (Debian/Ubuntu)
  if command -v apt &> /dev/null; then
    dpkg --get-selections > "${BACKUP_DIR}/${APT_FILE}"
    echo "APT packages backed up"
  fi

  # AdGuard backup (Linux)
  mkdir -p "${BACKUP_DIR}/${ADGUARD_DIR}"

  # Check for AdGuard Home installation and backup in one step
  if sudo test -d "/opt/AdGuardHome" && sudo test -f "/opt/AdGuardHome/AdGuardHome.yaml"; then
    echo "Found AdGuard Home installation, backing up configuration..."
    backup_file "/opt/AdGuardHome/AdGuardHome.yaml" "${BACKUP_DIR}/${ADGUARD_DIR}" "true"
  fi

  echo "Linux backup successful"
else
  echo "Unsupported operating system: $OSTYPE"
fi
