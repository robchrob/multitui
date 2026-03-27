#!/bin/bash
# MultiTUI — OpenCode shell functions
#
# First-time setup (once):
#   git clone https://github.com/robchrob/multitui.git ~/tools/multitui
#   source ~/tools/multitui/.shell-functions.sh   # add to ~/.bashrc
#   _build
#
# New project:
#   mkdir my-app && cd my-app && git init
#   _attach
#   _init "React 19 + Vite"
#   _start
#
# Existing project (no submodule yet):
#   cd my-project
#   _attach
#   _bootstrap "This is a monorepo, look into /packages"
#   _start
#
# Cloned project (already has agent/):
#   git clone --recurse-submodules ...
#   cd project
#   source agent/.shell-functions.sh
#   _start

_MULTITUI_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_AGENT_DIR="agent"
_OPENCODE_DEFAULT_MODEL="opencode/minimax-m2.5-free"

_container_name() {
  echo "mtui-$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')"
}

# ============================================================================
# CORE
# ============================================================================

_build() {
  if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker daemon is not running or not accessible" >&2
    return 1
  fi
  local flags=()
  for arg in "$@"; do [[ "$arg" == -* ]] && flags+=("$arg"); done
  echo "Building multitui..."
  docker build \
    --build-arg HOST_UID="$(id -u)" \
    --build-arg HOST_GID="$(id -g)" \
    -f "$_MULTITUI_DIR/docker/Dockerfile" \
    -t multitui "${flags[@]}" "$_MULTITUI_DIR/docker"
}

_has_image() { docker images -q multitui 2>/dev/null | grep -q .; }

_start() {
  if ! docker info >/dev/null 2>&1; then
    echo "Error: Docker daemon is not running or not accessible" >&2
    return 1
  fi
  if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
    echo "Error: OPENROUTER_API_KEY is not set" >&2
    return 1
  fi
  local MODE="${1:-auto}"
  shift 2>/dev/null || true
  local PORT_FLAGS=()
  while [[ $# -gt 0 ]]; do
    case "$1" in -p|--port) PORT_FLAGS+=("-p" "$2"); shift 2 ;; *) shift ;; esac
  done

  local PROJ_DIR="$PWD"
  local CN="$(_container_name)"
  local DOCKER_GID="$(stat -c '%g' /var/run/docker.sock 2>/dev/null || echo 0)"

  if docker ps -aq -f name="^/${CN}$" | grep -q .; then
    local mounted
    mounted="$(docker inspect "$CN" --format '{{.Config.WorkingDir}}' 2>/dev/null)"
    if [[ "$mounted" != "$PROJ_DIR" ]]; then
      echo "Container $CN exists but belongs to: $mounted" >&2
      echo "Run: _clean   then: _start" >&2
      return 1
    fi
    echo "Resuming: $CN ($PROJ_DIR)"
    docker start -ai "$CN"
    return
  fi

  _has_image || { echo "No multitui image. Run: _build" >&2; return 1; }
  local FLAGS=(
    -it
    --name "$CN" --detach-keys="ctrl-z"
    -v "$PROJ_DIR":"$PROJ_DIR"
    -v "$_MULTITUI_DIR/config/opencode.json":/home/dev/.config/opencode/opencode.json:ro
    --group-add "$DOCKER_GID"
    -v /var/run/docker.sock:/var/run/docker.sock
    -v "$HOME/.ssh":/home/dev/.ssh:ro
    -e OPENROUTER_API_KEY
    -e OPENCODE_DEFAULT_MODEL="$_OPENCODE_DEFAULT_MODEL"
    -e GITHUB_TOKEN -e GITHUB_KEY -e GITHUB_USER
    -e EXA_API_KEY
    -e PROJECT_ROOT="$PROJ_DIR"
    -w "$PROJ_DIR"
    "${PORT_FLAGS[@]}"
  )

  if [ "$MODE" = "tty" ]; then
    docker run "${FLAGS[@]}" multitui bash
  else
    docker run "${FLAGS[@]}" multitui \
      bash -lc "export PATH='/home/dev/.opencode/bin:$PATH' && cd '$PROJ_DIR' && opencode --model \"$OPENCODE_DEFAULT_MODEL\""
  fi
}

_clean() {
  local CN="$(_container_name)"
  docker rm -f "$CN" 2>/dev/null && echo "Removed: $CN" || echo "Not found: $CN"
}

# ============================================================================
# LIFECYCLE
# ============================================================================

_write_if_missing() { local f="$1"; [[ ! -f "$f" ]] && cat > "$f" || cat > /dev/null; }

_append_gitignore() {
  local m="# MultiTUI"
  if [[ ! -f .gitignore ]] || ! grep -qF "$m" .gitignore; then
    cat >> .gitignore <<'GI'

# MultiTUI
opencode.json
.opencode/
GI
  fi
}

