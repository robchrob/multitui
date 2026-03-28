---
name: container-debug
description: Debug running containers - shell access, logs, inspection. Use when container crashes, hangs, or needs investigation.
---

# Container Debugging

Debug and inspect running containers in a DooD environment.

## Shell Access

### Get Interactive Shell

```bash
# Inside container (most common)
docker compose exec app sh
docker compose exec app bash

# As root (if needed)
docker compose exec -u root app sh

# One-off command
docker compose run --rm app sh -c "ls -la /app"
```

### Non-Interactive Commands

```bash
# Run command and exit
docker compose exec app ls -la /app

# Run command with environment
docker compose exec app env

# Check running processes
docker compose exec app ps aux

# Check memory/disk
docker compose exec app df -h
docker compose exec app free -m
```

## Log Analysis

### View Logs

```bash
# All services
docker compose logs

# Specific service
docker compose logs app

# Follow in real-time
docker compose logs -f app

# Last N lines
docker compose logs --tail=100 app

# With timestamps
docker compose logs -t app

# Since time
docker compose logs --since=1h app
```

### Search Logs

```bash
# Search in logs (combine with grep)
docker compose logs app 2>&1 | grep ERROR
docker compose logs app 2>&1 | grep -i "exception\|fail\|error"

# Tail and grep
docker compose logs -f app 2>&1 | grep --line-buffered ERROR
```

## Inspection

### Container Status

```bash
# List running containers
docker compose ps

# List all containers (including stopped)
docker compose ps -a

# Detailed status
docker compose ps -a --format json | jq
```

### Inspect Container

```bash
# Full inspection
docker inspect app

# Specific field (JSON path)
docker inspect -f '{{.State.Status}}' app
docker inspect -f '{{.NetworkSettings.IPAddress}}' app
docker inspect -f '{{.Config.Env}}' app

# Mounts
docker inspect -f '{{.Mounts}}' app | jq
```

### Resource Usage

```bash
# Real-time stats
docker stats

# Specific container stats
docker stats app

# No streaming (single snapshot)
docker stats --no-stream app
```

## Network Debugging

### Check Connectivity

```bash
# DNS resolution
docker compose exec app nslookup db
docker compose exec app getent hosts db

# Port connectivity
docker compose exec app curl -v http://localhost:3000
docker compose exec app wget -O- http://db:5432

# Network info
docker network ls
docker network inspect <network>
```

### Port Issues

```bash
# Check what's listening
docker compose exec app netstat -tlnp
docker compose exec app ss -tlnp

# Check port mappings
docker port app
```

## Database Debugging

### PostgreSQL

```bash
# Connect to DB
docker compose exec db psql -U postgres

# List databases
docker compose exec db psql -U postgres -l

# Run SQL
docker compose exec db psql -U postgres -c "SELECT * FROM users;"
```

### Redis

```bash
# Connect to Redis
docker compose exec redis redis-cli

# Check keys
docker compose exec redis redis-cli KEYS "*"

# Check memory
docker compose exec redis redis-cli INFO memory
```

### MongoDB

```bash
# Connect
docker compose exec mongo mongosh

# List databases
docker compose exec mongo mongosh --eval "db.adminCommand('listDatabases')"
```

## Common Debugging Scenarios

### Container Keeps Restarting

```bash
# Check restart policy
docker inspect -f '{{.RestartCount}}' app

# Check exit code
docker inspect -f '{{.State.ExitCode}}' app

# View recent logs
docker compose logs --tail=50 app
```

### Out of Memory

```bash
# Check memory limits
docker inspect -f '{{.HostConfig.Memory}}' app

# Check OOM kills
dmesg | grep -i "out of memory" | tail -10

# In container
docker compose exec app cat /proc/meminfo
```

### Slow Performance

```bash
# Check CPU
docker stats --no-stream app

# Check I/O
docker stats --no-stream --format "table {{.Name}}\t{{.BlockIO}}\t{{.CPUPerc}}"

# Disk usage
docker system df
```

### Permission Denied

```bash
# Check user
docker compose exec app whoami
docker compose exec app id

# Fix ownership
docker compose exec app chown -R user:user /app
```

## Quick Diagnostics

### Full Health Check

```bash
# One-liner for container health
echo "=== Container Status ===" && \
docker inspect -f '{{.State.Status}} - Started: {{.State.StartedAt}}' app && \
echo "=== Recent Exits ===" && \
docker inspect -f '{{.State.ExitCode}} - ExitTime: {{.State.FinishedAt}}' app && \
echo "=== Logs (last 20) ===" && \
docker compose logs --tail=20 app && \
echo "=== Resource Usage ===" && \
docker stats --no-stream --format "CPU: {{.CPUPerc}} | Mem: {{.MemUsage}}" app
```

### Export for Help

```bash
# Export logs
docker compose logs app > app-logs.txt

# Export container info
docker inspect app > app-inspect.json

# Tar files for analysis
docker compose exec app tar -czf /tmp/debug.tar.gz /app
docker cp app:/tmp/debug.tar.gz ./debug.tar.gz
```

## Best Practices

1. ALWAYS use `docker compose exec` not `docker exec` (works with DooD)
2. Use `sh` not `bash` (alpine images often lack bash)
3. Check logs FIRST before shell access
4. Use `jq` for JSON inspection: `docker inspect app | jq`
5. For one-off debugging, use `--rm` to auto-cleanup
6. Capture full context: logs + inspect + stats
