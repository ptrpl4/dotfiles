BACKUP_SCRIPT = new-backup.sh
INSTALL_SCRIPT = new-install.sh

.PHONY: backup install

backup:
	@echo "Running backup script..."
	bash $(BACKUP_SCRIPT)

install:
	@echo "Running install script..."
	bash $(INSTALL_SCRIPT)
