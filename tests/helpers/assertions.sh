#!/usr/bin/env bash

set -Eeuo pipefail

TEST_ASSERTIONS_PASSED=0
TEST_ASSERTIONS_FAILED=0

fail() {
    local message="${1:-La prueba falló}"

    TEST_ASSERTIONS_FAILED=$((TEST_ASSERTIONS_FAILED + 1))

    printf 'FAIL: %s\n' "$message" >&2
    return 1
}

pass() {
    local message="${1:-Prueba correcta}"

    TEST_ASSERTIONS_PASSED=$((TEST_ASSERTIONS_PASSED + 1))

    printf 'PASS: %s\n' "$message"
}

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-Se esperaba $expected, pero se obtuvo: $actual}"

    if [[ "$actual" == "$expected" ]]; then
        pass "$message"
        return 0
    fi

    fail "$message"
}

assert_not_equals() {
    local unexpected="$1"
    local actual="$2"
    local message="${3:-No se esperaba $unexpected}"

    if [[ "$actual" != "$unexpected" ]]; then
        pass "$message"
        return 0
    fi

    fail "$message"
}

assert_contains() {
    local output="$1"
    local expected="$2"
    local message="${3:-La salida debe contener $expected}"

    if [[ "$output" == *"$expected"* ]]; then
        pass "$message"
        return 0
    fi

    fail "$message"
}

assert_not_contains() {
    local output="$1"
    local unexpected="$2"
    local message="${3:-La salida no debe contener $unexpected}"

    if [[ "$output" != *"$unexpected"* ]]; then
        pass "$message"
        return 0
    fi

    fail "$message"
}

assert_file_exists() {
    local path="$1"
    local message="${2:-El archivo debe existir: $path}"

    if [[ -f "$path" ]]; then
        pass "$message"
        return 0
    fi

    fail "$message"
}

assert_directory_exists() {
    local path="$1"
    local message="${2:-El directorio debe existir: $path}"

    if [[ -d "$path" ]]; then
        pass "$message"
        return 0
    fi

    fail "$message"
}

assert_executable() {
    local path="$1"
    local message="${2:-El archivo debe ser ejecutable: $path}"

    if [[ -x "$path" ]]; then
        pass "$message"
        return 0
    fi

    fail "$message"
}

assert_success() {
    local exit_code="$1"
    local message="${2:-El comando debe finalizar correctamente}"

    if [[ "$exit_code" -eq 0 ]]; then
        pass "$message"
        return 0
    fi

    fail "$message. Código recibido: $exit_code"
}

assert_failure() {
    local exit_code="$1"
    local message="${2:-El comando debe fallar}"

    if [[ "$exit_code" -ne 0 ]]; then
        pass "$message"
        return 0
    fi

    fail "$message"
}

print_assertion_summary() {
    printf '\nAssertions:\n'
    printf '  Correctas: %d\n' "$TEST_ASSERTIONS_PASSED"
    printf '  Fallidas:  %d\n' "$TEST_ASSERTIONS_FAILED"

    [[ "$TEST_ASSERTIONS_FAILED" -eq 0 ]]
}
