---
description: Debug an error - investigate cause and suggest fix
argument-hint: <error message or description>
---

Debug mode. Given an error message, investigate and find the cause.

## Usage

```
/debug Error: Cannot read property 'foo' of undefined
/debug TypeError: x is not a function
/debug [paste error or describe unexpected behavior]
```

## Step 0: Check AGENTS.md for Context

Before deep debugging, check AGENTS.md for project context:

```bash
if [ -f "AGENTS.md" ]; then
  echo "=== Stack from AGENTS.md ==="
  awk '/^## Stack/,/^##/' AGENTS.md | head -15
  echo ""
  echo "=== DooD Commands ==="
  awk '/^## DooD Commands/,/^##/' AGENTS.md | head -15
fi
```

This helps understand the stack and how to run reproduction commands.

## Step 1: Parse the Error

If no error provided, ask for it:

```
What error are you seeing? Paste:
- Error message
- Stack trace
- Console output
- Or describe the unexpected behavior
```

Extract from error:
- **Error type**: TypeError, SyntaxError, ReferenceError, runtime, build, etc.
- **File:line**: if present in stack trace
- **Function/component**: involved module or function name
- **Key values**: mentioned in error message

## Step 2: Locate Ground Zero

```bash
# If file:line present in error
read <file> 2>/dev/null

# Search for function/component name
rg -l "functionName|const functionName|class FunctionName" . 2>/dev/null

# For imports
rg "from ['\"]\.\/.*['\"]|from ['\"]@.*['\"]" . -l 2>/dev/null
```

## Step 3: Detect Stack for Reproduction

Follow MultiTUI conventions:

```bash
# Detect stack (same as /run and /test)
if [ -f "bun.lock" ]; then
  STACK="bun"
elif [ -f "pnpm-lock.yaml" ]; then
  STACK="pnpm"
elif [ -f "yarn.lock" ]; then
  STACK="yarn"
elif [ -f "package-lock.json" ]; then
  STACK="npm"
elif [ -f "uv.lock" ] || [ -f "pyproject.toml" ]; then
  STACK="uv"
elif [ -f "go.mod" ]; then
  STACK="go"
elif [ -f "Cargo.toml" ]; then
  STACK="rust"
else
  STACK="unknown"
fi

echo "Detected stack: $STACK"
```

## Step 4: Reproduce the Error

Use the appropriate command based on stack:

```bash
SERVICE=$(docker compose config --services 2>/dev/null | head -1 || echo "app")

case "$STACK" in
  bun)
    docker compose run --rm $SERVICE bun run dev 2>&1 | tail -50
    docker compose run --rm $SERVICE bun run test 2>&1 | tail -100
    ;;
  pnpm)
    docker compose run --rm $SERVICE pnpm dev 2>&1 | tail -50
    docker compose run --rm $SERVICE pnpm test 2>&1 | tail -100
    ;;
  yarn)
    docker compose run --rm $SERVICE yarn dev 2>&1 | tail -50
    docker compose run --rm $SERVICE yarn test 2>&1 | tail -100
    ;;
  npm)
    docker compose run --rm $SERVICE npm run dev 2>&1 | tail -50
    docker compose run --rm $SERVICE npm test 2>&1 | tail -100
    ;;
  uv)
    docker compose run --rm $SERVICE "uv run python main.py" 2>&1 | tail -50
    docker compose run --rm $SERVICE "uv run pytest" 2>&1 | tail -100
    ;;
  go)
    docker compose run --rm $SERVICE "go run ." 2>&1 | tail -50
    docker compose run --rm $SERVICE "go test ./..." 2>&1 | tail -100
    ;;
  rust)
    docker compose run --rm $SERVICE "cargo run" 2>&1 | tail -50
    docker compose run --rm $SERVICE "cargo test" 2>&1 | tail -100
    ;;
esac
```

## Step 5: Analyze Root Cause

Based on error type:

### TypeError / ReferenceError
- Variable undefined or wrong type?
- Check imports: is the export correct?
- Check async: is data ready?

### Module/Import Error
- Check if export exists
- Check path is correct
- Check package is installed

### Build Error
- Check syntax
- Check TypeScript types
- Check configuration

### Runtime Error
- Check data flow
- Check null/undefined handling
- Check async timing

### Python-specific
- Check virtualenv/uv environment
- Check imports: `from package import module`
- Check PYTHONPATH

## Step 6: Read Relevant Code

```bash
# Read the file around error line
read <file>

# Read related files
rg "import.*from" <file> -B 1
```

## Step 7: Identify Fix

Common fixes:
- Add null check
- Await async call
- Fix import path
- Install missing dependency
- Fix type annotation

## Step 8: Present Findings

Format:

```
## Debug Report

### Error
[original error]

### Root Cause
[1-2 sentence explanation]

### Location
[file]:[line] - [function]

### Problem
[code snippet]

### Suggested Fix
[corrected code]
```

## Step 9: Offer to Fix

```
Apply this fix? (y/n)
```

If yes, apply with Edit tool, then verify using the appropriate stack command:

```bash
# Verify with correct stack command
case "$STACK" in
  bun)
    docker compose run --rm $SERVICE bun run test 2>&1 | tail -30
    ;;
  uv)
    docker compose run --rm $SERVICE "uv run pytest" 2>&1 | tail -30
    ;;
  *)
    docker compose run --rm $SERVICE npm test 2>&1 | tail -30
    ;;
esac
```

## Step 10: Summarize Prevention

After fix, suggest:

```
### Prevention
- Add type check
- Add error boundary
- Add unit test for this case
- Use strict TypeScript
```

## MultiTUI Conventions Reference

- **JavaScript**: Use `bun run` for all commands
- **Python**: Use `uv run` for all commands
- **Services**: `docker compose run --rm <service> <command>`

## Notes

- If error is unclear, ask clarifying questions
- If multiple issues, fix one at a time
- After fix, run full test suite to ensure no regressions
- Prioritize understanding AGENTS.md context first
