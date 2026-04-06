# /sp-save

You are executing the `/sp-save` command. Create a lightweight snapshot of the current session state.

**Arguments received:** `$ARGUMENTS`

## Step 1: Parse flags

Parse `$ARGUMENTS` for:
- `--commit` — commit changes before saving
- `--edit-content` — refine the summary with a sub-agent before saving

## Step 2: Generate a savepoint name

Generate a memorable kebab-case name inspired by pop culture (movies, games, books, memes). Examples: `gandalf-shall-pass`, `one-more-thing`, `its-a-trap`, `do-or-do-not`. Keep it 2-4 words, fun, and unique within this session.

## Step 3: Determine session ID

Get the current session ID. Use the Bash tool to run:
```
echo "$CLAUDE_SESSION_ID"
```
Store this as `SESSION_ID`.

## Step 4: Commit changes (if `--commit`)

If `--commit` flag is present:

1. **Primary**: Use the `/commit` skill to commit all changes following the repo's commit conventions.
2. **Fallback**: If the `/commit` skill is unavailable, spawn a Sonnet sub-agent to commit:
   - The sub-agent should examine `git status` and `git diff`, then create a commit following the repo's conventions.
3. After committing, capture the hash:
   ```
   git rev-parse HEAD
   ```
   Store this as `COMMIT_HASH`.

## Step 5: Generate the savepoint content

Write a markdown summary with these sections:

```markdown
# Savepoint: {name}

**Session:** {SESSION_ID}
**Created:** {ISO 8601 timestamp}
**Commit:** {COMMIT_HASH or "none"}

## Task
What we're working on — the high-level goal.

## Key Decisions
- Important choices made during this session
- Why we chose approach X over Y
- Constraints or requirements discovered

## Modified Files
- `path/to/file` — what changed and why
- (list all files modified in this session)

## Current State
Where things stand right now. What's working, what's broken, what's in progress.

## Next Action
The immediate next step to take when resuming this work.
```

Fill in each section based on the conversation history. Be concise but capture enough context to resume without the full history.

## Step 6: Refine content (if `--edit-content`)

If `--edit-content` flag is present, spawn a Sonnet sub-agent to review and refine the summary:
- Check for accuracy and completeness
- Improve clarity and conciseness
- Ensure the "Next Action" is actionable

## Step 7: Write the savepoint file

1. Create the directory if needed:
   ```
   mkdir -p .claude/savepoints/{SESSION_ID}
   ```
2. Write the markdown file to `.claude/savepoints/{SESSION_ID}/{name}.md`

## Step 8: Update index.json

Detect the platform and run the appropriate script:

**On macOS/Linux:**
```bash
bash "${CLAUDE_PLUGIN_ROOT}/scripts/update-index.sh" \
  ".claude/savepoints/{SESSION_ID}/index.json" \
  "{name}" \
  "{SESSION_ID}" \
  [--commit-hash "{COMMIT_HASH}"]
```

**On Windows:**
```powershell
powershell -File "${CLAUDE_PLUGIN_ROOT}/scripts/update-index.ps1" `
  ".claude/savepoints/{SESSION_ID}/index.json" `
  "{name}" `
  "{SESSION_ID}" `
  [-CommitHash "{COMMIT_HASH}"]
```

Detect the OS using `uname` (if available) or check for PowerShell. Default to bash on unknown platforms.

## Step 9: Confirm to the user

Output a confirmation message:

```
Savepoint saved: {name}
Location: .claude/savepoints/{SESSION_ID}/{name}.md
{if commit: "Commit: {COMMIT_HASH}"}
```

To restore later, run: `/sp-load {SESSION_ID} {name}` or `/sp-load {SESSION_ID} last`
