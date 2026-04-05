#!/bin/bash
# mtui init tests - validates project scaffolding
# Note: These tests require OPENROUTER_API_KEY for full AI execution

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/mtui.sh"
source "$LIB_DIR/fixtures.sh"

TEST_TMP_DIR="/tmp/mtui_test_$$"
MTUI_IMAGE="${MTUI_IMAGE:-multitui}"

setup() {
    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up init test environment..."
    
    if ! docker_image_exists "$MTUI_IMAGE"; then
        log_info "Building multitui image..."
        local dockerfile="$SCRIPT_DIR/../../../docker/Dockerfile"
        docker build -f "$dockerfile" -t "$MTUI_IMAGE" "$(dirname "$dockerfile")" || {
            log_fail "Failed to build image"
            exit 1
        }
    fi
}

teardown() {
    log_info "Cleaning up init test environment..."
    docker rm -f mtui-test-init-$$ 2>/dev/null || true
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
}

test_init_js_project() {
    log_test "Testing mtui init with JS project..."
    
    local project_dir="$TEST_TMP_DIR/test-js-init"
    create_minimal_js "$project_dir"
    
    if [[ ! -d "$project_dir" ]]; then
        log_fail "Failed to create fixture"
        return 1
    fi
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    if [[ ! -x "$mtui_script" ]]; then
        log_fail "mtui script not found"
        return 1
    fi
    
    log_info "Running mtui init for JS project..."
    local output
    output=$("$mtui_script" init "bun" 2>&1) || true
    
    log_info "init output: $output"
    
    if [[ -f "$project_dir/AGENTS.md" ]]; then
        log_pass "AGENTS.md generated for JS project"
    else
        log_fail "AGENTS.md not generated"
        return 1
    fi
    
    return 0
}

test_init_py_project() {
    log_test "Testing mtui init with Python project..."
    
    local project_dir="$TEST_TMP_DIR/test-py-init"
    create_minimal_py "$project_dir"
    
    if [[ ! -d "$project_dir" ]]; then
        log_fail "Failed to create fixture"
        return 1
    fi
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    log_info "Running mtui init for Python project..."
    local output
    output=$("$mtui_script" init "python uv" 2>&1) || true
    
    log_info "init output: $output"
    
    if [[ -f "$project_dir/AGENTS.md" ]]; then
        log_pass "AGENTS.md generated for Python project"
    else
        log_fail "AGENTS.md not generated"
        return 1
    fi
    
    return 0
}

test_init_agents_md_sections() {
    log_test "Testing AGENTS.md has required sections..."
    
    local project_dir="$TEST_TMP_DIR/test-agents-sections"
    create_minimal_js "$project_dir"
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    "$mtui_script" init "bun" 2>&1 || true
    
    if [[ ! -f "$project_dir/AGENTS.md" ]]; then
        log_fail "AGENTS.md not generated"
        return 1
    fi
    
    local required_sections=("## Stack" "## Commands" "## Permissions")
    for section in "${required_sections[@]}"; do
        if ! grep -q "$section" "$project_dir/AGENTS.md"; then
            log_fail "Missing section: $section"
            return 1
        fi
    done
    
    log_pass "AGENTS.md has all required sections"
    return 0
}

test_init_dockerfile_generated() {
    log_test "Testing Dockerfile is generated..."
    
    local project_dir="$TEST_TMP_DIR/test-dockerfile"
    create_minimal_js "$project_dir"
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    "$mtui_script" init "bun" 2>&1 || true
    
    if [[ -f "$project_dir/Dockerfile" ]]; then
        log_pass "Dockerfile generated"
    else
        log_fail "Dockerfile not generated"
        return 1
    fi
    
    return 0
}

test_init_compose_generated() {
    log_test "Testing docker-compose.yml is generated..."
    
    local project_dir="$TEST_TMP_DIR/test-compose"
    create_minimal_js "$project_dir"
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    "$mtui_script" init "bun" 2>&1 || true
    
    if [[ -f "$project_dir/docker-compose.yml" ]]; then
        log_pass "docker-compose.yml generated"
    else
        log_fail "docker-compose.yml not generated"
        return 1
    fi
    
    return 0
}

test_init_agent_attached() {
    log_test "Testing agent directory is attached..."
    
    local project_dir="$TEST_TMP_DIR/test-agent-attach"
    create_minimal_js "$project_dir"
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    "$mtui_script" init "bun" 2>&1 || true
    
    if [[ -d "$project_dir/agent" ]]; then
        log_pass "agent directory attached"
    else
        log_fail "agent directory not attached"
        return 1
    fi
    
    return 0
}

main() {
    set +e
    local tests_passed=0
    local tests_failed=0
    
    setup
    
    local test_funcs=(
        "test_init_js_project"
        "test_init_py_project"
        "test_init_agents_md_sections"
        "test_init_dockerfile_generated"
        "test_init_compose_generated"
        "test_init_agent_attached"
    )
    
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
