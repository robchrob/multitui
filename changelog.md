# Changelog

## v0.3.8 — 2026-04-07 [MINOR]
### Changed (Breaking)
- Removed all submodule logic from `_attach()` (`.git/modules/agent` cleanup, `git config --remove-section submodule.agent`)
- Updated prompt templates to reference `agent/ directory` instead of `agent/ submodule`

## v0.3.7 — 2026-04-07 [MINOR]
### Added
- Dynamic branch base: `MTUI_BRANCH` env var now controls the base branch for `branch create` instead of hardcoded "develop"
- Branch naming uses `$REMOTE_BRANCH` prefix (e.g., `custom-base-projectname`)

### Changed
- All log messages and help text reference `$REMOTE_BRANCH` instead of hardcoded "develop"
- `branch create` prefix derived from `$REMOTE_BRANCH` instead of literal "develop"

## v0.3.6 — 2026-04-07 [PATCH]
### Added
- Quota management plugin (@slkiser/opencode-quota) for token/budget tracking
- Rate limit and retry plugin (@bdliyq/opencode-rate-limit-retry) for API resilience
- Reusable e2e test helper libraries (docker, fixtures, mtui, opencode, test_helpers)
- Isolated development with project branches (branch create/status/update commands)
- Session contract and semver 2.0 to magic versioning skill

### Changed
- Switch default model to stepfun/step-3.5-flash:free
- Isolate opencode state with dedicated writable directories under /workspace
- Parameterize model config via {env:MTUI_MODEL} in opencode.json
- Simplify Dockerfile lookup to check project root directly
- Enhance README with workflow documentation and mtui configurability
- Add autonomous execution rules and safety checks to rewrite-history command
- Improve prompts for precise project discovery and testing
- Reorganize README structure and clarify user capabilities in prompts
- Overhaul MCP documentation and restructure README

### Fixed
- Clarify when to read AGENTS_DEV.md vs AGENTS.md
- Add temporal context (year 2026) to init and bootstrap prompts
- Revert model to minimax and increase container wait time for test stability
- Remove stale GitHub MCP configuration causing failures

## v0.3.5 — 2026-04-06 [PATCH]
### Added
- Update-readme command with diff audit for accurate documentation
- Caveman skill for ultra-compressed communication
- License file (MIT)
- README overhaul with auto-update capability

### Fixed
- Clarify DEVMODE execution rules in AGENTS.md

## v0.3.4 — 2026-04-05 [PATCH]
### Added
- Comprehensive e2e test harness for mtui CLI
- Shared assertion library for test consolidation
- Centralized image build and test artifact management
- Parallelized AI calls in tests

### Changed
- Rewrite AGENTS_DEV.md as comprehensive development guide
- Streamline test suites with shared utilities

## v0.3.3 — 2026-04-05 [PATCH]
### Added
- Multiple concurrent sessions support via background container

### Fixed
- Standardize container paths using fixed /workspace mount point
- Correct config paths and support non-interactive stdin in docker-exec
- Return to PWD-based volume mounts for path resolution

## v0.3.2 — 2026-04-05 [PATCH]
### Added
- Structured 6-section agents.md template
- Comprehensive ignore file generation instructions
- Mount user package manager configurations into container

### Changed
- Reorganize config and prompt directories for clarity
- Separate MCP server configs for easier maintenance (then reverted to inline)
- Upgrade default model to qwen3.6-plus-free

### Fixed
- Create .config directory before mounting user configs
- Handle array expansion and command failures in strict mode
- Document dev user and fix cross-file path references
- Use symlinks for skills and ensure .opencode/ is ignored

## v0.3.1 — 2026-04-05 [PATCH]
### Fixed
- Resolve issues introduced by strict error handling
- Simplify opencode invocation by removing temp file indirection
- Simplify attach with shallow clone approach
- Track correct upstream branch (develop)

## v0.3.0 — 2026-04-05 [MINOR]
### Added
- OpenCode version checking and auto-rebuild on build
- Broken gitlink detection and recovery in attach command
- Bash version check and port argument validation

### Changed
- Implement robust error handling with strict mode
- Simplify with shallow clone approach for attach
- Update docs and status for cloned agent model
- Consolidate docker flags and prioritize agent Dockerfile

## v0.2.2 — 2026-04-05 [PATCH]
### Changed
- Prioritize project-specific commands from agents.md
- Simplify templates and consolidate mtui logic

## v0.2.1 — 2026-04-05 [PATCH]
### Added
- Initialize multitui framework project structure

### Changed
- Remove delegation pattern and consolidate helpers
- Consolidate shell functions into standalone mtui script

## v0.2.0 — 2026-04-05 [MINOR]
### Added
- Standalone mtui CLI script with external templates
- Custom user instructions support during bootstrap initialization
- Agent integration tracking in TODO

### Changed
- Remove dead code and unused variables from scripts
- Document Docker container execution model in AGENTS.md

## v0.1.1 — 2026-04-05 [PATCH]
### Fixed
- Include OpenCode binary directory in PATH in Dockerfile
- Ensure configured model is passed to all invocations

## v0.1.0 — 2026-04-05 [MINOR]
### Added
- Initial command templates and skill definitions
- Configurable default model for OpenCode

### Changed (Breaking)
- Migrate from Anthropic to OpenRouter as model gateway
