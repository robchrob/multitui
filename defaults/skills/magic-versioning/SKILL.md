---
name: magic-versioning
description: Manage projects with plan.md (roadmap), tasks.md (active work), changelog.md (history). Trigger with "magic" prefix.
---

# Magic Versioning Protocol
Boutique Synchronize three documents for milestone-based project management.

## Documents
**plan.md** - Very detailed and indepth version roadmap with implementation specifics
**tasks.md** - Task tracker with progress markers for all versions
**changelog.md** - Completed releases (append-only)

## Commands
Prefix with `magic` (e.g., `magic init`, `magic status`)

- `init <current> <target> <objectives>` - Analyze project, incorporate existing deferred items, create versioned milestones (feature complete, atomic and with clear definition of done), generate/update all three files. DO NOT START WORK, ONLY CREATE FULL DETAILED PLAN and TASKS!
- `start [next|<version>]` - Begin work on next or specified version
- `status` - Show progress and blockers
- `adjust` - Modify plan.md and tasks.md (add/edit versions, tasks)
- `release` - Validate all [x] or [>], fail if any [ ], [~], [!] → append changelog.md → clear tasks.md → clear plan.md (keep deferred beyond target)

## Versioning Strategy
When splitting <current> → <target>:
- Analyze objectives, decompose into atomic tasks
- Group tasks by dependency and logical cohesion
- Each version must be independently shippable
- Determine version count based on scope complexity
- Balance: too few = risky releases, too many = overhead
- Version numbering reflects semantic weight of changes

## During Work
- Update markers immediately
- Add subtasks as discovered
- Deferred `[>]`: add to plan.md AND tasks.md under future version

## Task Markers
`[ ]` pending · `[~]` in progress · `[x]` done · `[!]` blocked (reason) · `[>]` deferred → vX.X.X

## Task Format
```
## v0.2.0 - Goal
- [x] Deliverable 1
- [~] Deliverable 2
  - [x] Subtask A
  - [ ] Subtask B
- [!] Deliverable 3 (blocked: reason)
- [>] Deliverable 4 → v0.3.0
```

## Principles
- One active version at a time
- plan.md = reference, tasks.md = live state
- Release when all planned versions complete
