# MultiTUI — OpenCode in Docker, any stack, zero local setup
<p align="center">
  <a href="https://github.com/robchrob/multitui"><img src="https://img.shields.io/badge/Repo-GitHub-FFD700?style=for-the-badge" alt="Repository"></a>
  <a href="https://github.com/robchrob/multitui/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
</p>

Modular sandboxed OpenCode environments with full Docker access — code in any language without installing anything locally (aside of docker/bash/git/TODO all dependencies).
Spawn configurable and isolated OpenCode instances per-project.


| Feature | Benefit |
|---------|---------|
| **Any stack, one image** | Node, Python, Go, Rust — all via DooD |
| **Background containers** | `mtui start` from any terminal |
| **Skills & commands** | Reusable prompt templates from `agent/` |
| **MCP built-in** | memory, context7, exa, deepwiki ready |
| **Branch workflow** | Isolated feature branches with automated rebase |
| **Simple install** | Single curl, binary in `~/.local/bin` |

---

## Quick Install / Quick Start
```bash
## INSTALL
curl -fsSL https://raw.githubusercontent.com/robchrob/multitui/develop/mtui -o ./mtui
chmod +x ./mtui
./mtui setup
mtui --help

## USAGE
# init (kickstart new project)
mkdir project && cd project
mtui init "TODO init_msg"
# files generated in PWD by ./agent/prompt/init.md flow
mtui start # work on the project inside docker (all config/setup in agent/ dir)

# boostrap (connect workflow into existing project)
cd existing_project
mtui bootstrap "TODO bootstrap_msg"
# project agentic workflow ready, based on ./agent/prompt/bootstrap.md instructions
mtui start # work on the project
```
*REQUIRES*: docker, `OPENROUTER_API_KEY` environment variable set.
*OPTIONAL*: TODO api keys used in our setup (read from mtui)

## Getting Started
### New project
```bash
mkdir my-app && cd my-app && git init
mtui init "React + Vite"
mtui start
```

### Existing project
```bash
cd my-project
mtui bootstrap "analyze this codebase"
mtui start
```

### Work / Resume
```bash
mtui start
```

---

## CLI Reference
| Command | What |
|---------|------|
| `mtui setup` | Install binary, build Docker image |
| `mtui build [--no-cache]` | Build/rebuild Docker image |
| `mtui init "<desc>"` | Scaffold new project with AI |
| `mtui bootstrap "<desc>"` | Analyze existing project |
| `mtui start [--tty] [-p H:C]` | Run OpenCode container |
| `mtui clean` | Remove project container |
| `mtui ls` | List all containers |
| `mtui status` | Show project health |
| `mtui branch create` | Create project branch (develop-<name>) |
| `mtui branch status` | Show branch position vs develop |
| `mtui update [--continue]` | Rebase branch onto latest develop |

---

## Branch Workflow
Isolate changes on `develop-<project>` branches:

```bash
# Create and switch to feature branch
mtui branch create

# Make changes, then rebase onto latest develop
mtui update

# Check status
mtui branch status
```

Branches auto-rebase onto `develop` when running `mtui attach`/`start`. 
CONFLICT: Fix inside `agent/` repo, then `mtui update --continue`.

---

## Config
| File | Purpose |
|------|---------|
| `AGENTS.md` | Per-project environment, stack, commands |
| `defaults/opencode.json` | OpenCode configuration |
| `defaults/skills/*` | Reusable SKILL.md templates |
| `defaults/commands/*` | Command templates |
| `prompts/init.md` | New project AI prompt |
| `prompts/bootstrap.md` | Existing project AI prompt |
| `docker/Dockerfile` | Runtime image (Alpine + OpenCode + Docker CLI) |

---

## Development Workflow
```bash
git clone git@github.com:robchrob/multitui.git
cd multitui
./mtui setup # setup from local state, no push required
./tests/e2e/test/run.sh # run full test suite (real token usage on init / bootstrap!)
```
See `AGENTS_DEV.md` for full development instructions and test hierarchy.

---

## License
MIT — see [LICENSE](LICENSE).
