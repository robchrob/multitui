---
description: Conditionally fix commit formats and add missing bodies
argument-hint: <branch> or <sha1:sha2>
---

# SYSTEM DIRECTIVE: AUTONOMOUS EXECUTION
You are an autonomous CLI execution engine. Do not ask for user confirmation, do not wait for the user to provide messages, and do not overthink. Read the diffs, determine if fixes are needed, and execute immediately.

This command audits commit messages for a given branch or range. It will **ONLY** modify a commit message if:
1. The subject line does not align with Conventional Commits (`type(scope): subject`).
2. The commit lacks a detailed body explaining WHAT and WHY.

## Execution Steps

### Step 1: Detect Target & Backup
Determine the mode (branch or `sha1:sha2` range), move to the repo root, and backup.

*(Replace `<USER_TARGET>` below with the target provided by the user).*

```bash
cd "$(git rev-parse --show-toplevel)"

TARGET="<USER_TARGET>"
if [[ "$TARGET" == *":"* ]]; then
  TARGET="${TARGET/:/..}"
fi

BRANCH=$(git branch --show-current)
git branch "backup-$BRANCH" "$BRANCH"
```

### Step 2: Extract History for Analysis
Extract the original messages and a truncated diff to `/tmp/` so you can evaluate them.

```bash
rm -rf /tmp/rewrite_analysis /tmp/rewrite_messages
mkdir -p /tmp/rewrite_analysis /tmp/rewrite_messages

# Extract commit message and diff for every commit in the target range
for sha in $(git rev-list --reverse "$TARGET"); do
  git show --stat --patch "$sha" | head -n 200 > "/tmp/rewrite_analysis/$sha.txt"
done

echo "Extracted to /tmp/rewrite_analysis/. Proceeding to audit."
```

### Step 3: AI TASK - Audit and Fix
Read the files in `/tmp/rewrite_analysis/`. For each commit, audit the original message (at the top of the file).

**Audit Rules:**
- **Skip if Valid:** If the subject is formatted correctly (e.g., `feat: add login`) AND it has a descriptive body paragraph beneath it, **DO NOTHING**. Do not create a rewrite file for this SHA.
- **Fix if Invalid:** If the format is wrong (e.g., "Fixed bug" or capitalized/past tense) OR the body is missing/empty, you must fix it.

**How to Fix:**
Create a file at `/tmp/rewrite_messages/<sha>` (using the full 40-character SHA as the filename).
- Write the correctly formatted subject line: `type(optional-scope): lowercase imperative subject` (max 50 chars).
- Leave one blank line.
- Write a detailed body explaining *what* changed and *why* based on the diff context (wrapped at 72 chars).

### Step 4: Apply the Fixes
Create the filter script and run `filter-branch`. Commits without a file in `/tmp/rewrite_messages/` will automatically keep their exact original message.

```bash
cat << 'EOF' > /tmp/msg_filter.sh
#!/bin/bash
MSG_FILE="/tmp/rewrite_messages/$GIT_COMMIT"
if [ -f "$MSG_FILE" ]; then
  cat "$MSG_FILE"
else
  cat
fi
EOF
chmod +x /tmp/msg_filter.sh

# Ensure root directory, then run filter-branch
cd "$(git rev-parse --show-toplevel)"
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter '/tmp/msg_filter.sh' -- "$BRANCH"
```

### Step 5: Verify & Cleanup
```bash
# Review changes
git log --format="%h %s%n%b" "$BRANCH" | head -n 30

# Cleanup
rm -rf /tmp/rewrite_messages /tmp/rewrite_analysis /tmp/msg_filter.sh
```

*(Note: If the result is wrong, roll back using `git reset --hard backup-$BRANCH`)*
