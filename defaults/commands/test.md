---
description: Run tests in Docker container
argument-hint: [optional: test file, pattern, or flags]
---

Run tests inside a Docker container using DooD.

## Usage

```
/test                    # Run all tests (from AGENTS.md or auto-detected)
/test src/foo.test.ts   # Run specific file
/test --coverage       # Run with coverage
/test --watch         # Run in watch mode
/test pytest -x       # Run with custom flags
```

## Step 0: Check AGENTS.md First

Before auto-detecting, ALWAYS check if AGENTS.md exists and has DooD Commands:

```bash
# Check if AGENTS.md exists
if [ -f "AGENTS.md" ]; then
  # Extract DooD Commands section
  awk '/^## DooD Commands/,/^##/' AGENTS.md | grep -E 'test|pytest' | head -10
fi
```

If AGENTS.md has a `## DooD Commands` section with a test command, use that directly.
Skip auto-detection if AGENTS.md already specifies the test command.

## Step 1: Auto-Detect Stack

Follow MultiTUI conventions: bun for JS/TS, uv for Python.

```bash
# JavaScript/TypeScript
if [ -f "bun.lock" ]; then
  echo "bun"
elif [ -f "pnpm-lock.yaml" ]; then
  echo "pnpm"
elif [ -f "yarn.lock" ]; then
  echo "yarn"
elif [ -f "package-lock.json" ]; then
  echo "npm"
# Python (uv is primary)
elif [ -f "uv.lock" ]; then
  echo "uv"
elif [ -f "pyproject.toml" ]; then
  echo "uv"
elif [ -f "poetry.lock" ]; then
  echo "poetry"
elif [ -f "Pipfile.lock" ]; then
  echo "pipenv"
# Other languages
elif [ -f "go.mod" ]; then
  echo "go"
elif [ -f "Cargo.toml" ]; then
  echo "rust"
else
  echo "unknown"
fi
```

## Step 2: Auto-Detect Test Framework

### JavaScript/TypeScript

Check for test framework in this priority order:

1. **Vitest** (preferred for bun)
2. **Jest** 
3. **Node test**

```bash
# Check package.json scripts first
if [ -f "package.json" ]; then
  node -e "try {
    const pkg = require('./package.json');
    const scripts = pkg.scripts || {};
    if (scripts.vitest) console.log('vitest');
    else if (scripts.test) console.log('jest/node');
    else console.log('unknown');
  } catch(e) { console.log('unknown'); }"
fi

# Also check for config files
if [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ] || [ -f "vitest.config.mjs" ]; then
  echo "vitest"
elif [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
  echo "jest"
fi
```

### Python

```bash
# Check for pytest indicators
if [ -f "pytest.ini" ]; then
  echo "pytest"
elif grep -q "\[tool.pytest\]" pyproject.toml 2>/dev/null; then
  echo "pytest"
elif [ -f "conftest.py" ]; then
  echo "pytest"
elif [ -f "manage.py" ]; then
  echo "django"
else
  echo "unknown"
fi
```

### Go

```bash
# Check for test files
if ls *_test.go 2>/dev/null | head -1 | grep -q "_test.go"; then
  echo "go"
fi
```

### Rust

```bash
# Check for test files
if ls src/*_test.rs 2>/dev/null | head -1 | grep -q "_test.rs"; then
  echo "rust"
fi
```

## Step 3: Build Test Command

### JavaScript/TypeScript

For bun, ALWAYS use `bun run`:
- vitest: `bun run vitest run`
- jest/node: `bun run test`

For other package managers (if AGENTS.md specifies):
- pnpm: `pnpm test` 
- yarn: `yarn test`
- npm: `npm test`

```bash
# Parse arguments for flags
FLAGS=""
TARGET=""

if echo "$ARGUMENTS" | grep -q "coverage"; then
  FLAGS="--coverage"
fi
if echo "$ARGUMENTS" | grep -q "watch"; then
  FLAGS="--watch"
fi

# Extract file/pattern if provided (not a flag)
TARGET=$(echo "$ARGUMENTS" | sed 's/--coverage//g; s/--watch//g' | xargs)

# Build command based on framework
case "$FRAMEWORK" in
  vitest)
    if [ -n "$FLAGS" ]; then
      TEST_CMD="bun run vitest run $FLAGS $TARGET"
    elif [ -n "$TARGET" ]; then
      TEST_CMD="bun run vitest run $TARGET"
    else
      TEST_CMD="bun run vitest run"
    fi
    ;;
  jest)
    if [ -n "$FLAGS" ]; then
      TEST_CMD="npm test -- $FLAGS $TARGET"
    elif [ -n "$TARGET" ]; then
      TEST_CMD="npm test -- $TARGET"
    else
      TEST_CMD="npm test"
    fi
    ;;
  node)
    TEST_CMD="npm test"
    ;;
esac
```

### Python

For uv, ALWAYS use `uv run`:
- pytest: `uv run pytest`
- django: `uv run pytest` or `uv run manage.py test`

```bash
# Parse arguments
FLAGS=""
TARGET=""

if echo "$ARGUMENTS" | grep -q "coverage"; then
  FLAGS="--cov"
fi
if echo "$ARGUMENTS" | grep -q "watch"; then
  FLAGS="-x"  # Stop on first failure instead
fi

TARGET=$(echo "$ARGUMENTS" | sed 's/--coverage//g; s/--watch//g' | xargs)

case "$FRAMEWORK" in
  pytest)
    if [ -n "$FLAGS" ]; then
      TEST_CMD="uv run pytest $FLAGS $TARGET"
    elif [ -n "$TARGET" ]; then
      TEST_CMD="uv run pytest $TARGET"
    else
      TEST_CMD="uv run pytest ."
    fi
    ;;
  django)
    if [ -n "$TARGET" ]; then
      TEST_CMD="uv run manage.py test $TARGET"
    else
      TEST_CMD="uv run manage.py test"
    fi
    ;;
esac
```

### Go

```bash
if [ -n "$ARGUMENTS" ]; then
  TEST_CMD="go test $ARGUMENTS"
else
  TEST_CMD="go test ./..."
fi
```

### Rust

```bash
if [ -n "$ARGUMENTS" ]; then
  TEST_CMD="cargo test $ARGUMENTS"
else
  TEST_CMD="cargo test"
fi
```

## Step 4: Execute in Container

```bash
SERVICE=$(docker compose config --services 2>/dev/null | head -1 || echo "app")
docker compose run --rm $SERVICE $TEST_CMD
```

## Step 5: Capture and Display Results

Show test output with:
- Test summary (passed/failed/skipped)
- Failure details if any
- Coverage report if requested
- Exit code

## Output Format

```markdown
## Running Tests

**Source:** [AGENTS.md | auto-detected]
**Stack:** [bun/pnpm/yarn/npm/uv/poetry/go/rust]
**Framework:** [vitest/jest/pytest/go/rust]
**Service:** [service-name]
**Command:** [full command]

---

[Test output...]

---

**Result:** ✅ All tests passed | ❌ X tests failed
```

## MultiTUI Runtime Conventions (Reference)

- **JavaScript/TypeScript**: Use `bun run` for all commands
- **Python**: Use `uv run` for all commands
- Test framework: vitest for bun, pytest for Python

## Notes

- Exit code reflects test result (0 = success)
- Show failure diffs for failed tests
- Show coverage report if --coverage flag used
- Prioritize AGENTS.md over auto-detection
