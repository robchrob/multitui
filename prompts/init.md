${USER_INSTRUCTION:+USER INSTRUCTION: ${USER_INSTRUCTION}
}
You are setting up an agentic environment + initial functional version for a NEW EMPTY project.
Project name: "${PROJECT_NAME}"
Year is 2026.

## THIS IS A NEW EMPTY PROJECT
Derive intent entirely from the project name and user instruction above.
Do NOT explore the filesystem to detect the stack — there is nothing meaningful there.
The only pre-existing files may be the fixture stubs created by the test harness (ignored).

## Step 0 — Decide intent
From the project name and user instruction only, determine:
- Language: JavaScript/TypeScript, Python, or Other (Go, Rust, Ruby, PHP, Shell, C/C++, etc.)
- Framework and purpose: API, webapp, CLI tool, library, daemon, etc.
- For Other stacks: What is the primary executable pattern?
  - CLI tool → single binary/script execution
  - Library → build as module for import
  - Daemon/service → long-running process with healthchecks
- Use exa search / context7 for version-specific docs on the chosen stack

## Your execution environment
You are inside a Docker container with Alpine + OpenCode + Docker CLI.
NO language runtimes exist here. ALL code execution uses DooD:
  docker
  docker compose

## Runtime conventions
Apply these precisely for known stacks, or follow their spirit for others:

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

### Other stacks (Go, Rust, Ruby, PHP, Elixir, CLI tools, Shell, C/C++, etc.)
Be flexible. Apply DooD best practices based on language:

#### Go projects
- Package manager: go mod
- Base image: golang:1.23-alpine (or -slim for smaller images)
- No COPY in Dockerfile — volume mounted during dev
- WORKDIR /app
- Named cache volume: go_mod_cache → /go/pkg/mod
- Build: CGO_ENABLED=0 for static binaries
- Multi-stage build recommended for final binaries

#### Rust projects
- Package manager: cargo
- Base image: rust:1.82-alpine
- No COPY in Dockerfile (volume mounted)
- WORKDIR /app
- Named cache volume: cargo_registry → /usr/local/cargo/registry
- Build: cargo build --release for production
- Consider rustls over openssl to avoid system deps

#### Ruby projects
- Package manager: bundler (gem for system gems)
- Base image: ruby:3.3-alpine
- WORKDIR /app
- Named cache volume: gem_cache → /usr/local/bundle
- Install deps: bundle install
- Run: bundle exec [command]

#### PHP projects
- Package manager: composer
- Base image: php:8.4-cli-alpine
- WORKDIR /app
- Named cache volume: composer_cache → /usr/local/cache/composer
- Extensions: install via docker-php-ext-install if needed

#### Shell/CLI tools (POSIX sh, bash scripts)
- Base image: alpine:latest (for pure scripts) or debian:stable-slim
- Install dependencies: apk add / apt-get install
- WORKDIR /app
- Mark scripts executable: chmod +x
- Build: shellcheck for linting (if available)
- Pure shell avoids runtime entirely

#### C/C++ projects
- Base image: gcc:latest or clang:latest (or alpine variants)
- Build system: cmake, make, meson
- Named cache volume: cc_cache → /root/.ccache
- Multi-stage build: build in builder stage, copy binary to runtime

#### General DooD rules for Other stacks
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
  [one-line description]

  ## Environment
  This project uses MultiTUI — OpenCode runs inside a Docker container
  All code execution uses: docker / docker compose
  **User**: dev - sudo IS available if needed!

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

#### 5. Permissions
  ## Permissions
  ### Allowed without asking
  - All project files

  ### Never do
  - Read .env files

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

### .gitignore / .dockerignore
Generate a comprehensive .gitignore / .dockerignore for the detected stack covering:
- Language artifacts (node_modules/, __pycache__/, target/, vendor/, etc.)
- Package manager files (bun.lock if using text lockfile, .uv/, go.sum if vendored)
- Build outputs (dist/, build/, *.egg-info/, bin/)
- Environment files (.env, .env.local, .env.*.local, !.env.example)
- IDE/editor files (.idea/, .vscode/, *.swp, *.swo, *~)
- OS files (.DS_Store, Thumbs.db, desktop.ini)
- Logs (*.log, logs/, *.log.*)
- Coverage reports (coverage/, .coverage, *.lcov)
- Temporary files (*.tmp, .tmp/, *.cache)

Include stack-specific patterns based on detected framework (e.g., Next.js: .next/, SvelteKit: .svelte-kit/, Vite: .vite/).

Write all files directly.
