# MultiTUI E2E Tests

End-to-end test harness for MultiTUI. Tests validate the complete workflow: mtui CLI → Docker container → OpenCode → Project containers.

## Directory Structure

```
tests/e2e/
├── lib/
│   ├── docker.sh      # Docker helper functions
│   ├── mtui.sh        # mtui CLI wrapper
│   ├── opencode.sh    # OpenCode helpers
│   └── fixtures.sh    # Fixture generators
├── test/
│   ├── run.sh                    # Master test runner
│   ├── mtui_setup.sh             # Global setup tests
│   ├── mtui_build.sh             # Docker image build tests
│   ├── mtui_init.sh              # Project init tests
│   ├── mtui_bootstrap.sh         # Project bootstrap tests
│   ├── mtui_container.sh         # Container lifecycle tests
│   └── mtui_opencode.sh          # OpenCode flow tests
└── README.md
```

## Quick Start

```bash
# Run all tests
tests/e2e/test/run.sh

# Run specific test suite
tests/e2e/test/mtui_build.sh

# Run with verbose output
MTUI_TEST_VERBOSE=1 tests/e2e/test/run.sh
```

## Requirements

### Environment Variables
- `OPENROUTER_API_KEY` - Required for OpenCode tests (AI execution)
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

## Test Execution

Each test suite follows this pattern:
1. **setup()** - Create temp directory, build image if needed
2. **test_*** - Run test assertions
3. **teardown()** - Cleanup containers and directories

## Fixture Types

Tests generate ephemeral fixtures on-the-fly:
- **minimal-js**: bun + Vite + package.json
- **minimal-py**: uv + pytest + pyproject.toml

## Notes

- All tests are ephemeral - cleanup happens after each test
- Tests use temporary directories for isolation
- OpenCode execution tests require `OPENROUTER_API_KEY`
- Some tests may timeout without API key (expected)
