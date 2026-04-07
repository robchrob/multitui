# Plan.md — MultiTUI Roadmap

```
SESSION_CURRENT = 0.0.0
SESSION_TARGET  = 0.2.0
SESSION_SCOPE   = Restructure versioning with more granular versions
```

## v0.2.0 — Magic Versioning Protocol

**Goal:** Redefine magic versioning with narrative-first planning.

The magic versioning skill was previously a loose convention without a formal session contract. This version introduces a rigorous protocol: SESSION_CURRENT, SESSION_TARGET, and SESSION_SCOPE form an immutable session header that gates all versioning operations. The protocol enforces that work can only happen within the declared session range, preventing scope creep and accidental version bumps outside the planned scope.

The key architectural decision was to store session state in the files themselves (plan.md and tasks.md headers) rather than in memory or external state. This means any conversation can re-derive the session context by reading the header block — no state is lost on context window reset.

Tradeoff considered: we could have used a separate .session file, but embedding in plan.md/tasks.md keeps the session scope visible alongside the actual work items. The narrative-first approach means plan.md describes *why* each version exists, while tasks.md carries the mechanical checklist.

This version also replaces the hardcoded "develop" branch reference with a dynamic MTUI_BRANCH environment variable, making the framework usable in repos where the primary branch has a different name. Dead code from earlier iterations was removed to streamline the status output.

## v0.1.9 — Plugin Ecosystem

**Goal:** Add plugins for quota management and rate limiting.

MultiTUI's agent runs inside containers that consume AI model API tokens. Without visibility or control, token budgets can be exhausted unexpectedly. This version introduces two plugins: a quota management plugin (@slkiser/opencode-quota) for tracking token/budget consumption, and a rate limit and retry plugin (@bdliyq/opencode-rate-limit-retry) for API resilience when rate limits are hit.

The session contract and semver 2.0 specification were also added to the magic versioning skill itself, establishing the perpetual 0.x mode with clear bump rules: MINOR for new/breaking changes, PATCH for fixes only. This codifies the versioning strategy that was previously implicit.

## v0.1.8 — Branch Management & Runtime Isolation

**Goal:** Implement isolated development with project branches and improve runtime isolation.

Previously, all agent work happened on the same branch, risking conflicts and making it hard to track what was done in each session. This version introduces `mtui branch create/status/update` commands that create isolated project branches (e.g., `develop-projectname`) with a `.mtui-branch` file tracking the active branch. The `_attach()` function reads this file to know which branch to work on.

Runtime isolation was improved by giving the container dedicated writable directories under `/workspace` and parameterizing the model config via `{env:MTUI_MODEL}` in opencode.json. This means different projects can use different models without changing the framework code.

The default model was switched to stepfun/step-3.5-flash:free, and Dockerfile lookup was simplified to check the project root directly instead of searching multiple paths. Autonomous execution rules and safety checks were added to the rewrite-history command, including a SYSTEM DIRECTIVE for autonomous execution, prevention of the CWD deletion bug, and enforcement of strict 40-character SHA matching.

## v0.1.7 — Rewrite Command

**Goal:** Add commit message rewriting with safety checks.

The rewrite-history command was introduced to batch-edit commit messages across the project history. The initial implementation used a file-mapping approach that proved fragile at scale. This version switches to SHA-based file mapping, which is more robust because it uses exact commit hashes rather than relative positions.

The update-readme command was enhanced with diff audit capability — it now compares the actual file changes against the documentation updates to ensure accuracy.

## v0.1.6 — Update-Readme & License

**Goal:** Documentation tools, licensing, and test infrastructure foundations.

This version added the update-readme command and caveman skill for ultra-compressed communication. An MIT license file was added. The README was overhauled with auto-update capability documentation.

The MCP documentation was completely restructured, and the README was reorganized to clarify user capabilities in prompts. The AGENTS_DEV.md vs AGENTS.md reading rules were clarified to prevent confusion between development mode and production mode. Temporal context (year 2026) was added to init and bootstrap prompts so the agent always has correct date awareness.

Reusable e2e test helper libraries were created (docker.sh, fixtures.sh, mtui.sh, opencode.sh, test_helpers.sh), and prompts were improved for precise project discovery and testing.

## v0.1.5 — Testing Infrastructure

**Goal:** Comprehensive e2e testing and development guide.

