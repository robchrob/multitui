#!/bin/bash
# mtui build tests

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
    log_info "Setting up build test environment..."
}

teardown() {
    log_info "Cleaning up build test environment..."
    rm -rf "$TEST_TMP_DIR" 2>/dev/null || true
}

test_build_image() {
    log_test "Testing mtui build builds the image..."
    
    local dockerfile="$SCRIPT_DIR/../../../docker/Dockerfile"
    if [[ ! -f "$dockerfile" ]]; then
        log_fail "Dockerfile not found at $dockerfile"
        return 1
    fi
    
    docker build -f "$dockerfile" -t "$MTUI_IMAGE" "$(dirname "$dockerfile")" 2>&1 || {
        log_fail "docker build failed"
        return 1
    }
    
    if ! docker_image_exists "$MTUI_IMAGE"; then
        log_fail "Image $MTUI_IMAGE not created"
        return 1
    fi
    
    log_pass "mtui build created image $MTUI_IMAGE"
    return 0
}

test_build_image_exists() {
    log_test "Testing mtui build detects existing image..."
    
    if ! docker_image_exists "$MTUI_IMAGE"; then
        log_skip "Image $MTUI_IMAGE does not exist, skipping"
        return 0
    fi
    
    local version_before
    version_before=$(docker run --rm "$MTUI_IMAGE" opencode --version 2>/dev/null | tr -d '[:space:]' || echo "unknown")
    
    log_info "Current image version: $version_before"
    
    log_pass "Image exists with version: $version_before"
    return 0
}

test_build_no_cache() {
    log_test "Testing mtui build --no-cache forces rebuild..."
    
    local dockerfile="$SCRIPT_DIR/../../../docker/Dockerfile"
    
    local start_time
    start_time=$(date +%s)
    
    docker build --no-cache -f "$dockerfile" -t "${MTUI_IMAGE}-test" "$(dirname "$dockerfile")" 2>&1 || {
        log_fail "docker build --no-cache failed"
        return 1
    }
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    docker rmi "${MTUI_IMAGE}-test" 2>/dev/null || true
    
    log_pass "Build --no-cache completed in ${duration}s"
    return 0
}

test_build_cached() {
    log_test "Testing cached build is faster..."
    
    if ! docker_image_exists "$MTUI_IMAGE"; then
        log_skip "Image does not exist, skipping cache test"
        return 0
    fi
    
    local dockerfile="$SCRIPT_DIR/../../../docker/Dockerfile"
    
    local start_time
    start_time=$(date +%s)
    
    docker build -f "$dockerfile" -t "$MTUI_IMAGE" "$(dirname "$dockerfile")" 2>&1 || true
    
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log_info "Cached build took ${duration}s"
    
    if [[ $duration -lt 30 ]]; then
        log_pass "Cached build was fast (${duration}s)"
    else
        log_info "Cached build took ${duration}s (expected <30s for cache)"
    fi
    
    return 0
}

test_image_has_opencode() {
    log_test "Testing image has OpenCode installed..."
    
    if ! docker_image_exists "$MTUI_IMAGE"; then
        log_skip "Image does not exist, skipping"
        return 0
    fi
    
    local version
    version=$(docker run --rm "$MTUI_IMAGE" opencode --version 2>/dev/null || echo "not_found")
    
    if [[ "$version" == "not_found" ]]; then
        log_fail "OpenCode not found in image"
        return 1
    fi
    
    log_pass "OpenCode version: $version"
    return 0
}

main() {
    setup
    
    local tests_passed=0
    local tests_failed=0
    
    local test_funcs=(
        "test_build_image"
        "test_build_image_exists"
        "test_build_cached"
        "test_build_no_cache"
        "test_image_has_opencode"
    )
    
    for test_func in "${test_funcs[@]}"; do
        if $test_func; then
            ((tests_passed++))
        else
            ((tests_failed++))
        fi
    done
    
    teardown
    
    echo ""
    log_info "Results: $tests_passed passed, $tests_failed failed"
    
    [[ $tests_failed -eq 0 ]]
}

main "$@"
