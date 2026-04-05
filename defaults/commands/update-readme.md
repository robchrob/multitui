---
description: Update README.md based on git history since last README edit
argument-hint:
---

Analyze commits since README.md was last modified, extract diffs and commit metadata, then rewrite README.md in Hermes-style: punchy one-liner, feature highlights table, copy-paste install, CLI reference table, docs links, minimal contributing section.

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

git diff "$RANGE" --stat                          > /tmp/update_readme_analysis/files_changed.txt
git diff --name-status "$RANGE"                  > /tmp/update_readme_analysis/file_status.txt
git log "$RANGE" --format="%H|%an|%ae|%s|%b"    > /tmp/update_readme_analysis/commits.txt
git log "$RANGE" --oneline                        > /tmp/update_readme_analysis/oneline.txt
git diff --unified=5 "$RANGE"                    > /tmp/update_readme_analysis/full_diff.patch
```

### Step 3: Analyze and Plan

Read all analysis files, then read current README.md. Identify:

1. **What is this project?** Write a punchy one-liner that completes: "A tool that..."
2. **Key features** - extract 4-6 main features from `feat:` commits and file additions
3. **Install command** - what's the one command to get started?
4. **Core commands** - which CLI commands matter most?
5. **Links needed** - docs, repo, any external resources

### Step 4: Write Hermes-Style README

Structure:

```markdown
# [Project Name] — [One-liner]

<p align="center">
  [Badges: docs, repo, license]
</p>

[Feature description in 1-2 sentences + quick feature table]

---

## Quick Install

[One copy-paste command, no prerequisites except git]

## Getting Started

[3-4 essential commands: setup, first use, resume]

## CLI Reference

| Command | What |
|---------|------|
| [cmd] | [desc] |
| [cmd] | [desc] |

## Configuration

[Key config locations if any]

## Contributing

[Minimal: clone + one command to test]

## License

[One line]
```

### Step 5: Rewrite README.md

Apply the structure above. Keep:
- Existing tone (if good)
- Existing code examples that work
- Accurate command syntax

Update:
- One-liner to reflect current state
- Features table with new capabilities
- CLI commands that exist now
- Remove outdated sections

### Step 6: Cleanup
```bash
rm -rf /tmp/update_readme_analysis
```

## Output

Display summary:
- Commits analyzed
- Sections rewritten
- Key changes incorporated