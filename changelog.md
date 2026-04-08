# Changelog

## v0.2.1 — 2026-04-08 [MINOR]
### Added
- New fix-commit-msg.md command for auditing and fixing commit messages to comply with Conventional Commits
- Update magic versioning skill to support manual workflow where git tags serve as source of truth

### Fixed
- Generalized prompts for generic project discovery (was overly tuned for JS/Python stacks)

## v0.2.0 — 2026-04-07 [MINOR]
### Added
- Magic versioning protocol with narrative-first planning

### Changed (Breaking)
- Replace hardcoded "develop" with dynamic branch base via MTUI_BRANCH

### Fixed
- Remove dead code and streamline status output

### Documentation
- Populate magic versioning documents with historical data
- Overhaul README with structured feature and plugin documentation

## v0.1.9 — 2026-04-07 [MINOR]
### Added
- Quota management plugin (@slkiser/opencode-quota)
- Rate limit and retry plugin (@bdliyq/opencode-rate-limit-retry)
- Session contract and semver 2.0 to magic versioning skill

## v0.1.8 — 2026-04-06 [MINOR]
### Added
- Isolated development with project branches (branch create/status/update commands)
- Runtime isolation with dedicated writable directories under /workspace
- Autonomous execution rules and safety checks (SYSTEM DIRECTIVE)

### Changed
- Switch default model to stepfun/step-3.5-flash:free
- Simplify Dockerfile lookup to check project root directly
- Enhance README with workflow documentation and mtui configurability

## v0.1.7 — 2026-04-06 [MINOR]
### Added
- Batch commit message rewriting command
- SHA-based file mapping for scalability

### Changed
- Enhance update-readme with diff audit for accurate docs

## v0.1.6 — 2026-04-06 [MINOR]
### Added
- Update-readme command with diff audit
- Caveman skill for ultra-compressed communication
- License file (MIT)
- README auto-update capability
- Reusable e2e test helper libraries

### Changed
- Reorganize README and clarify user capabilities in prompts
- Overhaul MCP documentation and restructure README

### Fixed
- Clarify when to read AGENTS_DEV.md vs AGENTS.md
- Add temporal context (year 2026) to prompts
- Improve prompts for precise project discovery and testing

## v0.1.5 — 2026-04-05 [MINOR]
### Added
- Comprehensive e2e test harness for mtui CLI
- Shared assertion library for test consolidation
- Centralized image build and test artifact management
- Parallelized AI calls in tests

### Changed
- Rewrite AGENTS_DEV.md as comprehensive development guide

## v0.1.4 — 2026-04-05 [PATCH]
### Added
- Multiple concurrent sessions support via background container

### Fixed
- Standardize container paths using fixed /workspace mount point
- Correct config paths and support non-interactive stdin in docker-exec
- Return to PWD-based volume mounts for path resolution

## v0.1.3 — 2026-04-05 [MINOR]
### Added
- OpenCode version checking and auto-rebuild on build
- Broken gitlink detection and recovery in attach command

### Changed
- Implement robust error handling with strict mode
- Consolidate docker flags and prioritize agent Dockerfile
- Simplify opencode invocation by removing temp file indirection
- Simplify attach with shallow clone approach
- Update docs and status for cloned agent model

### Fixed
- Resolve issues introduced by strict error handling
- Add bash version check and port argument validation
- Track correct upstream branch (develop)

## v0.1.2 — 2026-04-05 [PATCH]
### Added
- Initialize multitui framework project structure
- Structured 6-section agents.md template
- Comprehensive ignore file generation instructions

### Changed
- Reorganize config and prompt directories for clarity
- Separate MCP server configs for easier maintenance
- Upgrade default model to qwen3.6-plus-free

### Fixed
- Use symlinks for skills and ensure .opencode/ is ignored
- Simplify permissions model and add environment context
- Document dev user and fix cross-file path references
- Mount user package manager configurations into container
- Create .config directory before mounting user configs
- Handle array expansion and command failures in strict mode

## v0.1.1 — 2026-04-05 [PATCH]
### Changed
- Prioritize project-specific commands from agents.md
- Simplify templates and consolidate mtui logic
- Create standalone mtui script with external templates
- Consolidate shell functions into standalone mtui script
- Remove delegation pattern and consolidate helpers

## v0.1.0 — 2026-04-05 [MINOR]
### Added
- Standalone mtui CLI script with external templates
- Custom user instructions support during bootstrap initialization
- Agent integration tracking in TODO

### Fixed
- Document Docker container execution model in AGENTS.md
- Remove dead code and unused variables from scripts

## v0.0.3 — 2026-04-05 [PATCH]
### Fixed
- Include OpenCode binary directory in PATH in Dockerfile
- Ensure configured model is passed to all invocations
- Update default model and improve test output management

## v0.0.2 — 2026-04-04 [PATCH]
### Added
- Configurable default model for OpenCode

## v0.0.1 — 2026-04-04 [MINOR]
### Changed (Breaking)
- Migrate from Anthropic to OpenRouter as model gateway

## v0.0.0 — 2026-04-04 [MINOR]
### Added
- Initial command templates and skill definitions
