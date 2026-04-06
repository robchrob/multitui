# MultiTUI — OpenCode in Docker, any stack, zero local setup
<p align="center">
  <a href="https://github.com/robchrob/multitui"><img src="https://img.shields.io/badge/Repo-GitHub-FFD700?style=for-the-badge" alt="Repository"></a>
  <a href="https://github.com/robchrob/multitui/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
</p>

Run OpenCode in isolated Docker containers for any project—no local language installs, just Docker, bash, and git. Full DooD execution with per-project agent directories and background containers.

---

## Quick Install
```bash
curl -fsSL https://raw.githubusercontent.com/robchrob/multitui/develop/mtui -o ./mtui
chmod +x ./mtui && ./mtui setup
```
**Requires**: Docker daemon, `OPENROUTER_API_KEY` set. Optional: `EXA_API_KEY`.

---

## Quick Start
```bash
# New project
mkdir myapp && cd myapp
mtui init "Build a React + Vite todo app"
mtui start

# Existing project
cd existing-project
mtui bootstrap "Analyze stack and set up dev workflow"
mtui start

# Branch workflow (isolated features) when need for customization in agent/
mtui branch create    # creates develop-<project>
# then after work, commit
mtui update           # rebases onto latest develop
```

Container persists. Detach with Ctrl+C, reattach with `mtui start`.

---

## Features
| Feature | Benefit |
|---------|---------|
| **Any stack, one image** | Node, Python, Go, Rust—all via Docker exec |
| **Background containers** | `mtui start` spawns long-lived per-project container |
| **Skills & commands** | Reusable / extensible templates in `agent/defaults/` |
| **MCP built-in** | memory, sequential-thinking, context7; exa search, deepwiki |
| **Branch workflow** | `develop-<project>` with auto-rebase and conflict resolution |
| **Zero local deps** | Only Docker, bash, git needed—everything else in container |

---

## CLI Reference
| Command | Purpose |
|---------|---------|
| `mtui setup` | Install binary, build Docker image |
| `mtui build [--no-cache]` | Rebuild image |
| `mtui init "<desc>"` | Scaffold new project with AI |
| `mtui bootstrap "<desc>"` | Configure existing project |
| `mtui start [--tty] [-p H:C]` | Run OpenCode container |
| `mtui clean` | Stop and remove container |
| `mtui ls` | List all `mtui-*` containers |
| `mtui status` | Show project health |
| `mtui branch create` | Create/switch to feature branch |
| `mtui branch status` | Show branch divergence vs `develop` |
| `mtui update [--continue]` | Rebase branch onto `develop` |

---

## Configuration
### Environment Variables
| Variable | Default | Purpose |
|----------|---------|---------|
| `OPENROUTER_API_KEY` | *required* | OpenCode AI backend |
| `MTUI_REMOTE` | `git@github.com:robchrob/multitui.git` | Agent repo to clone (set to fork for branching) |
| `MTUI_BRANCH` | `develop` | Default agent branch |
| `MTUI_MODEL` | `openrouter/stepfun/step-3.5-flash:free` | OpenCode model |
| `EXA_API_KEY` | optional | Exa web search MCP |

### Project Files
| File | Purpose |
|------|---------|
| `.mtui-branch` | Tracks current project branch, when using custom configuration branch |
| `AGENTS.md` | Per-project stack & conventions for AI (location is agent/AGENTS.md in project context)|
| `agent/defaults/opencode.json` | OpenCode config & permissions |
| `agent/defaults/skills/*/SKILL.md` | Skill templates |
| `agent/defaults/commands/*.md` | Command templates |
| `agent/prompts/init.md` | New project process prompt |
| `agent/prompts/bootstrap.md` | Existing project process prompt |
| `docker/Dockerfile` | Runtime image (Alpine + OpenCode + Docker CLI) |

---

## The `agent/` Directory
The `agent/` directory is the **brain** of MultiTUI — a cloned repository that configures how OpenCode understands and works with your project. It's attached automatically by `mtui init` (new projects) or `mtui bootstrap` (existing projects).

### Structure
```
agent/
├── defaults/
│   ├── opencode.json          # OpenCode config: MCP servers, permissions, model
│   ├── commands/              # Reusable command templates (test, run, debug)
│   └── skills/                # SKILL.md files — specialized AI workflows
├── prompts/
│   ├── init.md                # Prompt for scaffolding new projects
│   └── bootstrap.md           # Prompt for analyzing existing projects
└── AGENTS.md                  # Execution environment docs for AI (DooD, MCP, layers)
```

### How It Works
1. **Clone** — `mtui init`/`bootstrap` clones the agent repo from `MTUI_REMOTE` (default: `robchrob/multitui`) at `MTUI_BRANCH`
2. **Configure** — `defaults/opencode.json` sets up MCP servers, tool permissions, and the AI model
3. **Specialize** — `skills/` provide domain-specific workflows (Docker debugging, versioning, etc.)
4. **Scaffold** — The AI reads `prompts/init.md` or `prompts/bootstrap.md` to generate your project's `AGENTS.md` (at project root) with stack-specific commands, conventions, and context7 IDs

### Two AGENTS.md Files
| File | What it is | Who writes it |
|------|-----------|---------------|
| `agent/AGENTS.md` | Execution environment — DooD layers, MCP servers, rules | You (framework author) |
| `AGENTS.md` (project root) | Per-project stack, commands, conventions | AI during init/bootstrap |

The project-level `AGENTS.md` tells the AI: *"Load `@agent/AGENTS.md` for how to execute things."*

### Customization
The agent directory is your workspace for extending AI behavior:
- Add new skills in `agent/defaults/skills/<name>/SKILL.md`
- Create command templates in `agent/defaults/commands/`
- Modify `opencode.json` to add MCP servers or change permissions
- Edit prompts to change how projects are initialized

Changes live on `develop-<project>` branches — use `mtui branch create` to isolate experiments.

---

## Branch Workflow
Isolate changes on `develop-<project>` branches:

```bash
mtui branch create   # creates and tracks remote
# make changes in agent/, commit
git commit -am "Feature work"
mtui update          # auto-rebase onto develop
```

Conflicts? Resolve inside `agent/`, then `mtui update --continue`. Branches auto-rebase on every `mtui start`.

---

## Development (for MultiTUI itself)
```bash
git clone git@github.com:robchrob/multitui.git
cd multitui
./mtui setup
./tests/e2e/test/run.sh   # full test suite
```

See `AGENTS_DEV.md` for contributor guidelines and test architecture.

---

## License
MIT — see [LICENSE](LICENSE).
