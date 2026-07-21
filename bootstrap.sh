#!/bin/bash

BACKUP_MANAGER_DIR="${BACKUP_MANAGER_DIR:-$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)}"

export BACKUP_MANAGER_DIR

source "$BACKUP_MANAGER_DIR/config.sh"

source "$BACKUP_MANAGER_DIR/lib/logger.sh"
source "$BACKUP_MANAGER_DIR/lib/utils.sh"
source "$BACKUP_MANAGER_DIR/lib/workspace.sh"
source "$BACKUP_MANAGER_DIR/lib/errors.sh"
source "$BACKUP_MANAGER_DIR/lib/manifest.sh"
source "$BACKUP_MANAGER_DIR/lib/archive.sh"
source "$BACKUP_MANAGER_DIR/lib/pipeline.sh"
source "$BACKUP_MANAGER_DIR/lib/restore.sh"
source "$BACKUP_MANAGER_DIR/lib/retention.sh"

source "$BACKUP_MANAGER_DIR/modules/backup/server.sh"
source "$BACKUP_MANAGER_DIR/modules/backup/postgres.sh"
source "$BACKUP_MANAGER_DIR/modules/backup/mysql.sh"

source "$BACKUP_MANAGER_DIR/modules/restore/mysql.sh"
source "$BACKUP_MANAGER_DIR/modules/restore/postgres.sh"

enable_error_handling
