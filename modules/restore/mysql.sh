#!/bin/bash

restore_mysql() {
    local archive_path="${1:-}"
    local target_database="${2:-evaluacion_tecnica_restore_test}"
    local force_production="${3:-false}"

    local production_database
    local mysql_container
    local mysql_root_password
    local sql_entry
    local extracted_sql
    local restore_sql
    local restore_id
    local workspace
    local table_count

    if [[ -z "$archive_path" ||
          "$archive_path" == "latest" ]]; then
        archive_path="$(
            resolve_latest_backup \
                "$MYSQL_DIR" \
                "mysql"
        )"
    fi

    mysql_container="$(find_mysql_container)"

    production_database="$(
        get_mysql_env_value \
            "$mysql_container" \
            "MYSQL_DATABASE"
    )"

    if [[ "$target_database" == "$production_database" &&
          "$force_production" != "true" ]]; then
        log_error "Se bloqueó la restauración sobre la base de producción"
        log_error "Base protegida: $production_database"
        log_error "Usa una base temporal para probar la restauración"
        return 1
    fi

    if [[ ! "$target_database" =~ ^[a-zA-Z0-9_]+$ ]]; then
        log_error "Nombre de base de datos inválido: $target_database"
        return 1
    fi

    log_info "Iniciando restauración de MySQL"
    log_info "Archivo: $archive_path"
    log_info "Base de origen: $production_database"
    log_info "Base de destino: $target_database"

    validate_restore_archive "$archive_path"

    restore_id="restore-mysql-$(generate_backup_id)"

    start_managed_workspace "$restore_id"
    workspace="$(get_active_workspace)"

    sql_entry="$(find_sql_entry_in_archive "$archive_path")"

    extracted_sql="$workspace/data/mysql-original.sql"
    restore_sql="$workspace/data/mysql-restore.sql"

    extract_archive_entry \
        "$archive_path" \
        "$sql_entry" \
        "$extracted_sql"

    if ! grep -q "CREATE DATABASE" "$extracted_sql"; then
        log_error "El dump no contiene CREATE DATABASE"
        return 1
    fi

    log_info "Preparando SQL para la base de destino"

    sed \
        "s/\`${production_database}\`/\`${target_database}\`/g" \
        "$extracted_sql" \
        > "$restore_sql"

    if [[ ! -s "$restore_sql" ]]; then
        log_error "No se pudo preparar el archivo de restauración"
        return 1
    fi

    mysql_root_password="$(
        get_mysql_env_value \
            "$mysql_container" \
            "MYSQL_ROOT_PASSWORD"
    )"

    docker exec "$mysql_container" \
        mysql --version >/dev/null

    log_warning "La base de destino será reemplazada: $target_database"

    docker exec \
        -e MYSQL_PWD="$mysql_root_password" \
        "$mysql_container" \
        mysql \
        -uroot \
        -e "DROP DATABASE IF EXISTS \`$target_database\`;"

    log_info "Importando respaldo"

    docker exec \
        -i \
        -e MYSQL_PWD="$mysql_root_password" \
        "$mysql_container" \
        mysql \
        -uroot \
        < "$restore_sql"

    table_count="$(
        docker exec \
            -e MYSQL_PWD="$mysql_root_password" \
            "$mysql_container" \
            mysql \
            -uroot \
            -N \
            -e "
                SELECT COUNT(*)
                FROM information_schema.tables
                WHERE table_schema = '$target_database';
            "
    )"

    unset mysql_root_password

    if [[ ! "$table_count" =~ ^[0-9]+$ ]]; then
        log_error "No se pudo validar la base restaurada"
        return 1
    fi

    if (( table_count == 0 )); then
        log_error "La restauración terminó sin tablas"
        return 1
    fi

    log_success "Restauración MySQL completada"
    log_info "Base restaurada: $target_database"
    log_info "Tablas restauradas: $table_count"

    finish_managed_workspace
}
