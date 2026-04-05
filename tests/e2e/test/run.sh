#!/bin/bash
# Master test runner for MultiTUI e2e tests

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"
TEST_DIR="$SCRIPT_DIR"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/mtui.sh"
source "$LIB_DIR/fixtures.sh"
source "$LIB_DIR/opencode.sh"

VERBOSE="${MTUI_TEST_VERBOSE:-0}"
TEST_FILTER="${MTUI_TEST_FILTER:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
RESET='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${RESET} $*"; }
log_pass() { echo -e "${GREEN}[PASS]${RESET} $*"; }
log_fail() { echo -e "${RED}[FAIL]${RESET} $*"; }
log_skip() { echo -e "${YELLOW}[SKIP]${RESET} $*"; }
log_test() { echo -e "${BOLD}[TEST]${RESET} $*"; }

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    if ! command -v docker &>/dev/null; then
        log_fail "Docker not found"
        return 1
    fi
    
    if ! docker info &>/dev/null; then
        log_fail "Docker daemon not running"
        return 1
    fi
    
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
        log_skip "OPENROUTER_API_KEY not set - some tests may be skipped"
    fi
    
    log_pass "Prerequisites check passed"
    return 0
}

run_test_file() {
    local test_file="$1"
    local test_name
    test_name=$(basename "$test_file" .sh)
    
    if [[ -n "$TEST_FILTER" && "$test_name" != "$TEST_FILTER" ]]; then
        log_skip "Skipping $test_name (filtered)"
        return 0
    fi
    
    log_test "Running $test_name..."
    
    local start_time
    start_time=$(date +%s)
    
    if source "$test_file"; then
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_pass "$test_name passed (${duration}s)"
        return 0
    else
        local end_time
        end_time=$(date +%s)
        local duration=$((end_time - start_time))
        log_fail "$test_name failed (${duration}s)"
        return 1
    fi
}

run_all_tests() {
    local passed=0
    local failed=0
    local skipped=0
    
    log_info "Running e2e tests..."
    echo ""
    
    local test_order=(
        "mtui_setup.sh"
        "mtui_container.sh"
        "mtui_opencode.sh"
        "mtui_build.sh"
        "mtui_init.sh"
        "mtui_bootstrap.sh"
    )
    
    for test_file in "${test_order[@]}"; do
        local full_path="$TEST_DIR/$test_file"
        [[ -f "$full_path" ]] || continue
        
        if [[ -n "$TEST_FILTER" && "$test_file" != "$TEST_FILTER" ]]; then
            log_skip "Skipping $test_file (filtered)"
            continue
        fi
        
        if run_test_file "$full_path"; then
            ((passed++))
        else
            ((failed++))
        fi
    done
    
    echo ""
    log_info "Test Results: ${passed} passed, ${failed} failed, ${skipped} skipped"
    
    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    return 0
}

show_usage() {
    cat << EOF
MultiTUI E2E Test Runner

Usage: $0 [options]

Options:
    -v, --verbose    Enable verbose output
    -f, --filter     Run only tests matching pattern
    -h, --help       Show this help message

Environment Variables:
    MTUI_TEST_VERBOSE    Enable verbose output
    MTUI_TEST_FILTER     Run only tests matching pattern
    OPENROUTER_API_KEY   Required for OpenCode tests
    GITHUB_TOKEN         Optional, for GitHub MCP
    EXA_API_KEY          Optional, for Exa MCP

Examples:
    $0                          Run all tests
    $0 -f mtui_build            Run only build tests
    MTUI_TEST_VERBOSE=1 $0      Run with verbose output
EOF
}

main() {
    local opts
    opts=$(getopt -o vfh -l verbose,filter:,help -- "$@" 2>/dev/null) || {
        show_usage
        exit 1
    }
    
    eval set -- "$opts"
    
    while true; do
        case "$1" in
            -v|--verbose)
                VERBOSE=1
                export MTUI_TEST_VERBOSE=1
                shift
                ;;
            -f|--filter)
                TEST_FILTER="$2"
                export MTUI_TEST_FILTER="$2"
                shift 2
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            --)
                shift
                break
                ;;
        esac
    done
    
    if [[ "${1:-}" == "help" ]]; then
        show_usage
        exit 0
    fi
    
    check_prerequisites || exit 1
    
    run_all_tests
}

main "$@"
