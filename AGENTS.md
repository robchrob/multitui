# MultiTUI — Execution Environment
> This is the execution environment contract for the OpenCode agent running
> inside the `multitui` container. If you are developing MultiTUI itself,
> STOP and read AGENTS_DEV.md first.

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
Created by OpenCode during init/bootstrap. Never lives in the multitui image.

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

### deepwiki _(public GitHub repos, free, no key)_
Turn any public GitHub repo into a searchable wiki. Search by description
instead of file names. Useful for onboarding to large OSS codebases.

### filesystem _(no key)_
Read, write, list, move, copy, search files within the project directory.
Path validation enforced. The AI can inspect and modify your codebase directly.

### git _(no key)_
Full git operations: status, log, diff, commit, branch, push, pull, merge.
Exposes git CLI through MCP tools for version control without leaving the session.

### fetch _(no key)_
Fetch any URL and convert to clean markdown. Read documentation pages, blog
posts, API docs, and any public web content. Lightweight and fast.

### time _(no key)_
Current time, timezone conversions, date calculations. Useful for log analysis,
scheduling context, and time-sensitive data interpretation.

### a2a-search _(no key)_
Search 4,800+ MCP servers, AI agents, CLI tools, and agent skills.
Ask: "Find MCP servers for [use case]" — returns install commands and config.
No API key required. Use to discover new tools for any workflow need.

## Rules
- Configuration comes from the active config source (project-local → `~/.multitui/defaults` → image-baked); `mtui status` reports which one is active
- Dockerfiles, compose files → project root
- Spawned container ports bind to HOST
- Container state outside `$PROJECT_ROOT` is ephemeral
