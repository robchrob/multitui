# MultiTUI — Docker-isolated AI dev agent, any stack, zero local deps
<p align="center">
  <a href="https://github.com/robchrob/multitui"><img src="https://img.shields.io/badge/Repo-GitHub-FFD700?style=for-the-badge" alt="Repository"></a>
  <a href="https://github.com/robchrob/multitui/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
</p>

Run OpenCode AI in per-project Docker containers. No local installs—just Docker, bash, and git. Ships with MCP servers, plugin ecosystem, skill templates, and an isolated branch workflow for customizing the agent itself.

---

## Quick Install
```bash
curl -fsSL https://raw.githubusercontent.com/robchrob/multitui/develop/mtui -o ./mtui
chmod +x ./mtui && ./mtui setup
```

**Requires**: Docker daemon, `OPENROUTER_API_KEY`. Optional: `EXA_API_KEY`.

---

## Features
| Feature | What it does |
|---------|-------------|
| **Any stack, one image** | Node, Python, Go, Rust—all via Docker exec |
| **Background containers** | `mtui start` spawns long-lived per-project container |
| **Plugin ecosystem** | Quota tracking, rate-limit retry, and more via OpenCode plugins |
| **MCP built-in** | memory, sequential-thinking, context7, exa, deepwiki, filesystem, git, and more |
| **Skills & commands** | Reusable AI templates in `agent/defaults/` for Docker, versioning, debugging |
| **Magic versioning** | Session-aware semver 2.0 with `plan.md`, `tasks.md`, `changelog.md` workflow |
| **Branch workflow** | `develop-<project>` with auto-rebase for agent customization |
| **Zero local deps** | Only Docker, bash, git needed—everything else in container |

---

## Getting Started
```bash
# New project
mkdir myapp && cd myapp
mtui init "Build a React + Vite todo app"
mtui start

# Existing project
cd existing-project
mtui bootstrap "Analyze stack and set up dev workflow"
mtui start

# Branch workflow (isolate agent changes)
mtui branch create    # creates develop-<project>
mtui update           # rebases onto latest develop
```

Container persists. Detach with `Ctrl+C`, reattach with `mtui start`.

---

## CLI Reference
| Command | What |
|---------|------|
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
| `MTUI_REMOTE` | `git@github.com:robchrob/multitui.git` | Agent repo (set to fork for branching) |
| `MTUI_BRANCH` | `develop` | Default agent branch |
| `MTUI_MODEL` | `openrouter/stepfun/step-3.5-flash:free` | OpenCode model |
| `EXA_API_KEY` | optional | Exa web search MCP |

### Key Files
| File | Purpose |
|------|---------|
| `.mtui-branch` | Tracks current project branch |
| `AGENTS.md` (project root) | Per-project stack & conventions (AI-generated) |
| `agent/defaults/opencode.json` | OpenCode config: MCP, plugins, permissions |
| `agent/defaults/skills/*/SKILL.md` | Skill templates |
| `agent/prompts/init.md` | New project scaffolding prompt |
| `agent/prompts/bootstrap.md` | Existing project analysis prompt |

### Plugins
| Plugin | Purpose |
|--------|---------|
| `@slkiser/opencode-quota` | Token/budget tracking for AI sessions |
| `@bdliyq/opencode-rate-limit-retry` | Automatic retry on API rate limits |

---

## The `agent/` Directory
The `agent/` directory configures how OpenCode understands your project. Cloned automatically by `mtui init` / `mtui bootstrap`.

```
agent/
├── defaults/
│   ├── opencode.json          # MCP servers, plugins, permissions, model
│   ├── commands/              # Reusable command templates
│   └── skills/                # SKILL.md files — domain-specific AI workflows
├── prompts/
│   ├── init.md                # New project scaffolding
│   └── bootstrap.md           # Existing project analysis
└── AGENTS.md                  # Execution environment docs (DooD, MCP, rules)
```

### Two AGENTS.md Files
| File | What | Who writes |
|------|------|------------|
| `agent/AGENTS.md` | Execution environment — DooD layers, MCP, rules | Framework author |
| `AGENTS.md` (project root) | Per-project stack, commands, conventions | AI during init/bootstrap |

### Customization
- Add skills: `agent/defaults/skills/<name>/SKILL.md`
- Add commands: `agent/defaults/commands/`
- Edit config: `agent/defaults/opencode.json`
- Changes live on `develop-<project>` branches via `mtui branch create`

---

## Branch Workflow
```bash
mtui branch create   # creates and tracks remote
# make changes in agent/, commit
git commit -am "Feature work"
mtui update          # auto-rebase onto develop
```

Conflicts? Resolve inside `agent/`, then `mtui update --continue`.

---

## Development
```bash
git clone git@github.com:robchrob/multitui.git
cd multitui
./mtui setup
./tests/e2e/test/run.sh
```

See `AGENTS_DEV.md` for contributor guidelines.

---

## License
MIT — see [LICENSE](LICENSE).
