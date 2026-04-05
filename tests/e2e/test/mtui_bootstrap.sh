#!/bin/bash
# mtui bootstrap tests — validates analysis of existing projects
# Requires OPENROUTER_API_KEY

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/fixtures.sh"

MTUI_IMAGE="${MTUI_IMAGE:-multitui}"
TEST_TMP_DIR="/tmp/mtui_test_$$"

setup() {
    if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
        log_fail "OPENROUTER_API_KEY is required for bootstrap tests"
        exit 1
    fi

    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up bootstrap test environment..."

    if ! docker_image_exists "$MTUI_IMAGE"; then
        log_info "Building multitui image..."
        "$REPO_ROOT/mtui" build || { log_fail "Build failed"; exit 1; }
    fi
}

teardown() {
    rm -rf "$TEST_TMP_DIR"
}

test_bootstrap_python_detects_stack() {
    log_test "mtui bootstrap detects Python/uv stack correctly..."

    local project_dir="$TEST_TMP_DIR/bootstrap-py-$$"
    create_minimal_py "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" bootstrap 2>&1)

    local agents="$project_dir/AGENTS.md"
    assert_file_exists "$agents" "AGENTS.md not generated" || return 1

    assert_contains "$agents" -i "python\|uv"  "Must detect Python/uv stack" || return 1
    assert_not_contains "$agents" "bun run"    "Python project must not reference bun" || return 1

    log_pass "Python stack detected correctly"
}

test_bootstrap_js_detects_stack() {
    log_test "mtui bootstrap detects JS/bun stack correctly..."

    local project_dir="$TEST_TMP_DIR/bootstrap-js-$$"
    create_minimal_js "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" bootstrap 2>&1)

    local agents="$project_dir/AGENTS.md"
    assert_file_exists "$agents" "AGENTS.md not generated" || return 1

    assert_contains "$agents" -i "bun\|node\|vite" "Must detect JS stack" || return 1
    assert_not_contains "$agents" "uv run"          "JS project must not reference uv" || return 1

    log_pass "JS stack detected correctly"
}

test_bootstrap_commands_use_docker_compose() {
    log_test "AGENTS.md Commands section uses docker compose..."

    local project_dir="$TEST_TMP_DIR/bootstrap-cmds-$$"
    create_minimal_py "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" bootstrap 2>&1)

    local agents="$project_dir/AGENTS.md"
    assert_file_exists "$agents" "AGENTS.md not generated" || return 1

    assert_contains "$agents" "## Commands"   "Missing Commands section"              || return 1
    assert_contains "$agents" "docker compose" "Commands must use docker compose"     || return 1

    log_pass "Commands section uses docker compose"
}

test_bootstrap_preserves_existing_dockerfile() {
    log_test "mtui bootstrap does not overwrite an existing Dockerfile..."

    local project_dir="$TEST_TMP_DIR/bootstrap-preserve-$$"
    create_minimal_py "$project_dir"

    echo "# SENTINEL" > "$project_dir/Dockerfile"

    (cd "$project_dir" && "$REPO_ROOT/mtui" bootstrap 2>&1)

    if ! grep -q "SENTINEL" "$project_dir/Dockerfile"; then
        log_fail "Existing Dockerfile was overwritten by bootstrap"
        return 1
    fi

    log_pass "Existing Dockerfile preserved"
}

test_bootstrap_attaches_agent() {
    log_test "mtui bootstrap attaches the agent/ directory..."

    local project_dir="$TEST_TMP_DIR/bootstrap-agent-$$"
    create_minimal_py "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" bootstrap 2>&1)

    if [[ ! -d "$project_dir/agent" ]]; then
        log_fail "agent/ directory missing after bootstrap"
        return 1
    fi

    log_pass "agent/ directory attached"
}

main() {
    setup
    set +e
    local passed=0 failed=0

    for fn in \
        test_bootstrap_python_detects_stack \
        test_bootstrap_js_detects_stack \
        test_bootstrap_commands_use_docker_compose \
        test_bootstrap_preserves_existing_dockerfile \
        test_bootstrap_attaches_agent; do
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
