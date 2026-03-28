---
name: docker-compose
description: Docker Compose patterns for multi-container apps with DooD. Use when working with docker-compose.yml, managing services, or debugging containers.
---

# Docker Compose for DooD Development

This skill provides patterns for Docker Compose in a DooD (Docker-out-of-Docker) development environment.

## Key Commands

### Service Management
```bash
# Start all services
docker compose up -d

# Start specific service
docker compose up -d app

# Stop all services
docker compose down

# View service status
docker compose ps

# View logs
docker compose logs -f app
```

### DooD-Specific Patterns

**Always use `--rm` for one-off commands:**
```bash
# JavaScript/TypeScript - use bun run
docker compose run --rm app bun run test
docker compose run --rm app bun run build

# Python - use uv run
docker compose run --rm app "uv run pytest"
docker compose run --rm app "uv run python manage.py migrate"
```

**Use `-T` for non-interactive commands (cleaner output):**
```bash
docker compose run -T app bun run build
docker compose run -T app "uv run pytest"
```

**Service discovery:** Services communicate via service names:
```bash
# From app service, access db:
# connection string: postgresql://user:pass@db:5432/dbname
```

## Common Patterns

### depends_on with Healthchecks

ALWAYS use healthchecks for reliable startup:

```yaml
services:
  db:
    image: postgres:15
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
      start_period: 10s

  app:
    depends_on:
      db:
        condition: service_healthy
```

**Why:** `depends_on:` alone only waits for container START, not readiness. Add `condition: service_healthy`.

### Healthcheck start_period

Slow-starting services need grace period:

```yaml
healthcheck:
  test: ["CMD", "pg_isready"]
  start_period: 30s  # Initial grace period
  interval: 10s
  timeout: 5s
  retries: 5
```

**Why:** Without start_period, container marked unhealthy before it finishes initializing.

### Volume Safety

CRITICAL: `docker compose down` preserves volumes. To delete:

```bash
# Safe - preserves volumes
docker compose down

# DANGEROUS - deletes all volumes (data loss!)
docker compose down -v
```

### Development Override

Use override file for dev-specific settings:

```yaml
# docker-compose.yml - base config
services:
  app:
    build: .
    ports:
      - "3000:3000"

# docker-compose.override.yml - dev overrides (auto-loaded)
services:
  app:
    volumes:
      - .:/app
    environment:
      - NODE_ENV=development
    command: bun run dev
```

### Resource Limits

Set limits in development to catch issues early:

```yaml
services:
  app:
    deploy:
      resources:
        limits:
          memory: 512M
        reservations:
          memory: 256M
```

### Profiles

Use profiles for optional services:

```yaml
services:
  mailhog:
    image: mailhog/mailhog
    profiles: [dev]
```

```bash
# Only start with profile
docker compose --profile dev up
```

### Environment Variable Precedence

1. Shell environment (highest)
2. `.env` file in compose directory
3. `env_file:` directive
4. `environment:` in compose file (lowest)

## DooD-Specific Considerations

### Running in Container

When OpenCode runs inside a container (DooD):

```bash
# From inside multitui container, use host Docker socket
docker compose up -d

# Services bind to HOST ports, not container ports
# Access at localhost:3000 not container-ip:3000
```

### Volume Mounts

For DooD, mounts should target project root:

```yaml
services:
  app:
    volumes:
      - ${PROJECT_ROOT:-.}:/app
```

### Network

Services run on host network in DooD:

```yaml
# Not usually needed - services accessible on localhost
# But for inter-service communication:
services:
  app:
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

## Troubleshooting

### Service Won't Start

```bash
# Check logs
docker compose logs app

# Check config
docker compose config

# Rebuild
docker compose build --no-cache app
```

### Port Conflicts

```bash
# Find what's using the port
lsof -i :3000

# Or in container
docker compose exec app netstat -tlnp
```

### Database Connection Issues

```bash
# Wait for DB to be ready
docker compose exec app sh -c "until pg_isready; do sleep 1; done"

# Check DB logs
docker compose logs db
```

### Permission Issues

```bash
# Fix node_modules permissions
docker compose run --rm app chown -R node:node /app/node_modules
```

## Best Practices

1. ALWAYS use healthchecks with `condition: service_healthy`
2. Set `start_period` for slow-starting services (databases, elasticsearch)
3. NEVER run `docker compose down -v` unless you want to lose data
4. Use `.dockerignore` to exclude node_modules, .git, secrets
5. Keep base compose generic, use override for dev/prod
6. Use profiles for optional services (debug tools, test dbs)
7. Set resource limits in development
8. Use named volumes for persistent data
