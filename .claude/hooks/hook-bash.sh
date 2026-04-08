#!/usr/bin/env bash
# hook-bash.sh -- PreToolUse: Bash hook
# Safety guard for Bash commands:
# CHECK 1: Catastrophic destructive commands (DENY)
# CHECK 2: Compound command detection (DENY)
# CHECK 3: CWD escape via cd (DENY)
# CHECK 4: Risky but recoverable commands (WARN via context)

INPUT=$(cat)
EVENT_NAME=$(echo "$INPUT" | jq -r '.hook_event_name // "PreToolUse"')
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // ""')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$CWD}"
LOG="${PROJECT_DIR}/logs/hook-bash.log"

mkdir -p "$(dirname "$LOG")"

# Helper: Deny with reason
emit_deny() {
    local reason="$1"
    echo "$(date): DENY -- cmd=[$COMMAND] reason=[$reason]" >> "$LOG"
    jq -n --arg reason "$reason" '{
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
    }'
    exit 0
}

# Helper: emit context warning
emit_context() {
    local ctx="$1"
    echo "$(date): WARN -- cmd=[$COMMAND]" >> "$LOG"
    jq -n --arg ctx "$ctx" '{
        hookEventName: "PreToolUse",
        additionalContext: $ctx
    }'
    exit 0
}

# CHECK 1: Catastrophic destructive commands (DENY)
if echo "$COMMAND" | grep -qiE '\brm\s+-rf\s+/($|[^-a-z])|rm\s+-rf\s+/\*|rm\s+--no-preserve-root|mkfs\.|dd\s+if=.+of=/dev/[sh]d[a-z](\s|$|\*).*'; then
    emit_deny "BLOCKED: Catastrophically destructive command detected. Command: [$COMMAND]. A Saiyan fights WITH PRECISION, not annihilation."
fi

# Strip quoted strings to avoid false positives on operators inside quotes.
# Remove single-quoted strings, then double-quoted strings.
STRIPPED=$(echo "$COMMAND" | sed "s/'[^']*'//g" | sed 's/"[^"]*"//g')

# CHECK 2: Compound command detection (DENY)
if echo "$STRIPPED" | grep -qE '&&'; then
    emit_deny "BLOCKED: Compound command detected (&&). Execute commands SEQUENTIALLY via separate Bash tool calls, not chained. Split into individual commands. Command: [$COMMAND]"
fi

if echo "$STRIPPED" | grep -qE '\|\|'; then
    emit_deny "BLOCKED: Compound command detected (||). Execute commands SEQUENTIALLY via separate Bash tool calls, not chained. Split into individual commands. Command: [$COMMAND]"
fi

if echo "$STRIPPED" | grep -qE ';'; then
    emit_deny "BLOCKED: Compound command detected (;). Execute commands SEQUENTIALLY via separate Bash tool calls, not chained. Split into individual commands. Command: [$COMMAND]"
fi

# Pipe detection: single | but not ||
# if echo "$STRIPPED" | grep -qE '(^|[^|])\|([^|]|$)'; then
#     emit_deny "BLOCKED: Pipe command detected (|). Execute commands SEQUENTIALLY via separate Bash tool calls, not piped. Split into individual commands. Command: [$COMMAND]"
# fi

# CHECK 3: CWD escape via cd (DENY)
if echo "$COMMAND" | grep -qE '^\s*cd\s+'; then
    CD_TARGET=$(echo "$COMMAND" | sed -E 's/^\s*cd\s+//' | sed 's/\s*$//')
    
    # Block cd to home directory
    if [[ "$CD_TARGET" == "~" ]] || [[ "$CD_TARGET" == "~/"* ]]; then
        emit_deny "BLOCKED: cd to home directory detected. All operations must stay within the project directory [$PROJECT_DIR]. Command: [$COMMAND]"
    fi
    
    # Block cd to absolute path outside project (Unix /path or Windows C:/path)
    NORM_CD_TARGET=$(echo "$CD_TARGET" | sed 's/\\/\//g')
    CD_IS_ABS=false
    if [[ "$NORM_CD_TARGET" == "/"* ]]; then
        CD_IS_ABS=true
    elif [[ "$NORM_CD_TARGET" =~ ^[A-Za-z]:/ ]]; then
        CD_IS_ABS=true
    fi
    
    if [ "$CD_IS_ABS" = true ]; then
        NORM_CWD=$(echo "$CWD" | sed 's/\\/\//g')
        NORM_PROJECT=$(echo "$PROJECT_DIR" | sed 's/\\/\//g')
        if [[ "$NORM_CD_TARGET" != "$NORM_CWD"* ]] && [[ "$NORM_CD_TARGET" != "$NORM_PROJECT"* ]]; then
            emit_deny "BLOCKED: cd target [$CD_TARGET] is outside the project directory [$PROJECT_DIR]. All operations must stay within CWD. Command: [$COMMAND]"
        fi
    fi
fi

# CHECK 4: Risky but recoverable commands (WARN via context)
if echo "$COMMAND" | grep -qiE '\bgit\s+push\s+.*--force|git\s+reset\s+--hard|git\s+clean\s+-f|git\s+branch\s+-[Dd]\s+.*|DROP\s+TABLE|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\w+\s*;|chmod\s+-R\s+777'; then
    emit_context "RISKY COMMAND WARNING: This command is potentially destructive but recoverable. Confirm it is intentional, authorized, and reversible before proceeding. Command: [$COMMAND]"
fi

# Default: approve silently
echo "$(date): ALLOW -- cmd=[$COMMAND]" >> "$LOG"
exit 0