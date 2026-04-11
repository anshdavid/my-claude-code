---
paths:
  - "/*"
---

# Auto-Memory Rule

After completing any meaningful task, evaluate is there anything here worth remembering for future sessions?

If yes:

- Save it to `.claude/agent-memory/{agent|main_agent|[subagent_name]}/`
- Do not rely on re-discovery later

Best Practices:

- Save immediately after task completion
- Keep entries atomic (one idea per entry)
- Use clear, descriptive topic names
- Periodically refine and clean memory files

This ensures:

- Accumulated intelligence over time
- Faster future performance
- Reduced repeated mistakes
- Continuous learning
- Better future performance
- Reduced repetition and errors

## Memory System Structure

.claude/agent-memory/
├── MEMORY.md
├── experiments.md
├── patterns.md
├── decisions.md
└── {... additional generic files}

### MEMORY.md (Index)

- Concise index of all stored knowledge
- Auto-loaded every session
- Must stay under 200 lines
- Contains:
  - Topics
  - References to detailed files

### experiments.md (example)

- Results of tests, trials, and explorations
- What worked / failed
- Measured outcomes

### patterns.md (example)

- Reusable techniques
- Recurring solutions
- Known pitfalls and anti-patterns

### decisions.md (example)

- Architectural or design decisions
- Trade-offs and reasoning
- Why something was chosen over alternatives

### Additional Files

Create new topic files when needed:

- domain-specific knowledge
- frameworks
- workflows
- research notes

## Decision Criteria

1. When to Save: ONLY if the information is worth Saving:

- Non-obvious insight
- Reusable pattern
- Hard-earned learning
- Decision with reasoning
- Mistake worth avoiding
- Optimization or improvement
- New workflow or capability

2. Do NOT Save

- Code already in repository
- Anything easily re-derivable
- Temporary or session-specific state
- Incomplete or speculative ideas
- Raw outputs without insight

## Entry Design Principles

1. Be Concise, no long paragraphs. Use bullet points only
2. Capture Insight, Not Data

- Bad: Used 800-line chunks
- Good: Overlapping chunk reads (800/200) prevent boundary truncation errors

3. Make It Reusable: Write so it applies beyond the current task.
4. Avoid Redundancy: Do not repeat existing knowledge
5. Update instead of duplicating

## Examples

### Example 1 — Pattern

2026-04-07 — Iterative Writing Strategy

Large outputs (>500 lines) should never be generated in one pass
Use Sequential for independent sections
Use Scaffold → Fill for interdependent systems

### Example 2 — Decision

2026-04-07 — Chunked File Reading Strategy

Adopted 800-line chunks with 200-line overlap
Prevents truncation and boundary context loss
Trade-off: slight redundancy vs correctness (acceptable)

### Example 3 — Experiment

2026-04-07 — Resume ATS Optimization

Adding exact keyword matches improved ATS score from ~70% → ~92%
Keyword density matters more than formatting

### Example 4 — Feedback

2026-04-07 — Output Length Control

Avoid overly long single responses
Prefer structured, iterative delivery

### Example 5 — Skills

2026-04-07 — Agent Design Capability

Can design multi-agent orchestration systems
Strong in pattern-based architecture and workflow structuring

## Summary

- Evaluate learning after every task
- Save only high-value, reusable insights
- Use structured topic files
- Keep MEMORY.md as a clean index
- Focus on clarity, reuse, and long-term value
