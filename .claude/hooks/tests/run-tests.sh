#!/usr/bin/env bash
# run-tests.sh — Comprehensive hook test suite
# Tests every check in hook-bash.sh, hook-read.sh, hook-write.sh, hook-task.sh
# Usage: /workspace/.claude/hooks/tests/run-tests.sh
# Exit: 0 if all pass, 1 if any fail

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

# ── Assertion helpers ──────────────────────────────────────────────────────────

assert_deny() {
    local num="$1" desc="$2" json="$3"
    local out
    out=$(echo "$json" | "$HOOK_DIR/hook-bash.sh" 2>/dev/null)
    if echo "$out" | grep -q '"deny"'; then
        echo "PASS: [$num] $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: [$num] $desc  (expected DENY)"
        FAIL=$((FAIL + 1))
    fi
}

assert_allow() {
    local num="$1" desc="$2" json="$3"
    local out
    out=$(echo "$json" | "$HOOK_DIR/hook-bash.sh" 2>/dev/null)
    if echo "$out" | grep -q '"deny"'; then
        echo "FAIL: [$num] $desc  (expected ALLOW, got DENY)"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: [$num] $desc"
        PASS=$((PASS + 1))
    fi
}

assert_warn() {
    local num="$1" desc="$2" json="$3"
    local out
    out=$(echo "$json" | "$HOOK_DIR/hook-bash.sh" 2>/dev/null)
    if echo "$out" | grep -q '"deny"'; then
        echo "FAIL: [$num] $desc  (expected WARN, got DENY)"
        FAIL=$((FAIL + 1))
    elif echo "$out" | grep -q 'additionalContext'; then
        echo "PASS: [$num] $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: [$num] $desc  (expected WARN context, got nothing)"
        FAIL=$((FAIL + 1))
    fi
}

assert_context() {
    local num="$1" desc="$2" json="$3" hook="$4"
    local out
    out=$(echo "$json" | "$hook" 2>/dev/null)
    if echo "$out" | grep -q 'additionalContext'; then
        echo "PASS: [$num] $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: [$num] $desc  (expected additionalContext)"
        FAIL=$((FAIL + 1))
    fi
}

assert_context_contains() {
    local num="$1" desc="$2" json="$3" hook="$4" substr="$5"
    local out
    out=$(echo "$json" | "$hook" 2>/dev/null)
    if echo "$out" | grep -q "$substr"; then
        echo "PASS: [$num] $desc"
        PASS=$((PASS + 1))
    else
        echo "FAIL: [$num] $desc  (expected '$substr' in output)"
        FAIL=$((FAIL + 1))
    fi
}

assert_context_not_contains() {
    local num="$1" desc="$2" json="$3" hook="$4" substr="$5"
    local out
    out=$(echo "$json" | "$hook" 2>/dev/null)
    if echo "$out" | grep -q "$substr"; then
        echo "FAIL: [$num] $desc  (unexpected '$substr' found in output)"
        FAIL=$((FAIL + 1))
    else
        echo "PASS: [$num] $desc"
        PASS=$((PASS + 1))
    fi
}

# ── JSON builders ──────────────────────────────────────────────────────────────

bash_json() {
    jq -n --arg cmd "$1" \
        '{"hook_event_name":"PreToolUse","tool_input":{"command":$cmd},"cwd":"/workspace"}'
}

read_json() {
    jq -n --arg path "$1" \
        '{"hook_event_name":"PreToolUse","tool_input":{"file_path":$path},"cwd":"/workspace"}'
}

write_json() {
    jq -n --arg path "$1" --arg content "$2" \
        '{"hook_event_name":"PreToolUse","tool_input":{"file_path":$path,"content":$content},"cwd":"/workspace"}'
}

task_json() {
    jq -n --arg event "$1" --arg subject "$2" --arg desc "$3" \
        '{"hook_event_name":$event,"task_subject":$subject,"task_description":$desc,"cwd":"/workspace"}'
}

# ── Tests: hook-bash.sh ────────────────────────────────────────────────────────

echo ""
echo "=== hook-bash.sh: CHECK 0 — rm variants ==="
assert_deny  1  "rm file"                     "$(bash_json 'rm file')"
assert_deny  2  "rm -rf /"                    "$(bash_json 'rm -rf /')"
assert_deny  3  "sudo rm file"                "$(bash_json 'sudo rm file')"
assert_deny  4  "xargs rm < filelist"         "$(bash_json 'xargs rm < filelist')"
assert_deny  5  "find -exec rm {} +"          "$(bash_json 'find . -exec rm {} +')"
assert_deny  6  "env rm file"                 "$(bash_json 'env rm file')"

echo ""
echo "=== hook-bash.sh: CHECK 0b — git variants ==="
assert_deny  7  "git push"                    "$(bash_json 'git push')"
assert_deny  8  "git commit -m test"          "$(bash_json 'git commit -m test')"
assert_deny  9  "sudo git push"               "$(bash_json 'sudo git push')"
assert_deny 10  "xargs git add ."             "$(bash_json 'xargs git add .')"
assert_deny 11  "env git push"                "$(bash_json 'env git push')"

echo ""
echo "=== hook-bash.sh: CHECK 0c — shell wrappers ==="
assert_deny 12  "bash -c ls"                  "$(bash_json 'bash -c ls')"
assert_deny 13  "sh -c ls"                    "$(bash_json 'sh -c ls')"
assert_deny 14  "zsh -c ls"                   "$(bash_json 'zsh -c ls')"
assert_deny 15  "eval ls"                     "$(bash_json 'eval ls')"
assert_deny 16  "exec ls"                     "$(bash_json 'exec ls')"

