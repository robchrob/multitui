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

MTUI_IMAGE="${MTUI_IMAGE:-multitui}"

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

    log_pass "Prerequisites OK"
}

# Build the multitui image once before any suite runs.
# If the image already exists, mtui build is a no-op (it detects the version
# and skips unless an update is available). Individual suites never trigger
# builds — they rely on this single gate.
ensure_image() {
    if docker images -q "$MTUI_IMAGE" 2>/dev/null | grep -q .; then
        log_info "Image $MTUI_IMAGE already exists — skipping build"
        return 0
    fi

    log_info "Image $MTUI_IMAGE not found — building now (one-time)..."
    "$REPO_ROOT/mtui" build || {
        log_fail "mtui build failed — cannot run tests without the image"
        return 1
    }
}

# All test suites — OPENROUTER_API_KEY is assumed to be set in the environment
TEST_SUITES=(
    mtui_setup.sh       # installs framework, links binary
    mtui_build.sh       # builds Docker image, checks opencode binary
    mtui_opencode.sh    # binary version/help/env sanity
    mtui_container.sh   # start/status/clean/list lifecycle
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

    for suite in "${TEST_SUITES[@]}"; do
        local full="$SCRIPT_DIR/$suite"
        [[ -f "$full" ]] || { log_skip "$suite (file not found)"; ((skipped++)) || true; continue; }
        if run_suite "$full"; then ((passed++)) || true; else ((failed++)) || true; fi
    done

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
    OPENROUTER_API_KEY   Required (init and bootstrap tests call OpenCode)
    GITHUB_TOKEN         Optional, for GitHub MCP
    EXA_API_KEY          Optional, for Exa MCP
    MTUI_TEST_VERBOSE    Set to 1 to enable verbose output
    MTUI_TEST_FILTER     Name pattern to filter suites

Suites:
    mtui_setup      — global install + binary link
    mtui_build      — Docker image build
    mtui_opencode   — opencode binary sanity
    mtui_container  — start / status / clean / list lifecycle
    mtui_init       — project scaffolding + file content validation
    mtui_bootstrap  — existing project analysis + stack detection

Examples:
    $0                            Run all suites
    $0 -f container               Run only container lifecycle tests
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
    ensure_image       || exit 1
    run_all_tests
}

main "$@"
