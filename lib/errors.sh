#!/bin/bash

handle_error() {
    local exit_code=$?
    local line_number="${1:-unknown}"
    local failed_command="${2:-unknown}"
    local script_name

    script_name="$(basename "${BASH_SOURCE[1]:-$0}")"

    log_error "Ocurrió un error no controlado"
    log_error "Script: $script_name"
    log_error "Línea: $line_number"
    log_error "Comando: $failed_command"
    log_error "Código de salida: $exit_code"

    exit "$exit_code"
}

enable_error_handling() {
    set -Eeuo pipefail
    trap 'handle_error "$LINENO" "$BASH_COMMAND"' ERR
}

