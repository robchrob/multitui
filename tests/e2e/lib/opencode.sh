#!/bin/bash
# OpenCode test helpers for MultiTUI e2e tests

set -Eeuo pipefail

OPENCODE_IMAGE="${OPENCODE_IMAGE:-multitui}"
OPENCODE_MODEL="${OPENCODE_MODEL:-opencode/qwen3.6-plus-free}"

opencode_version_in_container() {
    local container="$1"
    docker exec "$container" opencode --version 2>/dev/null || echo "unknown"
}

opencode_health_check() {
    local container="$1"
    local timeout="${2:-30}"
    local elapsed=0
    while [[ $elapsed -lt $timeout ]]; do
        if docker exec "$container" which opencode >/dev/null 2>&1; then return 0; fi
        sleep 1
        ((elapsed++)) || true
    done
    return 1
}
