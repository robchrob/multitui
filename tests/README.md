# MultiTUI E2E Tests

End-to-end test harness for MultiTUI. Tests validate the complete workflow: mtui CLI → Docker container → OpenCode → Project containers.

## Directory Structure

```
tests/
├── lib/
│   ├── docker.sh      # Docker helper functions
│   ├── mtui.sh        # mtui CLI wrapper
│   ├── opencode.sh    # OpenCode helpers
│   ├── fixtures.sh    # Fixture generators
│   └── test_helpers.sh # Test utilities
├── run.sh             # Master test runner
├── local.sh           # Smoke tests (no API key required)
├── mtui_setup.sh      # Global setup tests
├── mtui_build.sh      # Docker image build tests
├── mtui_init.sh       # Project init tests (requires OPENROUTER_API_KEY)
├── mtui_bootstrap.sh # Project bootstrap tests (requires OPENROUTER_API_KEY)
├── mtui_container.sh # Container lifecycle tests
├── mtui_config.sh    # Config precedence tests (project > global > image-baked)
├── mtui_opencode.sh  # OpenCode flow tests
└── README.md
```

## Quick Start

```bash
# Run all tests
./tests/run.sh

# Run specific test suite
./tests/run.sh -f build

# Run smoke tests (no API key needed)
./tests/local.sh

# Run with verbose output
MTUI_TEST_VERBOSE=1 ./tests/run.sh
```

## Requirements

### Environment Variables
- `OPENROUTER_API_KEY` - Required for init/bootstrap/opencode tests (AI execution)
- `GITHUB_TOKEN` - Optional, for GitHub MCP
- `EXA_API_KEY` - Optional, for Exa MCP

### System Requirements
- Docker daemon running
- Bash 4.3+
- Internet access for Docker pulls

## Test Suites

| Test File | Coverage |
|-----------|----------|
| `mtui_setup.sh` | Global installation to ~/.multitui |
| `mtui_build.sh` | Docker image building |
| `mtui_init.sh` | Project scaffolding (JS + Python) |
| `mtui_bootstrap.sh` | Project analysis |
| `mtui_container.sh` | Container lifecycle (start, stop, status) |
| `mtui_opencode.sh` | OpenCode execution inside container |
| `mtui_config.sh` | Config precedence (project > global > image-baked) |

## Test Execution

Each test suite follows this pattern:
1. **setup()** - Create temp directory, build image if needed
2. **test_*** - Run test assertions
3. **teardown()** - Cleanup containers and directories

### Testing Hierarchy

```bash
# Single test function — only works for suites that create their own fixtures inline
# (mtui_container, mtui_build, mtui_opencode, mtui_setup, mtui_config)
bash -c 'source tests/mtui_container.sh && test_status_no_container'

# Single suite (always safe — runs setup() + all tests + teardown)
./tests/run.sh -f container

# Full suite
./tests/run.sh
```

> **init/bootstrap tests cannot be run as single functions.** They share expensive AI setup across all assertions — call the suite directly: `./tests/run.sh -f init`

## Fixture Types

Tests generate ephemeral fixtures on-the-fly:
- **minimal-js**: bun + Vite + package.json
- **minimal-py**: uv + pytest + pyproject.toml

## Notes

- All tests are ephemeral - cleanup happens after each test
- Tests use temporary directories for isolation
- OpenCode execution tests require `OPENROUTER_API_KEY`
- Some tests may timeout without API key (expected)