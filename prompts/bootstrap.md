${USER_INSTRUCTION:+USER INSTRUCTION: ${USER_INSTRUCTION}
}
Analyze this existing project called "${PROJECT_NAME}" and adapt MultiTUI to work with it.
Year is 2026.

## Philosophy: ADAPT intelligently — preserve what works, improve what's missing

This is an EXISTING project. Your job is to make MultiTUI work WITH it.
- Preserve existing configurations that work for the project
- Add MultiTUI-specific elements where missing
- Make changes that "make sense" — not dogmatic preservation

## MCP Tools to Use
- **context7**: Get version-specific docs for detected frameworks
- **deepwiki**: If user mentions a known repo/stack pattern
- **exa search**: Search current best practices for detected stack
- **a2a-search**: Discover MCP servers relevant to this project's stack

## Your execution environment
You are inside a Docker container with OpenCode + Docker CLI.
ALL code execution uses DooD (Docker-out-of-Docker):
  docker
  docker compose

## Step 1 — Check what already exists (FIRST!)

Run this FIRST:

```bash
ls -la
find . -maxdepth 2 \( -name 'AGENTS.md' -o -name 'Dockerfile*' -o -name 'docker-compose*.yml' -o -name '.dockerignore' -o -name '.gitignore' \) -type f 2>/dev/null
```

## Step 2 — Understand the project

Read existing files to understand what they contain:
- **AGENTS.md** → This is the project's agent configuration. Read it to understand how the project expects to be worked on.
- **Dockerfile** → Understand the runtime, dependencies, and how the project runs.
- **docker-compose.yml** → Understand services, ports, and how the project is typically run.

## Step 3 — Adapt intelligently

### For AGENTS.md:
- If it exists, READ IT FIRST — understand the project's existing conventions
- If it's missing, create it with minimal content based on discovered stack
- NEVER rewrite an existing AGENTS.md — it's the project's source of truth

### For Dockerfile:
- If it exists and works for development, preserve it as-is
- If it needs changes for MultiTUI to work (e.g., missing Docker CLI, specific workdir), make those changes
- If creating new, use conventions matching the project's stack

### For docker-compose.yml:
- If it exists, preserve all existing services (postgres, redis, etc.)
- Add or modify the app service only if needed for MultiTUI
- If creating new, use the same base image and ports as existing Dockerfile

### For .gitignore:
- If it exists, append `agent/` if not already present
- Never remove existing entries
- If creating new, minimal coverage: agent/, language-specific artifacts

### For .dockerignore:
- If it exists, append `agent/` if not already present
- Never remove existing entries
- If creating new, minimal coverage: agent/

## Step 4 — Create MultiTUI framework structure

Create the `agent/` directory for MultiTUI:
```
agent/
├── AGENTS.md          # Copy/reference to project's AGENTS.md
└── (MultiTUI manages the rest)
```

## Step 5 — Verify

If you modified docker-compose.yml:
```bash
docker compose config --quiet && echo "Valid" || echo "Invalid"
```

## Summary

| File | Action |
|------|--------|
| AGENTS.md exists | Read it, preserve it, reference it from agent/ |
| Dockerfile exists | Preserve unless changes needed for MultiTUI |
| docker-compose.yml exists | Preserve existing services, add app if needed |
| .gitignore exists | Append `agent/` if missing |
| .dockerignore exists | Append `agent/` if missing |
| None exist | Create minimal new files |

Be adaptive. Make changes that make sense.
