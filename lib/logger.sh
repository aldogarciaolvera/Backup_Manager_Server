#!/bin/bash

#######################################
# Logger
#######################################

mkdir -p "$LOG_DIR"

#######################################
# Internal
#######################################

_write_log() {

    local level="$1"
    local message="$2"
    local timestamp
    local line

    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"

    line="[$timestamp] [$level] $message"

    # Consola (stderr para no interferir con stdout)
    printf '%s\n' "$line" >&2

    # Archivo
    printf '%s\n' "$line" >> "$LOG_FILE"
}

#######################################
# Public API
#######################################

log_info() {
    _write_log "INFO" "$1"
}

log_success() {
    _write_log "SUCCESS" "$1"
}

log_warning() {
    _write_log "WARNING" "$1"
}

log_error() {
    _write_log "ERROR" "$1"
}
