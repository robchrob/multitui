# MultiTUI E2E Test Plan

## Overview

This document describes the end-to-end test harness for MultiTUI. The tests validate that core functionality works correctly by testing the complete workflow: mtui CLI → Docker container → OpenCode → Project containers.

## Technology Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Test Framework | **BATS-core** | POSIX-compliant, popular, well-documented |
| Test Location | `tests/e2e/` in this repo | Self-contained |
| mtui Binary | Local `./mtui` | Tests use working directory version |
| Docker | Real Docker (DooD) | Full workflow validation |
| AI API | Real OPENROUTER_API_KEY | Tests actual OpenCode behavior |

## Test Architecture

### Directory Structure
```
tests/
└── e2e/
    ├── lib/
    │   ├── docker.sh      # Docker helper functions
    │   ├── mtui.sh        # mtui CLI wrapper
    │   ├── opencode.sh    # OpenCode helpers
    │   └── fixtures.sh    # Fixture generators (ephemeral)
    ├── test/
    │   ├── run.sh                    # Master test runner
    │   ├── mtui_setup.sh             # mtui setup tests
    │   ├── mtui_build.sh             # Docker image build tests
    │   ├── mtui_init.sh              # Project init tests (JS/Python)
    │   ├── mtui_bootstrap.sh         # Project bootstrap tests
    │   ├── mtui_container.sh         # Container lifecycle tests
    │   └── mtui_opencode.sh          # OpenCode flow tests
    └── README.md
```

### Test Execution Flow
```
run.sh (master runner)
    │
    ├─► Verify prerequisites (Docker, env vars)
    │
    ├─► For each test/*.sh:
    │       │
    │       ├─► setup(): Create temp git repo + generate fixture
    │       │
    │       ├─► Run test assertions
    │       │
    │       └─► teardown(): Cleanup containers/dirs
    │
    └─► Report: PASS/FAIL per test
```

## Test Categories

### 1. mtui_setup.sh
Tests global mtui installation.

| Test | Validates |
|------|-----------|
| setup_install | `mtui setup` installs to ~/.multitui |
| setup_links | Binary linked to ~/.local/bin/mtui |

### 2. mtui_build.sh
Tests Docker image building.

| Test | Validates |
|------|-----------|
| build_image | `mtui build` builds multitui image |
| build_cached | Subsequent builds use cache |
| build_no_cache | `--no-cache` forces rebuild |

### 3. mtui_init.sh
Tests project scaffolding with `mtui init`.

| Test | Validates |
|------|-----------|
| init_js_project | Generates valid AGENTS.md, Dockerfile, docker-compose.yml for JS |
| init_py_project | Generates valid files for Python project |
| init_agents_md | AGENTS.md has required sections |
| init_dockerfile | Dockerfile is valid |
| init_compose | docker-compose.yml is valid |

### 4. mtui_bootstrap.sh
Tests project analysis with `mtui bootstrap`.

| Test | Validates |
|------|-----------|
| bootstrap_js | Analyzes existing JS project |
| bootstrap_py | Analyzes existing Python project |
| bootstrap_agents_md | AGENTS.md generated correctly |

### 5. mtui_container.sh
Tests container lifecycle management.

| Test | Validates |
|------|-----------|
| container_start | `mtui start` creates/runs container |
| container_status | `mtui status` shows correct state |
| container_list | `mtui list` shows containers |
| container_stop | `mtui clean` stops/removes container |

### 6. mtui_opencode.sh
Tests OpenCode execution inside container.

| Test | Validates |
|------|-----------|
| opencode_starts | OpenCode launches in container |
| opencode_tools | Read/write/edit/grep tools available |
| opencode_mcp | MCP servers initialize |

## Fixtures (Ephemeral, Generated)

### minimal-js
- **Package Manager**: bun
- **Files**: package.json, index.js
- **Runtime**: Node.js with bun

### minimal-py
- **Package Manager**: uv
- **Files**: pyproject.toml, main.py
- **Runtime**: Python 3.13 with uv

## Test Isolation

Each test:
1. Creates a **temporary directory** with a fresh git repo
2. Generates **ephemeral fixture** (minimal-js or minimal-py)
3. Runs **mtui command** being tested
4. Makes **assertions** on output/files
5. **Cleans up** all containers and directories

## Requirements

### Environment Variables
- `OPENROUTER_API_KEY` - Required for OpenCode tests
- `GITHUB_TOKEN` - Optional, for GitHub MCP
- `EXA_API_KEY` - Optional, for Exa MCP

### System Requirements
- Docker daemon running
- Bash 4.3+
- Internet access (for apt/npm installs)

## Running Tests

```bash
# Run all tests
tests/e2e/test/run.sh

# Run specific test suite
tests/e2e/test/mtui_build.sh

# Run with verbose output
MTUI_TEST_VERBOSE=1 tests/e2e/test/run.sh
```

## Success Criteria

- All tests pass consistently
- Tests run in < 10 minutes
- No manual intervention required
- Full cleanup after each test
- Deterministic results (no flakiness)

## Known Limitations

1. **AI API Dependency**: Tests require real OpenRouter API key
2. **Network Dependency**: Tests need internet for Docker pulls
3. **Time**: Full suite may take 10-15 minutes
4. **Port Conflicts**: Tests use ephemeral ports

## Future Enhancements

- Parallel test execution
- Test result caching
- CI/CD integration (GitHub Actions)
- Mock AI responses for faster tests
- Coverage reporting
