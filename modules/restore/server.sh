#!/bin/bash

restore_server() {
    local archive_path="${1:-latest}"
    local destination="${2:-/tmp/server-restore-test}"

    local restore_id
    local workspace
    local extracted_data
    local file_count
    local directory_count

    if [[ "$archive_path" == "latest" || -z "$archive_path" ]]; then
        archive_path="$(
            resolve_latest_backup \
                "$SERVER_DIR" \
                "server"
        )"
    fi

    if [[ -z "$destination" || "$destination" != /* ]]; then
        log_error "El destino debe ser una ruta absoluta"
        return 1
    fi

    case "$destination" in
        /|/etc|/opt|/home|/usr|/var|/root|/boot)
            log_error "Destino de restauración peligroso: $destination"
            return 1
            ;;
    esac

    if [[ "$destination" != /tmp/* &&
          "$destination" != /mnt/* ]]; then
        log_error "El destino debe estar dentro de /tmp o /mnt"
        return 1
    fi

    log_info "Iniciando restauración de servidor"
    log_info "Archivo: $archive_path"
    log_info "Destino: $destination"

    validate_restore_archive "$archive_path"

    restore_id="restore-server-$(generate_backup_id)"

    start_managed_workspace "$restore_id"
    workspace="$(get_active_workspace)"
    extracted_data="$workspace/data"

    log_info "Extrayendo respaldo del servidor"

    tar \
        --use-compress-program=zstd \
        --extract \
        --file="$archive_path" \
        --directory="$workspace" \
        --same-owner \
        --same-permissions \
        --acls \
        --xattrs

    if [[ ! -d "$extracted_data" ]]; then
        log_error "El respaldo no contiene el directorio data/"
        return 1
    fi

    if [[ -e "$destination" ]]; then
        log_warning "El destino será reemplazado: $destination"
        rm -rf -- "$destination"
    fi

    mkdir -p -- "$destination"

    log_info "Copiando archivos restaurados"

    rsync \
        -aHAX \
        --numeric-ids \
        "$extracted_data/" \
        "$destination/"

    file_count="$(
        find "$destination" \
            -type f \
            -printf '.' |
        wc -c
    )"

    directory_count="$(
        find "$destination" \
            -type d \
            -printf '.' |
        wc -c
    )"

    file_count="${file_count//[[:space:]]/}"
    directory_count="${directory_count//[[:space:]]/}"

    if [[ ! "$file_count" =~ ^[0-9]+$ ||
          ! "$directory_count" =~ ^[0-9]+$ ]]; then
        log_error "No se pudo validar el contenido restaurado"
        return 1
    fi

    if (( file_count == 0 )); then
        log_error "La restauración terminó sin archivos"
        return 1
    fi

    for expected_directory in etc opt home; do
        if [[ ! -d "$destination/$expected_directory" ]]; then
            log_warning "No se encontró el directorio esperado: $expected_directory"
        fi
    done

    log_success "Restauración de servidor completada"
    log_info "Destino restaurado: $destination"
    log_info "Archivos restaurados: $file_count"
    log_info "Directorios restaurados: $directory_count"

    finish_managed_workspace
}
