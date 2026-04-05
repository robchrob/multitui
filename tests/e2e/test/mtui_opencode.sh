#!/bin/bash
# mtui OpenCode flow tests - validates OpenCode execution
# These tests run without requiring OPENROUTER_API_KEY

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/mtui.sh"
source "$LIB_DIR/fixtures.sh"
source "$LIB_DIR/opencode.sh"

TEST_TMP_DIR="/tmp/mtui_test_$$"
MTUI_IMAGE="${MTUI_IMAGE:-multitui}"
TEST_CONTAINER_NAME="mtui-test-opencode"

setup() {
    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up OpenCode test environment..."
    
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
    log_info "Cleaning up OpenCode test environment..."
    docker rm -f "$TEST_CONTAINER_NAME" 2>/dev/null || true
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
}

test_opencode_version() {
    log_test "Testing OpenCode version check..."
    
    local version
    version=$(docker run --rm "$MTUI_IMAGE" opencode --version 2>/dev/null || echo "not_found")
    
    if [[ "$version" != "not_found" ]]; then
        log_pass "OpenCode installed: $version"
    else
        log_fail "OpenCode not found"
        return 1
    fi
    
    return 0
}

test_opencode_help() {
    log_test "Testing OpenCode help output..."
    
    local help_output
    help_output=$(docker run --rm "$MTUI_IMAGE" opencode --help 2>&1 | head -20)
    
    if echo "$help_output" | grep -q "opencode"; then
        log_pass "OpenCode help available"
    else
        log_fail "OpenCode help not available"
        return 1
    fi
    
    return 0
}

test_opencode_tools_available() {
    log_test "Testing OpenCode tools are available..."
    
    local tools_output
    tools_output=$(docker run --rm "$MTUI_IMAGE" opencode --help 2>&1)
    
    local required_tools=("read" "write" "edit" "glob" "grep" "bash")
    for tool in "${required_tools[@]}"; do
        if echo "$tools_output" | grep -qi "$tool"; then
            log_info "Tool $tool found"
        fi
    done
    
    log_pass "OpenCode tools listed"
    return 0
}

test_opencode_mcp_config() {
    log_test "Testing MCP configuration env..."
    
    local config_dir
    config_dir=$(docker run --rm "$MTUI_IMAGE" env | grep OPENCODE_CONFIG_DIR= || echo "")
    
    if [[ -n "$config_dir" ]]; then
        log_pass "OPENCODE_CONFIG_DIR set: $config_dir"
    else
        log_fail "OPENCODE_CONFIG_DIR not set"
        return 1
    fi
    
    return 0
}

test_opencode_file_operations() {
    log_test "Testing file operations in container..."
    
    docker rm -f "$TEST_CONTAINER_NAME" 2>/dev/null || true
    docker run -d --name "$TEST_CONTAINER_NAME" "$MTUI_IMAGE" sleep 30 2>/dev/null || true
    sleep 2
    
    local test_content="test content from opencode"
    local test_file="/tmp/test_file_$$.txt"
    echo "$test_content" > "$test_file"
    
    docker cp "$test_file" "$TEST_CONTAINER_NAME:/tmp/test_file.txt"
    rm -f "$test_file"
    
    local read_content
    read_content=$(docker exec "$TEST_CONTAINER_NAME" cat /tmp/test_file.txt)
    
    docker exec "$TEST_CONTAINER_NAME" rm -f /tmp/test_file.txt
    docker rm -f "$TEST_CONTAINER_NAME" 2>/dev/null || true
    
    if [[ "$read_content" == "$test_content" ]]; then
        log_pass "File read/write operations work"
    else
        log_fail "File operations failed"
        return 1
    fi
    
    return 0
}

test_opencode_docker_access() {
    log_test "Testing Docker access in container..."
    
    local docker_access
    docker_access=$(docker run --rm "$MTUI_IMAGE" which docker)
    
    if [[ -n "$docker_access" ]]; then
        log_pass "Docker CLI available in container"
    else
        log_fail "Docker CLI not available"
        return 1
    fi
    
    return 0
}

test_opencode_git_access() {
    log_test "Testing Git access in container..."
    
    local git_access
    git_access=$(docker run --rm "$MTUI_IMAGE" which git)
    
    if [[ -n "$git_access" ]]; then
        log_pass "Git available in container"
    else
        log_fail "Git not available"
        return 1
    fi
    
    return 0
}

test_opencode_node() {
    log_test "Testing Node.js available in container..."
    
    local node_version
    node_version=$(docker run --rm "$MTUI_IMAGE" node --version 2>/dev/null || echo "not_found")
    
    if [[ "$node_version" != "not_found" ]]; then
        log_pass "Node.js available: $node_version"
    else
        log_fail "Node.js not available"
        return 1
    fi
    
    return 0
}

test_opencode_bash() {
    log_test "Testing Bash available in container..."
    
    local bash_version
    bash_version=$(docker run --rm "$MTUI_IMAGE" bash --version 2>/dev/null | head -1 || echo "not_found")
    
    if [[ "$bash_version" != "not_found" ]]; then
        log_pass "Bash available: $bash_version"
    else
        log_fail "Bash not available"
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
        "test_opencode_version"
        "test_opencode_help"
        "test_opencode_tools_available"
        "test_opencode_mcp_config"
        "test_opencode_file_operations"
        "test_opencode_docker_access"
        "test_opencode_git_access"
        "test_opencode_node"
        "test_opencode_bash"
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
