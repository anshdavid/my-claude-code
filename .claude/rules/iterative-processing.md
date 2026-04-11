---
paths:
  - "/*"
---

# Iterative Processing Rule

> Builds on: `@.claude/rules/iterative-read.md` · `@.claude/rules/iterative-write.md` · `@.claude/rules/task-workflow-orchestration.md`

Governs coupling of chunked reading with incremental writing when both input and output are large. Enforces the triplet — the irreducible atomic unit:

```
READ chunk N  →  PROCESS chunk N  →  WRITE output for chunk N
```

Never decouple. Do NOT read all chunks first, then write. Do NOT write without having just read the corresponding input. The process step is mandatory — skipping it produces mechanical output with no synthesis.

What "process" means per task type:

| Task type                    | Process step                                         |
| ---------------------------- | ---------------------------------------------------- |
| Format transformation        | Apply formatting rules to the chunk's raw content    |
| Analysis / extraction        | Extract insights, entities, relationships            |
| Documentation / architecture | Write the corresponding section with full content    |
| Code generation              | Generate the corresponding code for the chunk's spec |
| Summarization                | Condense the chunk into its summary contribution     |

---

## When This Rule Applies

All three conditions must be true; otherwise apply `iterative-read.md` or `iterative-write.md` alone.

| Condition                | Threshold                                                      |
| ------------------------ | -------------------------------------------------------------- |
| Source input is large    | > 600 lines                                                    |
| Output is large          | > 500 lines                                                    |
| Processing is sequential | Each output section derives from its corresponding input chunk |

---

## Algorithm

Phase 0 — Assess & Plan (before reading anything):

1. Size the source (`wc -l` or read first 100 lines).
2. Plan chunks: 800-line limit, 200-line overlap, stride = 600 (per `iterative-read.md`). Name each chunk → output section mapping explicitly.
3. Choose write strategy: Sequential (independent sections) or Scaffold-then-Fill (cross-references need stable IDs first — write full scaffold with all headers/stubs/placeholders in Pass 1, then fill per chunk).
4. Create one task per triplet: `"Read chunk N (lines X–Y) → write Section Z"`.

```
Task 1:   Size source → plan chunks
Task 2:   Read chunk 1 (1–800)     → process → Write   Section A   ← creates file
Task 3:   Read chunk 2 (601–1400)  → process → Edit append Section B
Task 4:   Read chunk 3 (1201–2000) → process → Edit append Section C
Task N+1: Post-process — cross-reference and validate
Task N+2: Final verification
```

Phase 1 — First chunk: `Read(chunk 1)` → process → `Write` tool (creates the output file with chunk 1's content).

Phase 2 — Each subsequent chunk N:

1. Mark task in-progress.
2. `Read(chunk N)` at planned offset/limit.
3. Process the content.
4. `Edit` to append (≤ 500 lines per pass; split into sub-passes N.a / N.b if larger).
5. Validate: section complete, no remaining placeholders, next chunk can proceed.
6. Mark task complete. Stop when a chunk returns < 800 lines — that is EOF.

Phase 3 — Post-process: cross-reference consistency → `task-workflow-orchestration.md` validation → confirm 0 placeholders, 0 empty sections, 0 orphaned references.

---

## Anti-Patterns

- ❌ Read-all-then-write-all — `Read(1) → Read(2) → Read(3) → Write all`. Bloats context; early chunks are forgotten by write time.
- ❌ Write-without-reading — writing a section from memory, then reading to verify. Always read the chunk first.
- ❌ Unbounded writes — a single Edit call with 1,000+ lines. Apply the ≤ 500-line ceiling; split if needed.
- ❌ Skip the process step — `Read → Write` with no analysis in between. The middle step is where understanding happens.

---

## Examples

Sequential — independent sections (3,103-line raw dump → ~900-line formatted markdown, 6 chunks):

```
Task 1: wc -l → 3,103 lines → plan 6 chunks
Task 2: Read(0–600)     → identify §1–10  → Write Part I §1–10
Task 3: Read(600–1200)  → identify §11–16 → Append Part I §11–16
Task 4: Read(1200–1800) → identify Part II §1–14 → Append Part II §1–14
...continue per chunk...
Task 8: Post-process → verify 0 raw artifacts, check line count
```

Scaffold-then-Fill — cross-references require stable IDs (3,007-line guide → 3,658-line architecture reference, 33 diagrams, 20 ADRs, 27 TBDs):

```
Pass 1:  Write scaffold — all chapter headers, ADR-0001..0020 stubs, D1..D32 placeholders
Pass 2:  Read §I.1–§I.23   → Fill Part 1 (D1–D3)
Pass 3:  Read §I.4–§I.5    → Fill Part 2 (D4–D6)
Pass 4:  Read §II.2–§III.22 → Fill Part 3 Engine ch7–8 (D7–D11)
...continue per source section...
Pass 11: Sweep — 0 placeholders, all IDs present, balanced code fences
```

Scaffold locks in all stable identifiers before any prose is written so every pass can reference them.

---

## Strategy Choice

| Output type                                                           | Strategy                                                             |
| --------------------------------------------------------------------- | -------------------------------------------------------------------- |
| Independent sections (formatting, extraction, report chapters)        | Sequential — complete each section before the next chunk             |
| Interconnected system (cross-references, numbered IDs, shared schema) | Scaffold-then-Fill — stable IDs in Pass 1, fill per chunk thereafter |

---

## Integration Summary

| Rule                             | Role in iterative processing                                        |
| -------------------------------- | ------------------------------------------------------------------- |
| `iterative-read.md`              | Chunk boundaries: 800-line limit, 200-line overlap, EOF detection   |
| `iterative-write.md`             | ≤ 500 lines/pass; Sequential vs Scaffold-then-Fill strategy         |
| `task-workflow-orchestration.md` | Task structure, validation gates, dynamic adaptation mid-loop       |
| This rule                        | Couples them: enforces the triplet; forbids read-all-then-write-all |
