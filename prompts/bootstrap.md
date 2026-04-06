${USER_INSTRUCTION:+USER INSTRUCTION: ${USER_INSTRUCTION}
}
Analyze this existing project called "${PROJECT_NAME}" and generate MultiTUI config for it.
Year is 2026.

## MCP Tools to Use
- **context7**: Get version-specific docs for detected frameworks (run resolve-library-id first, then query-docs)
- **deepwiki**: If user mentions a known repo/stack pattern (e.g., "like T3 Stack"), query deepwiki to understand structure
- **exa search**: Search current best practices, troubleshooting, or common patterns for detected stack

## Your execution environment
You are inside a Docker container with OpenCode + Docker CLI.
NO language runtimes exist here. ALL code execution uses DooD (Docker-out-of-Docker):
  docker
  docker compose

## Runtime conventions
Apply these precisely for known stacks, or follow their spirit for others:

### JavaScript/TypeScript
- Package manager: bun - adjust if needed
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

Run these commands to understand the structure. Read only what they return — do not recurse further.

```bash
# Manifests and key config files only — stops at depth 3, skips all dependency dirs
find . -maxdepth 3 \
  -not -path './.git/*' \
  -not -path './node_modules/*' \
  -not -path './agent/*' \
  -not -path './.venv/*' \
  -not -path './venv/*' \
  -not -path './__pycache__/*' \
  -not -path './target/*' \
  -not -path './vendor/*' \
  -not -path './dist/*' \
  -not -path './build/*' \
  \( -name 'package.json' -o -name 'bun.lock' -o -name 'pyproject.toml' \
     -o -name 'requirements*.txt' -o -name 'uv.lock' -o -name '*.md' \
     -o -name 'go.mod' -o -name 'Cargo.toml' -o -name 'Gemfile' \
     -o -name 'Dockerfile*' -o -name 'docker-compose*.yml' \
     -o -name 'vite.config.*' -o -name 'app.config.*' \) \
  -type f | sort
```

**Reading priority — stop as soon as the stack is clear:**
1. Package manifest (package.json, pyproject.toml, go.mod, Cargo.toml, Gemfile) — this alone usually identifies the stack
2. Existing Dockerfile and docker-compose.yml if present
3. One entry point (main.ts, app.py, index.tsx, main.go, etc.) only if the manifest is ambiguous
4. README.md only if intent is still unclear after the above

**Hard stops — never read these:**
- `node_modules/`, `.venv/`, `venv/`, `target/`, `vendor/`, `dist/`, `build/`
- `agent/` and anything inside it
- Test files (`*.test.*`, `*_test.*`, `tests/`, `spec/`) — you don't need them to scaffold config
- Lock files beyond confirming package manager (bun.lock, uv.lock, package-lock.json)
- Any file not in the reading priority list above

Once you have identified runtime, package manager, and framework — stop exploring. You have enough.

## Step 2 — resolve stack with context7
With exact versions known, fetch docs for the primary framework only.
Do not fetch docs for every dependency — only those with version-sensitive config.

## Step 3 — generate files

### AGENTS.md
**Philosophy:** Write ONLY what this agent cannot discover by reading the code itself.
Do NOT repeat what's in README, package.json, or obvious from the file tree.
The best AGENTS.md is short and dense with non-inferable facts.

Include these six sections:

#### 1. Header
  # [project name]
  [one-line description]

  ## Environment
  This project uses MultiTUI — OpenCode runs inside a Docker container
 CRITICAL: Load @agent/AGENTS.md (./agent/AGENTS.md) for execution environment details
  All code execution uses: docker / docker compose
  **User**: dev - sudo IS available if needed!

#### 2. Stack
Exact versions only — not what's inferable from package.json.
Note non-obvious choices: why this package manager, why this base image, etc.
  ## Stack
  - Runtime: [detected runtime + version]
  - Framework: [name + exact version]
  - Key deps: [only ones with tricky or version-sensitive behavior]

#### 3. Commands (MOST IMPORTANT SECTION)
Every command must be copy-paste runnable. Include full flags.
Use the exact package manager, test runner, and toolchain found in the project.
Provide file-scoped variants where supported — prefer smallest scope needed.
  ## Commands
  # [dev server]
  docker compose up

  # [run all tests]
  docker compose run --rm app [detected test command]

  # [run a single test file]
  docker compose run --rm app [test command] path/to/file

  # [run tests matching a pattern]
  docker compose run --rm app [test command] [pattern flag] "name"

  # [static analysis / type check]
  docker compose run --rm app [detected check command] path/to/file

  # [lint with autofix]
  docker compose run --rm app [detected lint command] --fix path/to/file

  # [add a runtime dependency]
  docker compose run --rm app [detected package manager] add [package]

  # [add a dev dependency]
  docker compose run --rm app [detected package manager] add -d [package]

  # [production build]
  docker compose run --rm app [detected build command]

#### 4. Conventions (counterintuitive rules only)
Document ONLY patterns that will surprise an agent unfamiliar with this codebase.
Standard framework patterns do not belong here — agents already know them.
Write concrete rules. Show a short snippet if the rule is complex.
If everything follows standard conventions, omit this section entirely.

  ## Conventions
  [Only non-obvious, project-specific rules — e.g. error handling patterns,
  state management constraints, module boundaries, naming deviations, etc.]

#### 5. Permissions
  ## Permissions
  ### Allowed without asking
  - All project files (outside agent/)

  ### Ask first
  - Modify agent/ directory (MultiTUI framework - see @agent/AGENTS.md)

  ### Never do
  - Commit changes to agent/ submodule
  - Read .env files

#### 6. context7 IDs
List every library ID you resolved during this session so future sessions can skip resolve-library-id entirely.
  ## context7 IDs
  - [library name]: [/org/repo-id]
  - [library name]: [/org/repo-id]
  ...

### Dockerfile
Edit / modify as needed for making the project run

### docker-compose.yml
Edit / modify as needed for making the project run

### .gitignore / .dockerignore
Check for existing .gitignore / .dockerignore first. If missing or incomplete, generate one that covers:
- agent/ directory
- Language-specific artifacts (node_modules/, __pycache__/, target/, etc.)
- Package manager caches (.uv/, etc.)
- Build outputs (dist/, build/, *.egg-info/)
- Environment files (.env, .env.local, .env.*.local)
- IDE/editor files (.idea/, .vscode/, *.swp, *.swo)
- OS files (.DS_Store, Thumbs.db)
- Logs (*.log, logs/)
- Docker artifacts if applicable

If .gitignore exists, append missing patterns rather than overwriting. Never remove existing entries.

Write all files directly.
