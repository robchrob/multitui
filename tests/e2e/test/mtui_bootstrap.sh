#!/bin/bash
# mtui bootstrap tests — validates analysis of existing projects
# Requires OPENROUTER_API_KEY
#
# Design: ONE `mtui bootstrap` call per stack. All assertions reuse the
# same generated directory — no redundant AI runs.
#
# WARNING: Individual test functions CANNOT be sourced and called directly.
# They depend on setup() having run first. Always run via the suite runner:
#   ./tests/e2e/test/run.sh -f bootstrap
# or via main():
#   bash tests/e2e/test/mtui_bootstrap.sh

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/fixtures.sh"

MTUI_IMAGE="${MTUI_IMAGE:-multitui}"
TEST_TMP_DIR="/tmp/mtui_test_$$"

PY_DIR=""
JS_DIR=""

# Guard: called at the top of every test function to ensure setup() ran.
# Without this, an empty PY_DIR/JS_DIR causes mtui to operate on CWD (the repo root).
_require_fixtures() {
    if [[ -z "${PY_DIR:-}" || ! -d "$PY_DIR" ]]; then
        log_fail "ISOLATION ERROR: PY_DIR is unset or missing. setup() must run before test functions."
        log_fail "Run this suite via: ./tests/e2e/test/run.sh -f bootstrap"
        exit 1
    fi
    if [[ -z "${JS_DIR:-}" || ! -d "$JS_DIR" ]]; then
        log_fail "ISOLATION ERROR: JS_DIR is unset or missing. setup() must run before test functions."
        log_fail "Run this suite via: ./tests/e2e/test/run.sh -f bootstrap"
        exit 1
    fi
}

setup() {
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
        log_fail "OPENROUTER_API_KEY is required for bootstrap tests"
        exit 1
    fi

    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up bootstrap test environment..."
    # Image presence is guaranteed by run.sh before any suite executes.

    # --- Run mtui bootstrap for both stacks in parallel ---
    PY_DIR="$TEST_TMP_DIR/bootstrap-py"
    create_minimal_py "$PY_DIR"
    echo "# SENTINEL" > "$PY_DIR/Dockerfile"
    JS_DIR="$TEST_TMP_DIR/bootstrap-js"
    create_minimal_js "$JS_DIR"

    log_info "Running mtui bootstrap for Python and JS projects in parallel..."
    (cd "$PY_DIR" && "$REPO_ROOT/mtui" bootstrap 2>&1) &
    local py_pid=$!
    (cd "$JS_DIR" && "$REPO_ROOT/mtui" bootstrap 2>&1) &
    local js_pid=$!

    # Wait for both to finish
    local py_ok=0 js_ok=0
    wait "$py_pid" && py_ok=1 || true
    wait "$js_pid" && js_ok=1 || true

    if [[ $py_ok -eq 0 ]]; then
        log_fail "Python bootstrap failed"
        exit 1
    fi
    if [[ $js_ok -eq 0 ]]; then
        log_fail "JS bootstrap failed"
        exit 1
    fi
    log_info "Both bootstrap sessions completed successfully"
}

teardown() {
    local status="${1:-unknown}"
    local run_dir
    run_dir="$REPO_ROOT/tests/e2e/output/$(date +%Y%m%d_%H%M%S)_bootstrap_${status}"
    mkdir -p "$run_dir"

    [[ -n "$PY_DIR" && -d "$PY_DIR" ]] && cp -r "$PY_DIR" "$run_dir/py" 2>/dev/null || true
    [[ -n "$JS_DIR" && -d "$JS_DIR" ]] && cp -r "$JS_DIR" "$run_dir/js" 2>/dev/null || true

    log_info "Artifacts saved to $run_dir"
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || {
        docker run --rm -v "$TEST_TMP_DIR:/tmp/cleanup:rw" alpine rm -rf /tmp/cleanup 2>/dev/null || true
    }
}

# ── Python assertions ──────────────────────────────────────────────────────

test_bootstrap_python_generates_agents_md() {
    _require_fixtures
    log_test "Python bootstrap generates AGENTS.md..."
    assert_file_exists "$PY_DIR/AGENTS.md" "AGENTS.md not generated" || return 1
    log_pass "AGENTS.md generated"
}

test_bootstrap_python_detects_stack() {
    _require_fixtures
    log_test "Python bootstrap detects Python/uv stack..."

    local agents="$PY_DIR/AGENTS.md"
    assert_file_exists "$agents" || return 1

    if ! grep -qi "python\|uv" "$agents"; then
        log_fail "AGENTS.md does not mention Python or uv"
        return 1
    fi

    if grep -q "bun run" "$agents"; then
        log_fail "Python AGENTS.md references bun run — wrong stack"
        return 1
    fi

    log_pass "Python stack detected correctly"
}

test_bootstrap_python_commands_use_docker_compose() {
    _require_fixtures
    log_test "Python AGENTS.md Commands section uses docker compose..."

    local agents="$PY_DIR/AGENTS.md"
    assert_contains "$agents" "## Commands"    "Missing Commands section"   || return 1
    assert_contains "$agents" "docker compose" "Commands must use docker compose" || return 1

    log_pass "Commands section uses docker compose"
}

test_bootstrap_preserves_existing_dockerfile() {
    _require_fixtures
    log_test "bootstrap does not overwrite an existing Dockerfile..."

    if ! grep -q "SENTINEL" "$PY_DIR/Dockerfile"; then
        log_fail "Existing Dockerfile was overwritten by bootstrap"
        return 1
    fi

    log_pass "Existing Dockerfile preserved"
}

# ── JS assertions ──────────────────────────────────────────────────────────

test_bootstrap_js_generates_agents_md() {
    _require_fixtures
    log_test "JS bootstrap generates AGENTS.md..."
    assert_file_exists "$JS_DIR/AGENTS.md" "AGENTS.md not generated" || return 1
    log_pass "AGENTS.md generated"
}

test_bootstrap_js_detects_stack() {
    _require_fixtures
    log_test "JS bootstrap detects JS/bun stack..."

    local agents="$JS_DIR/AGENTS.md"
    assert_file_exists "$agents" || return 1

    if ! grep -qi "bun\|node\|vite" "$agents"; then
        log_fail "AGENTS.md does not mention bun, node, or vite"
        return 1
    fi

    if grep -q "uv run" "$agents"; then
        log_fail "JS AGENTS.md references uv run — wrong stack"
        return 1
    fi

    log_pass "JS stack detected correctly"
}

# ── Shared ─────────────────────────────────────────────────────────────────

test_bootstrap_attaches_agent() {
    _require_fixtures
    log_test "bootstrap attaches the agent/ directory..."

    local failed=0
    for dir in "$PY_DIR" "$JS_DIR"; do
        if [[ ! -d "$dir/agent" ]]; then
            log_fail "agent/ missing in $dir"
            failed=1
        fi
    done

    [[ $failed -eq 0 ]] && log_pass "agent/ attached in both projects"
    return $failed
}

main() {
    trap 'kill $(jobs -p) 2>/dev/null; exit 130' INT
    setup
    set +e
    local passed=0 failed=0

    for fn in \
        test_bootstrap_python_generates_agents_md \
        test_bootstrap_python_detects_stack \
        test_bootstrap_python_commands_use_docker_compose \
        test_bootstrap_preserves_existing_dockerfile \
        test_bootstrap_js_generates_agents_md \
        test_bootstrap_js_detects_stack \
        test_bootstrap_attaches_agent; do
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
