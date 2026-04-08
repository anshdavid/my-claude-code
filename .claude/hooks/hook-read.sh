#!/usr/bin/env bash
# hook-read.sh -- PreToolUse:Read hook

INPUT=$(cat)

EVENT_NAME=$(echo "$INPUT" | jq -r '.hook_event_name // "PreToolUse"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')

LOG="${CLAUDE_PROJECT_DIR:-$(echo "$INPUT" | jq -r '.cwd // "."')}/logs/hook-read.log"
mkdir -p "$(dirname "$LOG")"

echo "$(date): READ -- file=[$FILE_PATH]" >> "$LOG"

CTX="READ GUARD: For large files, use chunked reading: 800-line chunks with 200-line overlap. Never buffer entire files in memory. Process what you read immediately, write or update outputs per chunk, do not accumulate."

jq -n --arg event "$EVENT_NAME" --arg ctx "$CTX" '{
  hookSpecificOutput: {
    hookEventName: $event,
    additionalContext: $ctx
  }
}'