---
name: magic-versioning
description: Manage projects with plan.md (design narrative), tasks.md (live work tracker), changelog.md (history). Trigger with "magic" prefix.
---

# Magic Versioning Protocol
Synchronize three documents for milestone-based project management using Semantic Versioning 2.0.0 in perpetual 0.x mode.

## Documents

**plan.md** — The *why and how*. A verbose design document and roadmap. Each version gets a narrative section: goals, motivation, constraints, architectural decisions, tradeoffs considered, and approach. Prose-first. An engineer reading plan.md should understand what is being built and why — not just what to check off. plan.md is the source of truth that tasks.md is derived from.

**tasks.md** — The *what, right now*. A flat, live checkbox list derived from plan.md. Atomic work items only. Tracks real-time execution state with markers. No prose, no rationale — just the work and its status.

**changelog.md** — Completed releases. Append-only, newest first. What actually shipped.

---

## The plan.md / tasks.md Distinction

This is the most important structural rule in the protocol.

**plan.md is a design document, not a task mirror.** Each version section must include:
- **Goal** — One or two sentences: what this version accomplishes and why it matters now
- **Motivation** — What problem or gap this addresses; why this version exists
- **Approach** — How the work will be done: architecture decisions, patterns chosen, key constraints
- **Tradeoffs** — What alternatives were considered and rejected, and why
- **Definition of Done** — What "complete" looks like for this version
- **Tasks** — A structured list of deliverables (these become tasks.md entries)

plan.md sections are narrative and may be long. A version with three tasks might still have three paragraphs of design rationale above them. That's correct — the rationale is the point.

**tasks.md contains only the task list.** No motivation, no rationale, no prose. Just the atomic items and their live state. When you need to know *why* something is being done, you read plan.md. When you need to know *what state the work is in*, you read tasks.md.

---

## Session Contract
`magic init` opens a **versioning session**. A session is defined by three values burned in at init time and stored as a header block in both plan.md and tasks.md:

```
SESSION_CURRENT = <current>    # version already shipped; the starting point
SESSION_TARGET  = <target>     # final version this line of work ends at
SESSION_SCOPE   = <objectives> # the stated goals; immutable reference
```

Every subsequent command (`start`, `status`, `adjust`, `release`) **operates exclusively within SESSION_CURRENT → SESSION_TARGET**. No command can reference, modify, or release versions outside this range.

A session ends only when `magic release` successfully closes SESSION_TARGET. Until then:

- `magic init` **must not be re-run** without an explicit `--reset` flag from the user. Running init again mid-session is an error, not a restart.
- All commands implicitly assume they are operating on the active session. There is no ambiguity about "which work" is active.
- **Session state is derived from the files, not from memory.** If context lost (e.g. new conversation), re-derive SESSION_CURRENT / SESSION_TARGET / SESSION_SCOPE from the header block in plan.md and tasks.md before executing any command. The session is never lost — it lives in the files.

---

## Commands
Prefix with `magic` (e.g., `magic init`, `magic status`) — this is a command in text for the model, _NOT_ a CLI tool!

- `init <current> <target> <objectives>` — Open a session. `<current>` is the last shipped version (use `0.0.0` if nothing has been released yet). `<target>` is the final version this line of work ends at. When `<current>` and `<target>` differ by more than one version, **`init` must decompose the work into multiple intermediate versions** — each independently shippable, each with its own section in plan.md and tasks.md. A single-version plan for a multi-version range is always wrong. Incorporate any existing deferred items, classify each milestone as MINOR or PATCH, generate/update all three files. **plan.md gets full narrative sections per version (goal, motivation, approach, tradeoffs, definition of done, tasks). tasks.md gets only the derived checkbox list.** **DO NOT START WORK — only produce the full detailed plan and tasks.** Fails if a session is already open unless `--reset` is passed.

- `start [next|<version>]` — Begin work on the next unstarted version within the session, or on a specific version. Only versions within SESSION_CURRENT → SESSION_TARGET are valid targets. Marks the version `[~]` in tasks.md. Refuses if the specified version is outside the session range.

