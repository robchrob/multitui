# MultiTUI — OpenCode Docker Environment
One image. Any stack (language/frameworks).
OpenCode generates your project's Dockerfile and uses DooD for all execution.

## Prerequisites
- Docker running on host
- `OPENROUTER_API_KEY` set in environment (get one at openrouter.ai)

## Quick Start

### One-Time Setup
```bash
# Clone and setup globally
git clone https://github.com/anomalyco/multitui.git multitui
cd multitui
mtui setup
```

### New Project
```bash
mkdir my-app && cd my-app && git init
mtui init "React 19 + Vite + Tailwind"
mtui start
```

### Existing Project
```bash
cd my-project
mtui bootstrap "monorepo with packages/"
mtui start
```

### Resume Existing Project
```bash
mtui start
```

## How It Works
```
┌───────────────────────────────────────────────────────────────┐
│ multitui container (OpenCode lives here)                     │
│  OpenCode — reads/writes files directly                      │
│  Docker CLI  — spawns project containers via DooD            │
│  minimal alpine runtime                                       │
│  Node.js is for OpenCode internals ONLY                     │
│                                                             │
│  To run project code:                                       │
│    docker compose up                                        │
│    docker compose run --rm app npm test                    │
│    docker run --rm -v $PROJECT_ROOT:/app -w /app \          │
│      node:22-alpine npm test                                │
└──────────────────┬────────────────────────────────────────────┘
                   │ host Docker socket (DooD)
┌──────────────────▼────────────────────────────────────────────┐
│ project container(s) (spawned by OpenCode)                    │
│  Built from YOUR Dockerfile at project root                 │
│  Have the actual runtimes (node, python, rust, etc.)        │
│  Ports bind to host (localhost:3000, etc.)                  │
│  Volume-mount: project files + named cache volumes          │
└─────────────────────────────────────────────────────────────┘
```

## mtui Commands

| Command | What |
|---------|------|
| `mtui setup` | Install/upgrade framework globally to ~/.multitui |
| `mtui build` | Build the multitui Docker image |
| `mtui init [stack]` | Scaffold new project, attach agent/, AI generates files |
| `mtui bootstrap [instr]` | Analyze existing codebase, configure MultiTUI |
| `mtui start [-p H:C]` | Start or resume OpenCode container |
| `mtui clean` | Remove container for this project |
| `mtui list` | List all MultiTUI containers on machine |
| `mtui status` | Show health of current project |

## Session Management
- **Ctrl+Z** inside OpenCode → detaches (container keeps running)
- **`mtui start`** → resumes existing container
- **`mtui clean`** → removes container (start fresh)

## What Gets Generated
`mtui init "stack"` and `mtui bootstrap` create:

| File | Purpose | Overwrites? |
|------|---------|-------------|
| `AGENTS.md` | Stack, commands, conventions | Yes |
| `Dockerfile` | Dev runtime for project | Only if missing |
| `docker-compose.yml` | Services + volume caching | Only if missing |
| `.opencode/skills/` | Skills from agent/ | Only if missing |
| `.opencode/commands/` | Commands from agent/ | Only if missing |

## Project Layout After Setup
```
my-project/
├── AGENTS.md              # Stack + commands (generated)
├── Dockerfile             # Dev runtime (generated)
├── docker-compose.yml     # Services + caching (generated)
├── .opencode/
│   ├── skills/            # Scaffolded from agent/
│   └── commands/          # Scaffolded from agent/
├── agent/                 # MultiTUI submodule (READ-ONLY)
│   ├── mtui               # CLI binary
│   ├── docker/Dockerfile
│   ├── defaults/
│   │   ├── skills/
│   │   ├── commands/
│   │   └── templates/
│   ├── config/opencode.json
│   └── README.md
└── [source code]
```

## Config Hierarchy

| Location | Scope | Purpose |
|----------|-------|---------|
| `~/.config/opencode/opencode.json` | Global | User preferences |
| `agent/config/opencode.json` | Global | Framework defaults (mounted into container) |
| `AGENTS.md` | Project | Stack, commands, conventions |

The container mounts `agent/config/opencode.json` as the base config, providing MCP servers (memory, context7, exa, github, deepwiki) and permissions.
