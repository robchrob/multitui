# Autonomous Mode Guide

## What This Enables

Auto-running large tasks with automatic model fallback:
- **Model 1**: Z.AI GLM-5.3 (Coding Plan)
- **Model 2**: Gemma-4-31B (OpenRouter free)
- **Model 3**: DeepSeek V4 Flash (OpenCode free)

On API errors (400, 429, 503, 529, rate limits), automatically switches to next model. 30 fallback attempts per model.

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

- `ZAI_API_KEY` - Z.AI Coding Plan (primary model)
- `OPENROUTER_API_KEY` - OpenRouter (free fallbacks)

Optional: `OPENCODEGO_API_KEY` for OpenCode Go models (`opencode-go/*`).

Set in your shell or `.env`.

## How It Works

1. Task starts with GLM-5.3
2. On error → auto-switch to Gemma-4-31B (free)
3. On error → auto-switch to DeepSeek V4 Flash (free)
4. Each model gets 30 fallback attempts
5. Task keeps running until completion or all attempts exhausted