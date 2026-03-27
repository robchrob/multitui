# MultiTUI — Execution Environment
> Submodule at `$PROJECT_ROOT/agent/`. Project rules → `AGENTS.md`.

## Execution Layers
```
YOU ARE HERE → multitui container (OpenCode + Docker CLI + git)
  File I/O: direct (read/write/edit project files via volume mount)
  Code execution: DooD only (docker run / docker compose)
    → spawns runtime containers on HOST Docker daemon
```
_Node.js in this container is for OpenCode internals. NOT for project code._
The agent is also running inside docker, not on the host.
So the "multitui container" (where I'm running) is itself inside Docker, and it has access to Docker to spawn more containers. So you should be using docker compose to run commands.

## Code Execution (always DooD)
- One-off: `docker run --rm -v $PROJECT_ROOT:/app -w /app <image> <cmd>`
- Services: `docker compose up` (uses project's docker-compose.yml)
- Build project image: `docker build -t <name> $PROJECT_ROOT`

## Project Dockerfile
Location: `$PROJECT_ROOT/Dockerfile` — defines dev runtime for THIS project.
Created by OpenCode during init/bootstrap. Never lives in `agent/`.

## MCP Servers (always available)

### memory
Persistent key-value memory across tool calls. Use to track state, decisions,
and file lists within a session.

### sequential-thinking
Structured step-by-step reasoning for complex architectural decisions, debugging
chains, and multi-step plans. Invoke when a problem has more than 3 interdependent
parts.

### context7 _(requires no key)_
Injects real-time, version-specific library docs into the prompt. Add
`use context7` to any prompt involving an unfamiliar or version-sensitive API.
Prevents hallucinated method signatures and outdated call patterns.

### exa _(requires EXA_API_KEY)_
Semantic web search with code-focused result categories (GitHub, Stack Overflow,
academic, LinkedIn, blogs). Use when you need current answers that aren't in
training data — package changelogs, obscure error messages, recent CVEs.
Get a free key at exa.ai.

### github _(requires GITHUB_TOKEN)_
Full GitHub API via MCP: repos, PRs, issues, CI/CD, branches, file contents.
Runs via `docker run ghcr.io/github/github-mcp-server` (DooD-safe).
`GITHUB_DYNAMIC_TOOLSETS=1` keeps tool list compact — toolsets load on demand.
Use for: reading issues, creating PRs, checking CI status, searching org code.

### deepwiki _(public GitHub repos, free, no key)_
Turn any public GitHub repo into a searchable wiki. Search by description
instead of file names. Useful for onboarding to large OSS codebases.

## Rules
- `agent/` is READ-ONLY submodule
- Dockerfiles, compose files → project root
- Spawned container ports bind to HOST
- Container state outside `$PROJECT_ROOT` is ephemeral
