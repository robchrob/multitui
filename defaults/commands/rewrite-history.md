---
description: Rewrite git commit messages — full branch or SHA1:SHA2 range
argument-hint: <branch> or <sha1:sha2>
---

Rewrite commit messages in git history using `git filter-branch` with position-based message mapping. Supports two modes auto-detected from the argument.

## Mode Detection

Parse `$1` to determine mode:

- **Range mode**: Argument matches pattern `sha1:sha2` (two 40-char hex strings separated by colon)
  - Example: `rewrite-history a1b2c3d:ef45678`
  - Rewrites commits in range `sha1..sha2` on current branch
- **Full branch mode**: Argument is a branch name
  - Example: `rewrite-history develop`
  - Rewrites ALL commits reachable from that branch

## Execution Steps

### Step 1: Backup Current Branch

```bash
# Full branch mode
BRANCH="$1"
git branch "backup-$BRANCH" "$BRANCH"

# Range mode — still backup the full branch since children get new hashes
BRANCH=$(git branch --show-current)
git branch "backup-$BRANCH" "$BRANCH"
```

### Step 2: Collect Commits (Oldest First)

Determine the rev-list command based on mode:

```bash
# Range mode — commits reachable from SHA2 but not SHA1
git log --oneline --format="%H" sha1..sha2 | tac

# Full branch mode — all commits on branch
git log --oneline --format="%H" <branch> | tac
```

Count the commits — you need this number to generate messages.

### Step 3: Analyze Diffs (Optional)

If you need to understand what each commit does to generate good messages:

```bash
# Range mode
COMMITS=($(git log --format="%H" sha1..sha2 | tac))

# Full branch mode
COMMITS=($(git log --format="%H" <branch> | tac))

# Analyze consecutive diffs
for i in $(seq 0 $((${#COMMITS[@]} - 2))); do
  echo "=== Diff ${COMMITS[$i]} -> ${COMMITS[$((i+1))]} ==="
  git diff ${COMMITS[$i]} ${COMMITS[$((i+1))]}
done
```

Save this analysis to a temp file for reference while crafting messages.

### Step 4: Generate New Commit Messages

For each commit, craft a message using conventional commit format:

```
type: description

- What changed and why
- Additional details as needed
```

Types:
- `feat`: new feature for the user
- `fix`: bug fix for the user
- `docs`: changes to documentation
- `style`: formatting, no code change
- `refactor`: refactoring production code
- `test`: adding tests, no code change
- `chore`: updating build tasks, config, etc

Rules:
- Subject line: 72 chars max, imperative mood, lowercase
- Body: blank line after subject, then bullet points
- Explain WHAT and WHY, not HOW

### Step 5: Create the Message Filter Script

Create a bash script that maps commits to messages by POSITION:

```bash
#!/bin/bash
# msg_filter.sh — position-based commit message replacement
# Filter-branch processes commits NEWEST FIRST
# But 'git rev-list | tac' iterates OLDEST FIRST
# They meet in the middle, so INDEX matches correctly!

declare -a MSG_ARRAY

# Messages in order OLDEST FIRST (oldest commit = index 0)
# Include BOTH subject line AND body (blank line separates)
MSG_ARRAY[0]="type: first commit message

- Detailed description of what changed
- Another detail about the change"
MSG_ARRAY[1]="type: second commit message

- Another change explanation"
# ... add ALL messages in order (oldest to newest)

COMMIT="$GIT_COMMIT"
INDEX=0

# Use the SAME rev-list command as Step 2
for sha in $(git rev-list <branch_or_range> | tac); do
    if [ "$sha" = "$COMMIT" ]; then
        echo "${MSG_ARRAY[$INDEX]}"
        exit 0
    fi
    INDEX=$((INDEX + 1))
done

# Fallback — pass through unchanged
cat
```

**Critical rules:**
- Messages MUST be in array order OLDEST FIRST (index 0 = oldest commit)
- Use position-based indexing — hash matching doesn't work reliably
- The rev-list command MUST match the mode:
  - Full branch: `git rev-list <branch> | tac`
  - Range: `git rev-list sha1..sha2 | tac`

### Step 6: Run filter-branch

```bash
# Full branch mode
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter '/path/to/msg_filter.sh' -- <branch>

# Range mode
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter '/path/to/msg_filter.sh' -- sha1..sha2
```

### Step 7: Verify Result

```bash
git log --oneline <branch>
```

Check that all messages are correct and in the right order.

### Step 8: Rollback if Needed

```bash
git reset --hard backup-<branch>
```

The original refs are also stored in `refs/original/` by filter-branch as a safety net.

## Important Notes

- `git filter-branch` processes commits NEWEST FIRST by default
- Using `git rev-list | tac` iterates OLDEST FIRST
- They "meet in the middle" so INDEX counter correctly maps to MSG_ARRAY position
- Range mode only rewrites commits in the specified range — parent commits before the range are untouched
- Range mode still requires backing up the full branch because child commits after the range get new hashes
- After range mode rewrite, the branch tip will have a new hash even if commits after the range were not modified
- If something goes wrong, restore from backup immediately
- For large numbers of commits, consider using `git filter-repo` instead (faster, safer)
