# /sp-load

You are executing the `/sp-load` command. Load a previously saved savepoint into the current session.

**Arguments received:** `$ARGUMENTS`

## Step 1: Parse arguments

Parse `$ARGUMENTS` to determine the load mode:

| Input | Mode |
|-------|------|
| (empty) | Interactive picker — list all sessions |
| `{session_id}` | Interactive picker within that session |
| `{session_id} {name}` | Load specific savepoint |
| `{name}` (not a session ID) | Search all sessions for that name |
| `{session_id} last` | Load the most recent savepoint for that session |

A session ID looks like a UUID or hex string. A savepoint name is kebab-case words.

## Step 2: Locate savepoints directory

Search in order:
1. `.claude/savepoints/` (project-local, relative to git root)
2. `~/.claude/savepoints/` (global/home directory)

Use the Bash tool to check which directories exist:
```bash
git_root="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
ls -d "$git_root/.claude/savepoints" 2>/dev/null
ls -d "$HOME/.claude/savepoints" 2>/dev/null
```

## Step 3: Resolve the savepoint

### Mode: Interactive picker (no args or session_id only)

1. List available session directories:
   ```bash
   ls -1 {savepoints_dir}/
   ```
2. If a `session_id` was provided, list savepoints within it:
   ```bash
   ls -1 {savepoints_dir}/{session_id}/*.md
   ```
3. Present the options to the user and ask them to choose.
4. For each session, read its `index.json` to show savepoint names and timestamps.

### Mode: Specific savepoint (`session_id name`)

Look for the file at `{savepoints_dir}/{session_id}/{name}.md`.

### Mode: Search by name only

Search all session directories for a file matching `{name}.md`:
```bash
find {savepoints_dir} -name "{name}.md" -type f
```

### Mode: Last savepoint (`session_id last`)

1. Read `{savepoints_dir}/{session_id}/index.json`
2. Sort savepoints by `created_at` descending
3. Pick the most recent entry
4. If no savepoints exist for this session, **fall back**:
   - Tell the user: "No savepoints found for session {session_id}. You can resume the full session with: `claude --resume {session_id}`"
   - Do NOT automatically run `claude --resume`

## Step 4: Read the savepoint

Read the resolved `.md` file using the Read tool.

## Step 5: Inject context

Present the savepoint content to the user and explain:

```
Loaded savepoint: {name}
Session: {session_id}
Created: {timestamp}
{if commit_hash: "Commit: {commit_hash} — run `git checkout {commit_hash}` to restore that code state"}

---
{full savepoint markdown content}
---

I've loaded this savepoint context. I'm ready to continue from where this session left off.
The next action was: {next action from the savepoint}

Shall I proceed with that, or would you like to do something else?
```

## Error handling

- **Savepoint not found**: List available savepoints and ask the user to choose.
- **No savepoints directory**: Tell the user no savepoints have been created yet. Suggest running `/sp-save` in a session first.
- **Ambiguous name match**: If multiple sessions contain a savepoint with the same name, list them all and ask the user to specify the session ID.
