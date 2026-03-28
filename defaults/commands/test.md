---
description: Run tests in Docker container
argument-hint: [optional: test file, pattern, or flags]
---

Run tests inside a Docker container using DooD.

## Your Task

Run tests for this project using Docker Compose. Auto-detect the test framework and run appropriate tests.

## Detection Steps

1. **Read from project manifest** (preferred):
   - package.json → read the "test" script from scripts
   - pyproject.toml → read [tool.pytest] configuration
   - go.mod → use `go test ./...`
   - Cargo.toml → use `cargo test`

2. **If test script found in manifest**, use it directly.

3. **Detect test framework** only if no manifest script:
   - JS/TS: Check for vitest.config.*, jest.config.*, mocha.opts
   - Python: Check for pytest.ini, conftest.py, pyproject.toml [tool.pytest]
   - Go: Check for *_test.go files
   - Rust: Check for src/*_test.rs files

4. **Build test command** (fallback):
   - vitest: `bun run vitest run` or `npm run test`
   - jest: `bun run test` or `npm test`
   - pytest: `uv run pytest`
   - go: `go test ./...`
   - rust: `cargo test`

5. **Apply any flags from arguments**:
   - --coverage → add coverage flag
   - --watch → run in watch mode
   - Any other argument → pass through to test runner

## Execution

```bash
docker compose run --rm <service> <test-command>
```

Capture and display all test output.

## Output

Report:
- Stack detected
- Test framework detected
- Service used
- Command executed
- Test results (passed/failed/skipped counts)
- Any failures with details
