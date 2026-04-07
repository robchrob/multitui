# Tasks.md — MultiTUI Task Tracker

```
SESSION_CURRENT = 0.0.0
SESSION_TARGET  = 0.2.0
SESSION_SCOPE   = Restructure versioning with more granular versions
```

## v0.2.0 — Magic Versioning Protocol
- [x] Redefine magic versioning protocol with narrative-first planning
- [x] Replace hardcoded develop with dynamic branch base via MTUI_BRANCH
- [x] Remove dead code and streamline status output
- [x] Populate magic versioning documents with historical data
- [x] Overhaul README with structured feature and plugin documentation

## v0.1.9 — Plugin Ecosystem
- [x] Add quota management plugin
- [x] Add rate limit and retry plugin
- [x] Add session contract and semver 2.0 to magic versioning skill

## v0.1.8 — Branch Management & Runtime Isolation
- [x] Implement isolated development with project branches
  - [x] mtui branch create command
  - [x] mtui branch status command
  - [x] mtui update [--continue] command
  - [x] .mtui-branch file tracking
  - [x] Update _attach() to read .mtui-branch
- [x] Isolate opencode state with dedicated writable directories
- [x] Parameterize model config via {env:MTUI_MODEL}
- [x] Switch default model to step-3.5-flash
- [x] Simplify Dockerfile lookup logic
- [x] Add autonomous execution rules and safety checks

## v0.1.7 — Rewrite Command
- [x] Add command for batch commit message rewriting
- [x] Switch to SHA-based file mapping for scalability
- [x] Enhance update-readme with diff audit

## v0.1.6 — Update-Readme & License
- [x] Add update-readme command and caveman skill
- [x] Add license and overhaul readme with auto-update capability
- [x] Reorganize readme and clarify user capabilities in prompts
- [x] Overhaul mcp documentation and restructure readme
- [x] Clarify when to read AGENTS_DEV.md vs AGENTS.md
- [x] Add temporal context for year 2026
- [x] Create reusable e2e test helper libraries
- [x] Improve prompts for precise project discovery and testing

## v0.1.5 — Testing Infrastructure
- [x] Create comprehensive e2e test harness for mtui CLI
- [x] Consolidate tests with shared assertion library
- [x] Centralize image build and remove redundant tests
- [x] Parallelize AI calls and add artifact output
- [x] Rewrite AGENTS_DEV.md as comprehensive development guide
- [x] Rename dev workflow heading and remove TODO

## v0.1.4 — Multi-session Support
- [x] Support multiple concurrent sessions with background container
- [x] Standardize paths using fixed /workspace mount point
- [x] Correct config paths and support non-interactive stdin
- [x] Return to PWD-based volume mounts for path resolution

## v0.1.3 — Build & Attach System
- [x] Add OpenCode version checking and auto-rebuild
- [x] Add broken gitlink detection and recovery
- [x] Implement robust error handling with strict mode
- [x] Resolve issues introduced by strict error handling
- [x] Add bash version check and port argument validation
- [x] Simplify opencode invocation by removing temp file indirection
- [x] Simplify attach with shallow clone approach
- [x] Track correct upstream branch (develop)
- [x] Update docs and status for cloned agent model
- [x] Consolidate docker flags and prioritize agent Dockerfile

## v0.1.2 — Framework Initialization
- [x] Initialize multitui framework project structure
- [x] Reorganize config and prompt directories for clarity
- [x] Use symlinks for skills and ensure .opencode/ is ignored
- [x] Adopt structured 6-section agents.md template
- [x] Add comprehensive ignore file generation instructions
- [x] Simplify permissions model and add environment context
- [x] Document dev user and fix cross-file path references
- [x] Separate MCP server configs for easier maintenance
- [x] Upgrade default model to qwen3.6-plus-free
- [x] Mount user package manager configurations
- [x] Create .config directory before mounting user configs
- [x] Handle array expansion and command failures in strict mode

## v0.1.1 — CLI & Commands
- [x] Prioritize project-specific commands from agents.md
- [x] Simplify templates and consolidate mtui logic
- [x] Create standalone mtui script with external templates
- [x] Consolidate shell functions into standalone mtui script
- [x] Remove delegation pattern and consolidate helpers

## v0.1.0 — Bootstrap & Foundation
- [x] Accept custom user instructions during initialization
- [x] Track agent integration tasks in TODO
- [x] Document Docker container execution model
- [x] Remove dead code and unused variables

## v0.0.3 — Dockerfile & Model
- [x] Include OpenCode binary directory in PATH
- [x] Ensure configured model is passed to all invocations
- [x] Update default model and improve test output management

## v0.0.2 — Configurable Model
- [x] Introduce configurable default model for OpenCode

## v0.0.1 — API Migration
- [x] Migrate from Anthropic to OpenRouter as model gateway

## v0.0.0 — Project Inception
- [x] Add initial command templates and skill definitions
