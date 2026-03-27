# MultiTUI — OpenCode Docker Environment
One image. Any stack (language/frameworks).
OpenCode generates your project's Dockerfile and uses DooD for all execution.

## Prerequisites
- Docker running on host
- `ANTHROPIC_API_KEY` set in environment

## One-Time Setup
```bash
# Clone multitui
git clone https://github.com/anomalyco/multitui.git ~/tools/multitui

# Add to ~/.bashrc
cat >> ~/.bashrc << 'EOF'
export ANTHROPIC_API_KEY="sk-ant-..."
export GITHUB_TOKEN="ghp_..."   # optional
source ~/tools/multitui/.shell-functions.sh
EOF
source ~/.bashrc

# Build the image (once)
_build
```

## New Project
```bash
mkdir my-app && cd my-app && git init

# Add multitui as submodule at agent/
_attach

# Option A: tell it your stack — OpenCode generates Dockerfile + AGENTS.md + compose
_init "React 19 + Vite + Tailwind 4, Python 3.14 + FastAPI backend"

# Option B: blank scaffold — describe stack to OpenCode in first message
_init

# Start OpenCode
_start
```

## Existing Project (no submodule yet)
```bash
cd my-project

# Add multitui as submodule at agent/
_attach

# OpenCode reads your code, generates AGENTS.md + Dockerfile if missing
_bootstrap

# Start OpenCode
_start
```

## Cloned Project (already has agent/ submodule)
```bash
git clone --recurse-submodules git@github.com:you/project.git
cd project
source agent/.shell-functions.sh
_start
```

## How It Works
```
┌───────────────────────────────────────────────────────────────┐
│ multitui container (OpenCode lives here)                     │
│  OpenCode — reads/writes files directly                      │
│  Docker CLI  — spawns project containers via DooD            │
│  minimal alpine runtime                                       │
│  Node.js is for OpenCode internals ONLY                      │
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
└───────────────────────────────────────────────────────────────┘
```

## What Gets Generated
`_init "stack"` and `_bootstrap` create:

| File | Purpose | Overwrites? |
|------|---------|-------------|
| `AGENTS.md` | Stack, commands, conventions | Yes (that's the point) |
| `Dockerfile` | Dev runtime for project | Only if missing |
| `docker-compose.yml` | Services + volume caching | Only if missing |
| `opencode.json` | Config | Only if missing |
| `.opencode/skills/` | (skills) | Only if missing |
| `.opencode/commands/` | (custom commands) | Only if missing |

## Project Layout After Setup
```
my-project/
├── AGENTS.md              # Stack + commands (generated)
├── Dockerfile             # Dev runtime (generated)
├── docker-compose.yml     # Services + caching (generated)
├── opencode.json          # Config
├── .opencode/
│   ├── agents/
│   ├── commands/          # (custom commands)
│   ├── skills/            # (skills)
├── agent/                 # MultiTUI submodule (READ-ONLY)
│   ├── .shell-functions.sh
│   ├── docker/Dockerfile
│   ├── defaults/
│   ├── AGENTS.md
│   └── README.md
└── [source code]
```

## Commands
| Command | What |
|---------|------|
| `_build` | Build multitui image (once) |
| `_start [auto\|tty] [-p H:C]` | Start/resume OpenCode (Ctrl+Z to detach) |
| `_attach [remote]` | Add agent/ submodule to current project |
| `_init ["stack desc"]` | Scaffold new project, optional AI generation |
| `_bootstrap` | Analyze existing project with AI |
| `_clean` | Remove multitui container |

## Session Management
- **Ctrl+Z** inside OpenCode → detaches (container keeps running)
- **`_start`** → resumes existing container
- **`_clean`** → removes container (start fresh)

## Slash Commands (in OpenCode)
| Command | What |
|---------|------|
| `/clear` | Clear context between tasks |

## Config Hierarchy
| File | Scope | Purpose |
|------|-------|---------|
| `agent/config/opencode.json` | Global | Single source of truth for all config |
| `opencode.json` | Project | Config (inherited from global if missing) |
| `AGENTS.md` | Project | Stack, commands, conventions |

**Single Source of Truth**: `agent/config/opencode.json` contains the complete configuration. Project-level settings are automatically inherited from this file, ensuring no duplication and consistent configuration across all projects.
