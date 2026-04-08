#!/bin/bash
# Common test helpers - logging and utilities

set -Eeuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${RESET} $*"; }
log_pass() { echo -e "${GREEN}[PASS]${RESET} $*"; }
log_fail() { echo -e "${RED}[FAIL]${RESET} $*"; }
log_skip() { echo -e "${YELLOW}[SKIP]${RESET} $*"; }
log_test() { echo -e "${BOLD}[TEST]${RESET} $*"; }
log_debug() { [[ "${MTUI_TEST_VERBOSE:-0}" == "1" ]] && echo -e "${DIM}[DEBUG]${RESET} $*"; }

assert_file_exists() {
    local file="$1"
    local msg="${2:-File not found: $file}"
    [[ -f "$file" ]] || { log_fail "$msg"; return 1; }
}

assert_dir_exists() {
    local dir="$1"
    local msg="${2:-Directory not found: $dir}"
    [[ -d "$dir" ]] || { log_fail "$msg"; return 1; }
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    local msg="${3:-Pattern not found in $file}"
    grep -q "$pattern" "$file" || { log_fail "$msg"; return 1; }
}

assert_cmd_success() {
    local cmd="$1"
    local msg="${2:-Command failed: $cmd}"
    eval "$cmd" >/dev/null 2>&1 || { log_fail "$msg"; return 1; }
}

wait_for() {
    local timeout="$1"
    local condition="$2"
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if eval "$condition"; then return 0; fi
        sleep 1
        ((elapsed++)) || true
    done
    return 1
}

get_random_name() {
    echo "mtui-test-$(date +%s)-$$"
}
