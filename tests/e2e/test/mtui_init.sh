#!/bin/bash
# mtui init tests — validates project scaffolding for new projects
# Requires OPENROUTER_API_KEY (OpenCode generates the files)

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
        log_fail "OPENROUTER_API_KEY is required for init tests"
        exit 1
    fi

    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up init test environment..."

    if ! docker_image_exists "$MTUI_IMAGE"; then
        log_info "Building multitui image..."
        "$REPO_ROOT/mtui" build || { log_fail "Build failed"; exit 1; }
    fi
}

teardown() {
    rm -rf "$TEST_TMP_DIR"
}

test_init_python_generates_files() {
    log_test "mtui init generates required files for a Python project..."

    local project_dir="$TEST_TMP_DIR/init-py-$$"
    create_minimal_py "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" init "python uv project" 2>&1)

    local missing=()
    for f in AGENTS.md Dockerfile docker-compose.yml; do
        [[ -f "$project_dir/$f" ]] || missing+=("$f")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_fail "Missing files after init: ${missing[*]}"
        return 1
    fi

    log_pass "All required files generated"
}

test_init_python_agents_md_content() {
    log_test "AGENTS.md for Python project contains correct content..."

    local project_dir="$TEST_TMP_DIR/init-py-content-$$"
    create_minimal_py "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" init "python uv project" 2>&1)

    local agents="$project_dir/AGENTS.md"
    assert_file_exists "$agents" "AGENTS.md not generated" || return 1

    assert_contains "$agents" "## Stack"    "Missing ## Stack section"    || return 1
    assert_contains "$agents" "## Commands" "Missing ## Commands section"  || return 1
    assert_contains "$agents" "docker compose" "Commands must use docker compose" || return 1

    assert_contains "$agents" -i "python\|uv" "Stack section must mention Python or uv" || return 1
    assert_not_contains "$agents" "bun run" "Python project AGENTS.md must not reference bun" || return 1

    log_pass "AGENTS.md content is correct for Python project"
}

test_init_js_generates_files() {
    log_test "mtui init generates required files for a JS project..."

    local project_dir="$TEST_TMP_DIR/init-js-$$"
    create_minimal_js "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" init "bun vite" 2>&1)

    local missing=()
    for f in AGENTS.md Dockerfile docker-compose.yml; do
        [[ -f "$project_dir/$f" ]] || missing+=("$f")
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_fail "Missing files after init: ${missing[*]}"
        return 1
    fi

    log_pass "All required files generated"
}

test_init_js_agents_md_content() {
    log_test "AGENTS.md for JS project contains correct content..."

    local project_dir="$TEST_TMP_DIR/init-js-content-$$"
    create_minimal_js "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" init "bun vite" 2>&1)

    local agents="$project_dir/AGENTS.md"
    assert_file_exists "$agents" "AGENTS.md not generated" || return 1

    assert_contains "$agents" "## Stack"    "Missing ## Stack section"    || return 1
    assert_contains "$agents" "## Commands" "Missing ## Commands section"  || return 1
    assert_contains "$agents" "docker compose" "Commands must use docker compose" || return 1
    assert_contains "$agents" -i "bun\|node" "Stack must mention bun or node"  || return 1
    assert_not_contains "$agents" "uv run" "JS project AGENTS.md must not reference uv" || return 1

    log_pass "AGENTS.md content is correct for JS project"
}

test_init_attaches_agent() {
    log_test "mtui init attaches the agent/ directory..."

    local project_dir="$TEST_TMP_DIR/init-agent-$$"
    create_minimal_js "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" init "bun vite" 2>&1)

    if [[ ! -d "$project_dir/agent" ]]; then
        log_fail "agent/ directory not found after init"
        return 1
    fi

    if [[ ! -f "$project_dir/agent/AGENTS.md" ]]; then
        log_fail "agent/AGENTS.md missing — agent clone may be broken"
        return 1
    fi

    log_pass "agent/ directory attached and valid"
}

test_init_dockerfile_valid() {
    log_test "Generated Dockerfile passes docker build validation..."

    local project_dir="$TEST_TMP_DIR/init-dockerfile-$$"
    create_minimal_py "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" init "python uv project" 2>&1)

    assert_file_exists "$project_dir/Dockerfile" "Dockerfile not generated" || return 1

    if docker build --check -f "$project_dir/Dockerfile" "$project_dir" 2>&1; then
        log_pass "Dockerfile is syntactically valid"
    else
        if docker buildx build --no-cache --dry-run -f "$project_dir/Dockerfile" "$project_dir" 2>&1 | grep -q "ERROR"; then
            log_fail "Dockerfile has errors"
            return 1
        fi
        log_pass "Dockerfile appears valid"
    fi
}

test_init_compose_valid() {
    log_test "Generated docker-compose.yml is valid..."

    local project_dir="$TEST_TMP_DIR/init-compose-$$"
    create_minimal_py "$project_dir"

    (cd "$project_dir" && "$REPO_ROOT/mtui" init "python uv project" 2>&1)

    local compose="$project_dir/docker-compose.yml"
    assert_file_exists "$compose" "docker-compose.yml not generated" || return 1

    assert_contains "$compose" "services:" "docker-compose.yml must define services" || return 1

    if (cd "$project_dir" && docker compose config --quiet 2>&1); then
        log_pass "docker-compose.yml passes docker compose config validation"
    else
        log_fail "docker compose config rejected the generated file"
        return 1
    fi
}

main() {
    setup
    set +e
    local passed=0 failed=0

    for fn in \
        test_init_python_generates_files \
        test_init_python_agents_md_content \
        test_init_js_generates_files \
        test_init_js_agents_md_content \
        test_init_attaches_agent \
        test_init_dockerfile_valid \
        test_init_compose_valid; do
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
