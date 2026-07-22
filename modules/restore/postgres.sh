#!/bin/bash

restore_postgres() {
    local archive_path="${1:-latest}"
    local source_database="${2:-dokploy}"
    local target_database="${3:-${source_database}_restore_test}"
    local force_production="${4:-false}"

    local postgres_container
    local postgres_user
    local restore_id
    local workspace
    local sql_entry
    local extracted_sql
    local prepared_sql
    local table_count

    if [[ "$archive_path" == "latest" || -z "$archive_path" ]]; then
        archive_path="$(
            resolve_latest_backup \
                "$POSTGRES_DIR" \
                "postgres"
        )"
    fi

    if [[ ! "$source_database" =~ ^[a-zA-Z0-9_]+$ ]]; then
        log_error "Nombre de base origen inválido: $source_database"
        return 1
    fi

    if [[ ! "$target_database" =~ ^[a-zA-Z0-9_]+$ ]]; then
        log_error "Nombre de base destino inválido: $target_database"
        return 1
    fi

    if [[ "$target_database" == "$source_database" &&
          "$force_production" != "true" ]]; then
        log_error "Se bloqueó la restauración sobre la base original"
        log_error "Base protegida: $source_database"
        return 1
    fi

    postgres_container="$(find_postgres_container)"

    postgres_user="$(
        get_postgres_env_value \
            "$postgres_container" \
            "POSTGRES_USER"
    )"

    log_info "Iniciando restauración de PostgreSQL"
    log_info "Archivo: $archive_path"
    log_info "Base de origen: $source_database"
    log_info "Base de destino: $target_database"
    log_info "Contenedor: $postgres_container"

    validate_restore_archive "$archive_path"

    restore_id="restore-postgres-$(generate_backup_id)"

    start_managed_workspace "$restore_id"
    workspace="$(get_active_workspace)"

    sql_entry="$(find_sql_entry_in_archive "$archive_path")"

    extracted_sql="$workspace/data/postgres-all.sql"
    prepared_sql="$workspace/data/postgres-restore.sql"

    extract_archive_entry \
        "$archive_path" \
        "$sql_entry" \
        "$extracted_sql"

    prepare_postgres_database_restore \
        "$extracted_sql" \
        "$prepared_sql" \
        "$source_database"

    log_warning "La base temporal será reemplazada: $target_database"

    docker exec \
    "$postgres_container" \
    psql \
    -U "$postgres_user" \
    -d postgres \
    -v ON_ERROR_STOP=1 \
    -c "
        SELECT pg_terminate_backend(pid)
        FROM pg_stat_activity
        WHERE datname = '$target_database'
          AND pid <> pg_backend_pid();
    "

    docker exec \
    "$postgres_container" \
    psql \
    -U "$postgres_user" \
    -d postgres \
    -v ON_ERROR_STOP=1 \
    -c "DROP DATABASE IF EXISTS \"$target_database\";"

    docker exec \
    "$postgres_container" \
    psql \
    -U "$postgres_user" \
    -d postgres \
    -v ON_ERROR_STOP=1 \
    -c "CREATE DATABASE \"$target_database\";"

    log_info "Importando respaldo PostgreSQL"

    docker exec \
        -i \
        "$postgres_container" \
        psql \
        -U "$postgres_user" \
        -d "$target_database" \
        -v ON_ERROR_STOP=1 \
        < "$prepared_sql"

    table_count="$(
        docker exec \
            "$postgres_container" \
            psql \
            -U "$postgres_user" \
            -d "$target_database" \
            -tAc "
                SELECT COUNT(*)
                FROM information_schema.tables
                WHERE table_schema NOT IN (
                    'pg_catalog',
                    'information_schema'
                );
            "
    )"

    table_count="${table_count//[[:space:]]/}"

    if [[ ! "$table_count" =~ ^[0-9]+$ ]]; then
        log_error "No se pudo validar la base restaurada"
        return 1
    fi

    log_success "Restauración PostgreSQL completada"
    log_info "Base restaurada: $target_database"
    log_info "Tablas restauradas: $table_count"

    finish_managed_workspace
}
