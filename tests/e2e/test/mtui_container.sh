#!/bin/bash
# mtui container tests - validates container lifecycle
# These tests don't require OPENROUTER_API_KEY - they test CLI and Docker directly

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/mtui.sh"
source "$LIB_DIR/fixtures.sh"

TEST_TMP_DIR="/tmp/mtui_test_$$"
MTUI_IMAGE="${MTUI_IMAGE:-multitui}"
TEST_PROJECT_NAME="mtui-test-container"

setup() {
    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up container test environment..."
    
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
    log_info "Cleaning up container test environment..."
    
    docker rm -f mtui-test-container 2>/dev/null || true
    docker rm -f mtui-oc-port 2>/dev/null || true
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
}

test_container_dockerfile_exists() {
    log_test "Testing Dockerfile exists in project..."
    
    local dockerfile="$SCRIPT_DIR/../../../docker/Dockerfile"
    if [[ -f "$dockerfile" ]]; then
        log_pass "Dockerfile found at $dockerfile"
    else
        log_fail "Dockerfile not found"
        return 1
    fi
    return 0
}

test_container_image() {
    log_test "Testing multitui image exists..."
    
    if docker_image_exists "$MTUI_IMAGE"; then
        log_pass "Image $MTUI_IMAGE exists"
    else
        log_fail "Image $MTUI_IMAGE not found"
        return 1
    fi
    return 0
}

test_container_run() {
    log_test "Testing container can be created and run..."
    
    docker rm -f mtui-test-container 2>/dev/null || true
    
    if docker run -d --name mtui-test-container "$MTUI_IMAGE" sleep 30; then
        sleep 2
        if docker_container_running "mtui-test-container"; then
            log_pass "Container started successfully"
        else
            log_fail "Container not running"
            return 1
        fi
    else
        log_fail "Failed to start container"
        return 1
    fi
    return 0
}

test_container_stop() {
    log_test "Testing container can be stopped..."
    
    docker run -d --name mtui-test-container "$MTUI_IMAGE" sleep 30 2>/dev/null || true
    sleep 1
    
    if docker rm -f mtui-test-container 2>/dev/null; then
        log_pass "Container removed successfully"
    else
        log_fail "Failed to remove container"
        return 1
    fi
    return 0
}

test_container_exec() {
    log_test "Testing docker exec works in container..."
    
    docker rm -f mtui-test-container 2>/dev/null || true
    docker run -d --name mtui-test-container "$MTUI_IMAGE" sleep 30 2>/dev/null || true
    sleep 2
    
    local output
    output=$(docker exec mtui-test-container echo "hello" 2>&1)
    
    docker rm -f mtui-test-container 2>/dev/null || true
    
    if [[ "$output" == "hello" ]]; then
        log_pass "Docker exec works"
    else
        log_fail "Docker exec failed: $output"
        return 1
    fi
    return 0
}

test_container_docker_cli() {
    log_test "Testing Docker CLI available in container..."
    
    docker rm -f mtui-test-container 2>/dev/null || true
    docker run -d --name mtui-test-container "$MTUI_IMAGE" sleep 30 2>/dev/null || true
    sleep 2
    
    local docker_exists
    docker_exists=$(docker exec mtui-test-container which docker 2>/dev/null || echo "")
    
    docker rm -f mtui-test-container 2>/dev/null || true
    
    if [[ -n "$docker_exists" ]]; then
        log_pass "Docker CLI available in container"
    else
        log_fail "Docker CLI not available"
        return 1
    fi
    return 0
}

test_container_git() {
    log_test "Testing Git available in container..."
    
    docker rm -f mtui-test-container 2>/dev/null || true
    docker run -d --name mtui-test-container "$MTUI_IMAGE" sleep 30 2>/dev/null || true
    sleep 2
    
    local git_version
    git_version=$(docker exec mtui-test-container git --version 2>/dev/null || echo "")
    
    docker rm -f mtui-test-container 2>/dev/null || true
    
    if [[ -n "$git_version" ]]; then
        log_pass "Git available: $git_version"
    else
        log_fail "Git not available"
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
        "test_container_dockerfile_exists"
        "test_container_image"
        "test_container_run"
        "test_container_stop"
        "test_container_exec"
        "test_container_docker_cli"
        "test_container_git"
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
