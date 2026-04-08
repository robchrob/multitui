${USER_INSTRUCTION:+USER INSTRUCTION: ${USER_INSTRUCTION}
}
Analyze this existing project called "${PROJECT_NAME}" and adapt MultiTUI to work with it.
Year is 2026.

## Philosophy: ADAPT — preserve what works, improve what's missing

This is an EXISTING project. Make MultiTUI work WITH it:
- Preserve existing configs that work
- Add MultiTUI elements where missing
- Make changes that make sense — not dogmatic preservation
- NEVER discard existing AGENTS.md content — it's the project's source of truth

## Your execution environment
You are inside a Docker container with OpenCode + Docker CLI.
ALL code execution uses DooD (Docker-out-of-Docker):
  docker
  docker compose

## MCP Tools
- **context7**: Resolve library IDs for detected frameworks, get version-specific docs
- **exa search**: Search "Docker dev setup [stack]", "[framework] best practices 2025/2026"
- **deepwiki**: If project references a known repo/pattern
- **a2a-search**: Discover MCP servers relevant to this stack

## Phase 1 — DISCOVER

Scan the project to identify the stack:

```bash
ls -la
find . -maxdepth 3 -type f \( -name 'package.json' -o -name 'pyproject.toml' -o -name 'requirements.txt' -o -name 'go.mod' -o -name 'Cargo.toml' -o -name 'Gemfile' -o -name 'composer.json' -o -name '*.csproj' -o -name '*.sln' -o -name 'mix.exs' -o -name 'build.gradle*' -o -name 'pom.xml' -o -name 'Makefile' -o -name 'CMakeLists.txt' -o -name 'AGENTS.md' -o -name 'Dockerfile*' -o -name 'docker-compose*.yml' -o -name 'docker-compose*.yaml' -o -name '.dockerignore' -o -name '.gitignore' -o -name '.env.example' \) 2>/dev/null
```

Read whatever marker files you find. Identify:
- **Language** and runtime version
- **Framework** (if any) and version
- **Package manager** (bun, uv, npm, pip, go mod, cargo, gem, composer, mix, etc.)
- **Build/test/dev commands** from scripts entries, Makefiles, config files
- **Existing Docker setup**: base images, services, ports, volumes
- **Existing AGENTS.md**: if present, READ IT FIRST — it defines the project's conventions

## Phase 2 — RESEARCH

Using the detected stack, research with MCP tools:
- **context7**: `resolve-library-id` for the framework and key deps, then `query-docs` for setup/config
- **exa search**: search for Docker development patterns for the detected stack
- Record all resolved context7 library IDs — they go into AGENTS.md

## Phase 3 — GENERATE AGENTS.md

If AGENTS.md already exists, MERGE its content into this template — never discard existing rules.
If it's missing, generate fresh. Follow this structure:

### 1. Header
```
# [project name]
[one-line description]

## Environment
This project uses MultiTUI — OpenCode runs inside a Docker container
CRITICAL: Load @agent/AGENTS.md (./agent/AGENTS.md) for execution environment details
All code execution uses: docker / docker compose
**User**: dev - sudo IS available if needed!
```

### 2. Stack
Exact pinned versions. Explain non-obvious choices.
```
## Stack
- Runtime: [detected runtime + version]
- Framework: [name + version from context7]
- Key deps: [only deps with version-sensitive or tricky behavior]
```

### 3. Commands (MOST IMPORTANT)
Every command copy-paste runnable inside Docker. Full flags.
Use the detected package manager, test runner, and toolchain.
```
## Commands
# [dev server]
docker compose up

# [run all tests]
docker compose run --rm app [test command]

# [run a single test file]
docker compose run --rm app [test command] path/to/file

# [run tests matching a pattern]
docker compose run --rm app [test command] [pattern flag] "name"

# [static analysis / type check]
docker compose run --rm app [check command] path/to/file

# [lint with autofix]
docker compose run --rm app [lint command] --fix path/to/file

# [add a runtime dependency]
docker compose run --rm app [package manager] add [package]

# [add a dev dependency]
docker compose run --rm app [package manager] add -d [package]

# [production build]
docker compose run --rm app [build command]
```

### 4. Conventions
ONLY non-obvious, project-specific rules that would surprise an agent.
If everything follows standard framework conventions, omit this section.

### 5. Permissions
```
## Permissions
### Allowed without asking
- All project files (outside agent/)

### Ask first
- Modify agent/ directory (MultiTUI framework - see @agent/AGENTS.md)

### Never do
- Commit changes to agent/ directory
- Read .env files
```

### 6. context7 IDs
All resolved library IDs from Phase 2:
```
## context7 IDs
- [library name]: [/org/repo-id]
```

## Phase 4 — ADAPT

### DooD conventions (apply when creating/modifying Docker files)

For known stacks:
- **JavaScript/TypeScript**: Package manager bun, base `imbios/bun-node:latest-slim`, named cache volume `bun_cache` → `/root/.bun/install/cache`, HMR needs Vite polling (`server: { watch: { usePolling: true }, host: true }`)
- **Python**: Package manager uv, base `python:3.X-slim` + `COPY --from=ghcr.io/astral-sh/uv:latest /uv /uvx /bin/`, env `UV_LINK_MODE=copy UV_COMPILE_BYTECODE=1 UV_PYTHON_DOWNLOADS=never`, named cache volume `uv_cache` → `/root/.cache/uv`

For any other stack:
- Use appropriate slim or alpine base image for the language
- Use native package manager (go mod, cargo, gem, composer, mix, etc.)
- WORKDIR /app, no COPY in Dockerfile (volume-mounted during dev)
- Named cache volume for the package manager's cache directory
- CMD bound to 0.0.0.0

### Dockerfile
- Exists and works for dev → preserve, only modify if MultiTUI needs it (Docker CLI access, workdir)
- Exists but broken → fix with conventions above
- Missing → create with stack-appropriate base

### docker-compose.yml
- Exists → preserve ALL services (postgres, redis, etc.), adapt app service only if needed
- Missing → create with: app service, volume `${PROJECT_ROOT:-.}:/app`, named cache volume, PROJECT_ROOT env var, port mappings

### .gitignore
- Exists → append `agent/` if missing, never remove entries
- Missing → create with `agent/` + language-specific artifacts

### .dockerignore
- Exists → append `agent/` if missing, never remove entries
- Missing → create with `agent/`

## Phase 5 — VERIFY

```bash
docker compose config --quiet && echo "Valid" || echo "Invalid"
```

## Summary

| File | Action |
|------|--------|
| AGENTS.md exists | Merge into 6-section template, never discard |
| AGENTS.md missing | Generate from template with detected stack |
| Dockerfile exists | Preserve unless changes needed |
| Dockerfile missing | Create with stack-appropriate base |
| docker-compose.yml exists | Preserve services, adapt app if needed |
| docker-compose.yml missing | Create with proper volumes/ports |
| .gitignore | Append `agent/` if missing |
| .dockerignore | Append `agent/` if missing |

Be adaptive. Make changes that make sense.
