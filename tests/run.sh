#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &&
    pwd
)"

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_file="$1"

    printf '\nEjecutando %s...\n' "$test_file"

    if bash "$test_file"; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        printf 'OK: %s\n' "$test_file"
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        printf 'ERROR: %s\n' "$test_file" >&2
    fi
}

while IFS= read -r test_file; do
    run_test "$test_file"
done < <(
    find "$PROJECT_ROOT/tests" \
        -type f \
        -name 'test_*.sh' \
        -print |
        sort
)

printf '\nResultado:\n'
printf '  Correctas: %d\n' "$TESTS_PASSED"
printf '  Fallidas:  %d\n' "$TESTS_FAILED"

[[ "$TESTS_FAILED" -eq 0 ]]
