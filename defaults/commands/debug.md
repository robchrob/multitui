---
description: Debug an error - investigate cause and suggest fix
argument-hint: <error message or description>
---

Debug mode. Given an error message, investigate and find the cause.

## Usage

```
/debug Error: Cannot read property 'foo' of undefined
/debug TypeError: x is not a function
/debug [paste error or describe unexpected behavior]
```

## Step 1: Parse the Error

If no error provided, ask for it:

```
What error are you seeing? Paste:
- Error message
- Stack trace
- Console output
- Or describe the unexpected behavior
```

Extract from error:
- **Error type**: TypeError, SyntaxError, ReferenceError, runtime, build, etc.
- **File:line**: if present in stack trace
- **Function/component**: involved module or function name
- **Key values**: mentioned in error message

## Step 2: Locate Ground Zero

```bash
# If file:line present in error
read <file> 2>/dev/null

# Search for function/component name
rg -l "functionName\|const functionName\|class FunctionName" . 2>/dev/null

# For imports
rg "from ['\"]\.\/.*['\"]\|from ['\"]@.*['\"]" . -l 2>/dev/null
```

## Step 3: Reproduce the Error

Run the code to see the error:

```bash
# Try to run the failing code
docker compose run --rm app npm run dev 2>&1 | tail -50

# Or run tests
docker compose run --rm app npm test 2>&1 | tail -100
```

## Step 4: Analyze Root Cause

Based on error type:

### TypeError / ReferenceError
- Variable undefined or wrong type?
- Check imports: is the export correct?
- Check async: is data ready?

### Module/Import Error
- Check if export exists
- Check path is correct
- Check package is installed

### Build Error
- Check syntax
- Check TypeScript types
- Check configuration

### Runtime Error
- Check data flow
- Check null/undefined handling
- Check async timing

## Step 5: Read Relevant Code

```bash
# Read the file around error line
read <file>

# Read related files
rg "import.*from" <file> -B 1
```

## Step 6: Identify Fix

Common fixes:
- Add null check
- Await async call
- Fix import path
- Install missing dependency
- Fix type annotation

## Step 7: Present Findings

Format:

```
## Debug Report

### Error
[original error]

### Root Cause
[1-2 sentence explanation]

### Location
[file]:[line] - [function]

### Problem
[code snippet]

### Suggested Fix
[corrected code]
```

## Step 8: Offer to Fix

```
Apply this fix? (y/n)
```

If yes, apply with Edit tool, then verify:

```bash
# Re-run to confirm fix
docker compose run --rm app npm test 2>&1 | tail -30
```

## Step 9: Summarize Prevention

After fix, suggest:

```
### Prevention
- Add type check
- Add error boundary
- Add unit test for this case
```

## Notes

- If error is unclear, ask clarifying questions
- If multiple issues, fix one at a time
- After fix, run full test suite to ensure no regressions
