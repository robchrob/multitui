${USER_INSTRUCTION:+USER INSTRUCTION: ${USER_INSTRUCTION}
}
Analyze this existing project called "${PROJECT_NAME}" and generate MultiTUI config for it.

## Your execution environment
You are inside a Docker container with OpenCode + Docker CLI.
NO language runtimes exist here. ALL code execution uses DooD (Docker-out-of-Docker):
  docker run --rm -v $PROJECT_ROOT:/app -w /app <image> <cmd>
  docker compose up

## Runtime conventions
Apply these precisely for known stacks, or follow their spirit for others:

### JavaScript/TypeScript
- Package manager: bun. Check for bun.lock to confirm.
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
    \( -name 'package.json' -o -name 'bun.lock' -o -name 'pyproject.toml' \
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
