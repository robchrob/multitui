#!/bin/bash
# Docker test helpers for MultiTUI e2e tests

set -Eeuo pipefail

DOCKER="${DOCKER:-docker}"

docker_image_exists() {
    local image="$1"
    $DOCKER images -q "$image" 2>/dev/null | grep -q .
}

docker_container_exists() {
    local name="$1"
    $DOCKER ps -a -q -f "name=^/${name}$" 2>/dev/null | grep -q .
}

docker_container_running() {
    local name="$1"
    local state
    state=$($DOCKER inspect -f '{{.State.Status}}' "$name" 2>/dev/null || echo "Not Created")
    [[ "$state" == "running" ]]
}

docker_cleanup_container() {
    local name="$1"
    if docker_container_exists "$name"; then
        $DOCKER rm -f "$name" 2>/dev/null || true
    fi
}

docker_cleanup_all_mtui() {
    local prefix="${1:-mtui-}"
    local containers
    containers=$($DOCKER ps -aq -f "name=^${prefix}" 2>/dev/null || true)
    if [[ -n "$containers" ]]; then
        echo "$containers" | xargs -r $DOCKER rm -f 2>/dev/null || true
    fi
}
