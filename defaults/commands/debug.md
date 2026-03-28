---
description: Debug an error - investigate cause and suggest fix
argument-hint: <error message or description>
---

Debug mode. Given an error message or unexpected behavior, investigate and find the cause.

## Your Task

Analyze the error and trace it to the root cause.

## Steps

1. **Parse the error** - Extract:
   - Error type (TypeError, SyntaxError, runtime, build, etc.)
   - File:line if present
   - Function/component involved
   - Key values mentioned

2. **Locate the source**:
   - If file:line provided, read that file
   - Search for function/component names in codebase

3. **Reproduce the error**:
   - Detect stack (bun.lock → bun, uv.lock → uv, etc.)
   - Run appropriate dev or test command in container
   - Capture the error output

4. **Analyze root cause**:
   - Trace the data flow
   - Identify what assumption is violated
   - Common issues: null checks, async timing, import paths, type mismatches

5. **Suggest fix**:
   - Present the root cause clearly
   - Show the problematic code
   - Provide corrected code

6. **Verify fix**:
   - Apply the fix
   - Re-run the command to confirm it works

## Execution

Use docker compose to run commands:

```bash
docker compose run --rm <service> <command>
```

## Output Format

```
## Debug Report

### Error
[original error]

### Root Cause
[1-2 sentence explanation]

### Location
[file]:[line]

### Problem
[code snippet]

### Suggested Fix
[corrected code]
```
