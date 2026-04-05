---
description: Rewrite git commit messages — full branch or SHA1:SHA2 range
argument-hint: <branch> or <sha1:sha2>
---

Rewrite commit messages in git history using `git filter-branch` with SHA-based file mapping system.

## Mode Detection
Parse `$1` to determine mode:

- **Range mode**: Argument matches pattern `sha1:sha2` (two 40-char hex strings separated by colon)
  - Example: `rewrite-history a1b2c3d:ef45678`
  - Used to extract diffs only for a specific range.
- **Full branch mode**: Argument is a branch name
  - Example: `rewrite-history develop`

## Execution Steps
### Step 1: Detect Target & Backup
Determine the target mode automatically and backup the current state.

```bash
TARGET="$1"

# Convert sha1:sha2 to git-native sha1..sha2 range if needed
if [[ "$TARGET" == *":"* ]]; then
  TARGET="${TARGET/:/..}"
fi

# Always backup the current branch
BRANCH=$(git branch --show-current)
git branch "backup-$BRANCH" "$BRANCH"
```

### Step 2: Extract Diffs (AI & Context Friendly)
We place our analysis and mapping data in `/tmp/` to completely isolate it from `git filter-branch`'s aggressive `.git/` directory manipulations.

```bash
# Clean and recreate external directories
rm -rf /tmp/rewrite_analysis /tmp/rewrite_messages
mkdir -p /tmp/rewrite_analysis
mkdir -p /tmp/rewrite_messages

# Generate individual diff files for every commit in the target range (Oldest First)
for sha in $(git rev-list --reverse "$TARGET"); do
  git show --stat --patch "$sha" > "/tmp/rewrite_analysis/$sha.txt"
done

echo "Diffs extracted to /tmp/rewrite_analysis/. Review them to craft new messages."
```

### Step 3: Craft New Commit Messages
For **every commit you want to rewrite**, create a text file inside `/tmp/rewrite_messages/`.
- **Filename**: The *original* full commit SHA.
- **File content**: The new commit message.

*Note: You only need to create files for the commits you actually want to change. Missing files safely fall back to the original message.*

Read the isolated `/tmp/rewrite_analysis/<sha>.txt` files to understand what changed, then craft a detailed, robust message following this three-part structure:

```
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

## Important Notes
- **Unified Logic:** You no longer need separate logic for ranges vs. full branches. You always pass the `$BRANCH` to `filter-branch`. Commits that you don't map to files are passed through natively.
- **Filter-Repo:** For very large repositories or histories (thousands of commits), consider using `git filter-repo` as it is generally faster and the modern standard over `filter-branch`.
