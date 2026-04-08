#!/usr/bin/env bash
# hook-task.sh -- TaskCreated / TaskCompleted hook

INPUT=$(cat)

EVENT_NAME=$(echo "$INPUT" | jq -r '.hook_event_name // ""')
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // ""')
TASK_DESC=$(echo "$INPUT" | jq -r '.task_description // ""')

LOG="${CLAUDE_PROJECT_DIR:-$(echo "$INPUT" | jq -r '.cwd // "."')}/logs/hook-task.log"
mkdir -p "$(dirname "$LOG")"

if [ "$EVENT_NAME" == "TaskCreated" ]; then
  CTX="TASK CREATED: Verify this task follows decomposition standards: (1) Small scope with clear done-criteria, (2) Action-oriented title, (3) Dependency-ordered, (4) Specific enough that progress is unambiguous."
  
  DESC_LEN=${#TASK_DESC}
  if [ "$DESC_LEN" -lt 20 ]; then
    CTX="$CTX | WARNING: Task description is missing or too short ($DESC_LEN chars). A task without a clear description produces ambiguous outcomes. Add details."
  fi
  
  echo "$(date): TaskCreated -- subject=[$TASK_SUBJECT] desc_len=$DESC_LEN" >> "$LOG"

elif [ "$EVENT_NAME" == "TaskCompleted" ]; then
  CTX="TASK COMPLETING: Before marking done, verify the validation gate: (1) Output EXISTS - expected artifacts are present, (2) Output is CORRECT - matches task intent, (3) No ERRORS introduced (broken references), (4) Next task CAN PROCEED - output satisfies downstream needs. | MEMORY: If you encountered new patterns, errors, or lessons during this task, save them to agent-memory NOW"
  
  echo "$(date): TaskCompleted -- subject=[$TASK_SUBJECT]" >> "$LOG"

else
  exit 0
fi

jq -n --arg event "$EVENT_NAME" --arg ctx "$CTX" '{
  hookSpecificOutput: {
    hookEventName: $event,
    additionalContext: $ctx
  }
}'