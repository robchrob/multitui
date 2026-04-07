# Plan.md — MultiTUI Roadmap

```
SESSION_CURRENT = 0.3.8
SESSION_TARGET  = 0.3.8
SESSION_SCOPE   = read TODO file
```

## v0.3.8 — Remove Submodule Logic
**Goal:** Drop all submodule-related code from mtui since the framework uses cloning

### Submodule Cleanup
- [x] Identify and remove all submodule logic from mtui script (c308957)
- [x] Remove any submodule-related documentation or references
- [x] Verify mtui works correctly without submodule code paths

## v0.3.7 — Dynamic Branch Base
**Goal:** Use MTUI_BRANCH env var as the branching base instead of hardcoded "develop"

### Branch Base Configuration
- [x] Read MTUI_BRANCH for determining base branch (instead of hardcoded "develop")
- [x] Update branch create command to use dynamic base
- [x] Update documentation to reflect MTUI_BRANCH dual purpose
- [x] Test branching from non-develop base branches

## v0.3.6 — Polish, Isolation & Ecosystem
**Goal:** Agent improvements, branch management, runtime isolation, plugin ecosystem, and magic versioning session contract

### Agent & Prompts
- [x] Clarify AGENTS_DEV.md vs AGENTS.md reading rules (c308957)
- [x] Improve prompts for precise project discovery and testing (2b5d2b6)
- [x] Add temporal context (year 2026) to init and bootstrap prompts (cd43b17)
- [x] Reorganize README and clarify user capabilities in prompts (f4b1a52)
- [x] Overhaul MCP documentation and restructure README (5bd2df5)

### Branch Management
- [x] Implement isolated development with project branches (ee7b207)
  - [x] mtui branch create command
  - [x] mtui branch status command
  - [x] mtui update [--continue] command
  - [x] .mtui-branch file tracking
  - [x] Update _attach() to read .mtui-branch
  - [x] Comprehensive e2e test suite for branch commands

### Testing Infrastructure
- [x] Create reusable e2e test helper libraries (bf9a2e3)
  - [x] tests/e2e/lib/docker.sh
  - [x] tests/e2e/lib/fixtures.sh
  - [x] tests/e2e/lib/mtui.sh
  - [x] tests/e2e/lib/opencode.sh
  - [x] tests/e2e/lib/test_helpers.sh
- [x] Revert model to minimax and increase container wait time (77bc373)
- [x] Update default model and improve test output management (6c7ae79)

### Build & Configuration
- [x] Simplify Dockerfile lookup logic (afd0488)
- [x] Enhance README with workflow and make mtui configurable (7f05592)
  - [x] MTUI_BRANCH env var for remote branch
  - [x] MTUI_MODEL env var for model config
  - [x] Remove GITHUB_TOKEN from container

### Rewrite Command
- [x] Add autonomous execution rules and safety checks (3111bc7)
  - [x] SYSTEM DIRECTIVE for autonomous execution
  - [x] Prevent CWD deletion bug
  - [x] Enforce strict 40-character SHA matching

### Runtime Isolation
- [x] Switch default model to step-3.5-flash (8b0de42)
- [x] Isolate opencode state and parameterize model config (4016a14)
  - [x] Dedicated writable directories under /workspace
  - [x] {env:MTUI_MODEL} in opencode.json
  - [x] Update bootstrap.md for package manager flexibility

### Plugin Ecosystem
- [x] Add quota management plugin (be45f07)
- [x] Add rate limit and retry plugin (d1a7ce4)

### Magic Versioning
- [x] Add session contract and semver 2.0 to magic versioning skill (000d2a3)
  - [x] SESSION_CURRENT / SESSION_TARGET / SESSION_SCOPE
  - [x] Perpetual 0.x mode with bump rules
  - [x] Pre-release suffix support
  - [x] Error states table
  - [x] Changelog format template

## v0.3.5 — Rewrite & Update Tools
**Goal:** Commit message rewriting, documentation tools, and licensing

### Rewrite Command
- [x] Add command for batch commit message rewriting (6c8a595)
- [x] Switch to SHA-based file mapping for scalability (fdff653)

### Update-Readme
- [x] Add update-readme command and caveman skill (055eb87)
- [x] Enhance with diff audit for accurate docs (b591106)

### Documentation & License
- [x] Add license and overhaul readme with auto-update capability (3f290ca)
- [x] Clarify when to read AGENTS_DEV vs AGENTS.md (c308957)

## v0.3.4 — Testing Infrastructure
**Goal:** Comprehensive e2e testing and development guide

