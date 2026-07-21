#!/bin/bash

find_postgres_container() {
    local container

    container="$(
        docker ps \
            --filter "label=com.docker.swarm.service.name=dokploy-postgres" \
            --format '{{.Names}}' |
        head -n 1
    )"

    if [[ -z "$container" ]]; then
        log_error "No se encontró el contenedor del servicio dokploy-postgres"
        return 1
    fi

    printf '%s\n' "$container"
}

get_postgres_user() {
    local container="$1"
    local postgres_user

    postgres_user="$(
        docker inspect "$container" \
            --format '{{range .Config.Env}}{{println .}}{{end}}' |
        sed -n 's/^POSTGRES_USER=//p' |
        head -n 1
    )"

    if [[ -z "$postgres_user" ]]; then
        log_error "No se pudo detectar POSTGRES_USER en el contenedor"
        return 1
    fi

    printf '%s\n' "$postgres_user"
}

backup_postgres() {
    local backup_type="postgres"
    local backup_id
    local workspace
    local postgres_container
    local postgres_user
    local dump_file
    local final_archive
    local start_time
    local end_time
    local duration
    local original_size
    local database_count

    start_time="$(date +%s)"
    backup_id="$(generate_backup_id)"
    
    start_managed_workspace "$backup_id"

    workspace="$(get_active_workspace)"

    log_info "Iniciando respaldo de PostgreSQL"
    log_info "Backup ID: $backup_id"
    log_info "Workspace: $workspace"

    require_command docker
    validate_archive_dependencies

    ensure_directory "$POSTGRES_DIR"

    postgres_container="$(find_postgres_container)"
    postgres_user="$(get_postgres_user "$postgres_container")"

    log_info "Contenedor detectado: $postgres_container"
    log_info "Usuario PostgreSQL: $postgres_user"

    docker exec "$postgres_container" \
        pg_dumpall --version >/dev/null

    database_count="$(
        docker exec "$postgres_container" \
            psql \
            -U "$postgres_user" \
            -d postgres \
            -Atc \
            "SELECT COUNT(*) FROM pg_database WHERE datistemplate = false;"
    )"

    dump_file="$workspace/data/postgres-all.sql"

    log_info "Generando respaldo lógico con pg_dumpall"

    docker exec "$postgres_container" \
        pg_dumpall \
        -U "$postgres_user" \
        --clean \
        --if-exists \
        > "$dump_file"

    if [[ ! -s "$dump_file" ]]; then
        log_error "El archivo generado por pg_dumpall está vacío"
        return 1
    fi

    original_size="$(du -h "$dump_file" | awk '{print $1}')"

    log_success "Dump PostgreSQL generado: $dump_file"
    log_info "Bases incluidas: $database_count"
    log_info "Tamaño del dump: $original_size"
    
    final_archive="$(
    finalize_backup_archive \
        "$backup_type" \
        "$backup_id" \
        "$workspace" \
        "$POSTGRES_DIR"
    )"
    
    end_time="$(date +%s)"
    duration="$((end_time - start_time))"

    log_success "Respaldo de PostgreSQL completado"
    log_info "Archivo: $final_archive"
    log_info "Bases respaldadas: $database_count"
    log_info "Tamaño original: $original_size"
    log_info "Tamaño comprimido: $(get_archive_size "$final_archive")"
    log_info "Duración: ${duration}s"

    finish_managed_workspace

    printf '%s\n' "$final_archive"
}


