#!/bin/bash

#######################################
# Verifica dependencias de compresión
#######################################
validate_archive_dependencies() {
    require_command tar
    require_command zstd
    require_command sha256sum
}

#######################################
# Genera el nombre del archivo
#######################################
build_archive_name() {
    local backup_type="${1:-}"
    local backup_id="${2:-}"

    if [[ -z "$backup_type" || -z "$backup_id" ]]; then
        log_error "No se pudo generar el nombre del archivo"
        return 1
    fi

    printf '%s-%s.tar.zst' "$backup_type" "$backup_id"
}

#######################################
# Comprime data/ y manifest.json
#######################################
compress_workspace() {
    local workspace="${1:-}"
    local backup_type="${2:-}"
    local backup_id="${3:-}"

    validate_workspace "$workspace"
    validate_archive_dependencies

    local archive_name
    local archive_path

    archive_name="$(build_archive_name "$backup_type" "$backup_id")"
    archive_path="$workspace/output/$archive_name"

    log_info "Comprimiendo workspace: $workspace"

    tar \
        --create \
        --directory="$workspace" \
        --file=- \
        manifest.json data \
    | zstd \
        "-$COMPRESS_LEVEL" \
        --threads=0 \
        --quiet \
        > "$archive_path"

    if [[ ! -s "$archive_path" ]]; then
        log_error "El archivo comprimido no fue creado correctamente"
        return 1
    fi

    log_success "Archivo generado: $archive_path"

    printf '%s' "$archive_path"
}

#######################################
# Verifica la integridad del archivo
#######################################
verify_archive() {
    local archive_path="${1:-}"

    if [[ ! -s "$archive_path" ]]; then
        log_error "El archivo no existe o está vacío: $archive_path"
        return 1
    fi

    log_info "Verificando integridad del archivo"

    if ! zstd --test --quiet "$archive_path"; then
        log_error "La verificación Zstandard falló: $archive_path"
        return 1
    fi

    if ! tar --use-compress-program=zstd --list --file="$archive_path" >/dev/null; then
        log_error "La verificación TAR falló: $archive_path"
        return 1
    fi

    log_success "Integridad verificada: $archive_path"
}

#######################################
# Genera checksum SHA-256
#######################################
generate_archive_checksum() {
    local archive_path="${1:-}"

    if [[ ! -s "$archive_path" ]]; then
        log_error "No se puede generar checksum: archivo inexistente"
        return 1
    fi

    local checksum_file
    checksum_file="${archive_path}.sha256"

    (
        cd "$(dirname "$archive_path")" || return 1
        sha256sum "$(basename "$archive_path")" > "$(basename "$checksum_file")"
    )

    if [[ ! -s "$checksum_file" ]]; then
        log_error "No se generó el checksum correctamente"
        return 1
    fi

    log_success "Checksum generado: $checksum_file"

    printf '%s' "$checksum_file"
}

#######################################
# Verifica checksum SHA-256
#######################################
verify_archive_checksum() {
    local checksum_file="${1:-}"

    if [[ ! -s "$checksum_file" ]]; then
        log_error "El archivo de checksum no existe: $checksum_file"
        return 1
    fi

    log_info "Verificando checksum"

    (
        cd "$(dirname "$checksum_file")" || return 1
        sha256sum --check "$(basename "$checksum_file")" >&2
    )

    log_success "Checksum válido"
}

#######################################
# Obtiene tamaño legible
#######################################
get_archive_size() {
    local archive_path="${1:-}"

    if [[ ! -f "$archive_path" ]]; then
        log_error "No existe el archivo: $archive_path"
        return 1
    fi

    get_file_size "$archive_path"
}
