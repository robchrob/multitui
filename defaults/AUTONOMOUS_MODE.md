# Autonomous Mode Guide

## What This Enables

Auto-running large tasks with automatic model fallback:
- **Model 1**: Z.AI GLM-5.1
- **Model 2**: MiniMax-M2.5 (OpenRouter free)
- **Model 3**: StepFun-3.5-flash (OpenRouter free)

On API errors (429, 503, 529, rate limits), automatically switches to next model. 30 fallback attempts per model.

## Files

| File | Purpose |
|------|---------|
| `defaults/opencode.json` | Core config: plugins, providers, MCP, permissions |
| `defaults/oh-my-openagent.json` | Model chain + runtime fallback config |

## Usage

```bash
# Start container
mtui start

# Inside container - fully autonomous:
ultrawork "implement feature X"

# Or with Prometheus planning:
@plan "refactor auth system"
/start-work
```

## Environment Variables Required

- `ZAI_API_KEY` - Z.AI Coding Plan
- `OPENROUTER_API_KEY` - OpenRouter (for MiniMax/StepFun fallbacks)

Set in your shell or `.env`.

## How It Works

1. Task starts with GLM-5.1
2. On error → auto-switch to MiniMax-M2.5
3. On error → auto-switch to StepFun-3.5-flash
4. Each model gets 30 fallback attempts
5. Task keeps running until completion or all attempts exhausted
