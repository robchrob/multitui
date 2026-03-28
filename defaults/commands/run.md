---
description: Start development server in Docker container
argument-hint: [optional: custom command]
---

Start the development server inside a Docker container using DooD.

## Your Task

Run the dev server for this project using Docker Compose. Detect the stack and run the appropriate command.

## Detection Steps

1. **Read from project manifest** (preferred):
   - package.json → read the "dev" script from scripts
   - pyproject.toml → read [tool.scripts] for dev command
   - go.mod → use `go run .`
   - Cargo.toml → use `cargo run`
   - Gemfile → use `bundle exec ruby <file>`

2. **If dev script found in manifest**, use it directly.

3. **Fallback** - Only if no dev script in manifest:
   - Detect stack from lockfiles: bun.lock, pnpm-lock.yaml, yarn.lock, package-lock.json, uv.lock, go.mod, Cargo.toml
   - JS: try `bun run dev` → `npm run dev` → `pnpm dev` → `yarn dev`
   - Python: try `uv run uvicorn main:app --reload` or `uv run flask run`
   - Go: `go run .`
   - Rust: `cargo run`

4. **Detect compose service**: `docker compose config --services` → first service or 'app'

5. **If custom argument provided**, use that as the command instead.

## Execution

Run the command inside the container:

```bash
docker compose run --rm -T <service> <command>
```

Stream the output in real-time.

## Output

Report:
- Stack detected
- Service used
- Command executed
- Any errors encountered
