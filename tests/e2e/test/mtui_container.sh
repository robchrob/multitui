#!/bin/bash
# mtui container lifecycle tests — start, status, clean
# Does NOT require OPENROUTER_API_KEY (uses --tty / sleep infinity path)

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
LIB_DIR="$SCRIPT_DIR/../lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"
source "$LIB_DIR/fixtures.sh"

MTUI_IMAGE="${MTUI_IMAGE:-multitui}"
TEST_TMP_DIR="/tmp/mtui_test_$$"

# Derive the container name the same way mtui does
_expected_container_name() {
    local dir="$1"
    echo "mtui-$(basename "$dir" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"
}

setup() {
    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up container lifecycle test environment..."
    # Image presence is guaranteed by run.sh before any suite executes.
}

teardown() {
    # Best-effort cleanup of any containers created by this test run
    docker ps -aq --filter "name=^/mtui-mtui-fixture" 2>/dev/null | xargs -r docker rm -f 2>/dev/null || true
    rm -rf "$TEST_TMP_DIR"
}

# Real test: `mtui start` creates a background container with the correct name
test_start_creates_named_container() {
    log_test "mtui start creates a correctly-named background container..."

    local project_dir="$TEST_TMP_DIR/mtui-fixture-start"
    create_minimal_py "$project_dir"

    local expected_cn
    expected_cn="$(_expected_container_name "$project_dir")"

    # Clean up stale container if any
    docker rm -f "$expected_cn" 2>/dev/null || true

    # start requires OPENROUTER_API_KEY but the container creation itself happens
    # before OpenCode is exec'd — we only need the background container to appear.
    # We export a dummy key so the env check passes; OpenCode won't be exec'd in
    # this path because we immediately check container state and clean up.
    OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-dummy}" \
        (cd "$project_dir" && timeout 15 "$REPO_ROOT/mtui" start 2>&1) &
    local bg_pid=$!

    # Wait up to 10s for the container to appear
    local elapsed=0
    while [[ $elapsed -lt 10 ]]; do
        if docker_container_exists "$expected_cn"; then
            break
        fi
        sleep 1
        ((elapsed++)) || true
    done

    # Kill the bg start process (we don't need OpenCode to actually run)
    kill "$bg_pid" 2>/dev/null || true
    wait "$bg_pid" 2>/dev/null || true

    if docker_container_exists "$expected_cn"; then
        log_pass "Container $expected_cn created by mtui start"
        docker rm -f "$expected_cn" 2>/dev/null || true
    else
        log_fail "Container $expected_cn was not created within 10s"
        return 1
    fi
}

# Real test: `mtui status` reports correct state (no container → Not Created)
test_status_no_container() {
    log_test "mtui status reports 'Not Created' when no container exists..."

    local project_dir="$TEST_TMP_DIR/mtui-fixture-status"
    create_minimal_py "$project_dir"

    local expected_cn
    expected_cn="$(_expected_container_name "$project_dir")"
    docker rm -f "$expected_cn" 2>/dev/null || true

    local output
    output=$(cd "$project_dir" && "$REPO_ROOT/mtui" status 2>&1)

    if echo "$output" | grep -qi "not created"; then
        log_pass "Status correctly reports 'Not Created'"
    else
        log_fail "Expected 'Not Created' in status output, got:\n$output"
        return 1
    fi
}

# Real test: `mtui status` reports Running after container is up
test_status_running_after_start() {
    log_test "mtui status reports Running after container is started..."

    local project_dir="$TEST_TMP_DIR/mtui-fixture-status-run"
    create_minimal_py "$project_dir"

    local expected_cn
    expected_cn="$(_expected_container_name "$project_dir")"
    docker rm -f "$expected_cn" 2>/dev/null || true

    # Manually create the container the same way mtui start does (background sleep)
    docker run -d --name "$expected_cn" \
        -v "$project_dir:$project_dir" \
        -w "$project_dir" \
        "$MTUI_IMAGE" sleep infinity >/dev/null

    local output
    output=$(cd "$project_dir" && "$REPO_ROOT/mtui" status 2>&1)

    docker rm -f "$expected_cn" 2>/dev/null || true

    if echo "$output" | grep -qi "running"; then
        log_pass "Status correctly reports Running"
    else
        log_fail "Expected 'Running' in status output, got:\n$output"
        return 1
    fi
}

# Real test: `mtui clean` removes the container
test_clean_removes_container() {
    log_test "mtui clean removes the project container..."

    local project_dir="$TEST_TMP_DIR/mtui-fixture-clean"
    create_minimal_py "$project_dir"

    local expected_cn
    expected_cn="$(_expected_container_name "$project_dir")"

    # Manually create the container so we can test clean
    docker run -d --name "$expected_cn" "$MTUI_IMAGE" sleep infinity >/dev/null

    (cd "$project_dir" && "$REPO_ROOT/mtui" clean 2>&1)

    if docker_container_exists "$expected_cn"; then
        log_fail "Container $expected_cn still exists after mtui clean"
        docker rm -f "$expected_cn" 2>/dev/null || true
        return 1
    fi

    log_pass "Container removed by mtui clean"
}

# Real test: `mtui list` shows the running container
test_list_shows_running_container() {
    log_test "mtui list shows a running project container..."

    local project_dir="$TEST_TMP_DIR/mtui-fixture-list"
    create_minimal_py "$project_dir"

    local expected_cn
    expected_cn="$(_expected_container_name "$project_dir")"

    docker run -d --name "$expected_cn" "$MTUI_IMAGE" sleep infinity >/dev/null

    local output
    output=$(cd "$project_dir" && "$REPO_ROOT/mtui" list 2>&1)

    docker rm -f "$expected_cn" 2>/dev/null || true

    # mtui list strips the "mtui-" prefix in output
    local short_name
    short_name="${expected_cn#mtui-}"

    if echo "$output" | grep -q "$short_name"; then
        log_pass "mtui list shows $short_name"
    else
        log_fail "Expected $short_name in mtui list output, got:\n$output"
        return 1
    fi
}

main() {
    setup
    set +e
    local passed=0 failed=0

    for fn in \
        test_start_creates_named_container \
        test_status_no_container \
        test_status_running_after_start \
        test_clean_removes_container \
        test_list_shows_running_container; do
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