### Test Harness
- [x] Create comprehensive e2e test harness for mtui CLI (baa1851)
- [x] Consolidate tests with shared assertion library (4c8574f)
- [x] Centralize image build and remove redundant tests (fb760d6)
- [x] Parallelize AI calls and add artifact output (cece50c)

### Documentation
- [x] Rewrite AGENTS_DEV.md as comprehensive development guide (7581877)
- [x] Rename dev workflow heading and remove TODO (342898d)

## v0.3.3 — Multi-session Support
**Goal:** Concurrent sessions and container path standardization

### Multi-session
- [x] Support multiple concurrent sessions with background container (8c2e62f)

### Container Paths
- [x] Standardize paths using fixed /workspace mount point (e745812)
- [x] Correct config paths and support non-interactive stdin (b439476)
- [x] Return to PWD-based volume mounts for path resolution (cc838c6)

## v0.3.2 — Configuration & Prompts
**Goal:** Structured prompts, MCP configs, and container improvements

### Prompts
- [x] Adopt structured 6-section agents.md template (96acb5a)
- [x] Add comprehensive ignore file generation instructions (bf9c0b9)
- [x] Simplify permissions model and add environment context (a4e8578)
- [x] Document dev user and fix cross-file path references (763bb10)

### Configuration
- [x] Reorganize config and prompt directories for clarity (e8cfd82)
- [x] Separate MCP server configs for easier maintenance (ef37b82)
- [x] Upgrade default model to qwen3.6-plus-free (8140769)

### Container
- [x] Mount user package manager configurations (9f66f89)
- [x] Create .config directory before mounting user configs (f4c4a6a)

### Fixes
- [x] Handle array expansion and command failures in strict mode (f3b6164)
- [x] Use symlinks for skills and ensure .opencode/ is ignored (1f63c4f)

## v0.3.1 — Error Handling Fixes
**Goal:** Resolve strict mode issues and simplify attach

### Fixes
- [x] Resolve issues introduced by strict error handling (d660890)
- [x] Simplify opencode invocation by removing temp file indirection (69d3222)
- [x] Simplify attach with shallow clone approach (2bc6618)
- [x] Track correct upstream branch (develop) (a391460)

## v0.3.0 — Build & Attach System
**Goal:** Robust build process with version checking and attach recovery

### Build
- [x] Add OpenCode version checking and auto-rebuild (ca5b76a)

### Attach
- [x] Add broken gitlink detection and recovery (9fea5de)

### Error Handling
- [x] Add bash version check and port argument validation (c683c50)
- [x] Implement robust error handling with strict mode (8921007)

### Agent Management
- [x] Update docs and status for cloned agent model (4e38d8a)
- [x] Consolidate docker flags and prioritize agent Dockerfile (79a5a43)

## v0.2.2 — Command Improvements
**Goal:** Enhance command system and mtui logic

### Commands
- [x] Prioritize project-specific commands from agents.md (95987bf)

### CLI Refinement
- [x] Simplify templates and consolidate mtui logic (eac59e8)

## v0.2.1 — Framework Initialization
**Goal:** Initialize multitui framework project structure

### Project Structure
- [x] Initialize multitui framework project structure (47a1f98)
- [x] Prioritize project-specific commands from agents.md (95987bf)
- [x] Simplify templates and consolidate mtui logic (eac59e8)

## v0.2.0 — Bootstrap & CLI
**Goal:** Customizable bootstrap and standalone mtui CLI

### Bootstrap
- [x] Accept custom user instructions during initialization (1ede762)
- [x] Track agent integration tasks in TODO (4e36777)

### CLI
- [x] Create standalone mtui script with external templates (9412dbb)
- [x] Consolidate shell functions into standalone mtui script (8766a6e)
- [x] Remove delegation pattern and consolidate helpers (17c883d)

## v0.1.1 — Documentation & Cleanup
**Goal:** Document execution model and remove dead code

### Documentation
- [x] Document Docker container execution model in AGENTS.md (5fae31a)

### Cleanup
- [x] Remove dead code and unused variables from scripts (0b65378)

## v0.1.0 — Initial Foundation
**Goal:** Establish core framework with AI model gateway and configurable defaults

### API & Model
- [x] Add initial command templates and skill definitions (a75d52f)
- [x] Migrate from Anthropic to OpenRouter as model gateway (b4245e2)
- [x] Introduce configurable default model for OpenCode (95e57a8)

### Dockerfile & Runtime
- [x] Include OpenCode binary directory in PATH (b77d20b)
