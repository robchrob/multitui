#!/bin/bash
# mtui setup tests — validates global installation

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"

MTUI_HOME="$HOME/.multitui"
MTUI_LINK="$HOME/.local/bin/mtui"

setup() {
    log_info "Setting up setup test environment..."
    # Remove only our own installation artifacts — don't nuke unrelated config
    rm -rf "$MTUI_HOME" 2>/dev/null || true
    rm -f  "$MTUI_LINK" 2>/dev/null || true
}

teardown() {
    log_info "Teardown complete (leaving ~/.multitui in place for subsequent tests)"
}

# Real test: mtui setup clones the framework to ~/.multitui
test_setup_install() {
    log_test "mtui setup installs framework to ~/.multitui..."

    "$REPO_ROOT/mtui" setup 2>&1 || {
        log_fail "mtui setup exited non-zero"
        return 1
    }

    assert_dir_exists "$MTUI_HOME" "~/.multitui not created" || return 1

    log_pass "Framework installed to $MTUI_HOME"
}

# Real test: mtui is symlinked to ~/.local/bin/mtui and is executable
test_setup_links_binary() {
    log_test "mtui binary is linked at ~/.local/bin/mtui..."

    assert_file_exists "$MTUI_LINK" "~/.local/bin/mtui not found" || return 1

    if [[ ! -L "$MTUI_LINK" ]]; then
        log_fail "$MTUI_LINK is not a symlink"
        return 1
    fi

    if [[ ! -x "$MTUI_LINK" ]]; then
        log_fail "$MTUI_LINK is not executable"
        return 1
    fi

    log_pass "mtui linked and executable at $MTUI_LINK"
}

# Real test: the installed binary exits 0 on --help
test_setup_installed_binary_works() {
    log_test "Installed mtui binary responds to --help..."

    # Use exit code only — ANSI escape codes make grep unreliable here
    "$MTUI_LINK" --help >/dev/null 2>&1 || {
        log_fail "Installed mtui --help exited non-zero"
        return 1
    }

    log_pass "Installed mtui binary works"
}

main() {
    setup
    set +e
    local passed=0 failed=0

    for fn in \
        test_setup_install \
        test_setup_links_binary \
        test_setup_installed_binary_works; do
        log_test "Running $fn..."
        if $fn; then
            log_pass "$fn"
            ((passed++)) || true
        else
            log_fail "$fn"
            ((failed++)) || true
        fi
    done

    teardown
    echo ""
    log_info "Results: $passed passed, $failed failed"
    [[ $failed -eq 0 ]]
}

main "$@"
