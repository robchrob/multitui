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
  cat <<PROMPT
You are setting up a NEW EMPTY project.
Project name: "$name"
Stack: $stack

## Your execution environment
You are inside a Docker container with OpenCode + Docker CLI.
NO language runtimes exist here. ALL code execution uses DooD:
  docker run --rm -v \$PROJECT_ROOT:/app -w /app <image> <cmd>
  docker compose up
\$PROJECT_ROOT contains the absolute project path on the host.

## Runtime conventions
This project uses specific runtimes — apply them precisely:

### JavaScript/TypeScript projects
- Package manager: bun (never npm/yarn/pnpm)
- Runtime base image: imbios/bun-node:latest-slim
  (required for Vinxi/TanStack Start: Vinxi's dev server needs Node internally
   even when using bun as package manager — pure oven/bun image will fail)
- Lockfile: bun.lock (not bun.lockb, changed in bun v1.2)
- Dev scripts: bun run dev / bun run build / bun run test
- HMR in Docker: Vite polling required — vite.config must include:
    server: { watch: { usePolling: true }, host: true }
  (bun --watch / --hot don't receive filesystem events from Docker volume mounts)
- Named cache volume: bun_cache → /root/.bun/install/cache

### Python projects
- Package manager: uv (never pip directly)
- Base image: python:3.13-slim with uv binary copied in:
    COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
- Required env vars in Dockerfile:
    ENV UV_LINK_MODE=copy        # symlinks break on volume mounts
    ENV UV_COMPILE_BYTECODE=1    # faster startup
    ENV UV_PYTHON_DOWNLOADS=never
- Dev commands: uv run <script> / uv run pytest / uv sync
- Named cache volume: uv_cache → /root/.cache/uv

## Step 1 — resolve library versions with context7
Use context7 for the framework and its 2-3 most version-sensitive dependencies.
Skip resolve-library-id if you know the ID (e.g. /vitejs/vite, /tanstack/router,
/drizzle-team/drizzle-orm, /facebook/react). Use targeted queries:
  "setup and config for [version]"
  "breaking changes in [version]"
  "correct vite.config / app.config for [version]"
Use results to pin exact versions in the Dockerfile and dependency files.

## Step 2 — generate these files

### AGENTS.md
Only project-specific facts. Include:

  # [project name]
  [one-line description]

  ## Stack
  [framework + exact versions from context7, key dependencies]

  ## DooD Commands
  [exact docker compose commands for: dev, test, build, lint, add dep]

  ## Structure
  [dirs and their purpose — only relevant once project has files]

  ## context7 library IDs
  [resolved IDs so future sessions skip resolve-library-id, e.g.:
   - Vite: /vitejs/vite
   - TanStack Start: /tanstack/start
   - Drizzle: /drizzle-team/drizzle-orm]

### Dockerfile
- Use the runtime conventions above exactly
- WORKDIR /app, no COPY (volume-mounted)
- Include the HMR polling config instruction comment if JS project
- CMD bound to 0.0.0.0

### docker-compose.yml
- Service using the Dockerfile
- Volume: \${PROJECT_ROOT:-.}:/app
- Named cache volume per the conventions above
- Port mappings, any backing services with healthchecks

Write all files directly. No explanation. No markdown fences.
PROMPT
}

_gen_prompt_bootstrap() {
  local name="$1" msg="$2"
  cat <<PROMPT
${msg:+USER INSTRUCTION: $msg
}
Analyze this existing project called "$name" and generate MultiTUI config for it.

## Your execution environment
You are inside a Docker container with OpenCode + Docker CLI.
NO language runtimes exist here. ALL code execution uses DooD (Docker-out-of-Docker):
  docker run --rm -v \$PROJECT_ROOT:/app -w /app <image> <cmd>
  docker compose up

## Runtime conventions
Apply these precisely for known stacks, or follow their spirit for others:

### JavaScript/TypeScript
- Package manager: bun. Check for bun.lock or bun.lockb to confirm.
- Base image: imbios/bun-node:latest-slim
- HMR: add server.watch.usePolling=true to vite.config if not present
- Cache volume: bun_cache → /root/.bun/install/cache

### Python
- Package manager: uv. Check for uv.lock or pyproject.toml to confirm.
- Base image: python:3.13-slim + uv binary:
    COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/
- Required env: UV_LINK_MODE=copy, UV_COMPILE_BYTECODE=1, UV_PYTHON_DOWNLOADS=never
- Cache volume: uv_cache → /root/.cache/uv

### Other Stacks (Go, Rust, Ruby, etc.)
If the stack is NOT JS or Python, be flexible but stick to DooD best practices:
- Use *-slim or alpine base images.
- WORKDIR /app.
- Do NOT use COPY in the Dockerfile (it's volume-mounted during dev).
- Define named cache volumes for the language's package manager (e.g., GOPATH, cargo registry).
- All commands in AGENTS.md must be 'docker compose run' or 'docker run'.

## Step 1 — discover the project
Run these to understand the structure:

  # Full tree excluding junk
  find . -maxdepth 3 -not -path '*/.*' -not -path './node_modules/*' -not -path './agent/*'

  # Look for manifests, docs, and entry points
  find . -maxdepth 3 \
    -not -path './.git/*' \
    -not -path './node_modules/*' \
    -not -path './agent/*' \
    \( -name 'package.json' -o -name 'bun.lock*' -o -name 'pyproject.toml' \
       -o -name 'requirements*.txt' -o -name 'uv.lock' -o -name '*.md' \
       -o -name 'go.mod' -o -name 'Cargo.toml' -o -name 'Gemfile' \
       -o -name 'Dockerfile*' -o -name 'docker-compose*.yml' \
       -o -name 'vite.config.*' -o -name 'app.config.*' \) \
    -type f | sort

Reading priority:
  1. All manifests found (package.json, pyproject.toml, go.mod, etc.)
  2. Any markdown files (README.md, details.md, etc.) to understand the context
  3. Existing Dockerfile and docker-compose.yml
  4. Entry points (main.ts, main.go, app.py, index.tsx, etc.)

## Step 2 — resolve stack with context7
With exact versions known, fetch docs for major dependencies.

## Step 3 — generate files

### AGENTS.md
Include:
  # [project name]
  [one-line description]
  ## Stack
  [Detected stack + versions]
  ## DooD Commands
  [Exact runnable commands — dev, test, build, lint, add dep]
  ## Structure
  ## context7 library IDs

### Dockerfile (ONLY if none exists)
### docker-compose.yml (ONLY if none exists)

Do NOT overwrite existing Dockerfile or docker-compose.yml.
Write files directly. No explanation.
PROMPT
}

_write_fallback_agents_md() {
  local name="$1" stack="$2"
  cat > AGENTS.md <<EOF
# $name
${stack:+$stack
}
## Stack
[fill in: framework, key dependencies with exact versions]

## DooD Commands
[fill in: exact docker compose commands for dev, test, build, lint]

## Structure
[fill in: dirs and their purpose once project has files]

## context7 library IDs
[fill in after first session: /org/repo IDs for main libs]
EOF
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
export -f _write_if_missing _append_gitignore
export -f _install_skills _install_commands
