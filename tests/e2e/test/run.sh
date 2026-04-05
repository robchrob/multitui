#!/bin/bash
# Master test runner for MultiTUI e2e tests

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"

VERBOSE="${MTUI_TEST_VERBOSE:-0}"
TEST_FILTER="${MTUI_TEST_FILTER:-}"

check_prerequisites() {
    log_info "Checking prerequisites..."

    if ! command -v docker &>/dev/null; then
        log_fail "Docker not found in PATH"
        return 1
    fi

    if ! docker info &>/dev/null; then
        log_fail "Docker daemon is not running"
        return 1
    fi

    if [[ ! -x "$REPO_ROOT/mtui" ]]; then
        log_fail "mtui script not found or not executable at $REPO_ROOT/mtui"
        return 1
    fi

    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
        log_skip "OPENROUTER_API_KEY not set — init and bootstrap tests will be skipped"
    fi

    log_pass "Prerequisites OK"
}

# Tests that need no API key — run always
NO_KEY_TESTS=(
    mtui_setup.sh       # installs framework, links binary
    mtui_build.sh       # builds Docker image, checks opencode binary
    mtui_opencode.sh    # binary version/help/env sanity
    mtui_container.sh   # start/status/clean/list lifecycle
)

# Tests that call OpenCode and generate files — require OPENROUTER_API_KEY
KEY_TESTS=(
    mtui_init.sh        # full init workflow, file content checks
    mtui_bootstrap.sh   # full bootstrap workflow, stack detection
)

run_suite() {
    local suite_file="$1"
    local suite_name
    suite_name="$(basename "$suite_file" .sh)"

    if [[ -n "$TEST_FILTER" && "$suite_name" != *"$TEST_FILTER"* ]]; then
        log_skip "$suite_name (filtered)"
        return 0
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_test "Suite: $suite_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    local start
    start=$(date +%s)

    if bash "$suite_file"; then
        local elapsed=$(( $(date +%s) - start ))
        log_pass "$suite_name — ${elapsed}s"
        return 0
    else
        local elapsed=$(( $(date +%s) - start ))
        log_fail "$suite_name — ${elapsed}s"
        return 1
    fi
}

run_all_tests() {
    local passed=0 failed=0 skipped=0

    log_info "Running suites that do not require OPENROUTER_API_KEY..."
    for suite in "${NO_KEY_TESTS[@]}"; do
        local full="$SCRIPT_DIR/$suite"
        [[ -f "$full" ]] || { log_skip "$suite (file not found)"; ((skipped++)) || true; continue; }
        if run_suite "$full"; then ((passed++)) || true; else ((failed++)) || true; fi
    done

    if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
        log_info "Running suites that require OPENROUTER_API_KEY..."
        for suite in "${KEY_TESTS[@]}"; do
            local full="$SCRIPT_DIR/$suite"
            [[ -f "$full" ]] || { log_skip "$suite (file not found)"; ((skipped++)) || true; continue; }
            if run_suite "$full"; then ((passed++)) || true; else ((failed++)) || true; fi
        done
    else
        for suite in "${KEY_TESTS[@]}"; do
            log_skip "$suite requires OPENROUTER_API_KEY"
            ((skipped++)) || true
        done
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Final results: ${passed} passed  ${failed} failed  ${skipped} skipped"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    [[ $failed -eq 0 ]]
}

show_usage() {
    cat << 'EOF'
MultiTUI E2E Test Runner

Usage: $0 [options]

Options:
    -f, --filter PATTERN   Run only suites whose name contains PATTERN
    -v, --verbose          Enable verbose output
    -h, --help             Show this help

Environment Variables:
    OPENROUTER_API_KEY   Required for init and bootstrap tests (AI generates files)
    GITHUB_TOKEN         Optional, for GitHub MCP
    EXA_API_KEY          Optional, for Exa MCP
    MTUI_TEST_VERBOSE    Set to 1 to enable verbose output
    MTUI_TEST_FILTER     Name pattern to filter suites

Suites (no API key required):
    mtui_setup      — global install + binary link
    mtui_build      — Docker image build
    mtui_opencode   — opencode binary sanity
    mtui_container  — start / status / clean / list lifecycle

Suites (OPENROUTER_API_KEY required):
    mtui_init       — project scaffolding + file content validation
    mtui_bootstrap  — existing project analysis + stack detection

Examples:
    $0                            Run all tests (AI tests skipped without key)
    $0 -f container               Run only container lifecycle tests
    OPENROUTER_API_KEY=... $0     Run all tests including AI-generated file tests
EOF
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -v|--verbose)  export MTUI_TEST_VERBOSE=1; shift ;;
            -f|--filter)   TEST_FILTER="$2"; export MTUI_TEST_FILTER="$2"; shift 2 ;;
            -h|--help)     show_usage; exit 0 ;;
            *) log_fail "Unknown option: $1"; show_usage; exit 1 ;;
        esac
    done

    check_prerequisites || exit 1
    run_all_tests
}

main "$@"
