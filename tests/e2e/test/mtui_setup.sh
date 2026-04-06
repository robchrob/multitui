#!/bin/bash
# mtui setup tests — validates global installation

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"

MTUI_LINK="$HOME/.local/bin/mtui"

setup() {
    log_info "Setting up setup test environment..."
    rm -f "$MTUI_LINK" 2>/dev/null || true
}

teardown() {
    log_info "Teardown complete"
}

test_setup_e2e() {
    log_test "mtui setup runs, binary responds, image exists..."

    if [[ -x "$REPO_ROOT/mtui" ]]; then
        "$REPO_ROOT/mtui" setup 2>&1 || {
            log_fail "mtui setup exited non-zero"
            return 1
        }
    else
        log_fail "Repo mtui not found at $REPO_ROOT/mtui"
        return 1
    fi

    if [[ ! -x "$MTUI_LINK" ]]; then
        log_fail "mtui not installed at $MTUI_LINK"
        return 1
    fi

    if ! docker_image_exists "multitui"; then
        log_fail "multitui image not found after setup"
        return 1
    fi

    log_pass "Setup works: binary installed, image exists"
}

main() {
    trap 'kill $(jobs -p) 2>/dev/null; exit 130' INT
    setup
    set +e
    local passed=0 failed=0

    if test_setup_e2e; then
        log_pass "test_setup_e2e"
        ((passed++)) || true
    else
        log_fail "test_setup_e2e"
        ((failed++)) || true
    fi

    teardown
    echo ""
    log_info "Results: $passed passed, $failed failed"
    [[ $failed -eq 0 ]]
}

main "$@"