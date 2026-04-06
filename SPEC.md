# savepoint Specification

## Problem

`claude --resume` replays full conversation history as input tokens, making long sessions expensive to resume. This plugin provides `/sp-save` and `/sp-load` skills to create lightweight snapshots (summaries) that can be loaded into fresh sessions without replaying history.

## Skills

### `/sp-save [--commit] [--edit-content]`

Creates a savepoint snapshot of the current session state.

**Behavior:**
1. Generate a pop-culture-inspired kebab-case name (e.g., `gandalf-shall-pass`, `luke-i-am-your-father`)
2. Create a savepoint markdown file with:
   - **Task**: What we're working on
   - **Key decisions**: Important choices made during the session
   - **Modified files**: Files changed and why
   - **Current state**: Where things stand right now
   - **Next action**: What should happen next
3. Write the file to `.claude/savepoints/{session_id}/{name}.md`
4. Upsert entry into `.claude/savepoints/{session_id}/index.json`

**Flags:**
- `--commit`: Commit all staged/unstaged changes, then record the commit hash in `index.json`
  - Uses Claude's `/commit` skill (or Sonnet sub-agent fallback)
- `--edit-content`: Spawn a Sonnet sub-agent to refine the summary before saving

**Storage layout:**
```
.claude/savepoints/
  {session_id}/
    index.json
    {name}.md
```

**`index.json` schema:**
```json
{
  "session_id": "abc123",
  "savepoints": [
    {
      "name": "gandalf-shall-pass",
      "created_at": "2025-01-15T10:30:00Z",
      "commit_hash": "a1b2c3d"
    }
  ]
}
```

### `/sp-load [session_id] [name | "last"]`

Loads a previously saved savepoint into the current session.

**Argument forms:**
- No args → interactive picker (list all sessions, then savepoints)
- `{session_id}` → interactive picker within that session
- `{session_id} {name}` → load specific savepoint
- `{name}` → search all sessions for a savepoint with that name
- `{session_id} last` → load most recent savepoint for that session

**Fallback behavior for `last`:**
1. Savepoint exists → load it
2. No savepoint for this session → fall back to `claude --resume {session_id}`
3. Plugin not installed → command not found (standard Claude Code behavior)

**Lookup order:**
1. `.claude/savepoints/` (project-local)
2. `~/.claude/savepoints/` (global)

## Scripts

### `scripts/update-index.sh` (macOS/Linux)
### `scripts/update-index.ps1` (Windows)

Cross-platform scripts for upserting commit hashes into `index.json`. No external dependencies beyond git and the native shell.

**Arguments:** `<index_json_path> <savepoint_name> <session_id> [--commit-hash <hash>]`

## Design Decisions

- **Skills (not commands)**: Uses `skills/` directory with `SKILL.md` files — the current plugin standard.
- **Cross-platform scripts**: Bash + PowerShell. No jq, node, or bun dependency.
- **Commit via Claude skill**: Respects repo commit conventions rather than using a hardcoded `git commit` command.
- **`${CLAUDE_PLUGIN_ROOT}`**: Used in skill prompts to reference scripts relative to the plugin installation.
- **Marketplace publishing**: `.claude-plugin/marketplace.json` enables installation via `/plugin marketplace add`.
