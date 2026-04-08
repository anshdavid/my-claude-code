#!/usr/bin/env bash
# hook-write.sh -- PreToolUse:Write hook

INPUT=$(cat)

EVENT_NAME=$(echo "$INPUT" | jq -r '.hook_event_name // "PreToolUse"')
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // "unknown"')
CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // ""')

LOG="${CLAUDE_PROJECT_DIR:-$(echo "$INPUT" | jq -r '.cwd // "."')}/logs/hook-write.log"
mkdir -p "$(dirname "$LOG")"

LINE_COUNT=$(echo "$CONTENT" | wc -l)
echo "$(date): WRITE -- file=[$FILE_PATH] lines=$LINE_COUNT" >> "$LOG"

CTX="WRITE GUARD: Max 500 lines per write pass — use iterative strategy for large outputs. Prefer Edit over Write for existing files. Never overwrite without reading the file first. Scaffold-then-fill for interdependent structures."

if [ "$LINE_COUNT" -gt 500 ]; then
  CTX="$CTX | WARNING: This write is ${LINE_COUNT} lines — exceeds the 500-line limit. Break into iterative passes instead."
fi

jq -n --arg event "$EVENT_NAME" --arg ctx "$CTX" '{
  hookSpecificOutput: {
    hookEventName: $event,
    additionalContext: $ctx
  }
}'
