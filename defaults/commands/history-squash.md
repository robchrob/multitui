---
description: Compact and rewrite git history by squashing ONLY iterative "trash" commits — full branch or SHA1:SHA2 range
argument-hint: <branch> or <sha1:sha2>
---

# SYSTEM DIRECTIVE: AUTONOMOUS EXECUTION
You are acting as an autonomous CLI execution engine.
- **NO WAITING**: Do NOT ask the user for confirmation.
- **JUST EXECUTE**: Stop overthinking the strategy and just start executing the bash commands.

Your objective is to clean up a "stream of consciousness" git history. You will identify iterative "trash" commits (typos, fixes, broken states) and squash them upward. **YOU MUST STRICTLY PRESERVE THE GRANULARITY OF THE HISTORY.**

## THE "TRASH-ONLY" SQUASHING ALGORITHM
**CRITICAL RULE: DO NOT GROUP BY MODULE.**
Your goal is NOT to group everything touching "Finance" into one commit. Your goal is to erase the *developer's struggle* while preserving every distinct *milestone*.

To achieve this, evaluate every commit using this algorithm:

### 1. Is it a Substantive Milestone? -> `pick`
Does the commit introduce a new component, a new configuration, a distinct refactor step, or a new logical idea?
- Examples: `add sleep tab`, `move to vinext`, `finview simpler`, `zoomed sparklines`, `before diet rework`.
- **Action:** KEEP IT AS A `pick`. Do NOT squash these together. If a developer built 5 distinct features in the Finance module, there MUST be 5 separate `pick` commits.

### 2. Is it a "Trash" / Iterative Commit? -> `fixup`
Does the commit exist merely because the developer didn't get the previous commit right the first time?
Look for these heuristics:
- **Vague/Short Messages:** `< 3 words` (e.g., `update`, `fixes`, `import`, `spacing`, `units`).
- **Struggle/Emotive Words:** `broken`, `still bad`, `idk`, `fked up`, `finally`, `dieeet`, `nice`.
- **Tweaks/Polish:** Minor adjustments to the immediate predecessor (`ui changes`, `faster sparklines`, `slightly less broken`).
- **Action:** Use `fixup` to absorb this commit into the *most recent* `pick` commit.

### 3. SIMULATION OF A CORRECT SQUASH PLAN
If you see this history (oldest to newest):
```text
1. df43e81 sparkline finview           <-- Substantive Milestone
2. 19f4a91 sparklines broken           <-- Trash (Struggle)
3. af7862e fixes                       <-- Trash (Struggle)
4. 76cab31 updates charts kinda ok     <-- Trash (Struggle)
5. a6fed84 zoomed in sparklines        <-- Substantive Milestone (New Feature)
6. 14524b6 zoomed sparkline for cards  <-- Trash (Tweak to previous)
7. 261c61a before fitness              <-- Substantive Milestone
```

**CORRECT PLAN:**
```text
# Milestone 1: Base Sparklines
pick df43e81
fixup 19f4a91
fixup af7862e
fixup 76cab31
exec git commit --amend --allow-empty -F /tmp/compact_messages/df43e81.txt # "feat(finance): implement base sparkline charts"

# Milestone 2: Zoom Feature
pick a6fed84
fixup 14524b6
exec git commit --amend --allow-empty -F /tmp/compact_messages/a6fed84.txt # "feat(finance): add zoomed sparkline views"

# Milestone 3: Fitness Base
pick 261c61a
# (No fixups, no exec amend needed if the original message is fine, or amend if it needs clean up)
```

## Execution Steps

### Step 1: Detect Target, Stash & Backup
*(Note for AI: Replace `<USER_TARGET>` in the script below with the actual target).*

```bash
cd "$(git rev-parse --show-toplevel)"
git stash || true

TARGET="<USER_TARGET>"

if [[ "$TARGET" == *":"* ]]; then
  START_SHA=$(echo "$TARGET" | cut -d: -f1)
  END_SHA=$(echo "$TARGET" | cut -d: -f2)
  REBASE_BASE="${START_SHA}~1"
  LOG_RANGE="${START_SHA}~1..${END_SHA}"
else
  LOG_RANGE="$TARGET"
  REBASE_BASE="--root"
fi

BRANCH=$(git branch --show-current)
git branch "backup-$BRANCH" "$BRANCH"
```

### Step 2: Extract History
```bash
rm -rf /tmp/compact_analysis /tmp/compact_messages
mkdir -p /tmp/compact_analysis /tmp/compact_messages

git log --reverse --format="%H %s" $LOG_RANGE > /tmp/compact_analysis/00_commit_list.txt

echo "History extracted. Read /tmp/compact_analysis/00_commit_list.txt to map out the Trash vs Substantive commits."
cat /tmp/compact_analysis/00_commit_list.txt
```

### Step 3: AI TASK - Plan Compaction & Craft Messages
**Task A: Create Consolidated Commit Messages (Only for messy groups)**
For groups of commits that are squashed and need a better name, create a file in `/tmp/compact_messages/`:
- **Filename**: The FULL 40-character SHA of the **base commit**.
- **Content**: The new commit message (imperative mood, e.g., `feat(module): description`).
*(Note: If a `pick` has no fixups and its message is already acceptable, you do not need to write a file for it).*

**Task B: Generate the Rebase Plan**
Create `/tmp/rebase_plan.txt` with the exact `git rebase` sequence.
1. **DO NOT DROP COMMITS**: Every single SHA from `00_commit_list.txt` MUST be in your plan.
2. Apply the "Trash-Only" algorithm: `pick` substantive steps, `fixup` the struggles beneath them.
3. If you wrote a message in Task A, insert `exec git commit --amend --allow-empty -F /tmp/compact_messages/<FULL_SHA>.txt` immediately after that block.

### Step 4: Execute the Rebase
**CRITICAL AI BUG PREVENTION:**
1. Do **NOT** replace `"$1"` inside the EOF block with a branch name.
2. Do **NOT** forget the `-i` flag in the git rebase command.

```bash
cd "$(git rev-parse --show-toplevel)"

cat << 'EOF' > /tmp/seq_editor.sh
#!/bin/bash
# CRITICAL: $1 is passed by git. DO NOT REPLACE IT WITH A BRANCH NAME.
cat /tmp/rebase_plan.txt > "$1"
EOF
chmod +x /tmp/seq_editor.sh

env GIT_SEQUENCE_EDITOR="/tmp/seq_editor.sh" git rebase -i $REBASE_BASE
```

### Step 5: Verify & Cleanup
```bash
git log --oneline "$BRANCH" | head -n 45
git log --format="%B" -n 5 "$BRANCH"

rm -rf /tmp/compact_messages /tmp/compact_analysis /tmp/rebase_plan.txt /tmp/seq_editor.sh
git stash pop || true
```

### Step 6: Rollback (If needed)
If the rebase fails or aborts:
```bash
git rebase --abort || true
git reset --hard "backup-$BRANCH"
git stash pop || true
```
