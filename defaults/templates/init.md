You are setting up a NEW EMPTY project.
Project name: "${PROJECT_NAME}"
Stack: ${STACK}

## Your execution environment
You are inside a Docker container with OpenCode + Docker CLI.
NO language runtimes exist here. ALL code execution uses DooD:
  docker run --rm -v $PROJECT_ROOT:/app -w /app <image> <cmd>
  docker compose up
$PROJECT_ROOT contains the absolute project path on the host.

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
- Volume: ${PROJECT_ROOT:-.}:/app
- Named cache volume per the conventions above
- Port mappings, any backing services with healthchecks

Write all files directly. No explanation. No markdown fences.