- `status` — Show the current session scope (SESSION_CURRENT → SESSION_TARGET), which version is active `[~]`, task-level progress, and any blockers `[!]`. Always scoped to the open session; never reports on versions outside the range.

- `adjust` — Modify plan.md and tasks.md within the session scope: add rationale, update design decisions, add subtasks, edit estimates, move tasks between versions, or defer items to a future version beyond SESSION_TARGET (marking them `[>]`). Cannot change SESSION_CURRENT or SESSION_TARGET themselves — those require `--reset`. When adding tasks, always update plan.md narrative first, then derive the tasks.md entry.

- `release <version>` — Normal flow: validate that all tasks for the **active version** are `[x]` or `[>]`. Fails and lists every blocking item if any are `[ ]`, `[~]`, or `[!]`. On success: append an entry to changelog.md → mark done tasks.md → mark done plan.md → **create git tag v<version>** → close session if SESSION_TARGET reached.

- `release <version> --infer` — Retroactive inference: use when work was done outside the normal magic versioning workflow (no init/start/tasks). See **Retroactive Inference** section below for the full algorithm.

---

## Retroactive Inference

Use `magic release <version> --infer` when work was done on the repo without following the normal magic versioning workflow (no `init`, no `start`, no task tracking). The system infers plan.md and tasks.md entries from git history, then proceeds with release.

### When to use

- You committed code without using `magic init` / `magic start`
- plan.md and tasks.md are missing or stale
- You want to "catch up" the paperwork to reflect what's already done

### The Algorithm (8 phases)

```
magic release <version> --infer
```

#### Phase 1: Read State

1. **Read git tags**: `git tag -l --sort=-v:refname` → sorted list
2. **Determine latest released version**: highest semver tag (e.g., v0.2.0)
   - If no tags exist → use root commit as boundary
3. **Read changelog.md**: get the last entry's version (for backfill detection)
4. **Read plan.md + tasks.md**: note existing version entries and session header
5. **Sanity check**: Does latest_tag version == last_changelog version?
   - MATCH → consistent
   - TAG AHEAD → use tag, note missing changelog entry
   - CHANGELOG AHEAD → use changelog, warn about missing tag

#### Phase 2: Determine Git Range

1. **since_ref** = latest tag (e.g., v0.2.0) or root commit if no tags
2. **commits** = `git log <since_ref>..HEAD --format="%h|%s|%b---COMMIT_END---"`
3. If no commits in range → FAIL: "No commits since v0.X.Y. Nothing to release."

#### Phase 3: Parse Commits

For each commit in the range:
- Extract: hash, type (feat/fix/chore/docs/refactor), scope, subject, body
- Conventional commit prefixes → type classification
- Non-prefixed commits → classify as "Changed"

#### Phase 4: Check — Is Inference Needed?

Does `<version>` already have entries in plan.md AND tasks.md?
- YES → skip to Phase 7 (only need changelog + tag)
- NO → continue to Phase 5

#### Phase 5: Infer Plan + Tasks (Fill Gaps Only)

**Generate plan.md entry** for `<version>`:
- **Goal**: Synthesized from commit subjects (1-2 sentences)
- **Motivation**: Extracted from commit bodies (the "why")
- **Approach**: Inferred from the nature of changes (scope + types)
- **Tradeoffs**: Extracted from bodies where present; omitted if not available (conservative)
- **Definition of Done**: "All commits in this version merged to main" (factual)
- **Tasks**: One `[x]` task per logical commit (group micro-commits)

**Generate tasks.md entry** for `<version>`:
- Flat `[x]` checkbox list derived from plan.md tasks
- All items marked done since work is complete

**Append** to plan.md and tasks.md (preserve existing, fill gaps only):
- Insert version entry in correct version-ordered position
- If files don't exist → create with header + entry

#### Phase 6: Update Session Header

