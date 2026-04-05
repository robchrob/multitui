# MultiTUI — Development Guide

## Project Structure
```
mtui                    ← single CLI script (Bash 4.3+), all commands
docker/Dockerfile       ← dev runtime image (OpenCode + Docker CLI + git)
agent/                  ← cloned agent framework (READ-ONLY)
defaults/               ← opencode config: opencode.json, mcps, commands, skills
prompts/                ← prompt templates for init/bootstrap AI cmds
tests/e2e/
  test/                 ← test suites + master runner
    run.sh              ← master runner — owns image build gate
  lib/                  ← shared helpers (test_helpers, docker, fixtures)
  output/               ← test artifacts — always saved, git-ignored
```

## mtui CLI Commands
- `mtui setup` — clone framework to `~/.multitui`, symlink to `~/.local/bin/mtui`
- `mtui build` — build Docker image (idempotent, skips if up-to-date)
- `mtui init "<description>"` — new project: generates AGENTS.md, Dockerfile, docker-compose.yml, attaches agent/
- `mtui bootstrap` — existing project: analyzes stack, generates AGENTS.md, attaches agent/
- `mtui start` — create background container, exec OpenCode
- `mtui status` — report container state
- `mtui clean` — remove project container
- `mtui list` — show all project containers

## Running Tests
```bash
./tests/e2e/test/run.sh                        # all no-key suites
./tests/e2e/test/run.sh -f container           # single suite
OPENROUTER_API_KEY=... ./tests/e2e/test/run.sh # all suites including AI tests
```

## Image Build Gate
`run.sh` checks `docker images -q multitui` once before any suite runs. If missing, `mtui build` runs exactly once. Individual suites never build — they assume the image exists. The `mtui_build.sh` suite calls `mtui build` again intentionally to assert idempotency (it's a no-op when image is current).

## Test Design Principles
- **Parallel AI**: init/bootstrap setup spawns Python and JS sessions concurrently (`&` + `wait`), cutting AI time in half.
- **One AI call per stack**: `setup()` runs `mtui init`/`bootstrap` once per stack; all assertions reuse the same `PY_DIR`/`JS_DIR`.
- **Artifact output**: `teardown()` copies project dirs to `tests/e2e/output/<timestamp>_<suite>_<pass|fail>/` for post-mortem inspection. Always saved, even on failure.
- **No AGENTS.md contamination**: every `mtui init`/`bootstrap` call runs inside `(cd "$project_dir" && ...)` so it operates on the fixture directory, never the repo root.
- **Container tests use real mtui commands**: `start`/`status`/`clean`/`list` — not raw `docker run`/`docker exec` testing Docker basics.
- **`--help` assertion uses exit code**: grep on ANSI-colored output is unreliable; just check `$?`.

## Conventions
- Bash 4.3+ required (namerefs)
- `set -Eeuo pipefail` in all scripts
- Test functions return 0/1, never `exit` (except setup failures)
- Fixtures created under `/tmp/mtui_test_$$`, cleaned up in teardown
- No test suite should build the image — that's `run.sh`'s job
