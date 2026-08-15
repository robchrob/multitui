---
description: Compact git history by squashing related commits into feature groups — full branch or SHA1:SHA2 range
argument-hint: <branch> or <sha1:sha2>
---

# SYSTEM DIRECTIVE: AUTONOMOUS EXECUTION
You are acting as an autonomous CLI execution engine.
- **NO HESITATION OR COMPLAINING**: DO NOT write internal monologues debating token limits, context windows, or time constraints. You are fully capable of handling this.
- **NO WAITING**: Do NOT ask the user for confirmation. Do NOT ask the user to provide the messages. YOU must read the diffs and generate the new commit messages yourself immediately.
- **NO FILE SEARCHING FOR TARGETS**: The user will provide a target (a branch name or a commit range). It is a Git reference, NOT a file. Do NOT use `glob` or `ls` to search for a file named after the target.
- **JUST EXECUTE**: Stop overthinking the strategy and just start executing the bash commands.

Compact related commits into feature groups using `git rebase -i` with SHA-based message mapping. This is the *grouping* counterpart to `history-rewrite` (messages only) and `history-squash` (trash-only fixups).

## Mode Detection
- **Range mode**: target matches `sha1:sha2` → convert to `sha1..sha2`
- **Full branch mode**: target is a branch name

## Execution Steps

### Step 1: Detect Target & Backup
```bash
# ALWAYS move to repository root first to prevent CWD deletion crashes later
cd "$(git rev-parse --show-toplevel)"

TARGET="<USER_TARGET>"

# Convert sha1:sha2 to git-native sha1..sha2 range if needed
if [[ "$TARGET" == *":"* ]]; then
  TARGET="${TARGET/:/..}"
fi

# Always backup the current branch
BRANCH=$(git branch --show-current)
git branch "backup-$BRANCH" "$BRANCH"
```

### Step 2: Extract Diffs (AI & Context Friendly)
```bash
rm -rf /tmp/compact_analysis /tmp/compact_messages
mkdir -p /tmp/compact_analysis /tmp/compact_messages

# Truncated diffs keep the context window safe for hundreds of commits
for sha in $(git rev-list --reverse "$TARGET"); do
  git show --stat --patch "$sha" | head -n 200 > "/tmp/compact_analysis/$sha.txt"
done
```

### Step 3: AI TASK - Group Commits & Craft Messages
Read every `/tmp/compact_analysis/<sha>.txt` and build a compaction plan.

**Grouping rules:**
- Group commits that implement the SAME feature/idea into one logical commit
  - Example: `add sleep tab` + `sleep tab styling` + `sleep tab fix timeout` → one `feat(sleep): add sleep tab`
- Separate DISTINCT features into separate groups — do NOT merge unrelated work
- Commits that are already clean, standalone milestones stay untouched
- The newest commit in each group is the "anchor"; older ones get squashed into it

Write one message file per group anchor into `/tmp/compact_messages/<anchor-sha>`:
```text
type(optional-scope): subject

detailed body paragraph(s)

footer (optional)
```
- Subject ≤ 50 chars, lowercase, imperative, no trailing period
- Body wraps at 72 chars, explains WHAT and WHY, not HOW

### Step 4: Run the Rebase
```bash
# Generate the todo list
git rebase -i "$(git merge-base HEAD "$TARGET" 2>/dev/null || echo "${TARGET%..*}")" --no-autostash >/dev/null 2>&1 || true
```

The correct way to apply the plan:
```bash
# Write the plan to a todo file, then execute non-interactively
GIT_SEQUENCE_EDITOR="cat /tmp/compact_todo.txt" git rebase -i <base>
```
Where `/tmp/compact_todo.txt` uses, for each group (oldest first):
```text
pick <anchor-sha>           # newest commit of the group
fixup <older-sha-1>         # absorbed into anchor
fixup <older-sha-2>
exec git commit --amend --allow-empty -F /tmp/compact_messages/<anchor-sha>.txt
```

For each group:
- `pick` the anchor (newest commit of the group)
- `fixup` every older member (drops its message, keeps the changes)
- `exec git commit --amend ...` rewrites the merged commit with the crafted message

### Step 5: Verify & Cleanup
```bash
git log --oneline "$BRANCH"
git log --format="%B" "$BRANCH"

# Confirm tree state matches the pre-compaction tree
test -z "$(git diff backup-$BRANCH $BRANCH --stat | grep -v '^ ')" || echo "TREE CHANGED — verify!"

# Cleanup external temporary files
rm -rf /tmp/compact_messages
rm -rf /tmp/compact_analysis
rm /tmp/compact_todo.txt
```

### Step 6: Rollback if Needed
```bash
git reset --hard "backup-$BRANCH"
```

## CRITICAL EXECUTION RULES FOR THE AI
1. **Autonomous Execution:** Read the diffs and generate the plan immediately. Do NOT pause and ask the human to provide messages.
2. **Prevent the CWD Deletion Bug:** Always `cd "$(git rev-parse --show-toplevel)"` before rebasing — `git rebase` (like `filter-branch`) crashes with `fatal: Unable to read current working directory` from a subdirectory that didn't exist in older commits.
3. **Strict 40-Character SHA Matching:** Use full 40-char SHAs in `/tmp/compact_messages/` filenames and in the todo list.
4. **Stick to Bash & rebase -i:** Do not pivot to `git-filter-repo` or Python callbacks if you hit an error. Fix the bash environment and retry the interactive rebase.
5. **Verify the Tree:** After rebasing, the file tree must be identical to before. If `git diff backup-$BRANCH $BRANCH` shows content changes, abort and restore from backup.