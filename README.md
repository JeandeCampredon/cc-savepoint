# savepoint

Lightweight session savepoints for Claude Code. Save and restore conversation context without replaying full history.

## Problem

`claude --resume` replays the full conversation history as input tokens, making long sessions expensive to resume. This plugin creates compact snapshots that capture the essential context — task, decisions, modified files, current state, and next action — so you can start a fresh session with just the right context.

## Installation

### Via plugin management (recommended)

```
/plugin marketplace add jeandecampredon/cc-savepoint
/plugin install savepoint@savepoint
```

### Local development

```bash
claude --plugin-dir ./path/to/savepoint
```

## Usage

### Save a snapshot

```
/sp-save
```

Creates a savepoint with a memorable pop-culture name (e.g., `gandalf-shall-pass`).

**Options:**
- `/sp-save --commit` — Commit all changes first, then save (records the commit hash)
- `/sp-save --edit-content` — Review and refine the snapshot summary before saving

### Load a snapshot

```
/sp-load                          # Interactive picker
/sp-load {session_id}             # Pick from a specific session
/sp-load {session_id} {name}      # Load a specific savepoint
/sp-load {session_id} last        # Load the most recent savepoint
/sp-load {name}                   # Search all sessions by name
```

## Storage

Savepoints are stored in `.claude/savepoints/{session_id}/`:

```
.claude/savepoints/
  abc123/
    index.json
    gandalf-shall-pass.md
    one-more-thing.md
```

Each savepoint is a markdown file with: task context, key decisions, modified files, current state, and the next action to take.

## Requirements

- Claude Code CLI
- `git` (for commit hash tracking)
- Bash (macOS/Linux) or PowerShell (Windows) for the index update scripts

## License

MIT
