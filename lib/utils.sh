#!/bin/bash

#######################################
# File and Directory
#######################################

file_exists() {
    [[ -f "$1" ]]
}

directory_exists() {
    [[ -d "$1" ]]
}

ensure_directory() {

    local dir="$1"

    if ! directory_exists "$dir"; then
        mkdir -p "$dir"
    fi
}

#######################################
# Commands
#######################################

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#######################################
# System
#######################################

get_hostname() {
    hostname
}

get_timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}

#######################################
# Disk
#######################################

get_free_space() {

    df -h "$1" | awk 'NR==2 {print $4}'
}

get_file_size() {

    du -sh "$1" | cut -f1
}

#######################################
# Hash
#######################################

calculate_sha256() {

    sha256sum "$1" | awk '{print $1}'
}

#######################################
# Validation
#######################################

require_command() {

    local cmd="$1"

    if ! command_exists "$cmd"; then

        log_error "Required command '$cmd' not found."

        exit 1
    fi
}

#######################################
# UUID / IDs
#######################################

generate_backup_id() {

    local timestamp
    local random

    timestamp="$(date +%Y%m%d-%H%M%S)"

    random_hex="$(
        od -An -N3 -tx1 /dev/urandom |
        tr -d ' \n' |
        tr '[:lower:]' '[:upper:]'
    )"

    printf "%s-%s" "$timestamp" "$random_hex"
}

#######################################
# Date
#######################################

iso_datetime() {

    date --iso-8601=seconds
}

#######################################
# Workspace
#######################################

create_workspace() {
    local backup_id="${1:-}"

    if [[ -z "$backup_id" ]]; then
        log_error "No se indicó un backup ID para crear el workspace"
        return 1
    fi

    local workspace="$TEMP_DIR/$backup_id"

    ensure_directory "$workspace"
    ensure_directory "$workspace/data"
    ensure_directory "$workspace/output"

    printf '%s' "$workspace"
}

remove_workspace() {
    local workspace="${1:-}"

    if [[ -z "$workspace" ]]; then
        log_error "No se indicó un workspace para eliminar"
        return 1
    fi

    if [[ "$workspace" != "$TEMP_DIR/"* ]]; then
        log_error "Se rechazó eliminar una ruta fuera de TEMP_DIR: $workspace"
        return 1
    fi

    if [[ -d "$workspace" ]]; then
        rm -rf -- "$workspace"
        log_success "Workspace eliminado: $workspace"
    fi
}

validate_workspace() {
    local workspace="${1:-}"

    if [[ -z "$workspace" ]]; then
        log_error "No se indicó un workspace"
        return 1
    fi

    if [[ ! -d "$workspace" ]]; then
        log_error "El workspace no existe: $workspace"
        return 1
    fi

    if [[ ! -d "$workspace/data" ]]; then
        log_error "El workspace no contiene data/: $workspace"
        return 1
    fi

    if [[ ! -d "$workspace/output" ]]; then
        log_error "El workspace no contiene output/: $workspace"
        return 1
    fi

    return 0
}

get_postgres_env_value() {
    local container_name="$1"
    local variable_name="$2"
    local variable_value

    if [[ -z "$container_name" || -z "$variable_name" ]]; then
        log_error "Uso: get_postgres_env_value CONTENEDOR VARIABLE"
        return 1
    fi

    variable_value="$(
        docker inspect \
            --format '{{range .Config.Env}}{{println .}}{{end}}' \
            "$container_name" |
        awk -F= \
            -v variable_name="$variable_name" \
            '$1 == variable_name {
                sub(/^[^=]*=/, "")
                print
                exit
            }'
    )"

    if [[ -z "$variable_value" ]]; then
        log_error "No se encontró $variable_name en el contenedor $container_name"
        return 1
    fi

    printf '%s\n' "$variable_value"
}
