#!/bin/bash

#######################################
# Backup Manager Configuration
#######################################

# Proyecto
export BACKUP_MANAGER_DIR="${BACKUP_MANAGER_DIR:-/opt/scripts/backup-manager}"

#######################################
# Sistema
#######################################

export SERVER_USER="wall2"
export SERVER_HOME="/home/$SERVER_USER"

export HOSTNAME="${HOSTNAME:-$(hostname)}"
export DATE="${DATE:-$(date +'%Y-%m-%d')}"
export TIMESTAMP="${TIMESTAMP:-$(date +'%Y-%m-%d_%H-%M-%S')}"

#######################################
# Directorios
#######################################

export BACKUP_ROOT="/mnt/storage/backups"

export SERVER_DIR="$BACKUP_ROOT/server"
export POSTGRES_DIR="$BACKUP_ROOT/postgres"
export MYSQL_DIR="$BACKUP_ROOT/mysql"

export DAILY_DIR="$BACKUP_ROOT/daily"
export WEEKLY_DIR="$BACKUP_ROOT/weekly"
export MONTHLY_DIR="$BACKUP_ROOT/monthly"

export DOKPLOY_DIR="$BACKUP_ROOT/dokploy"
export APPS_DIR="$BACKUP_ROOT/apps"
export LOG_DIR="$BACKUP_ROOT/logs"

export TEMP_DIR="/tmp/backup-manager"

#######################################
# Herramientas del host
#######################################

export DOCKER_BIN="docker"
export TAR_BIN="tar"
export ZSTD_BIN="zstd"
export SHA256_BIN="sha256sum"
export FIND_BIN="find"
export DU_BIN="du"

#######################################
# Compresión
#######################################

export COMPRESSOR="$ZSTD_BIN"
export COMPRESS_LEVEL=10

#######################################
# Retención
#######################################

export KEEP_SERVER=7
export KEEP_POSTGRES=7
export KEEP_MYSQL=7

# Compatibilidad con configuración anterior
export KEEP_DAILY=7
export KEEP_WEEKLY=4
export KEEP_MONTHLY=12

#######################################
# Permisos
#######################################

export BACKUP_DIRECTORY_MODE=700
export BACKUP_FILE_MODE=600
export WORKSPACE_DIRECTORY_MODE=700
export EXTRACTED_FILE_MODE=600

#######################################
# Logging
#######################################

export LOG_LEVEL="INFO"
export LOG_FILE="$LOG_DIR/backup-$DATE.log"
