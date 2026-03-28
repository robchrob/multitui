---
description: Start development server in Docker container
argument-hint: [optional: custom command]
---

Run the development server inside a Docker container using DooD.

## Usage

```
/run                   # Run dev server (from AGENTS.md or auto-detected)
/run bun run dev      # Run custom command
/run python manage.py runserver  # Run arbitrary command
```

## Step 0: Check AGENTS.md First

Before auto-detecting, ALWAYS check if AGENTS.md exists and has DooD Commands:

```bash
# Check if AGENTS.md exists
if [ -f "AGENTS.md" ]; then
  # Extract DooD Commands section
  awk '/^## DooD Commands/,/^##/' AGENTS.md | grep -E '^\s*[-`]|docker compose' | head -20
fi
```

If AGENTS.md has a `## DooD Commands` section with a `dev` command, use that directly.
Skip auto-detection if AGENTS.md already specifies the dev command.

## Step 1: Auto-Detect Project Stack

Follow MultiTUI conventions: bun for JS/TS, uv for Python.

### Priority Order

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
  echo "uv"  # Use uv even with just pyproject.toml
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

## Step 2: Auto-Detect Docker Compose Service

Find the primary service to run:

```bash
# Get services from compose file (first one is primary)
docker compose config --services 2>/dev/null | head -1 || echo "app"
```

Priority: first defined service > `app` > `web`

## Step 3: Auto-Detect Dev Command

### JavaScript/TypeScript (bun, pnpm, yarn, npm)

For bun, ALWAYS use `bun run`:

```bash
# Read package.json for scripts (for non-bun only)
if [ -f "package.json" ]; then
  node -e "try {
    const pkg = require('./package.json');
    console.log(pkg.scripts?.dev || pkg.scripts?.start || '');
  } catch(e) { console.log(''); }"
fi
```

**Build the final command:**
- bun: `bun run dev` (or from package.json scripts: `bun run <script>`)
- pnpm: `pnpm dev` (or `pnpm <script>`)
- yarn: `yarn dev` (or `yarn <script>`)
- npm: `npm run dev` (or `npm run <script>`)

### Python (uv, poetry, pipenv)

For uv, ALWAYS use `uv run`:

```bash
# Default for Python is uv run with main.py or manage.py
if [ -f "manage.py" ]; then
  echo "uv run python manage.py runserver"
else
  echo "uv run python main.py"
fi
```

**Build the final command:**
- uv: `uv run <command>` (ALWAYS)
- poetry: `poetry run <command>`
- pipenv: `pipenv run <command>`

### Go

```bash
echo "go run ."
```

### Rust

```bash
echo "cargo run"
```

## Step 4: Check for Custom Argument

If user provided custom command as argument, use that instead:

```bash
if [ -n "$ARGUMENTS" ]; then
  DEV_CMD="$ARGUMENTS"
fi
```

## Step 5: Execute in Container

```bash
# Build command based on detected stack
case "$STACK" in
  bun)
    FULL_CMD="bun run ${DEV_CMD:-dev}"
    ;;
  pnpm)
    FULL_CMD="pnpm ${DEV_CMD:-dev}"
    ;;
  yarn)
    FULL_CMD="yarn ${DEV_CMD:-dev}"
    ;;
  npm)
    FULL_CMD="npm run ${DEV_CMD:-dev}"
    ;;
  uv)
    FULL_CMD="uv run ${DEV_CMD:-python main.py}"
    ;;
  poetry)
    FULL_CMD="poetry run ${DEV_CMD}"
    ;;
  pipenv)
    FULL_CMD="pipenv run ${DEV_CMD}"
    ;;
  go)
    FULL_CMD="go run ."
    ;;
  rust)
    FULL_CMD="cargo run"
    ;;
  *)
    FULL_CMD="${DEV_CMD:-npm run dev}"
    ;;
esac

# Run in container (use -T for cleaner output, --rm for cleanup)
docker compose run --rm -T $SERVICE $FULL_CMD
```

## Step 6: Stream Output

Execute and stream output in real-time. Show:
- Container starting
- Dependencies installing (if applicable)
- Dev server starting
- Live server output

## Output Format

```markdown
## Running Development Server

**Source:** [AGENTS.md | auto-detected]
**Stack:** [bun/pnpm/yarn/npm/uv/poetry/go/rust]
**Service:** [service-name]
**Command:** [full command]

---

[Streaming output...]

---
```

## MultiTUI Runtime Conventions (Reference)

Follow these exactly:

- **JavaScript/TypeScript**: Use `bun run` (not npm/yarn/pnpm directly)
- **Python**: Use `uv run` (not pip/poetry directly unless required)
- **Base images**: 
  - JS: `imbios/bun-node:latest-slim`
  - Python: `python:3.13-slim` with uv
- **Named cache volumes**: 
  - bun: `bun_cache → /root/.bun/install/cache`
  - uv: `uv_cache → /root/.cache/uv`

## Notes

- First run may be slower if images need to build
- Use Ctrl+C to stop the server
- Container is automatically removed after (--rm)
- ALWAYS prioritize AGENTS.md over auto-detection
