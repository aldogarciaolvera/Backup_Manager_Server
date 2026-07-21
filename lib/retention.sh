#!/bin/bash

validate_retention_directory() {
    local backup_directory="$1"

    if [[ -z "$backup_directory" ]]; then
        log_error "No se especificó un directorio para la retención"
        return 1
    fi

    if [[ "$backup_directory" != "$BACKUP_ROOT/"* ]]; then
        log_error "Directorio de retención fuera de BACKUP_ROOT: $backup_directory"
        return 1
    fi

    if [[ ! -d "$backup_directory" ]]; then
        log_warning "El directorio no existe; se omite retención: $backup_directory"
        return 0
    fi
}

cleanup_backup_directory() {
    local backup_directory="$1"
    local backup_prefix="$2"
    local keep_count="$3"
    local dry_run="${4:-false}"

    local -a archives=()
    local archive
    local checksum
    local total
    local delete_count
    local index

    validate_retention_directory "$backup_directory"

    if [[ ! "$keep_count" =~ ^[0-9]+$ ]] || (( keep_count < 1 )); then
        log_error "Cantidad de retención inválida: $keep_count"
        return 1
    fi

    mapfile -t archives < <(
        find "$backup_directory" \
            -maxdepth 1 \
            -type f \
            -name "${backup_prefix}-*.tar.zst" \
            -printf '%T@ %p\n' |
        sort -nr |
        cut -d' ' -f2-
    )

    total="${#archives[@]}"

    log_info "Retención $backup_prefix: $total respaldo(s), se conservarán $keep_count"

    if (( total <= keep_count )); then
        log_info "No hay respaldos antiguos para eliminar"
        return 0
    fi

    delete_count="$((total - keep_count))"

    for ((index = keep_count; index < total; index++)); do
        archive="${archives[$index]}"
        checksum="${archive}.sha256"

        if [[ "$dry_run" == "true" ]]; then
            log_warning "[SIMULACIÓN] Se eliminaría: $archive"

            if [[ -f "$checksum" ]]; then
                log_warning "[SIMULACIÓN] Se eliminaría: $checksum"
            fi

            continue
        fi

        rm -f -- "$archive"
        log_success "Respaldo antiguo eliminado: $archive"

        if [[ -f "$checksum" ]]; then
            rm -f -- "$checksum"
            log_success "Checksum antiguo eliminado: $checksum"
        fi
    done

    log_success "Retención completada: $delete_count respaldo(s) eliminado(s)"
}

cleanup_all_backups() {
    local dry_run="${1:-false}"

    log_info "Iniciando política de retención"

    cleanup_backup_directory \
        "$SERVER_DIR" \
        "server" \
        "$KEEP_SERVER"
    cleanup_backup_directory \
        "$POSTGRES_DIR" \
        "postgres" \
        "$KEEP_POSTGRES"

    cleanup_backup_directory \
        "$MYSQL_DIR" \
        "mysql" \
        "$KEEP_MYSQL"

    log_success "Política de retención finalizada"
}
