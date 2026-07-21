#!/bin/bash

#######################################
# Obtiene el nombre y versión del sistema
#######################################
_get_os_name() {
    if [[ -r /etc/os-release ]]; then
        (
            source /etc/os-release
            printf '%s' "${PRETTY_NAME:-Unknown}"
        )
    else
        printf '%s' "Unknown"
    fi
}

#######################################
# Obtiene la versión de Docker
#######################################
_get_docker_version() {
    if command_exists docker; then
        docker version \
            --format '{{.Server.Version}}' \
            2>/dev/null || printf '%s' "Unavailable"
    else
        printf '%s' "Not installed"
    fi
}

#######################################
# Escapa texto para JSON
#######################################
_json_escape() {
    local value="${1:-}"

    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\n'/\\n}"
    value="${value//$'\r'/\\r}"
    value="${value//$'\t'/\\t}"

    printf '%s' "$value"
}

#######################################
# Crea el manifiesto de un respaldo
#
# Uso:
# create_manifest "server" "/ruta/manifest.json"
#######################################
create_manifest() {
    local backup_type="${1:-}"
    local output_file="${2:-}"

    if [[ -z "$backup_type" ]]; then
        log_error "No se indicó el tipo de respaldo para el manifiesto"
        return 1
    fi

    if [[ -z "$output_file" ]]; then
        log_error "No se indicó la ruta de salida del manifiesto"
        return 1
    fi

    local output_directory
    local backup_id
    local created_at
    local os_name
    local kernel_version
    local docker_version
    local hostname_value

    output_directory="$(dirname "$output_file")"
    ensure_directory "$output_directory"

    backup_id="$(generate_backup_id)"
    created_at="$(iso_datetime)"
    os_name="$(_get_os_name)"
    kernel_version="$(uname -r)"
    docker_version="$(_get_docker_version)"
    hostname_value="$(get_hostname)"

    cat > "$output_file" <<EOF
{
  "schemaVersion": "1.0",
  "backup": {
    "id": "$(_json_escape "$backup_id")",
    "type": "$(_json_escape "$backup_type")",
    "workspace": "$(_json_escape "$backup_type")",
    "createdAt": "$(_json_escape "$created_at")",
    "managerVersion": "1.0.0"
  },
  "system": {
    "hostname": "$(_json_escape "$hostname_value")",
    "operatingSystem": "$(_json_escape "$os_name")",
    "kernel": "$(_json_escape "$kernel_version")",
    "dockerVersion": "$(_json_escape "$docker_version")"
  },
  "archive": {
    "compression": "$(_json_escape "$COMPRESSOR")",
    "compressionLevel": $COMPRESS_LEVEL
  }
}
EOF

    if [[ ! -s "$output_file" ]]; then
        log_error "El manifiesto no fue creado correctamente: $output_file"
        return 1
    fi

    log_success "Manifiesto generado: $output_file"
}
