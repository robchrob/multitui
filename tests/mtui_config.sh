#!/bin/bash
# mtui config precedence tests — project-local > global ($MTUI_HOME/defaults) > image-baked
# Does NOT require OPENROUTER_API_KEY

set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

source "$LIB_DIR/test_helpers.sh"
source "$LIB_DIR/docker.sh"

MTUI_IMAGE="${MTUI_IMAGE:-multitui}"
MTUI_HOME="$HOME/.multitui"
TEST_TMP_DIR="/tmp/mtui_test_$$"

setup() {
    mkdir -p "$TEST_TMP_DIR"
    log_info "Setting up config test environment..."
    # Ensure global defaults exist so the global-config path is testable
    if [[ ! -f "$MTUI_HOME/defaults/opencode.json" ]]; then
        mkdir -p "$MTUI_HOME/defaults"
        cp "$REPO_ROOT/defaults/opencode.json" "$MTUI_HOME/defaults/opencode.json"
        log_info "Installed repo defaults to $MTUI_HOME/defaults/ (test fixture)"
    fi
}

teardown() {
    rm -rf "$TEST_TMP_DIR"
}

# Image-baked defaults: bare `docker run multitui` has config, commands, skills
test_image_bakes_defaults() {
    log_test "Image contains baked opencode.json, commands, and skills..."

    if ! docker run --rm "$MTUI_IMAGE" test -f /workspace/.opencode/opencode.json; then
        log_fail "opencode.json not baked into image"
        return 1
    fi
    if ! docker run --rm "$MTUI_IMAGE" test -f /workspace/.opencode/commands/run.md; then
        log_fail "commands/ not baked into image"
        return 1
    fi
    if ! docker run --rm "$MTUI_IMAGE" test -f /workspace/.opencode/skills/magic-versioning/SKILL.md; then
        log_fail "skills/ not baked into image"
        return 1
    fi

    log_pass "Image bakes defaults, commands, and skills"
}

# Bare container must not reference removed plugins
test_image_has_no_plugins() {
    log_test "Baked config no longer references third-party plugins..."

    local output
    output=$(docker run --rm "$MTUI_IMAGE" cat /workspace/.opencode/opencode.json)
    if echo "$output" | grep -q "oh-my-openagent\|ensemble"; then
        log_fail "Baked config still references plugins:\n$output"
        return 1
    fi

    log_pass "Baked config is plugin-free"
}

# Global config: mtui status reports the $MTUI_HOME/defaults source
test_status_reports_global_config() {
    log_test "mtui status reports global config source..."

    local project_dir="$TEST_TMP_DIR/cfg-global"
    mkdir -p "$project_dir"

    local output
    output=$(cd "$project_dir" && "$REPO_ROOT/mtui" status 2>&1)

    if echo "$output" | grep -q "opencode.json (global)"; then
        log_pass "Status shows global config source"
    else
        log_fail "Expected global config source in status, got:\n$output"
        return 1
    fi
}

# Project-local opencode.json overrides global
test_project_config_overrides_global() {
    log_test "Project-local opencode.json overrides global config..."

    local project_dir="$TEST_TMP_DIR/cfg-project"
    mkdir -p "$project_dir"
    echo '{ "model": "opencode/test-model" }' > "$project_dir/opencode.json"

    local output
    output=$(cd "$project_dir" && "$REPO_ROOT/mtui" status 2>&1)

    if echo "$output" | grep -q "opencode.json (project)"; then
        log_pass "Status shows project config source"
    else
        log_fail "Expected project config source in status, got:\n$output"
        return 1
    fi
}

# .multitui/opencode.json takes highest precedence
test_multitui_dir_config_wins() {
    log_test ".multitui/opencode.json takes precedence over root opencode.json..."

    local project_dir="$TEST_TMP_DIR/cfg-dot"
    mkdir -p "$project_dir/.multitui"
    echo '{ "model": "opencode/test-model" }' > "$project_dir/opencode.json"
    echo '{ "model": "opencode/dot-model" }' > "$project_dir/.multitui/opencode.json"

    local output
    output=$(cd "$project_dir" && "$REPO_ROOT/mtui" status 2>&1)

    if echo "$output" | grep -q "\.multitui/opencode.json (project)"; then
        log_pass "Status shows .multitui config source"
    else
        log_fail "Expected .multitui config source in status, got:\n$output"
        return 1
    fi
}

main() {
    trap 'kill $(jobs -p) 2>/dev/null; exit 130' INT
    setup
    set +e
    local passed=0 failed=0

    for fn in \
        test_image_bakes_defaults \
        test_image_has_no_plugins \
        test_status_reports_global_config \
        test_project_config_overrides_global \
        test_multitui_dir_config_wins; do
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