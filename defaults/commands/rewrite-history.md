---
description: Rewrite git commit messages — full branch or SHA1:SHA2 range
argument-hint: <branch> or <sha1:sha2>
---

# SYSTEM DIRECTIVE: AUTONOMOUS EXECUTION
You are acting as an autonomous CLI execution engine.
- **NO HESITATION OR COMPLAINING**: DO NOT write internal monologues debating token limits, context windows, or time constraints. You are fully capable of handling this.
- **NO WAITING**: Do NOT ask the user for confirmation. Do NOT ask the user to provide the messages. YOU must read the diffs and generate the new commit messages yourself immediately.
- **NO FILE SEARCHING FOR TARGETS**: The user will provide a target (a branch name or a commit range). It is a Git reference, NOT a file. Do NOT use `glob` or `ls` to search for a file named after the target.
- **JUST EXECUTE**: Stop overthinking the strategy and just start executing the bash commands.

Rewrite commit messages in git history using `git filter-branch` with a SHA-based file mapping system.

## Mode Detection
Parse the target provided by the user in their message to determine the mode:

- **Range mode**: The target matches pattern `sha1:sha2` (two 40-char hex strings separated by colon)
  - Example: `a1b2c3d:ef45678`
  - Used to extract diffs only for a specific range.
- **Full branch mode**: The target is a branch name
  - Example: `develop-hist`

## Execution Steps

### Step 1: Detect Target & Backup
Determine the target mode automatically, move to the repo root, and backup the current state.

*(Note for AI: Replace `<USER_TARGET>` in the script below with the actual branch or range the user asked you to rewrite).*

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
We place our analysis and mapping data in `/tmp/` to completely isolate it from `git filter-branch`. **Notice that we truncate the diffs to 200 lines.** This ensures your context window is perfectly safe, even for hundreds of commits.

```bash
# Clean and recreate external directories
rm -rf /tmp/rewrite_analysis /tmp/rewrite_messages
mkdir -p /tmp/rewrite_analysis
mkdir -p /tmp/rewrite_messages

# Generate individual diff files (truncated to save AI context) for every commit in the target range
for sha in $(git rev-list --reverse "$TARGET"); do
  git show --stat --patch "$sha" | head -n 200 > "/tmp/rewrite_analysis/$sha.txt"
done

echo "Diffs extracted to /tmp/rewrite_analysis/. Proceeding to craft new messages."
```

### Step 3: AI TASK - Craft New Commit Messages
**AI INSTRUCTION:** You must now read the isolated `/tmp/rewrite_analysis/<sha>.txt` files to understand what changed. Then, autonomously create a text file inside `/tmp/rewrite_messages/` for **every commit**.

- **Filename**: The *original* full 40-character commit SHA (no `.txt` extension needed for the output file, just the SHA).
- **File content**: The new commit message you generate.

*Note: You only need to create files for the commits you actually want to change. Missing files safely fall back to the original message.*

Craft a detailed, robust message following this three-part structure:

```text
type(optional-scope): subject

detailed body paragraph(s)

footer (optional)
```

#### Subject Line Rules
- **Max 50 characters** — keep it brief and scannable
- **Lowercase** — consistent style across all commits
- **Imperative mood** — read as a command, not past tense
  - Test: "If applied, this commit will [subject]" should make sense
  - Use "add", "fix", "update" — NOT "added", "fixed", "updating"
- **No trailing period** — never end the subject with punctuation
- **Emphasize WHY, not HOW** — focus on the purpose, not the implementation

#### Body (Description) — Detailed and Robust
**Rules:**
- Blank line between subject and body
- **Wrap at 72 characters** per line
- **Explain WHAT changed and WHY** — not HOW (the diff shows how)
- **Provide context** — what was the situation before? What problem does this solve?

**Good example:**

```text
feat(auth): add support for external key imports

currently, users can only use keys created within the platform.
this is a significant limitation for teams migrating from other
services who already have established key infrastructure.

adds the import_key() function and a new api endpoint that
accepts externally-generated keys. validates key format and
checks for conflicts before accepting.
```

### Step 4: Create the Filter Script
Create a standalone executable script. This prevents `git filter-branch` from losing environment variables, losing its current working directory (CWD), or throwing subshell syntax errors.

```bash
cat << 'EOF' > /tmp/msg_filter.sh
#!/bin/bash
# $GIT_COMMIT is provided by git and is always the ORIGINAL hash
MSG_FILE="/tmp/rewrite_messages/$GIT_COMMIT"

if [ -f "$MSG_FILE" ]; then
  cat "$MSG_FILE"
else
  # Fallback: read original commit message via standard input.
  cat
fi
EOF

chmod +x /tmp/msg_filter.sh
```

### Step 5: Run filter-branch
Run the rewrite. Always pass the branch name (`$BRANCH`) to `filter-branch`, never the SHA range. Our script handles range limiting automatically: if a commit is outside your target range, it simply won't have a file in `/tmp/rewrite_messages/`, so the fallback cleanly passes the original message through.

```bash
# Ensure we are at the repo root to prevent CWD crash
cd "$(git rev-parse --show-toplevel)"

# Squelch the deprecation warning and execute the external script
FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter '/tmp/msg_filter.sh' -- "$BRANCH"
```

### Step 6: Verify Result & Cleanup
```bash
# Quick overview
git log --oneline "$BRANCH"

# Full messages to verify body content
git log --format="%B" "$BRANCH"

# Cleanup external temporary files
rm -rf /tmp/rewrite_messages
rm -rf /tmp/rewrite_analysis
rm /tmp/msg_filter.sh
```

### Step 7: Rollback if Needed
If something went wrong, immediately restore from your backup:

```bash
git reset --hard "backup-$BRANCH"
```

## CRITICAL EXECUTION RULES FOR THE AI
To prevent known crashes during this process, you must strictly follow these rules:

1. **Autonomous Execution:** You must read the diffs and generate the commit messages yourself immediately. Do NOT pause and ask the human to provide them.
2. **Prevent the CWD Deletion Bug:** `git filter-branch` will crash with `fatal: Unable to read current working directory` if you run it from a subdirectory that didn't exist in older commits. **Fix:** You MUST run `cd "$(git rev-parse --show-toplevel)"` to move to the repository root immediately before executing `git filter-branch` (already included in the Bash snippets above).
3. **Strict 40-Character SHA Matching:** Do NOT rename your `/tmp/rewrite_messages/` files to 7-character short SHAs. The environment variable `$GIT_COMMIT` in `git filter-branch` provides the FULL 40-character SHA. Ensure your mapping files use the full 40-character SHA.
4. **Stick to Bash & filter-branch:** Do not attempt to pivot to `git-filter-repo` or write Python callbacks if you encounter an error. If `filter-branch` fails, it is an environment issue (like the CWD bug). Fix the bash environment and retry `filter-branch`.
