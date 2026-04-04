${USER_INSTRUCTION:+USER INSTRUCTION: ${USER_INSTRUCTION}
}
You are setting up a agentic environment + initial functional version for new NEW EMPTY project.
Project name: "${PROJECT_NAME}"

## Step 0 — Detect intent
From the project name or user instruction, detect:
- Language: JavaScript/TypeScript, Python, or Other
- Frameworks: use exa search / context7
- Purpose: API, webapp, CLI tool, etc.

Use tools to help:
- web search / reseatch → exa search
- Unfamiliar framework → deepwiki_ask_question to understand typical project structure
- Need version-specific docs → context7_resolve-library-id + context7_query-docs

## Your execution environment
You are inside a Docker container with Alpine + OpenCode + Docker CLI.
NO language runtimes exist here. ALL code execution uses DooD:
  docker
  docker compose

## Runtime conventions
This project uses specific runtimes — apply them precisely:

### JavaScript/TypeScript projects
- Package manager: bun (never npm/yarn/pnpm)
- Runtime base image: imbios/bun-node:latest-slim
  (required for Vinxi/TanStack Start: Vinxi's dev server needs Node internally
   even when using bun as package manager — pure oven/bun image will fail)
- Lockfile: bun.lock
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
- Dev commands: uv run script / uv run pytest / uv sync
- Named cache volume: uv_cache → /root/.cache/uv

### Other stacks (Go, Rust, Ruby, PHP, Elixir, etc.)
Be flexible. Apply DooD best practices:
- Use appropriate slim or alpine base image for the language
- Use native package manager (go mod, cargo, gem, composer, mix, etc.)
- WORKDIR /app, no COPY in Dockerfile (volume-mounted during dev)
- Define named cache volumes for the language's package manager
- CMD bound to 0.0.0.0

## Step 1 — resolve library versions with context7
Use context7 for the framework and all of its dependencies.
Skip resolve-library-id if you know the ID (e.g. /vitejs/vite, /tanstack/router,
/drizzle-team/drizzle-orm, /facebook/react). Use targeted queries (exa search):
  "setup and config for [version]"
  "breaking changes in [version]"
  "correct vite.config / app.config for [version]"
Use results to pin exact versions in the Dockerfile and dependency files.

## Step 2 — generate these files

### AGENTS.md
**Philosophy:** AGENTS.md is a README for agents, not for humans. Write ONLY
what an AI agent cannot discover by reading the source code itself.
Do NOT summarize what the framework does. Do NOT repeat README content.
Every line must earn its place — if an agent could figure it out from the code, cut it.

Include these six sections:

#### 1. Header
  # [project name]
  [one-line description of what the project does and its purpose]

#### 2. Stack
Exact pinned versions with emphasis on non-obvious choices.
Explain deviations from defaults (e.g. why this base image was chosen).
  ## Stack
  - Runtime: [detected runtime + version]
  - Framework: [name + exact version from context7]
  - Key deps: [only deps with version-sensitive or tricky behavior]

#### 3. Commands (MOST IMPORTANT SECTION)
Every command must be copy-paste runnable inside Docker. Include full flags.
Use the exact package manager, test runner, and toolchain for the detected stack.
Provide file-scoped variants where supported — prefer running smallest scope needed.
  ## Commands
  # [dev server]
  docker compose up

  # [run all tests]
  docker compose run --rm app [stack-appropriate test command]

  # [run a single test file]
  docker compose run --rm app [test command] path/to/file

  # [run tests matching a pattern]
  docker compose run --rm app [test command] [pattern flag] "name"

  # [static analysis / type check]
  docker compose run --rm app [stack-appropriate check command] path/to/file

  # [lint with autofix]
  docker compose run --rm app [lint command] --fix path/to/file

  # [add a runtime dependency]
  docker compose run --rm app [package manager] add [package]

  # [add a dev dependency]
  docker compose run --rm app [package manager] add -d [package]

  # [production build]
  docker compose run --rm app [build command]

#### 4. Conventions (counterintuitive rules only)
Document ONLY patterns that will surprise an agent unfamiliar with this codebase.
Standard framework patterns do not belong here — agents already know them.
Write concrete rules. Show a short snippet if the rule is complex.
If everything follows standard framework conventions, omit this section entirely.

  ## Conventions
  [Only non-obvious, project-specific rules — e.g. error handling patterns,
  state management constraints, module boundaries, naming deviations, etc.]

#### 5. Permissions (three-tier allow/deny)
Give the agent explicit operating boundaries so it never has to guess what's safe.
  ## Permissions
  ### Allowed without asking
  - Everything but (below)

  ### Ask first
  - Modify agent configuration in agent/
  - Modify DooD agent/docker/Dockerfile

  ### Never do
  - Read or modify .env files
  - Hard-code secrets, API keys, or credentials anywhere

#### 6. context7 IDs
List every library ID you resolved during this session so future sessions can skip resolve-library-id entirely.
  ## context7 IDs
  - [library name]: [/org/repo-id]
  - [library name]: [/org/repo-id]
  ...

### Dockerfile
- Use the runtime conventions above exactly
- WORKDIR /app, no COPY (volume-mounted during dev)
- Comment explains any non-obvious image choice
- CMD bound to 0.0.0.0

### docker-compose.yml
- Service using the Dockerfile
- Volume: ${PROJECT_ROOT:-.}:/app
- Named cache volume per the conventions above
- Port mappings, any backing services with healthchecks
- Pass PROJECT_ROOT as env var

Write all files directly.
