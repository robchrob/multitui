---
description: Run tests in Docker container (auto-detects test framework)
argument-hint: [optional: test file, pattern, or flags]
---

Run tests inside a Docker container using DooD. Auto-detects test framework.

## Usage

```
/test                 # Run all tests
/test src/foo.test.ts # Run specific file
/test --coverage     # Run with coverage
/test --watch       # Run in watch mode
```

## Step 1: Auto-Detect Stack

```bash
# Same detection as /run command
if [ -f "bun.lock" ]; then
  echo "bun"
elif [ -f "pnpm-lock.yaml" ]; then
  echo "pnpm"
elif [ -f "yarn.lock" ]; then
  echo "yarn"
elif [ -f "package-lock.json" ]; then
  echo "npm"
elif [ -f "uv.lock" ]; then
  echo "uv"
elif [ -f "poetry.lock" ]; then
  echo "poetry"
elif [ -f "go.mod" ]; then
  echo "go"
else
  echo "unknown"
fi
```

## Step 2: Auto-Detect Test Framework

### JavaScript/TypeScript

Check `package.json` for test scripts:

```bash
node -e "try {
  const pkg = require('./package.json');
  const scripts = pkg.scripts || {};
  // Priority: vitest > jest > node test
  if (scripts.vitest) console.log('vitest');
  else if (scripts.test) console.log('jest/node');
  else console.log('unknown');
} catch(e) { console.log('unknown'); }"
```

Also check for config files:
- `vitest.config.ts` / `vitest.config.js` → vitest
- `jest.config.js` / `jest.config.ts` → jest
- `pytest.ini` → pytest
- `pyproject.toml` with `[tool.pytest]` → pytest
- `conftest.py` → pytest
- `*_test.go` files → Go tests
- `*_test.rs` files → Rust tests

### Python

```bash
if [ -f "pytest.ini" ] || grep -q "\[tool.pytest\]" pyproject.toml 2>/dev/null || [ -f "conftest.py" ]; then
  echo "pytest"
elif [ -f "manage.py" ]; then
  echo "django"
else
  echo "unknown"
fi
```

### Go

```bash
if ls *_test.go 2>/dev/null | head -1 | grep -q "_test.go"; then
  echo "go"
fi
```

## Step 3: Build Test Command

### Vitest
```bash
TEST_CMD="vitest run"
if echo "$ARGUMENTS" | grep -q "coverage"; then
  TEST_CMD="vitest run --coverage"
elif echo "$ARGUMENTS" | grep -q "watch"; then
  TEST_CMD="vitest"
elif [ -n "$ARGUMENTS" ]; then
  TEST_CMD="vitest run $ARGUMENTS"
fi
```

### Jest/npm
```bash
TEST_CMD="npm test"
if echo "$ARGUMENTS" | grep -q "coverage"; then
  TEST_CMD="npm test -- --coverage"
elif echo "$ARGUMENTS" | grep -q "watch"; then
  TEST_CMD="npm test -- --watch"
elif [ -n "$ARGUMENTS" ]; then
  TEST_CMD="npm test -- $ARGUMENTS"
fi
```

### Pytest
```bash
TEST_CMD="pytest"
if echo "$ARGUMENTS" | grep -q "coverage"; then
  TEST_CMD="pytest --cov"
elif [ -n "$ARGUMENTS" ]; then
  TEST_CMD="pytest $ARGUMENTS"
else
  TEST_CMD="pytest ."
fi
```

### Go
```bash
TEST_CMD="go test ./..."
if [ -n "$ARGUMENTS" ]; then
  TEST_CMD="go test $ARGUMENTS"
fi
```

### Rust
```bash
TEST_CMD="cargo test"
if [ -n "$ARGUMENTS" ]; then
  TEST_CMD="cargo test $ARGUMENTS"
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

**Stack:** [bun/pnpm/yarn/npm/uv/poetry/go/rust]
**Framework:** [vitest/jest/pytest/go/rust]
**Service:** [service-name]
**Command:** [test-command]

---

[Test output...]

---

**Result:** ✅ All tests passed | ❌ X tests failed
```

## Notes

- Exit code reflects test result (0 = success)
- Show failure diffs for failed tests
- Offer to re-run with watch mode if tests pass
