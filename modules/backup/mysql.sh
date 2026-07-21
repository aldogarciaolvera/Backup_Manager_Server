#!/bin/bash

find_mysql_container() {
    local container

    container="$(
        docker ps \
            --filter "label=com.docker.swarm.service.name=bd-evaluaciontecnica-fbnp70" \
            --format '{{.Names}}' |
        head -n 1
    )"

    if [[ -z "$container" ]]; then
        log_error "No se encontró el contenedor MySQL de evaluaciontecnica"
        return 1
    fi

    printf '%s\n' "$container"
}

get_mysql_env_value() {
    local container="$1"
    local variable_name="$2"
    local value

    value="$(
        docker inspect "$container" \
            --format '{{range .Config.Env}}{{println .}}{{end}}' |
        sed -n "s/^${variable_name}=//p" |
        head -n 1
    )"

    if [[ -z "$value" ]]; then
        log_error "No se pudo detectar $variable_name en el contenedor"
        return 1
    fi

    printf '%s\n' "$value"
}

backup_mysql() {
    local backup_type="mysql"
    local backup_id
    local workspace
    local mysql_container
    local mysql_database
    local mysql_root_password
    local dump_file
    local final_archive
    local start_time
    local end_time
    local duration
    local original_size
   
    start_time="$(date +%s)"
    backup_id="$(generate_backup_id)"
    
    start_managed_workspace "$backup_id"
    workspace="$(get_active_workspace)"

    log_info "Iniciando respaldo de MySQL"
    log_info "Backup ID: $backup_id"
    log_info "Workspace: $workspace"

    require_command docker
    validate_archive_dependencies

    ensure_directory "$MYSQL_DIR"

    mysql_container="$(find_mysql_container)"
    mysql_database="$(get_mysql_env_value "$mysql_container" "MYSQL_DATABASE")"
    mysql_root_password="$(get_mysql_env_value "$mysql_container" "MYSQL_ROOT_PASSWORD")"

    log_info "Contenedor detectado: $mysql_container"
    log_info "Base de datos: $mysql_database"

    docker exec "$mysql_container" \
        mysqldump --version >/dev/null

    dump_file="$workspace/data/${mysql_database}.sql"

    log_info "Generando respaldo lógico con mysqldump"

    docker exec \
        -e MYSQL_PWD="$mysql_root_password" \
        "$mysql_container" \
        mysqldump \
        -uroot \
        --single-transaction \
        --quick \
        --routines \
        --triggers \
        --events \
        --hex-blob \
        --set-gtid-purged=OFF \
        --databases "$mysql_database" \
        > "$dump_file"

    unset mysql_root_password

    if [[ ! -s "$dump_file" ]]; then
        log_error "El archivo generado por mysqldump está vacío"
        return 1
    fi

    if ! grep -q "CREATE DATABASE" "$dump_file"; then
        log_error "El dump MySQL no contiene una definición de base de datos"
        return 1
    fi

    original_size="$(du -h "$dump_file" | awk '{print $1}')"

    log_success "Dump MySQL generado: $dump_file"
    log_info "Tamaño del dump: $original_size"

    final_archive="$(
    finalize_backup_archive \
        "$backup_type" \
        "$backup_id" \
        "$workspace" \
        "$MYSQL_DIR"
    )"
    
    end_time="$(date +%s)"
    duration="$((end_time - start_time))"

    log_success "Respaldo de MySQL completado"
    log_info "Archivo: $final_archive"
    log_info "Base respaldada: $mysql_database"
    log_info "Tamaño original: $original_size"
    log_info "Tamaño comprimido: $(get_archive_size "$final_archive")"
    log_info "Duración: ${duration}s"

    finish_managed_workspace

    printf '%s\n' "$final_archive"
}