echo ""
echo "=== hook-bash.sh: CHECK 1 — catastrophic wipes ==="
assert_deny 17  "mkfs.ext4 /dev/sda"          "$(bash_json 'mkfs.ext4 /dev/sda')"
assert_deny 18  "dd if=/dev/zero of=/dev/sdb" "$(bash_json 'dd if=/dev/zero of=/dev/sdb')"

echo ""
echo "=== hook-bash.sh: CHECK 2 — compound operators ==="
assert_deny 19  "ls && echo test  (&&)"       "$(bash_json 'ls && echo test')"
assert_deny 20  "ls || echo test  (||)"       "$(bash_json 'ls || echo test')"
assert_deny 21  "ls; echo test    (;)"        "$(bash_json 'ls; echo test')"
assert_allow 22 "echo 'hello; world'  (quoted semicolon → ALLOW)" \
    "$(bash_json "echo 'hello; world'")"

echo ""
echo "=== hook-bash.sh: CHECK 3 — cd escape ==="
assert_deny 23  "cd ~"                        "$(bash_json 'cd ~')"
assert_deny 24  "cd ~/projects"               "$(bash_json 'cd ~/projects')"
assert_deny 25  "cd /etc  (outside project)"  "$(bash_json 'cd /etc')"
assert_allow 26 "cd /workspace/subdir  (inside project)" \
    "$(bash_json 'cd /workspace/subdir')"
assert_allow 27 "cd relative/path  (relative, no abs check)" \
    "$(bash_json 'cd relative/path')"

echo ""
echo "=== hook-bash.sh: CHECK 4 — risky commands (WARN not DENY) ==="
assert_warn 28  "DROP TABLE → warn"           "$(bash_json 'DROP TABLE users')"
assert_warn 29  "chmod -R 777 → warn"         "$(bash_json 'chmod -R 777 /workspace')"

echo ""
echo "=== hook-bash.sh: safe commands — ALLOW ==="
assert_allow 30 "ls -la"                      "$(bash_json 'ls -la')"
assert_allow 31 "grep -r pattern /workspace"  "$(bash_json 'grep -r pattern /workspace')"
assert_allow 32 "mkdir -p /workspace/dir"     "$(bash_json 'mkdir -p /workspace/dir')"
assert_allow 33 "echo hello"                  "$(bash_json 'echo hello')"
assert_allow 34 "cat /workspace/file.txt"     "$(bash_json 'cat /workspace/file.txt')"
assert_allow 35 "wc -l /workspace/file.txt"   "$(bash_json 'wc -l /workspace/file.txt')"

# ── Tests: hook-read.sh ────────────────────────────────────────────────────────

echo ""
echo "=== hook-read.sh ==="
assert_context 36 "read any file → context emitted" \
    "$(read_json '/workspace/somefile.txt')" "$HOOK_DIR/hook-read.sh"
assert_context 37 "read non-existent path → context still emitted" \
    "$(read_json '/workspace/does-not-exist.txt')" "$HOOK_DIR/hook-read.sh"

# ── Tests: hook-write.sh ───────────────────────────────────────────────────────

echo ""
echo "=== hook-write.sh ==="
SMALL_CONTENT=$(awk 'BEGIN{for(i=1;i<=100;i++)print "line"}')
LARGE_CONTENT=$(awk 'BEGIN{for(i=1;i<=600;i++)print "line"}')
assert_context_not_contains 38 "100-line write → no 500-line warning" \
    "$(write_json '/workspace/out.txt' "$SMALL_CONTENT")" \
    "$HOOK_DIR/hook-write.sh" "exceeds the 500-line limit"
assert_context_contains 39 "600-line write → 500-line warning" \
    "$(write_json '/workspace/out.txt' "$LARGE_CONTENT")" \
    "$HOOK_DIR/hook-write.sh" "exceeds the 500-line limit"

# ── Tests: hook-task.sh ────────────────────────────────────────────────────────

echo ""
echo "=== hook-task.sh ==="
assert_context_contains 40 "TaskCreated short desc → warns about length" \
    "$(task_json 'TaskCreated' 'Fix bug' 'short')" \
    "$HOOK_DIR/hook-task.sh" "too short"
assert_context_not_contains 41 "TaskCreated valid desc → no short-desc warning" \
    "$(task_json 'TaskCreated' 'Fix bug' 'This is a sufficiently long task description')" \
    "$HOOK_DIR/hook-task.sh" "too short"
assert_context_contains 42 "TaskCompleted → validation gate context" \
    "$(task_json 'TaskCompleted' 'Fix bug' '')" \
    "$HOOK_DIR/hook-task.sh" "validation gate"
assert_context 43 "TaskCompleted → hook exits 0 (non-blocking)" \
    "$(task_json 'TaskCompleted' 'Fix bug' '')" "$HOOK_DIR/hook-task.sh"

# ── Summary ────────────────────────────────────────────────────────────────────

echo ""
echo "══════════════════════════════════════"
TOTAL=$((PASS + FAIL))
echo "SUMMARY: $PASS/$TOTAL passed"
if [ "$FAIL" -gt 0 ]; then
    echo "$FAIL test(s) FAILED"
    exit 1
fi
echo "All tests passed."
exit 0
