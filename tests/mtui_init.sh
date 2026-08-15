#!/bin/bash
# mtui init tests — validates project scaffolding for new projects
# Requires OPENROUTER_API_KEY
#
# Design: ONE `mtui init` call per stack (Python, JS). All assertions for
# that stack reuse the same generated directory. This avoids re-running
# the AI for every individual assertion.
#
# WARNING: Individual test functions CANNOT be sourced and called directly.
# They depend on setup() having run first. Always run via the suite runner:
#   ./tests/run.sh -f init
# or via main():
#   bash tests/mtui_init.sh

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/fixtures.sh"

MTUI_IMAGE="${MTUI_IMAGE:-multitui}"
TEST_TMP_DIR="/tmp/mtui_test_$$"

# Set by setup — reused by all tests
PY_DIR=""
JS_DIR=""

# Guard: called at the top of every test function to ensure setup() ran.
# Without this, an empty PY_DIR/JS_DIR causes mtui to operate on CWD (the repo root).
_require_fixtures() {
    if [[ -z "${PY_DIR:-}" || ! -d "$PY_DIR" ]]; then
        log_fail "ISOLATION ERROR: PY_DIR is unset or missing. setup() must run before test functions."
        log_fail "Run this suite via: ./tests/run.sh -f init"
        exit 1
    fi
    if [[ -z "${JS_DIR:-}" || ! -d "$JS_DIR" ]]; then
        log_fail "ISOLATION ERROR: JS_DIR is unset or missing. setup() must run before test functions."
        log_fail "Run this suite via: ./tests/run.sh -f init"
        exit 1
    fi
}

setup() {
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
        log_fail "OPENROUTER_API_KEY is required for init tests"
        exit 1
    fi

    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up init test environment..."
    # Image presence is guaranteed by run.sh before any suite executes.

    # --- Run mtui init for both stacks in parallel ---
    PY_DIR="$TEST_TMP_DIR/init-py"
    create_minimal_py "$PY_DIR"
    JS_DIR="$TEST_TMP_DIR/init-js"
    create_minimal_js "$JS_DIR"

    log_info "Running mtui init for Python and JS projects in parallel..."
    (cd "$PY_DIR" && "$REPO_ROOT/mtui" init "python uv project" 2>&1) &
    local py_pid=$!
    (cd "$JS_DIR" && "$REPO_ROOT/mtui" init "bun vite" 2>&1) &
    local js_pid=$!

    # Wait for both to finish
    local py_ok=0 js_ok=0
    wait "$py_pid" && py_ok=1 || true
    wait "$js_pid" && js_ok=1 || true

    if [[ $py_ok -eq 0 ]]; then
        log_fail "Python init failed"
        exit 1
    fi
    if [[ $js_ok -eq 0 ]]; then
        log_fail "JS init failed"
        exit 1
    fi
    log_info "Both init sessions completed successfully"
}

teardown() {
    local status="${1:-unknown}"
    local output_dir="$REPO_ROOT/tests/output"
    mkdir -p "$output_dir"

    log_info "Output dir: $output_dir"

    local all_runs
    all_runs=$(ls -1t "$output_dir"/ 2>/dev/null | grep '_init_' | tail -n +3)
    [[ -n "$all_runs" ]] && rm -rf "$all_runs" 2>/dev/null || true

    rm -rf "$TEST_TMP_DIR" 2>/dev/null || {
        docker run --rm -v "$TEST_TMP_DIR:/tmp/cleanup:rw" alpine rm -rf /tmp/cleanup 2>/dev/null || true
    }
}

# ── Python assertions ──────────────────────────────────────────────────────

test_init_python_generates_files() {
    _require_fixtures
    log_test "Python init generates AGENTS.md, Dockerfile, docker-compose.yml..."

    local missing=()
    for f in AGENTS.md Dockerfile docker-compose.yml; do
        [[ -f "$PY_DIR/$f" ]] || missing+=("$f")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_fail "Missing files: ${missing[*]}"
        return 1
    fi

    log_pass "All required files generated"
}

