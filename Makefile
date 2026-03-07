BACKUP_SCRIPT = backup.sh
INSTALL_SCRIPT = install.sh

.PHONY: backup install

backup:
	@echo "Running backup script..."
	bash $(BACKUP_SCRIPT)

install:
	@echo "Running install script..."
	bash $(INSTALL_SCRIPT)
