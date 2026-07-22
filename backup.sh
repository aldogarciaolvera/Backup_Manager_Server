#!/bin/bash

set -Eeuo pipefail

BACKUP_MANAGER_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &&
    pwd
)"

export BACKUP_MANAGER_DIR

source "$BACKUP_MANAGER_DIR/bootstrap.sh"

show_version() {
    local version_file="$BACKUP_MANAGER_DIR/VERSION"

    if [[ ! -f "$version_file" ]]; then
        log_error "No se encontró el archivo VERSION"
        return 1
    fi

    printf 'Backup Manager %s\n' "$(tr -d '[:space:]' < "$version_file")"
}

acquire_lock() {
    local lock_file="${BACKUP_MANAGER_LOCK_FILE:-/run/lock/backup-manager.lock}"

    if ! exec 9>"$lock_file"; then
        log_error "No se pudo abrir el archivo de bloqueo: $lock_file"
        return 1
    fi

    if ! flock -n 9; then
        log_error "Ya existe otro respaldo en ejecución"
        return 1
    fi
}

show_usage() {
    cat <<EOF
Uso:

  backup.sh server
  backup.sh postgres
  backup.sh all
  backup.sh cleanup
  backup.sh cleanup --dry-run
  backup.sh restore mysql
  backup.sh restore mysql latest
  backup.sh restore mysql ARCHIVO BASE_DESTINO

Respaldos disponibles:

  server    Respalda configuración y archivos principales del servidor
  postgres    Respalda PostgreSQL de Dokploy mediante pg_dumpall
  mysql       Respalda la base MySQL evaluacion_tecnica
  all         Ejecuta todos los respaldos
  cleanup     Elimina respaldos antiguos segun la politica de retencion
EOF
}

backup_all() {
    local failed=0

    log_info "Iniciando respaldo completo"

    if ! backup_server; then
        log_error "Falló el respaldo del servidor"
        failed=1
    fi

    if ! backup_postgres; then
        log_error "Falló el respaldo de PostgreSQL"
        failed=1
    fi

    if ! backup_mysql; then
        log_error "Falló el respaldo de MySQL"
        failed=1
    fi

    if (( failed != 0 )); then
        log_error "El respaldo completo terminó con errores"
        return 1
    fi
   
   log_info "Aplicando política de retención..."

    cleanup_all_backups false

    log_success "Respaldo completo finalizado correctamente"
}

main() {
    local command="${1:-}"
    local restore_type

    case "$command" in
        --version|-v|version)
            show_version
            return 0
            ;;

        help|--help|-h|"")
            show_usage
            return 0
            ;;
    esac

    acquire_lock || return 1

    case "$command" in
        server)
            backup_server
            ;;

        postgres)
            backup_postgres
            ;;

        mysql)
            backup_mysql
            ;;

        all)
            backup_all
            ;;

        cleanup)
            if [[ "${2:-}" == "--dry-run" ]]; then
                cleanup_all_backups true
            else
                cleanup_all_backups false
            fi
            ;;

        restore)
            restore_type="${2:-}"

            case "$restore_type" in
                mysql)
                    restore_mysql \
                        "${3:-latest}" \
                        "${4:-evaluacion_tecnica_restore_test}" \
                        "${5:-false}"
                    ;;

                postgres)
                    restore_postgres \
                        "${3:-latest}" \
                        "${4:-dokploy}" \
                        "${5:-dokploy_restore_test}" \
                        "${6:-false}"
                    ;;

                *)
                    log_error "Tipo de restauración inválido: $restore_type"
                    log_info "Opciones disponibles: mysql, postgres"
                    return 1
                    ;;
            esac
            ;;

        *)
            log_error "Tipo de respaldo desconocido: $command"
            show_usage
            return 1
            ;;
    esac
}

main "$@"