Set in both plan.md and tasks.md:
- `SESSION_CURRENT = <version>` (since it's being released)
- `SESSION_TARGET = <version>` (session closes)
- `SESSION_SCOPE = "Retroactive: inferred from git history"`

#### Phase 7: Generate Changelog

1. **Categorize commits** into changelog sections:
   - `feat` → "Added"
   - `fix` → "Fixed"
   - `refactor` → "Changed"
   - `docs` → "Documentation"
   - `chore` → omit (internal)
   - Any type with `!` → "Changed (Breaking)"

2. **Classify bump type**:
   - Any `feat` or breaking change → [MINOR]
   - Only `fix` → [PATCH]

3. **Backfill missing entry** if tag exists but no changelog entry

4. **Prepend** entry to changelog.md (newest first)

#### Phase 8: Tag

`git tag -a v<version> -m "Release v<version>"`

Session closes. Release complete.

### Tag / Changelog Conflict Resolution

| Scenario | Resolution |
|----------|------------|
| Tag exists, no matching changelog | Backfill changelog entry, proceed with release |
| Changelog entry exists, no tag | Warn, proceed (tag will be created) |
| Both exist, consistent | Proceed normally |
| Tag v<version> already exists | FAIL — releases are immutable |

---

## Error States
| Situation | Correct behaviour |
|-----------|-------------------|
| `magic init` called while a session is open | Refuse. Show current SESSION_CURRENT → SESSION_TARGET. Require `magic init --reset ...` to explicitly abandon. |
| `start <version>` targeting a version outside the session range | Refuse. Only versions within SESSION_CURRENT → SESSION_TARGET are valid. |
| `release` with any `[ ]`, `[~]`, or `[!]` tasks remaining | Refuse. List every blocking item explicitly. |
| Context lost / fresh conversation | Re-derive session from the header block in plan.md + tasks.md before executing any command. Never proceed without confirming the session scope. |
| plan.md looks like a second tasks.md (no prose, only checkboxes) | This is a protocol violation. plan.md must have narrative sections. Rewrite before proceeding. |
| `release <version>` with stale plan.md/tasks.md | Refuse. Show which versions are missing. Suggest `--infer` flag. |
| `release <version> --infer` with no commits since last release | Refuse. "No commits found since v0.X.Y. Nothing to release." |
| `release <version> --infer` but v<version> already tagged | Refuse. "v0.X.Y already tagged. Releases are immutable — create a new version instead." |
| Changelog entry exists but no matching git tag | Warn about untagged release, proceed with release (tag will be created) |

---

## Versioning Strategy (SemVer 2.0.0 — Perpetual 0.x)
All versions follow **0.MINOR.PATCH** — MAJOR is always 0. No 1.0.0 is ever declared.

Per SemVer spec: _"Major version zero (0.y.z) is for initial development. Anything may change at any time."_

This is an intentional, permanent choice — not a sign of immaturity. It signals:

- No stability promise — API can change at any time
- Breaking changes are allowed without MAJOR bumps
- Faster iteration without compatibility burden
- Honest signaling: this software is always evolving

### Bump Rules under 0.x
| Segment | Increment when… |
|---------|----------------|
| **MINOR** `0.Y.z` | New functionality, features, or any breaking change |
| **PATCH** `0.y.Z` | Backward-compatible bug fixes only |

Breaking changes → bump MINOR (not MAJOR, since MAJOR stays 0).
Resetting: bumping MINOR resets PATCH to 0.

### When splitting `<current>` → `<target>`:
`0.0.0` is the conventional `<current>` for a project with nothing shipped yet — it is not a real version, just the starting sentinel.

The intermediate versions between `<current>` and `<target>` are the actual deliverable of `init`. The model must:

- Decompose objectives into atomic tasks
- Group tasks by dependency and logical cohesion into **multiple intermediate versions** — never collapse everything into one
- Classify each version: new functionality or any breaking change → MINOR bump; bug fixes only → PATCH bump
- Ensure each version is independently shippable with a clear definition of done
- Example: `0.0.0` → `0.1.0` (core scaffold) → `0.1.1` (bug fixes) → `0.2.0` (feature layer) → `0.3.0` (target)

### Pre-release Suffixes
Use for versions in active development not yet ready for release:
`0.2.0-alpha`, `0.2.0-beta`, `0.2.0-rc.1`

Precedence (low → high): `alpha < alpha.1 < beta < rc.1 < release`

Once released, a version's contents are **immutable** — any change requires a new version number.

---

## Git Tags

Tags are the ground truth of what has been released. Every successful release **must** produce an annotated git tag as the final step.

### Rules

- **Tag format**: v<version> (e.g., v0.3.0, v0.2.1)
- **Always annotated**: `git tag -a v<version> -m "Release v<version>"`
- **Tag is the final step**: changelog is written first, tag is created last — never the other way around
- **Existing tags are immutable**: never move, delete, or amend a tag
- **Tags take precedence over changelog**: when determining the last released version, prefer git tags as the source of truth. If a tag exists but changelog doesn't have the entry, backfill the changelog.

### Tag / Changelog Consistency

| Situation | Behaviour |
|-----------|-----------|
| Tag exists, changelog has matching entry | Consistent — proceed normally |
| Tag exists, no matching changelog entry | Use tag as truth, backfill changelog entry, warn |
| Changelog entry exists, no tag | Use changelog as truth, warn about missing tag |

---

## During Work
- Update task markers immediately as work progresses
- Add subtasks as they are discovered; always update plan.md rationale first if the scope changes
- Deferred items `[>]`: add to plan.md narrative AND tasks.md under a correctly-typed future version

---

## Task Markers
`[ ]` pending · `[~]` in progress · `[x]` done · `[!]` blocked (reason) · `[>]` deferred → v0.Y.Z

---

## plan.md Format (per version)

```markdown
## v0.3.0 — Feature Layer [MINOR]

### Goal
Add user-facing export functionality so downstream consumers can pull data without API access.

### Motivation
Three integrations are blocked on this capability. The current workaround (manual CSV pulls) is unsustainable at scale. This unblocks v0.4.0 streaming work.

### Approach
Implement a new `/export` route behind the existing auth middleware. Use streaming responses (chunked transfer) to avoid memory pressure on large datasets. Export format negotiation via `Accept` header — JSON and CSV to start.

### Tradeoffs
- Considered a background job approach (async export + download link) but ruled out: adds queue infrastructure complexity, bad UX for small exports
- CSV chosen over Parquet for now: simpler, universally supported, sufficient for current data volumes

### Definition of Done
`/export` endpoint live, auth-gated, returning correct Content-Type for JSON and CSV. Tested with datasets up to 100k rows. Documented in README.

### Tasks
- [ ] Add `/export` route to router
- [ ] Implement JSON serializer with streaming support
- [ ] Implement CSV serializer with streaming support
- [ ] Wire Accept header negotiation
- [ ] Auth middleware integration test
- [ ] README export section
```

---

## tasks.md Format (per version)

```markdown
## v0.3.0 — Feature Layer [MINOR]
- [ ] Add `/export` route to router
- [~] Implement JSON serializer with streaming support
  - [x] Basic serializer
  - [ ] Streaming support
- [ ] Implement CSV serializer with streaming support
- [ ] Wire Accept header negotiation
- [!] Auth middleware integration test (blocked: staging env down)
- [ ] README export section
```

---

## Changelog Format

```markdown
## v0.3.0 — 2026-04-06 [MINOR]
### Added
- New export functionality (`/export` endpoint, JSON + CSV)
### Changed (Breaking)
- Renamed config keys (breaking — allowed freely under 0.x)

## v0.2.1 — 2026-03-15 [PATCH]
### Fixed
- Null pointer in auth middleware
```

---

## Principles
- plan.md is a design document first, task list second
- tasks.md is derived from plan.md — never the other way around
- One active version at a time
- MAJOR is always 0 — this is the contract
- MINOR = new or breaking; PATCH = fix only
- Pre-release suffixes signal in-progress work; drop them on stable release
- Release when all planned versions within the session are complete
- **The session is the unit of work** — init opens it, release closes it, everything else operates inside it
- **Tags are the final step of every release** — changelog first, then tag. Tags are the ground truth.
- **Retroactive inference is an escape hatch**, not the primary workflow. If `--infer` is used frequently, adopt the normal init/start/release flow instead.
- **Inferred narratives are only as good as commit messages** — sparse commits produce thin plans. Write meaningful commit messages to get useful inferred documentation.
