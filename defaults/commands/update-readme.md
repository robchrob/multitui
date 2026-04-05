---
description: Update README.md based on git history since last README edit
argument-hint:
---

Analyze commits since README.md was last modified, extract diffs and commit metadata, then rewrite README.md to reflect current state.

## Execution Steps

### Step 1: Find Last README Commit

```bash
LAST_README_SHA=$(git log -1 --format=%H -- README.md 2>/dev/null)

if [ -z "$LAST_README_SHA" ]; then
  echo "No previous README.md commit. Starting fresh."
  RANGE="HEAD"
else
  RANGE="${LAST_README_SHA}..HEAD"
fi

COMMIT_COUNT=$(git rev-list --count "$RANGE" 2>/dev/null || echo "0")

if [ "$COMMIT_COUNT" -eq 0 ]; then
  echo "README.md is up to date."
  exit 0
fi

echo "Processing $COMMIT_COUNT commits since last README update."
```

### Step 2: Collect Diff and Commit Data

```bash
rm -rf /tmp/update_readme_analysis
mkdir -p /tmp/update_readme_analysis

git diff "$RANGE" --stat > /tmp/update_readme_analysis/files_changed.txt
git diff --name-status "$RANGE" > /tmp/update_readme_analysis/file_status.txt
git log "$RANGE" --format="%H|%an|%ae|%s|%b" > /tmp/update_readme_analysis/commits.txt
git log "$RANGE" --oneline > /tmp/update_readme_analysis/oneline.txt
```

### Step 3: Update README

Read the analysis files and current README.md, then rewrite/align README.md with:

1. New features from `feat:` commits
2. Breaking changes from `BREAKING CHANGE:` footers
3. New commands, scripts, or tools added
4. Updated file structure if project layout changed
5. New dependencies or requirements
6. API/configuration changes that affect usage

Preserve existing style, formatting, and valid sections. Update only what changed.

### Step 4: Cleanup

```bash
rm -rf /tmp/update_readme_analysis
```

## Output

Display summary:
- Commits analyzed
- Key changes incorporated
- Sections updated
