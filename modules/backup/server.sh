#!/bin/bash

backup_server() {
    local backup_type="server"
    local backup_id
    local workspace
    local final_archive
    local start_time
    local end_time
    local duration
    local original_size
    local file_count

    start_time="$(date +%s)"
    backup_id="$(generate_backup_id)"
   
    start_managed_workspace "$backup_id"
    workspace="$(get_active_workspace)"

    log_info "Iniciando respaldo del servidor"
    log_info "Backup ID: $backup_id"
    log_info "Workspace: $workspace"

    ensure_directory "$SERVER_DIR"

    log_info "Copiando configuración de /etc"

    mkdir -p "$workspace/data/etc"

    rsync \
        -aHAX \
        --numeric-ids \
        --exclude='/dokploy/' \
        /etc/ \
        "$workspace/data/etc/"

    if [[ -d /etc/dokploy ]]; then
        log_info "Copiando configuración de Dokploy"

        mkdir -p "$workspace/data/etc/dokploy"

        rsync \
            -aHAX \
            --numeric-ids \
            /etc/dokploy/ \
            "$workspace/data/etc/dokploy/"
    fi

    if [[ -d /opt ]]; then
        log_info "Copiando /opt"

        mkdir -p "$workspace/data/opt"

        rsync \
            -aHAX \
            --numeric-ids \
            --exclude='/scripts/backup-manager/logs/' \
            /opt/ \
            "$workspace/data/opt/"
    fi

    if [[ -d "$SERVER_HOME" ]]; then
        log_info "Copiando $SERVER_HOME "

        mkdir -p "$workspace/data/home/$SERVER_USER"

        rsync \
            -aHAX \
            --numeric-ids \
            --exclude='.cache/' \
            --exclude='.local/share/Trash/' \
            "$SERVER_HOME/" \
            "$workspace/data/home/$SERVER_USER/"
    fi

    original_size="$(du -sh "$workspace/data" | awk '{print $1}')"
    file_count="$(find "$workspace/data" -type f | wc -l)"

    final_archive="$(
    finalize_backup_archive \
        "$backup_type" \
        "$backup_id" \
        "$workspace" \
        "$SERVER_DIR"
    )"
    
    end_time="$(date +%s)"
    duration="$((end_time - start_time))"

    log_success "Respaldo del servidor completado"
    log_info "Archivo: $final_archive"
    log_info "Tamaño original: $original_size"
    log_info "Tamaño comprimido: $(get_archive_size "$final_archive")"
    log_info "Archivos: file_count="$(
    tar \
        --use-compress-program=zstd \
        --list \
        --file="$final_archive" |
    wc -l
    )""
    log_info "Duración: ${duration}s"

    finish_managed_workspace

    printf '%s\n' "$final_archive"
}
