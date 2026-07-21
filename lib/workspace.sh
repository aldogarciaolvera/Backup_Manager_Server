#!/bin/bash

ACTIVE_WORKSPACE=""

cleanup_active_workspace() {
    if [[ -n "${ACTIVE_WORKSPACE:-}" &&
          -d "${ACTIVE_WORKSPACE:-}" ]]; then
        remove_workspace "$ACTIVE_WORKSPACE"
    fi

    ACTIVE_WORKSPACE=""
}

start_managed_workspace() {
    local workspace_id="$1"

    if [[ -z "$workspace_id" ]]; then
        log_error "No se proporcionó un ID para el workspace"
        return 1
    fi

    if [[ -n "${ACTIVE_WORKSPACE:-}" ]]; then
        log_error "Ya existe un workspace activo: $ACTIVE_WORKSPACE"
        return 1
    fi

    ACTIVE_WORKSPACE="$(create_workspace "$workspace_id")"

    if [[ -z "$ACTIVE_WORKSPACE" ||
          ! -d "$ACTIVE_WORKSPACE" ]]; then
        log_error "No se pudo crear el workspace administrado"
        ACTIVE_WORKSPACE=""
        return 1
    fi

    trap cleanup_active_workspace EXIT INT TERM

    log_info "Workspace administrado: $ACTIVE_WORKSPACE"
}

finish_managed_workspace() {
    if [[ -z "${ACTIVE_WORKSPACE:-}" ]]; then
        log_warning "No existe un workspace activo para finalizar"
        return 0
    fi

    remove_workspace "$ACTIVE_WORKSPACE"

    ACTIVE_WORKSPACE=""

    trap - EXIT INT TERM
}

get_active_workspace() {
    if [[ -z "${ACTIVE_WORKSPACE:-}" ]]; then
        log_error "No existe un workspace activo"
        return 1
    fi

    printf '%s\n' "$ACTIVE_WORKSPACE"
}
