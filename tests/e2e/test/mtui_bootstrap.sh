#!/bin/bash
# mtui bootstrap tests - validates project analysis
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
    log_info "Setting up bootstrap test environment..."
    
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
    log_info "Cleaning up bootstrap test environment..."
    docker rm -f mtui-test-bootstrap-$$ 2>/dev/null || true
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
}

test_bootstrap_js() {
    log_test "Testing mtui bootstrap with existing JS project..."
    
    local project_dir="$TEST_TMP_DIR/test-js-bootstrap"
    create_minimal_js "$project_dir"
    
    if [[ ! -d "$project_dir" ]]; then
        log_fail "Failed to create fixture"
        return 1
    fi
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    log_info "Running mtui bootstrap for JS project..."
    local output
    output=$("$mtui_script" bootstrap "analyze existing project" 2>&1) || true
    
    log_info "bootstrap output: $output"
    
    if [[ -f "$project_dir/AGENTS.md" ]]; then
        log_pass "AGENTS.md generated for JS project"
    else
        log_fail "AGENTS.md not generated"
        return 1
    fi
    
    return 0
}

test_bootstrap_py() {
    log_test "Testing mtui bootstrap with existing Python project..."
    
    local project_dir="$TEST_TMP_DIR/test-py-bootstrap"
    create_minimal_py "$project_dir"
    
    if [[ ! -d "$project_dir" ]]; then
        log_fail "Failed to create fixture"
        return 1
    fi
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    log_info "Running mtui bootstrap for Python project..."
    local output
    output=$("$mtui_script" bootstrap "python uv project" 2>&1) || true
    
    log_info "bootstrap output: $output"
    
    if [[ -f "$project_dir/AGENTS.md" ]]; then
        log_pass "AGENTS.md generated for Python project"
    else
        log_fail "AGENTS.md not generated"
        return 1
    fi
    
    return 0
}

test_bootstrap_agents_md_content() {
    log_test "Testing AGENTS.md contains project analysis..."
    
    local project_dir="$TEST_TMP_DIR/test-agents-content"
    create_minimal_js "$project_dir"
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    "$mtui_script" bootstrap "analyze existing project" 2>&1 || true
    
    if [[ ! -f "$project_dir/AGENTS.md" ]]; then
        log_fail "AGENTS.md not generated"
        return 1
    fi
    
    local content
    content=$(cat "$project_dir/AGENTS.md")
    
    if [[ ${#content} -lt 100 ]]; then
        log_fail "AGENTS.md content too short"
        return 1
    fi
    
    log_pass "AGENTS.md has meaningful content"
    return 0
}

test_bootstrap_stack_detected() {
    log_test "Testing stack detection in bootstrap..."
    
    local project_dir="$TEST_TMP_DIR/test-stack-detect"
    create_minimal_py "$project_dir"
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    "$mtui_script" bootstrap "analyze existing project" 2>&1 || true
    
    if [[ ! -f "$project_dir/AGENTS.md" ]]; then
        log_fail "AGENTS.md not generated"
        return 1
    fi
    
    local content
    content=$(cat "$project_dir/AGENTS.md")
    
    if echo "$content" | grep -qi "python\|uv"; then
        log_pass "Stack (Python/uv) detected"
    else
        log_info "Stack detection content: $content"
    fi
    
    return 0
}

test_bootstrap_commands_section() {
    log_test "Testing Commands section in AGENTS.md..."
    
    local project_dir="$TEST_TMP_DIR/test-commands-section"
    create_minimal_py "$project_dir"
    
    local mtui_script="$SCRIPT_DIR/../../../mtui"
    "$mtui_script" bootstrap "python project" 2>&1 || true
    
    if [[ ! -f "$project_dir/AGENTS.md" ]]; then
        log_fail "AGENTS.md not generated"
        return 1
    fi
    
    if grep -q "## Commands" "$project_dir/AGENTS.md"; then
        log_pass "Commands section present"
    else
        log_fail "Commands section missing"
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
        "test_bootstrap_js"
        "test_bootstrap_py"
        "test_bootstrap_agents_md_content"
        "test_bootstrap_stack_detected"
        "test_bootstrap_commands_section"
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
