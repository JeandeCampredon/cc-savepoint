# savepoint

A Claude Code plugin that provides `/sp-save` and `/sp-load` skills for lightweight session snapshots.

## Structure

- `.claude-plugin/plugin.json` — Plugin manifest
- `.claude-plugin/marketplace.json` — Marketplace manifest for plugin distribution
- `skills/sp-save/SKILL.md` — /sp-save skill prompt
- `skills/sp-load/SKILL.md` — /sp-load skill prompt
- `scripts/update-index.sh` — Bash script for index.json manipulation (macOS/Linux)
- `scripts/update-index.ps1` — PowerShell script for index.json manipulation (Windows)

## Testing the scripts

```bash
# Bash (macOS/Linux)
bash scripts/update-index.sh /tmp/test-index.json test-savepoint session-123
bash scripts/update-index.sh /tmp/test-index.json test-savepoint session-123 --commit-hash abc123

# PowerShell (Windows)
pwsh scripts/update-index.ps1 /tmp/test-index.json test-savepoint session-123 -CommitHash abc123
```

## Install via plugin management

```
/plugin marketplace add jeandecampredon/cc-savepoint
/plugin install savepoint@savepoint
```

## Local plugin install (dev)

```bash
claude --plugin-dir ./path/to/savepoint
```
