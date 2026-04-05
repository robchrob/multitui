#!/bin/bash
# mtui build tests — validates that `mtui build` produces a working image
# run.sh ensures the image exists before this suite runs; these tests verify
# the *output* of a build, not that a build was triggered unnecessarily.

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"

MTUI_IMAGE="${MTUI_IMAGE:-multitui}"

setup() { log_info "Setting up build test environment..."; }
teardown() { :; }

# Real test: mtui build exits 0 and image is present afterwards.
# If the image already exists and is up-to-date, mtui build is a no-op —
# that is correct and expected behaviour, not a failure.
test_build_produces_image() {
    log_test "mtui build exits 0 and image exists..."

    "$REPO_ROOT/mtui" build 2>&1 || {
        log_fail "mtui build exited non-zero"
        return 1
    }

    if ! docker_image_exists "$MTUI_IMAGE"; then
        log_fail "Image $MTUI_IMAGE not found after build"
        return 1
    fi

    log_pass "Image $MTUI_IMAGE present after build"
}

# Real test: the image actually contains a runnable opencode binary.
test_built_image_has_opencode() {
    log_test "Built image contains a runnable opencode binary..."

    local version
    version=$(docker run --rm "$MTUI_IMAGE" opencode --version 2>/dev/null) || {
        log_fail "opencode --version failed inside image"
        return 1
    }

    if [[ -z "$version" ]]; then
        log_fail "opencode --version returned empty output"
        return 1
    fi

    log_pass "opencode version in image: $version"
}

main() {
    setup
    set +e
    local passed=0 failed=0

    for fn in test_build_produces_image test_built_image_has_opencode; do
        log_test "Running $fn..."
        if $fn; then log_pass "$fn"; ((passed++)) || true
        else          log_fail "$fn"; ((failed++)) || true
        fi
    done

    teardown
    echo ""
    log_info "Results: $passed passed, $failed failed"
    [[ $failed -eq 0 ]]
}

main "$@"
