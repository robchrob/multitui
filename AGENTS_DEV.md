# MultiTUI — Development Instructions

DEVMODE=true

Extensively use deepwiki anomalyco/opencode and exa search before proceeding to ground yourself in valuable data.

## Project Structure
```
mtui                         ← single CLI script
docker/Dockerfile            ← runtime image (Alpine + OpenCode + Docker CLI)
defaults/
  opencode.json              ← MCP servers, permissions, model config
  commands/                  ← OpenCode command templates
  skills/                    ← SKILL.md files
prompts/
  init.md                    ← AI prompt for new project scaffolding
  bootstrap.md               ← AI prompt for existing project bootstrap
tests/e2e/
  test/                      ← test suites
    run.sh                   ← master runner (build gate + orchestration)
    mtui_*.sh                ← test runners
  lib/                       ← shared helpers
```

## Quick Start
```bash
# Run all tests
./tests/e2e/test/run.sh
```

## mtui CLI Commands
- `mtui setup` — clone framework to `~/.multitui`, symlink binary, build image
- `mtui build [--no-cache]` — build Docker image (checks OpenCode updates, auto-rebuilds if needed)
- `mtui init "<desc>"` — attach agent/, scaffold new project with prompt/init.md
- `mtui bootstrap "<desc>"` — attach agent/, analyze existing project with prompt/bootstrap.md
- `mtui start [--tty] [-p H:C]` — create/resume background container, exec OpenCode (_interactive_, DO NOT use in DEV_MODE)
- `mtui clean` — remove project container
- `mtui status` — report container state, agent status, file presence
- `mtui ls` — show all project containers

## Development Workflow

### Plan → Edit → Test Cycle
```bash
# 0. Research with exa search, context7 and deepwiki anomalyco/opencode, read files
# 1. Edit mtui script and/or defaults/prompts/other
# 2. Run and ADD relevant tests (for new feature / changes)
./tests/e2e/test/run.sh -f build      # after Dockerfile changes
./tests/e2e/test/run.sh -f container  # after container lifecycle changes
./tests/e2e/test/run.sh -f setup      # after install changes
./tests/e2e/test/run.sh -f init       # after init prompt changes
./tests/e2e/test/run.sh -f bootstrap  # after bootstrap prompt changes
./tests/e2e/test/run.sh -f opencode   # after image/tooling changes
# 3. Test runs based on Testing Hierarchy
```

### Testing Hierarchy
```bash
# Single test function (fastest feedback)
bash -c 'source tests/e2e/test/mtui_container.sh && test_status_no_container'

# Single suite
./tests/e2e/test/run.sh -f container

# Full suite
./tests/e2e/test/run.sh
```

### Test Suite Architecture
- **Build gate**: `run.sh` checks `docker images -q multitui` once before any suite. Builds only if missing. Individual suites never build.
- **Parallel AI**: init/bootstrap setup spawns Python + JS sessions concurrently (`&` + `wait`), cutting AI time in half
- **One AI call per stack**: `setup()` runs `mtui init`/`bootstrap` once; all assertions reuse `PY_DIR`/`JS_DIR`
- **Artifacts**: `teardown()` copies to `tests/e2e/output/<timestamp>_<suite>_<pass|fail>/` — always saved for debugging (read to analyze and adjust course)

### Critical: AGENTS.md Contamination Bug
Every `mtui init`/`bootstrap` call MUST run inside `(cd "$project_dir" && ...)` — never from the test script's CWD. Running from wrong directory generates AGENTS.md in the repo root, contaminating the project with wrong-stack content.

## Conventions
- Bash 4.3+ required (namerefs)
- Test functions return 0/1, never `exit` (except setup failures)
- Fixtures under `/tmp/mtui_test_$$`, cleaned in teardown
- No suite builds the image — that's `run.sh`'s job
- Container names: `mtui-<project-dir-lowercased>`
- Remote agent repo: `git@github.com:robchrob/multitui.git` branch `develop-detach`
