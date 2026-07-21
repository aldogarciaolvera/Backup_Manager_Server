#!/bin/bash

finalize_backup_archive() {
    local backup_type="$1"
    local backup_id="$2"
    local workspace="$3"
    local destination_directory="$4"

    local manifest_file
    local temporary_archive
    local temporary_checksum
    local final_archive
    local final_checksum

    if [[ -z "$backup_type" ||
          -z "$backup_id" ||
          -z "$workspace" ||
          -z "$destination_directory" ]]; then
        log_error "Faltan argumentos para finalizar el respaldo"
        return 1
    fi

    if [[ ! -d "$workspace" ]]; then
        log_error "El workspace no existe: $workspace"
        return 1
    fi

    manifest_file="$workspace/manifest.json"

    log_info "Generando manifest"

    create_manifest \
        "$backup_type" \
        "$manifest_file"

    log_info "Comprimiendo respaldo"

    temporary_archive="$(
        compress_workspace \
            "$workspace" \
            "$backup_type" \
            "$backup_id"
    )"

    verify_archive "$temporary_archive"

    temporary_checksum="$(
        generate_archive_checksum "$temporary_archive"
    )"

    verify_archive_checksum "$temporary_checksum"

    mkdir -p "$destination_directory"
    chmod "$BACKUP_DIRECTORY_MODE" "$destination_directory"

    final_archive="$destination_directory/$(basename "$temporary_archive")"
    final_checksum="${final_archive}.sha256"

    mv -- "$temporary_archive" "$final_archive"
    mv -- "$temporary_checksum" "$final_checksum"

    chmod "$BACKUP_FILE_MODE" "$final_archive" "$final_checksum"

    log_success "Archivo final preparado"
    log_info "Archivo: $final_archive"

    printf '%s\n' "$final_archive"
}