test_init_python_agents_md_stack() {
    _require_fixtures
    log_test "Python AGENTS.md mentions Python/uv, not bun..."

    local agents="$PY_DIR/AGENTS.md"
    assert_file_exists "$agents" || return 1
    assert_contains "$agents" "## Stack"    "Missing ## Stack"    || return 1
    assert_contains "$agents" "## Commands" "Missing ## Commands"  || return 1
    assert_contains "$agents" "docker compose" "Commands must use docker compose" || return 1

    if ! grep -qi "python\|uv" "$agents"; then
        log_fail "AGENTS.md does not mention Python or uv"
        return 1
    fi

    if grep -q "bun run" "$agents"; then
        log_fail "Python AGENTS.md references bun run — wrong stack"
        return 1
    fi

    log_pass "Python AGENTS.md content correct"
}

test_init_python_compose_valid() {
    _require_fixtures
    log_test "Python docker-compose.yml passes validation..."

    local compose="$PY_DIR/docker-compose.yml"
    assert_file_exists "$compose" "docker-compose.yml not generated" || return 1
    assert_contains "$compose" "services:" "Missing services block" || return 1

    if (cd "$PY_DIR" && docker compose config --quiet 2>&1); then
        log_pass "docker-compose.yml is valid"
    else
        log_fail "docker compose config rejected the file"
        return 1
    fi
}

# ── JS assertions ──────────────────────────────────────────────────────────

test_init_js_generates_files() {
    _require_fixtures
    log_test "JS init generates AGENTS.md, Dockerfile, docker-compose.yml..."

    local missing=()
    for f in AGENTS.md Dockerfile docker-compose.yml; do
        [[ -f "$JS_DIR/$f" ]] || missing+=("$f")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_fail "Missing files: ${missing[*]}"
        return 1
    fi

    log_pass "All required files generated"
}

test_init_js_agents_md_stack() {
    _require_fixtures
    log_test "JS AGENTS.md mentions bun/node, not uv..."

    local agents="$JS_DIR/AGENTS.md"
    assert_file_exists "$agents" || return 1
    assert_contains "$agents" "## Stack"    "Missing ## Stack"    || return 1
    assert_contains "$agents" "## Commands" "Missing ## Commands"  || return 1
    assert_contains "$agents" "docker compose" "Commands must use docker compose" || return 1

    if ! grep -qi "bun\|node\|vite" "$agents"; then
        log_fail "AGENTS.md does not mention bun, node, or vite"
        return 1
    fi

    if grep -q "uv run" "$agents"; then
        log_fail "JS AGENTS.md references uv run — wrong stack"
        return 1
    fi

    log_pass "JS AGENTS.md content correct"
}

test_init_js_compose_valid() {
    _require_fixtures
    log_test "JS docker-compose.yml passes validation..."

    local compose="$JS_DIR/docker-compose.yml"
    assert_file_exists "$compose" "docker-compose.yml not generated" || return 1
    assert_contains "$compose" "services:" "Missing services block" || return 1

    if (cd "$JS_DIR" && docker compose config --quiet 2>&1); then
        log_pass "docker-compose.yml is valid"
    else
        log_fail "docker compose config rejected the file"
        return 1
    fi
}

# ── Shared ─────────────────────────────────────────────────────────────────

test_init_no_agent_dir() {
    _require_fixtures
    log_test "mtui init does NOT create an agent/ directory..."

    local failed=0
    for dir in "$PY_DIR" "$JS_DIR"; do
        if [[ -d "$dir/agent" ]]; then
            log_fail "agent/ exists in $dir"
            failed=1
        fi
    done

    [[ $failed -eq 0 ]] && log_pass "No agent/ directory in either project"
    return $failed
}

main() {
    trap 'kill $(jobs -p) 2>/dev/null; exit 130' INT
    setup
    set +e
    local passed=0 failed=0

    for fn in \
        test_init_python_generates_files \
        test_init_python_agents_md_stack \
        test_init_python_compose_valid \
        test_init_js_generates_files \
        test_init_js_agents_md_stack \
        test_init_js_compose_valid \
        test_init_no_agent_dir; do
        log_test "Running $fn..."
        if $fn; then log_pass "$fn"; ((passed++)) || true
        else          log_fail "$fn"; ((failed++)) || true
        fi
    done

    teardown "$( [[ $failed -eq 0 ]] && echo pass || echo fail )"
    echo ""
    log_info "Results: $passed passed, $failed failed"
    [[ $failed -eq 0 ]]
}

main "$@"
