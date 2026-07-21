#!/bin/bash

resolve_latest_backup() {
    local backup_directory="$1"
    local backup_prefix="$2"
    local latest_backup

    if [[ ! -d "$backup_directory" ]]; then
        log_error "No existe el directorio de respaldos: $backup_directory"
        return 1
    fi

    latest_backup="$(
        find "$backup_directory" \
            -maxdepth 1 \
            -type f \
            -name "${backup_prefix}-*.tar.zst" \
            -printf '%T@ %p\n' |
        sort -nr |
        sed -n '1s/^[^ ]* //p'
    )"

    if [[ -z "$latest_backup" ]]; then
        log_error "No se encontraron respaldos de tipo: $backup_prefix"
        return 1
    fi

    printf '%s\n' "$latest_backup"
}

validate_restore_archive() {
    local archive_path="$1"
    local checksum_path="${archive_path}.sha256"

    if [[ ! -f "$archive_path" ]]; then
        log_error "No existe el archivo de respaldo: $archive_path"
        return 1
    fi

    if [[ ! -f "$checksum_path" ]]; then
        log_error "No existe el checksum: $checksum_path"
        return 1
    fi

    log_info "Verificando archivo antes de restaurar"

    verify_archive "$archive_path"
    verify_archive_checksum "$checksum_path"

    log_success "El respaldo pasó las verificaciones de integridad"
}

find_sql_entry_in_archive() {
    local archive_path="$1"
    local -a sql_entries=()

    mapfile -t sql_entries < <(
        tar \
            --use-compress-program=zstd \
            --list \
            --file="$archive_path" |
        grep -E '^data/[^/]+\.sql$'
    )

    if (( ${#sql_entries[@]} == 0 )); then
        log_error "El respaldo no contiene ningún archivo SQL"
        return 1
    fi

    if (( ${#sql_entries[@]} > 1 )); then
        log_error "El respaldo contiene más de un archivo SQL"
        return 1
    fi

    printf '%s\n' "${sql_entries[0]}"
}

extract_archive_entry() {
    local archive_path="$1"
    local archive_entry="$2"
    local destination_file="$3"

    log_info "Extrayendo: $archive_entry"

    tar \
        --use-compress-program=zstd \
        --extract \
        --to-stdout \
        --file="$archive_path" \
        "$archive_entry" \
        > "$destination_file"

    if [[ ! -s "$destination_file" ]]; then
        log_error "El archivo extraído está vacío: $destination_file"
        return 1
    fi

    chmod "$EXTRACTED_FILE_MODE" "$destination_file"

    log_success "Archivo extraído correctamente"
}

prepare_postgres_database_restore() {
    local source_file="$1"
    local destination_file="$2"
    local source_database="$3"
    local target_database="$4"

    if [[ ! -s "$source_file" ]]; then
        log_error "El dump PostgreSQL está vacío: $source_file"
        return 1
    fi

    log_info "Extrayendo la sección de la base: $source_database"

    awk \
        -v source_database="$source_database" '
        BEGIN {
            capturing = 0
        }

        $0 == "\\connect " source_database {
            capturing = 1
            next
        }

        capturing && /^\\connect / {
            exit
        }

        capturing {
            print
        }
        ' "$source_file" > "$destination_file"

    if [[ ! -s "$destination_file" ]]; then
        log_error "No se encontró contenido para la base: $source_database"
        return 1
    fi

    chmod "$EXTRACTED_FILE_MODE" "$destination_file"

    log_success "SQL preparado para restauración"
}
