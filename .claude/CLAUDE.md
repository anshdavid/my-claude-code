# CLAUDE.md

## 1. Plan Node Default

- Enter plan mode for ANY non-trivial task (3+ steps or architectural decisions)
- If something goes sideways, STOP and re-plan immediately - don't keep pushing
- Use plan mode for verification steps, not just building
- Write detailed specs upfront to reduce ambiguity

## 2. Subagent Strategy

Use subagents liberally to keep main context window clean

- Offload research, exploration, and parallel analysis to subagents
- For complex problems, throw more compute at it via subagents
- One tack per subagent for focused execution

## 3. Self-Improvement Loop

- After ANY correction from the user: update memory with the pattern
- Write rules for yourself that prevent the same mistake
- Ruthlessly iterate on these lessons until mistake rate drops
- Review lessons at session start for relevant project

## 4. Verification Before Done

- Never mark a task complete without proving it works
- Diff behavior between main and your changes when relevant
- Ask yourself: "Would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness

## 5. Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "Knowing everything I know now, implement the elegant solution"
- Skip this for simple, obvious fixes - don't over-engineer
- Challenge your own work before presenting it

## 6. Autonomous Bug Fizing

- When given a bug report: just fix it. Don't ask for hand-holding
- Point at logs, errors, failing tests - then resolve them
- Zero context switching required from the user
- Go fix failing CI tests without being told how

## Task Management

1. **Analyze** — understand the problem fully before touching anything
2. **Plan First**: Write plan to tasks/todo.md with checkable items
3. **Verify Plan**: Check in before starting implementation
4. **Implement** — execute with precision
5. **Track Progress**: Mark items complete as you go
6. **Explain Changes**: High-level summary at each step
7. **Document Results**: Add review section to 'tasks/todo.md'
8. **Capture Lessons**: Update `tasks/lessons.md' after corrections
9. **Simplicity First**: Make every change as simple as possible. Impact minimal code.
10. **No Laziness**: Find root causes. No temporary fixes. Senior developer standards.
11. **Minimat Impact**: Changes should only touch what's necessary. Avoid introducing bugs.
12. **Refine** — tighten the plan before writing code

## Rule Protocol

1. Follow the memory rules at `@.claude/rules/memory-update.md`
2. Follow the read chunking rules at `@.claude/rules/iterative-read.md`
3. Follow the iterative write rules at `@.claude/rules/iterative-write.md`

**For Claude:** Match this pace. Front-load understanding. Don't jump to solutions. When asked to build something, lead with analysis and a clear plan. Raise constraints and tradeoffs explicitly rather than quietly making assumptions.

**Key env vars:** `CLAUDE_CONFIG_DIR=/home/node/.claude`, `DEVCONTAINER=true`
