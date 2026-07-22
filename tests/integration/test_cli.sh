#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_ROOT="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." &&
    pwd
)"

source "$PROJECT_ROOT/tests/helpers/assertions.sh"

BACKUP_SCRIPT="$PROJECT_ROOT/backup.sh"

assert_file_exists \
    "$BACKUP_SCRIPT" \
    "backup.sh existe"

assert_executable \
    "$BACKUP_SCRIPT" \
    "backup.sh es ejecutable"

version_output="$("$BACKUP_SCRIPT" --version)"
version_exit_code=$?

assert_success \
    "$version_exit_code" \
    "--version termina correctamente"

assert_contains \
    "$version_output" \
    "Backup Manager" \
    "--version muestra el nombre del programa"

assert_contains \
    "$version_output" \
    "1.0.0" \
    "--version muestra la versión actual"

help_output="$("$BACKUP_SCRIPT" --help)"
help_exit_code=$?

assert_success \
    "$help_exit_code" \
    "--help termina correctamente"

assert_contains \
    "$help_output" \
    "server" \
    "--help documenta server"

assert_contains \
    "$help_output" \
    "postgres" \
    "--help documenta postgres"

assert_contains \
    "$help_output" \
    "mysql" \
    "--help documenta mysql"

assert_contains \
    "$help_output" \
    "restore" \
    "--help documenta restore"

assert_contains \
    "$help_output" \
    "cleanup" \
    "--help documenta cleanup"

set +e

invalid_output="$(
    BACKUP_MANAGER_LOCK_FILE="/tmp/backup-manager-test.lock" \
        "$BACKUP_SCRIPT" comando-invalido 2>&1
)"

invalid_exit_code=$?

set -e

assert_failure \
    "$invalid_exit_code" \
    "Un comando inválido devuelve error"

assert_contains \
    "$invalid_output" \
    "Tipo de respaldo desconocido" \
    "Un comando inválido muestra un mensaje claro"

print_assertion_summary
