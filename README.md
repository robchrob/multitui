# MultiTUI (mtui) — OpenCode Docker Runner

<p align="center">
  <a href="https://github.com/robchrob/multitui"><img src="https://img.shields.io/badge/Repo-GitHub-FFD700?style=for-the-badge" alt="Repository"></a>
  <a href="https://github.com/robchrob/multitui/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
</p>

Run [OpenCode](https://opencode.ai) in per-project Docker containers. Zero local deps — just Docker, bash, and git. Works with any language stack (Node, Python, Go, Rust, Ruby, PHP, Shell, C/C++). Ships with curated defaults: MCP servers, skills, commands, and a strict permission model — no third-party plugins.

| Feature | What it does |
|---------|-------------|
| **Any stack, one image** | Node, Python, Go, Rust, Ruby, PHP, Shell, C/C++—all via Docker exec |
| **Per-project containers** | `mtui start` spawns a long-lived named container per project |
| **DooD execution** | The agent uses Docker-outside-of-Docker for all code execution |
| **Baked defaults** | Image ships with opencode.json, commands, and skills — `docker run multitui opencode` works bare |
| **Config precedence** | Project-local config → `~/.multitui/defaults` → image-baked defaults |
| **MCP built-in** | memory, sequential-thinking, context7, exa, deepwiki, filesystem, a2a-search, playwright |
| **Skills & commands** | Reusable AI templates for Docker, versioning, debugging |
| **Magic versioning** | Narrative-first semver 2.0 with `plan.md` (design doc) + `tasks.md` (live tracker) + `changelog.md` |
| **Zero third-party plugins** | Only stock OpenCode + curated config — no plugin supply-chain |
| **Zero local deps** | Only Docker, bash, git needed—everything else in container |

---

## Quick Install
```bash
curl -fsSL https://raw.githubusercontent.com/robchrob/multitui/develop/mtui -o ./mtui
chmod +x ./mtui && ./mtui setup
```

**Requires**: Docker daemon, one of `OPENROUTER_API_KEY`, `ZAI_API_KEY` or `OPENCODEGO_API_KEY`. Optional: `EXA_API_KEY`.

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
```

Container persists. Detach with `Ctrl+C`, reattach with `mtui start`.

---

## CLI Reference

| Command | What |
|---------|------|
| `mtui setup` | Install binary, build Docker image, install global defaults + prompts |
| `mtui build [--no-cache]` | Rebuild image |
| `mtui init "<desc>"` | Scaffold new project with AI |
| `mtui bootstrap "<desc>"` | Configure existing project |
| `mtui start [--tty] [-p H:C]` | Run OpenCode container |
| `mtui clean` | Stop and remove container |
| `mtui ls` | List all `mtui-*` containers |
| `mtui status` | Show project health + active config source |

### Shell Completion (bash)
```bash
# Preview completion
source ./mtui_completion.bash

# Persist configuration
cp ./mtui_completion.bash /etc/bash_completion.d/mtui
```

---

## Configuration

### Environment Variables
| Variable | Default | Purpose |
|----------|---------|---------|
| `OPENROUTER_API_KEY` | *one required* | OpenRouter provider (free model fallbacks) |
| `ZAI_API_KEY` | *one required* | Z.AI Coding Plan provider (GLM-5.3, GLM-5-Turbo) |
| `OPENCODEGO_API_KEY` | *one required* | OpenCode Go provider |
| `MTUI_MODEL` | `opencode/deepseek-v4-flash-free` | OpenCode model |
| `MTUI_UPSTREAM` | `robchrob/multitui` | Source repo for install/build (fork for your own defaults) |
| `MTUI_UPSTREAM_BRANCH` | `develop` | Source branch for install/build |
| `EXA_API_KEY` | optional | Exa web search MCP |

### Config Precedence
OpenCode config is resolved in this order — first match wins:

1. **Project-local** — `./.multitui/opencode.json` (highest)
2. **Project-local** — `./opencode.json`
3. **Global** — `~/.multitui/defaults/opencode.json` (installed by `mtui setup`)
4. **Image-baked** — `/workspace/.opencode/opencode.json` (ships with the image)

Check which one is active with `mtui status`. Commands and skills resolve the same way: project `.multitui/commands|skills` → global `~/.multitui/defaults/` → image `/workspace/.opencode/`.

### Key Files
| File | Purpose |
|------|---------|
| `AGENTS.md` (project root) | Per-project stack & conventions (AI-generated) |
| `~/.multitui/defaults/opencode.json` | Global config: MCP, permissions, providers |
| `~/.multitui/defaults/commands/` | Reusable command templates |
| `~/.multitui/defaults/skills/*/SKILL.md` | Skill templates |
| `~/.multitui/prompts/init.md` | New project scaffolding prompt |
| `~/.multitui/prompts/bootstrap.md` | Existing project analysis prompt |

No plugins are shipped — the image contains only stock OpenCode plus curated config (providers, MCP servers, a strict permission model, skills, commands).

---

## How It Works

`mtui` is a single bash script. It builds one base image (`multitui`) that contains OpenCode, Docker + Compose CLIs, git, and the curated defaults. Each project gets its own named background container (`mtui-<project>`), with your project directory mounted in and the host Docker socket passed through:

```
host ── mtui (bash) ──> multitui container (opencode)
                              │  docker exec
                              └─> project runtime containers (DooD)
```

All code execution happens through **Docker-outside-of-Docker (DooD)**: the agent runs `docker` / `docker compose` against the host daemon, so project runtimes (Node, Python, etc.) are never installed into the base image.

### Security

Be aware of what this trade-off means:

- The agent has **full host Docker access** via `/var/run/docker.sock` — equivalent to root on the host. MultiTUI is an *automation tool*, not a sandbox.
- The container itself is disposable and per-project; nothing persists outside your project directory and the container filesystem.
- The permission model in `opencode.json` blocks dangerous patterns by default (`rm -rf /`, `git push --force`, reading `.env`, `DROP`/`TRUNCATE` SQL).
- Keys are passed by environment variable only — never written into the container or project.
- For stronger isolation (microVM per agent, private daemon), consider [Docker Sandboxes](https://www.docker.com/products/docker-sandboxes/) — MultiTUI is the zero-dependency Linux-first alternative, not a security boundary.

---

## Alternatives

| Tool | Model | Isolation | OpenCode | Linux-native |
|------|-------|-----------|----------|--------------|
| **MultiTUI** | self-hosted, free | Docker container + DooD | first-class | yes |
| Docker Sandboxes | Docker Desktop | microVM + private daemon | supported | no (macOS/Windows, Linux roadmap) |
| Claude Code sandboxing | Claude sub | native OS sandbox / devcontainer / VM | no | yes |
| devcontainers | any editor | Docker container | via config | yes |

MultiTUI's niche: **opencode-first, self-hosted, per-project containers on Linux with zero local dependencies.**

---

## Development
```bash
git clone git@github.com:robchrob/multitui.git
cd multitui
./mtui setup
./tests/run.sh
```

See `AGENTS_DEV.md` for contributor guidelines.

---

## License
MIT — see [LICENSE](LICENSE).