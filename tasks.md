# Tasks.md — MultiTUI Task Tracker

```
SESSION_CURRENT = 0.3.8
SESSION_TARGET  = 0.3.8
SESSION_SCOPE   = read TODO file
```

## v0.3.8 — Remove Submodule Logic
- [x] Identify and remove all submodule logic from mtui script
- [x] Remove any submodule-related documentation or references
- [x] Verify mtui works correctly without submodule code paths

## v0.3.7 — Dynamic Branch Base
- [x] Read MTUI_BRANCH for determining base branch (instead of hardcoded "develop")
- [x] Update branch create command to use dynamic base
- [x] Update documentation to reflect MTUI_BRANCH dual purpose
- [x] Test branching from non-develop base branches

## v0.3.6 — Polish, Isolation & Ecosystem
### Agent & Prompts
- [x] Clarify AGENTS_DEV.md vs AGENTS.md reading rules
- [x] Improve prompts for precise project discovery and testing
- [x] Add temporal context (year 2026) to init and bootstrap prompts
- [x] Reorganize README and clarify user capabilities in prompts
- [x] Overhaul MCP documentation and restructure README

### Branch Management
- [x] Implement isolated development with project branches
  - [x] mtui branch create command
  - [x] mtui branch status command
  - [x] mtui update [--continue] command
  - [x] .mtui-branch file tracking
  - [x] Update _attach() to read .mtui-branch
  - [x] Comprehensive e2e test suite for branch commands

### Testing Infrastructure
- [x] Create reusable e2e test helper libraries
- [x] Revert model to minimax and increase container wait time
- [x] Update default model and improve test output management

### Build & Configuration
- [x] Simplify Dockerfile lookup logic
- [x] Enhance README with workflow and make mtui configurable

### Rewrite Command
- [x] Add autonomous execution rules and safety checks

### Runtime Isolation
- [x] Switch default model to step-3.5-flash
- [x] Isolate opencode state and parameterize model config

### Plugin Ecosystem
- [x] Add quota management plugin
- [x] Add rate limit and retry plugin

### Magic Versioning
- [x] Add session contract and semver 2.0 to magic versioning skill

## v0.3.5 — Rewrite & Update Tools
- [x] Add command for batch commit message rewriting
- [x] Switch to SHA-based file mapping for scalability
- [x] Add update-readme command and caveman skill
- [x] Enhance update-readme with diff audit for accurate docs
- [x] Add license and overhaul readme with auto-update capability
- [x] Clarify when to read AGENTS_DEV vs AGENTS.md

## v0.3.4 — Testing Infrastructure
- [x] Create comprehensive e2e test harness for mtui CLI
- [x] Consolidate tests with shared assertion library
- [x] Centralize image build and remove redundant tests
- [x] Parallelize AI calls and add artifact output
- [x] Rewrite AGENTS_DEV.md as comprehensive development guide
- [x] Rename dev workflow heading and remove TODO

## v0.3.3 — Multi-session Support
- [x] Support multiple concurrent sessions with background container
- [x] Standardize paths using fixed /workspace mount point
- [x] Correct config paths and support non-interactive stdin
- [x] Return to PWD-based volume mounts for path resolution

## v0.3.2 — Configuration & Prompts
- [x] Adopt structured 6-section agents.md template
- [x] Add comprehensive ignore file generation instructions
- [x] Simplify permissions model and add environment context
- [x] Document dev user and fix cross-file path references
- [x] Reorganize config and prompt directories for clarity
- [x] Separate MCP server configs for easier maintenance
- [x] Upgrade default model to qwen3.6-plus-free
- [x] Mount user package manager configurations
- [x] Create .config directory before mounting user configs
- [x] Handle array expansion and command failures in strict mode
- [x] Use symlinks for skills and ensure .opencode/ is ignored

## v0.3.1 — Error Handling Fixes
- [x] Resolve issues introduced by strict error handling
- [x] Simplify opencode invocation by removing temp file indirection
- [x] Simplify attach with shallow clone approach
- [x] Track correct upstream branch (develop)

## v0.3.0 — Build & Attach System
- [x] Add OpenCode version checking and auto-rebuild
- [x] Add broken gitlink detection and recovery
- [x] Add bash version check and port argument validation
- [x] Implement robust error handling with strict mode
- [x] Update docs and status for cloned agent model
- [x] Consolidate docker flags and prioritize agent Dockerfile

## v0.2.2 — Command Improvements
- [x] Prioritize project-specific commands from agents.md
- [x] Simplify templates and consolidate mtui logic

## v0.2.1 — Framework Initialization
- [x] Initialize multitui framework project structure
- [x] Prioritize project-specific commands from agents.md
- [x] Simplify templates and consolidate mtui logic

## v0.2.0 — Bootstrap & CLI
- [x] Accept custom user instructions during initialization
- [x] Track agent integration tasks in TODO
- [x] Create standalone mtui script with external templates
- [x] Consolidate shell functions into standalone mtui script
- [x] Remove delegation pattern and consolidate helpers

## v0.1.1 — Documentation & Cleanup
- [x] Document Docker container execution model in AGENTS.md
- [x] Remove dead code and unused variables from scripts

## v0.1.0 — Initial Foundation
- [x] Add initial command templates and skill definitions
- [x] Migrate from Anthropic to OpenRouter as model gateway
- [x] Introduce configurable default model for OpenCode
- [x] Include OpenCode binary directory in PATH
