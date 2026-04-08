#!/usr/bin/env bash
# hook-bash.sh -- PreToolUse: Bash hook
# Safety guard for Bash commands:
# CHECK 0:  All rm commands (DENY) — direct, sudo, xargs, find -exec, env
# CHECK 0b: All git commands (DENY) — direct, sudo, xargs, env
# CHECK 0c: Shell execution wrappers (DENY) — bash -c, sh -c, eval, exec
# CHECK 1:  Catastrophic filesystem wipe — mkfs, dd (DENY)
# CHECK 2:  Compound command detection (DENY)
# CHECK 3:  CWD escape via cd (DENY)
# CHECK 4:  Risky but recoverable — SQL, chmod 777 (WARN via context)

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
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: "deny",
            permissionDecisionReason: $reason
        }
    }'
    exit 0
}

# Helper: emit context warning
emit_context() {
    local ctx="$1"
    echo "$(date): WARN -- cmd=[$COMMAND]" >> "$LOG"
    jq -n --arg ctx "$ctx" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            additionalContext: $ctx
        }
    }'
    exit 0
}

# CHECK 0: Block all rm commands (DENY)
# Catches: rm, sudo rm, xargs rm, find -exec rm, env rm
if echo "$COMMAND" | grep -qE '(^\s*rm\b|^\s*sudo\s+.*\brm\b|\bxargs\s+.*\brm\b|\bfind\b.*-exec\s+rm\b|^\s*env\s+.*\brm\b)'; then
    emit_deny "BLOCKED: rm is not allowed. Ask the user to remove files manually. Command: [$COMMAND]"
fi

# CHECK 0b: Block all git commands (DENY)
# Catches: git, sudo git, xargs git, env git
if echo "$COMMAND" | grep -qE '(^\s*git\b|^\s*sudo\s+.*\bgit\b|\bxargs\s+.*\bgit\b|^\s*env\s+.*\bgit\b)'; then
    emit_deny "BLOCKED: git commands are not allowed. All version control operations must be performed manually by the user. Command: [$COMMAND]"
fi

# CHECK 0c: Block shell execution wrappers (DENY)
# These wrap arbitrary commands and bypass quote-stripping analysis.
# bash -c "rm file" → after stripping quotes, rm is invisible to later checks.
if echo "$COMMAND" | grep -qE '^\s*(bash|sh|zsh|dash)\s+.*-c\b'; then
    emit_deny "BLOCKED: Shell execution wrappers (bash -c, sh -c, etc.) are not allowed as they bypass safety checks. Run commands directly instead. Command: [$COMMAND]"
fi
if echo "$COMMAND" | grep -qE '^\s*eval\b'; then
    emit_deny "BLOCKED: eval is not allowed as it bypasses safety checks. Run commands directly instead. Command: [$COMMAND]"
fi
if echo "$COMMAND" | grep -qE '^\s*exec\b'; then
    emit_deny "BLOCKED: exec is not allowed as it bypasses safety checks. Run commands directly instead. Command: [$COMMAND]"
fi

# CHECK 1: Catastrophic filesystem wipe (DENY)
if echo "$COMMAND" | grep -qiE 'mkfs\.|dd\s+if=.+of=/dev/[sh]d[a-z](\s|$|\*).*'; then
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
if echo "$COMMAND" | grep -qiE 'DROP\s+TABLE|TRUNCATE\s+TABLE|DELETE\s+FROM\s+\w+\s*;|chmod\s+-R\s+777'; then
    emit_context "RISKY COMMAND WARNING: This command is potentially destructive but recoverable. Confirm it is intentional, authorized, and reversible before proceeding. Command: [$COMMAND]"
fi

# Default: approve silently
echo "$(date): ALLOW -- cmd=[$COMMAND]" >> "$LOG"
exit 0