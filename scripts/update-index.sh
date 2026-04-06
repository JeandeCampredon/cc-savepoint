#!/usr/bin/env bash
set -euo pipefail

# update-index.sh — Upsert a savepoint entry in index.json
# No external dependencies (no jq, no node). Pure bash.
#
# Usage:
#   update-index.sh <index_json_path> <savepoint_name> <session_id> [--commit-hash <hash>]
#
# If index.json doesn't exist, creates it.
# If the savepoint name already exists, updates it.
# If the savepoint name is new, appends it.

usage() {
  echo "Usage: $0 <index_json_path> <savepoint_name> <session_id> [--commit-hash <hash>]"
  exit 1
}

if [[ $# -lt 3 ]]; then
  usage
fi

INDEX_PATH="$1"
SAVEPOINT_NAME="$2"
SESSION_ID="$3"
COMMIT_HASH=""

shift 3
while [[ $# -gt 0 ]]; do
  case "$1" in
    --commit-hash)
      COMMIT_HASH="$2"
      shift 2
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      ;;
  esac
done

CREATED_AT="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

# Build the new savepoint JSON entry
build_entry() {
  local entry="    {"
  entry+="\n      \"name\": \"${SAVEPOINT_NAME}\","
  entry+="\n      \"created_at\": \"${CREATED_AT}\""
  if [[ -n "$COMMIT_HASH" ]]; then
    entry+=",\n      \"commit_hash\": \"${COMMIT_HASH}\""
  fi
  entry+="\n    }"
  echo -e "$entry"
}

# If index.json doesn't exist, create it from scratch
if [[ ! -f "$INDEX_PATH" ]]; then
  cat > "$INDEX_PATH" <<ENDJSON
{
  "session_id": "${SESSION_ID}",
  "savepoints": [
$(build_entry)
  ]
}
ENDJSON
  echo "Created $INDEX_PATH with savepoint '${SAVEPOINT_NAME}'"
  exit 0
fi

# Read existing file
CONTENT="$(cat "$INDEX_PATH")"

# Check if this savepoint name already exists in the file
if echo "$CONTENT" | grep -q "\"name\": \"${SAVEPOINT_NAME}\""; then
  # Update existing entry: replace the block for this savepoint
  # Strategy: read the file, rebuild the savepoints array
  echo "Savepoint '${SAVEPOINT_NAME}' already exists — updating."
else
  echo "Adding savepoint '${SAVEPOINT_NAME}' to index."
fi

# Rebuild approach: extract existing savepoint names (except the one we're upserting),
# then append our new/updated entry.
# This is simpler and safer than trying to do in-place JSON editing in bash.

# Extract all savepoint names from the file
NAMES=()
while IFS= read -r line; do
  # Match lines like: "name": "something"
  if [[ "$line" =~ \"name\":\ \"([^\"]+)\" ]]; then
    NAMES+=("${BASH_REMATCH[1]}")
  fi
done < "$INDEX_PATH"

# Extract existing entries we want to keep (everything except the one being upserted)
# We'll rebuild by parsing name/created_at/commit_hash blocks
TMP_FILE="$(mktemp)"
trap 'rm -f "$TMP_FILE"' EXIT

{
  echo "{"
  echo "  \"session_id\": \"${SESSION_ID}\","
  echo "  \"savepoints\": ["

  FIRST=true

  # Re-read existing entries, skip the one we're upserting
  CURRENT_NAME=""
  CURRENT_CREATED=""
  CURRENT_HASH=""
  IN_ENTRY=false

  while IFS= read -r line; do
    # Detect entry start
    if [[ "$line" =~ \"name\":\ \"([^\"]+)\" ]]; then
      CURRENT_NAME="${BASH_REMATCH[1]}"
      IN_ENTRY=true
    fi
    if [[ "$IN_ENTRY" == true && "$line" =~ \"created_at\":\ \"([^\"]+)\" ]]; then
      CURRENT_CREATED="${BASH_REMATCH[1]}"
    fi
    if [[ "$IN_ENTRY" == true && "$line" =~ \"commit_hash\":\ \"([^\"]+)\" ]]; then
      CURRENT_HASH="${BASH_REMATCH[1]}"
    fi
    # Detect entry end (closing brace with possible comma)
    if [[ "$IN_ENTRY" == true && "$line" =~ ^[[:space:]]*\} ]]; then
      IN_ENTRY=false
      # Write this entry if it's not the one we're replacing
      if [[ "$CURRENT_NAME" != "$SAVEPOINT_NAME" && -n "$CURRENT_NAME" ]]; then
        if [[ "$FIRST" != true ]]; then
          echo ","
        fi
        FIRST=false
        echo -n "    {"
        echo -n "\"name\": \"${CURRENT_NAME}\", "
        echo -n "\"created_at\": \"${CURRENT_CREATED}\""
        if [[ -n "$CURRENT_HASH" ]]; then
          echo -n ", \"commit_hash\": \"${CURRENT_HASH}\""
        fi
        echo -n "}"
      fi
      CURRENT_NAME=""
      CURRENT_CREATED=""
      CURRENT_HASH=""
    fi
  done < "$INDEX_PATH"

  # Append the new/updated entry
  if [[ "$FIRST" != true ]]; then
    echo ","
  fi
  build_entry
  echo "  ]"
  echo "}"
} > "$TMP_FILE"

mv "$TMP_FILE" "$INDEX_PATH"
echo "Updated $INDEX_PATH"
