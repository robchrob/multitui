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

- `release` — Validate that all tasks for the **active version** are `[x]` or `[>]`. Fails and lists every blocking item if any are `[ ]`, `[~]`, or `[!]`. On success: append an entry to changelog.md → mark done tasks.md → mark done plan.md → advance the internal pointer to the next version in the session. When SESSION_TARGET is the version just released, the session closes.

---

## Error States
| Situation | Correct behaviour |
|-----------|-------------------|
| `magic init` called while a session is open | Refuse. Show current SESSION_CURRENT → SESSION_TARGET. Require `magic init --reset ...` to explicitly abandon. |
| `start <version>` targeting a version outside the session range | Refuse. Only versions within SESSION_CURRENT → SESSION_TARGET are valid. |
| `release` with any `[ ]`, `[~]`, or `[!]` tasks remaining | Refuse. List every blocking item explicitly. |
| Context lost / fresh conversation | Re-derive session from the header block in plan.md + tasks.md before executing any command. Never proceed without confirming the session scope. |
| plan.md looks like a second tasks.md (no prose, only checkboxes) | This is a protocol violation. plan.md must have narrative sections. Rewrite before proceeding. |

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
