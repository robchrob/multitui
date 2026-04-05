# MultiTUI — OpenCode in Docker, any stack
<p align="center">
  <a href="https://github.com/robchrob/multitui"><img src="https://img.shields.io/badge/Repo-GitHub-FFD700?style=for-the-badge" alt="Repository"></a>
  <a href="https://github.com/robchrob/multitui/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License: MIT"></a>
</p>

One Docker image runs OpenCode with full Docker access — spawn containers for any language or framework without installing anything locally.

| Feature | What It Means |
|---------|---------------|
| **Single image, any stack** | Node, Python, Go, Rust — OpenCode runs them all via DooD |
| **Background containers** | Start once, `mtui start` from multiple terminals |
| **Skills & commands** | Reusable prompt templates loaded from agent/ |
| **MCP built-in** | memory, context7, exa, github, deepwiki ready to go |

---

## Quick Install
```bash
git clone git@github.com:robchrob/multitui.git multitui
cd multitui
mtui setup
```

Requires: Docker, `OPENROUTER_API_KEY` in environment.

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

### Resume
```bash
mtui start
```

---

## CLI Reference
| Command | What |
|---------|------|
| `mtui setup` | Install globally to ~/.multitui |
| `mtui build [--no-cache]` | Build Docker image |
| `mtui init [instruction]` | Scaffold new project |
| `mtui bootstrap [instruction]` | Analyze existing project |
| `mtui start [--tty] [-p H:C]` | Run OpenCode container |
| `mtui clean` | Remove container |
| `mtui ls` | List active containers |
| `mtui status` | Show project health |

---

## Config
| Location | Scope | Purpose |
|----------|-------|---------|
| `AGENTS.md` | Per-project | Environment description, stack, commands |
| `defaults/opencode.json` | per-project | OpenCode configuration |
| `docker/Dockerfile` | per-project | OpenCode environment |

---

## License
MIT — see [LICENSE](LICENSE).
