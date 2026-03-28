---
description: Start development server in Docker container (auto-detects stack)
argument-hint: [optional: custom command]
---

Run the development server inside a Docker container using DooD.

## Usage

```
/run              # Auto-detect and run dev server
/run npm run dev  # Run custom command
/run              # Run with auto-detected dev command
```

## Step 1: Auto-Detect Project Stack

Detect the project stack by checking for lockfiles in priority order:

```bash
# Check for lockfiles (first match wins)
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
elif [ -f "Pipfile.lock" ]; then
  echo "pipenv"
elif [ -f "go.mod" ]; then
  echo "go"
elif [ -f "Cargo.toml" ]; then
  echo "rust"
else
  echo "unknown"
fi
```

## Step 2: Auto-Detect Docker Compose Service

Find the primary service to run:

```bash
# Get services from compose file
docker compose config --services 2>/dev/null || echo "app"
```

Priority: `app` > `web` > first service defined

## Step 3: Auto-Detect Dev Command

Based on detected stack:

### JavaScript/TypeScript (bun, pnpm, yarn, npm)
```bash
# Check package.json scripts (priority order)
node -e "try {
  const pkg = require('./package.json');
  console.log(pkg.scripts?.dev || pkg.scripts?.start || 'npm run dev');
} catch(e) { console.log('npm run dev'); }"
```

### Python (uv, poetry, pipenv)
```bash
# Check for common patterns
if [ -f "manage.py" ]; then
  echo "python manage.py runserver"
elif grep -q "fastapi" pyproject.toml 2>/dev/null; then
  echo "uvicorn main:app --reload"
elif grep -q "flask" pyproject.toml 2>/dev/null; then
  echo "flask run"
else
  echo "python main.py"
fi
```

### Go
```bash
echo "go run ."
```

### Rust
```bash
echo "cargo run"
```

## Step 4: Build and Execute Command

Construct the final command:

```bash
# Get detected values
STACK=$(detect_stack)
SERVICE=$(detect_compose_service)
DEV_CMD=$(detect_dev_command)

# For custom command argument, use that instead
if [ -n "$ARGUMENTS" ]; then
  DEV_CMD="$ARGUMENTS"
fi

# Run in container
docker compose run --rm -T $SERVICE $DEV_CMD
```

The `-T` flag disables pseudo-TTY for cleaner output streaming.

## Step 5: Stream Output

Execute and stream output in real-time. Show:
- Container starting
- Dependencies installing (if applicable)
- Dev server starting
- Live server output

## Output

```markdown
## Running Development Server

**Stack detected:** [bun/pnpm/yarn/npm/uv/poetry/go/rust]
**Service:** [service-name]
**Command:** [command]

---

[Streaming output...]

---
```

## Notes

- First run may be slower if images need to build
- Use Ctrl+C to stop the server
- Container is automatically removed after (--rm)
