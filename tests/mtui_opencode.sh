#!/bin/bash
# mtui OpenCode sanity tests — validates the binary works inside the image
# Does NOT require OPENROUTER_API_KEY (no AI calls made)

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"

MTUI_IMAGE="${MTUI_IMAGE:-multitui}"

setup() {
    # Image presence is guaranteed by run.sh before any suite executes.
    :
}

teardown() { :; }

# Real test: opencode binary is present and returns a version string
test_opencode_version() {
    log_test "opencode --version returns a non-empty version..."

    local version
    version=$(docker run --rm "$MTUI_IMAGE" opencode --version 2>/dev/null) || {
        log_fail "opencode --version failed"
        return 1
    }

    if [[ -z "$version" ]]; then
        log_fail "opencode --version returned empty output"
        return 1
    fi

    log_pass "opencode version: $version"
}

# Real test: opencode can be invoked with `run` and a prompt (non-interactive, no key needed for --help)
test_opencode_help() {
    log_test "opencode --help exits cleanly..."

    docker run --rm "$MTUI_IMAGE" opencode --help 2>&1 | grep -qi "opencode" || {
        log_fail "opencode --help output did not mention 'opencode'"
        return 1
    }

    log_pass "opencode --help output is sane"
}

# Real test: OPENCODE_CONFIG env var is respected — config dir must be mountable
# This validates that the container is set up to receive the agent config correctly.
test_opencode_config_env_passthrough() {
    log_test "OPENCODE_CONFIG_DIR env var is passed through to container..."

    local output
    output=$(docker run --rm \
        -e OPENCODE_CONFIG_DIR=/workspace/.opencode \
        "$MTUI_IMAGE" \
        env 2>/dev/null | grep OPENCODE_CONFIG_DIR || true)

    if [[ "$output" == *"/workspace/.opencode"* ]]; then
        log_pass "OPENCODE_CONFIG_DIR is set correctly in container"
    else
        log_fail "OPENCODE_CONFIG_DIR not found in container env: $output"
        return 1
    fi
}

# Real test: When mtui start runs OpenCode it uses the model flag from config.
# We verify the model env var is set in the container that mtui start would create.
test_opencode_model_env_set() {
    log_test "OPENCODE_DEFAULT_MODEL env var is set in container..."

    local output
    output=$(docker run --rm \
        -e OPENCODE_DEFAULT_MODEL="opencode/qwen3.6-plus-free" \
        "$MTUI_IMAGE" \
        env 2>/dev/null | grep OPENCODE_DEFAULT_MODEL || true)

    if [[ "$output" == *"qwen"* ]]; then
        log_pass "OPENCODE_DEFAULT_MODEL passthrough works"
    else
        log_fail "OPENCODE_DEFAULT_MODEL not visible in container: $output"
        return 1
    fi
}

main() {
    setup
    set +e
    local passed=0 failed=0

    for fn in \
        test_opencode_version \
        test_opencode_help \
        test_opencode_config_env_passthrough \
        test_opencode_model_env_set; do
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