_render_template() {
  local file="$1"
  local content
  content="$(cat "$file")"
  shift
  while [[ $# -gt 0 ]]; do
    local var="${1%%=*}" val="${1#*=}"
    content="${content//\$\{$var\}/$val}"
    shift
  done
  echo "$content"
}

_attach() {
  local REMOTE="${1:-git@github.com:robchrob/multitui.git}"
  [[ ! -d .git ]] && git init
  if [[ ! -d "$_AGENT_DIR" ]]; then
    git submodule add "$REMOTE" "$_AGENT_DIR" 2>/dev/null || true
    git submodule update --init --recursive
    echo "Submodule added at $PWD/$_AGENT_DIR/"
  else
    echo "agent/ already exists"
  fi
  source "$PWD/$_AGENT_DIR/.shell-functions.sh"
  echo "Next: _init [\"stack description\"]  or  _bootstrap [\"instruction\"]"
}

_scaffold() {
  mkdir -p .opencode/{agents,commands,skills}
  _install_skills
  _install_commands
  _append_gitignore
}

_init() {
  local STACK_DESC="${1:-}"
  local N="$(basename "$PWD")"

  if [[ ! -d "$_AGENT_DIR" ]]; then
    echo "No agent/ submodule. Run: _attach" >&2
    return 1
  fi

  _scaffold

  if [[ -n "$STACK_DESC" ]] && _has_image; then
    echo "Generating project files for: $STACK_DESC"
    _run_opencode "$(_gen_prompt_init "$N" "$STACK_DESC")"
    echo ""
    echo "Generated. Check these files:"
    echo "  AGENTS.md            — project context for OpenCode"
    echo "  Dockerfile           — dev runtime"
    echo "  docker-compose.yml   — services and volume caching"
    echo ""
    echo "Then: _start"
  elif [[ -n "$STACK_DESC" ]]; then
    echo "No multitui image yet. Run _build first for AI-generated files."
    _write_fallback_agents_md "$N" "$STACK_DESC"
    echo "Wrote template AGENTS.md. After _build: run _init again, or _start and tell OpenCode."
  else
    _write_fallback_agents_md "$N" ""
    echo "Scaffolded with template AGENTS.md."
    echo "  Option A: _init \"your stack description\"  (generates everything)"
    echo "  Option B: _start and describe your stack to OpenCode"
  fi
}

_bootstrap() {
  local BOOTSTRAP_MSG="${1:-}"
  local N="$(basename "$PWD")"

  if [[ ! -d "$_AGENT_DIR" ]]; then
    echo "No agent/ submodule. Run: _attach" >&2
    return 1
  fi

  _scaffold

  if _has_image; then
    echo "Analyzing project with OpenCode..."
    _run_opencode "$(_gen_prompt_bootstrap "$N" "$BOOTSTRAP_MSG")"
    echo ""
    echo "Generated. Check:"
    echo "  AGENTS.md            — project context for OpenCode"
    echo "  Dockerfile           — dev runtime (if created)"
    echo "  docker-compose.yml   — services (if created)"
    echo ""
    echo "Then: _start"
  else
    local info=""
    [[ -f package.json ]] && info="JS/TS"
    [[ -f pyproject.toml || -f requirements.txt ]] && info="${info:+$info + }Python"
    _write_fallback_agents_md "$N" "${info:-unknown stack}"
    echo "Basic bootstrap (${info:-unknown}). For full AI analysis:"
    echo "  _build && _bootstrap"
  fi
}

# ============================================================================
# OPENCODE INTERACTION
# ============================================================================

_run_opencode() {
  local prompt="$1"
  local proj_dir="$PWD"
  local gid="$(stat -c '%g' /var/run/docker.sock 2>/dev/null || echo 0)"
  local prompt_file
  prompt_file="$(mktemp)"
  printf '%s' "$prompt" > "$prompt_file"
  # Headless one-shot: permission: "allow" in mounted config covers this.
  docker run --rm \
    -v "$proj_dir":"$proj_dir" \
    -v "$prompt_file":/tmp/prompt.txt:ro \
    -v "$_MULTITUI_DIR/config/opencode.json":/home/dev/.config/opencode/opencode.json:ro \
    --group-add "$gid" \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -e OPENROUTER_API_KEY \
    -e OPENCODE_DEFAULT_MODEL="$_OPENCODE_DEFAULT_MODEL" \
    -e GITHUB_TOKEN \
    -e EXA_API_KEY \
    -e PROJECT_ROOT="$proj_dir" \
    -w "$proj_dir" \
    multitui bash -lc 'export PATH="/home/dev/.opencode/bin:$PATH" && opencode --model "$OPENCODE_DEFAULT_MODEL" run "$(cat /tmp/prompt.txt)"'
  rm -f "$prompt_file"
}

_gen_prompt_init() {
  local name="$1" stack="$2"
  _render_template "$_MULTITUI_DIR/defaults/templates/init.md" \
    "PROJECT_NAME=$name" "STACK=$stack"
}

_gen_prompt_bootstrap() {
  local name="$1" msg="$2"
  _render_template "$_MULTITUI_DIR/defaults/templates/bootstrap.md" \
    "PROJECT_NAME=$name" "USER_INSTRUCTION=$msg"
}

_write_fallback_agents_md() {
  local name="$1" stack="$2"
  _render_template "$_MULTITUI_DIR/defaults/templates/fallback-agents-md.md" \
    "PROJECT_NAME=$name" "STACK=$stack" > AGENTS.md
}

# ============================================================================
# HELPERS
# ============================================================================

_install_skills() {
  for f in "$_MULTITUI_DIR"/defaults/skills/*/SKILL.md; do
    [[ -f "$f" ]] || continue
    local skill_name
    skill_name="$(basename "$(dirname "$f")")"
    mkdir -p ".opencode/skills/$skill_name"
    _write_if_missing ".opencode/skills/$skill_name/SKILL.md" < "$f"
  done
}

_install_commands() {
  mkdir -p .opencode/commands
  for f in "$_MULTITUI_DIR"/defaults/commands/*.md; do
    [[ -f "$f" ]] || continue
    local cmd_name
    cmd_name="$(basename "$f" .md)"
    _write_if_missing ".opencode/commands/$cmd_name.md" < "$f"
  done
}

# ============================================================================
# EXPORTS
# ============================================================================
export -f _build _start _has_image _container_name
export -f _clean
export -f _attach _init _bootstrap _scaffold
export -f _run_opencode _write_fallback_agents_md
export -f _gen_prompt_init _gen_prompt_bootstrap
export -f _write_if_missing _append_gitignore _render_template
export -f _install_skills _install_commands
