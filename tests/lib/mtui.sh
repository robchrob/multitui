#!/bin/bash
# mtui CLI wrapper for MultiTUI e2e tests

set -Eeuo pipefail

MTUI_BINARY="${MTUI_BINARY:-$HOME/.local/bin/mtui}"
MTUI_LOCAL="./mtui"

mtui_run() {
    local dir="$1"
    shift
    if [[ -x "$MTUI_LOCAL" ]]; then
        (cd "$dir" && "$MTUI_LOCAL" "$@")
    elif [[ -x "$MTUI_BINARY" ]]; then
        (cd "$dir" && "$MTUI_BINARY" "$@")
    else
        echo "mtui not found" >&2
        return 1
    fi
}