A comprehensive e2e test harness was built for the mtui CLI, testing all commands end-to-end inside Docker containers. Tests were consolidated with a shared assertion library to reduce duplication. The image build was centralized and redundant tests were removed. AI calls in tests were parallelized to speed up execution, and test artifacts were added for debugging failures.

AGENTS_DEV.md was rewritten as a comprehensive development guide, replacing the previous TODO-style format. The dev workflow heading was renamed for prominence.

## v0.1.4 — Multi-session Support

**Goal:** Concurrent sessions and container path standardization.

Previously, only one mtui session could run at a time because it used a single foreground container. This version introduced background container support, enabling multiple concurrent sessions. Each session gets its own container instance.

Container paths were standardized to use a fixed `/workspace` mount point, replacing the earlier PWD-based approach. Config paths were corrected and non-interactive stdin support was added for docker-exec. The PWD-based volume mount approach was eventually restored after the fixed path approach proved problematic with certain directory structures.

## v0.1.3 — Build & Attach System

**Goal:** Robust build process with version checking and attach recovery.

The build system was enhanced with OpenCode version checking — if the installed OpenCode version doesn't match the expected version, mtui automatically rebuilds. Broken gitlink detection and recovery was added to the attach command, handling cases where the agent directory's git state is corrupted.

Robust error handling was implemented with strict mode (`set -euo pipefail`), which caught several latent bugs. A bash version check and port argument validation were added to fail early with clear error messages.

The opencode invocation was simplified by removing temp file indirection. The attach command was simplified with a shallow clone approach instead of the previous complex delegation pattern. The upstream branch tracking was corrected to use "develop". Docker flags were consolidated and the agent Dockerfile was prioritized in the build order.

## v0.1.2 — Framework Initialization

**Goal:** Initialize multitui framework project structure.

This version established the foundational project structure: config directories, prompt templates, skill definitions, and the initial mtui script. The config and prompt directories were reorganized for clarity. Symlinks were used for skills to avoid duplication, and `.opencode/` was added to the ignore list.

A structured 6-section agents.md template was adopted for consistent prompt formatting. Comprehensive ignore file generation instructions were added. The permissions model was simplified and environment context was documented. The dev user was documented with cross-file path references fixed.

MCP server configs were separated for easier maintenance (though later reverted to inline). The default model was upgraded to qwen3.6-plus-free. User package manager configurations were mounted into the container, and the `.config` directory was created before mounting. Array expansion and command failures in strict mode were fixed.

## v0.1.1 — CLI & Commands

**Goal:** Enhance command system and mtui logic.

The command system was refactored to prioritize project-specific commands from agents.md over the framework defaults. Templates were simplified and mtui logic was consolidated. The standalone mtui script was created with external templates, replacing the earlier approach of embedding templates in shell functions. Shell functions were consolidated into the standalone script, and the delegation pattern was removed in favor of direct execution.

## v0.1.0 — Bootstrap & Foundation

**Goal:** Customizable bootstrap and standalone mtui CLI.

The bootstrap process was enhanced to accept custom user instructions during initialization, allowing projects to customize the agent's behavior from the start. Agent integration tasks were tracked in a TODO file. The Docker container execution model was documented in AGENTS.md. Dead code and unused variables were removed from the scripts.

## v0.0.3 — Dockerfile & Model

**Goal:** Fix Docker environment and model configuration.

The Dockerfile was fixed to include the OpenCode binary directory in PATH, ensuring the `opencode` command is available in the container. The configured model was ensured to be passed to all invocations, preventing cases where the default model was used instead of the user's choice. The default model was updated and test output management was improved.

## v0.0.2 — Configurable Model

**Goal:** Establish configurable defaults.

The mtui framework introduced a configurable default model for OpenCode, allowing users to specify which AI model to use via environment variable rather than hardcoding it. This was the first step toward making the framework adaptable to different model providers and preferences.

## v0.0.1 — API Migration

**Goal:** Establish AI model gateway.

The framework migrated from direct Anthropic API calls to OpenRouter as the model gateway. This provides access to multiple models through a single API, enabling easy model switching and fallback. This was a breaking change in the API layer but transparent to the end user.

## v0.0.0 — Project Inception

**Goal:** Start the MultiTUI framework.

The project began with initial command templates and skill definitions. The core idea: a CLI wrapper (`mtui`) around OpenCode that manages Docker-based agent sessions, with built-in skills for common development workflows. The framework was designed from the start to run entirely in containers (DooD pattern), with the agent spawning runtime containers on the host Docker daemon.
