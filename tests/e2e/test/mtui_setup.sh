#!/bin/bash
# mtui setup tests

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/mtui.sh"
source "$LIB_DIR/fixtures.sh"

TEST_TMP_DIR="/tmp/mtui_test_$$"
MTUI_HOME="$HOME/.multitui"
MTUI_LINK="$HOME/.local/bin/mtui"

setup() {
    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up test environment..."
    
    # Aggressively clean up any existing state
    if [[ -d "$MTUI_HOME" ]]; then
        log_info "Removing existing $MTUI_HOME..."
        # Use find to remove read-only files first
        find "$MTUI_HOME" -type f -exec chmod u+w {} \; 2>/dev/null || true
        find "$MTUI_HOME" -type d -exec chmod u+w {} \; 2>/dev/null || true
        rm -rf "$MTUI_HOME" 2>/dev/null || true
        # Verify removal
        if [[ -d "$MTUI_HOME" ]]; then
            log_info "Still exists, trying again..."
            rm -rf "$MTUI_HOME" 2>/dev/null || true
            sleep 1
        fi
    fi
    
    rm -f "$MTUI_LINK" 2>/dev/null || true
    rm -rf "$HOME/.config/opencode" 2>/dev/null || true
    rm -rf "$HOME/.local/share/opencode" 2>/dev/null || true
}

teardown() {
    log_info "Cleaning up test environment..."
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
    # Don't remove ~/.multitui - other tests depend on it
}

test_setup_install() {
    log_test "Testing mtui setup installs globally..."
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    if [[ ! -x "$mtui_script" ]]; then
        log_fail "mtui script not found at $mtui_script"
        return 1
    fi
    
    "$mtui_script" setup 2>&1 || {
        log_fail "mtui setup failed"
        return 1
    }
    
    if [[ ! -d "$MTUI_HOME" ]]; then
        log_fail "mtui home not created at $MTUI_HOME"
        return 1
    fi
    
    log_pass "mtui setup installed to $MTUI_HOME"
    return 0
}

test_setup_links() {
    log_test "Testing mtui binary is linked..."
    
    local link_path="$HOME/.local/bin/mtui"
    if [[ ! -L "$link_path" ]]; then
        log_fail "mtui not linked at $link_path"
        return 1
    fi
    
    if [[ ! -x "$link_path" ]]; then
        log_fail "mtui link not executable"
        return 1
    fi
    
    local linked_target
    linked_target=$(readlink -f "$link_path")
    
    log_pass "mtui linked to $linked_target"
    return 0
}

test_setup_mtui_runs() {
    log_test "Testing mtui command works after setup..."
    
    local mtui_cmd="$HOME/.local/bin/mtui"
    if ! "$mtui_cmd" --help &>/dev/null; then
        log_fail "mtui --help failed"
        return 1
    fi
    
    log_pass "mtui command is functional"
    return 0
}

main() {
    set +e
    local tests_passed=0
    local tests_failed=0
    
    setup
    
    local test_funcs=("test_setup_install" "test_setup_links" "test_setup_mtui_runs")
    
    for test_func in "${test_funcs[@]}"; do
        echo "Running $test_func..."
        if $test_func; then
            echo "$test_func PASSED"
            ((tests_passed++)) || true
        else
            echo "$test_func FAILED"
            ((tests_failed++)) || true
        fi
    done
    
    teardown
    
    echo ""
    log_info "Results: $tests_passed passed, $tests_failed failed"
    
    [[ $tests_failed -eq 0 ]]
}

main "$@"
