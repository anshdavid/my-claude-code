---
paths:
  - "**/*"
---

# Iterative Processing Rule

> **Builds on:** `@.claude/rules/iterative-read.md` · `@.claude/rules/iterative-write.md` · `@.claude/rules/task-workflow-orchestration.md`

This rule governs how to couple chunked reading with incremental writing when both input and output are large. It enforces the core principle:

**Read one chunk → Process it → Write its output → then read the next chunk.**

Never decouple: do NOT read all chunks first, then write everything. Do NOT write without having just read the corresponding input.

---

## When This Rule Applies

Apply iterative processing when ALL of the following are true:

| Condition                | Threshold                                                      |
| ------------------------ | -------------------------------------------------------------- |
| Source input is large    | > 600 lines (chunked reading required)                         |
| Output is large          | > 500 lines (iterative writing required)                       |
| Processing is sequential | Each output section derives from the corresponding input chunk |

When only one condition is true, apply the relevant individual rule (`iterative-read.md` or `iterative-write.md`) instead.

---

## The Atomic Unit

The irreducible unit of iterative processing is a **triplet**:

```
READ chunk N  →  PROCESS chunk N  →  WRITE output for chunk N
```

This triplet must stay coupled. Breaking it apart is the primary anti-pattern.

**What "process" means per task type:**

| Task type             | Process step                                             |
| --------------------- | -------------------------------------------------------- |
| Format transformation | Apply formatting rules to the chunk's raw content        |
| Analysis / extraction | Extract insights, entities, relationships from the chunk |
| Documentation         | Write the corresponding documentation section            |
| Code generation       | Generate the corresponding code for the chunk's spec     |
| Summarization         | Condense the chunk into its summary contribution         |

---

## The Loop Algorithm

### Phase 0 — Assess and Plan

Before reading anything:

1. **Size the input.** Read the first 50–100 lines (or use `wc -l`) to determine total size.
2. **Plan chunks.** Apply `iterative-read.md` rules: 800-line limit, 200-line overlap (stride = 600).
3. **Plan output sections.** Map each chunk to its output section. Name them explicitly.
4. **Create tasks.** One task per chunk-triplet: "Read chunk N (lines X–Y) → write section Z".

```
Chunk plan example (2,400-line source → 4 chunks):
  Chunk 1: offset=0,    limit=800  → Section A
  Chunk 2: offset=600,  limit=800  → Section B
  Chunk 3: offset=1200, limit=800  → Section C
  Chunk 4: offset=1800, limit=800  → Section D (EOF if <800 lines returned)
```

### Phase 1 — First Chunk (Write or Scaffold)

For the **first chunk**:

- Read chunk 1 per `iterative-read.md`
- Process its content
- **Write**: use `Write` tool to create the output file with chunk 1's content
  - If output sections are independent → use **Sequential strategy** (`iterative-write.md §1`)
  - If output is a single interconnected structure → use **Scaffold-then-Fill** (`iterative-write.md §2`): write the full scaffold in Pass 1 (all headers, stable IDs, placeholders), then fill section 1

### Phase 2 — Subsequent Chunks (Append)

For each remaining chunk N:

1. **Mark task N in-progress.**
2. **Read** chunk N using the planned offset/limit from `iterative-read.md`.
3. **Process** the chunk content (analyze, extract, transform).
4. **Write** the output for chunk N:
   - Use `Edit` tool to append to the output file
   - Keep each write ≤ 500 lines (`iterative-write.md` ceiling)
   - If chunk N's output > 500 lines, split into sub-passes (N.a, N.b)
5. **Validate** before proceeding:
   - Content is complete for this chunk's scope
   - No placeholder tokens remain in chunk N's section
   - The next chunk can proceed (context is correctly established)
6. **Mark task N complete.**
7. Read chunk N+1. Stop when a chunk returns fewer than 800 lines — that is EOF.

### Phase 3 — Post-Processing

After all chunks are written:

1. **Cross-reference pass**: check consistency across sections (references, numbering, terminology).
2. **Verification**: run the checks from `task-workflow-orchestration.md §Task validation`.
3. **Completeness**: no placeholder tokens, no empty sections, no orphaned cross-references.

---

## Task Structure

Map the loop to tasks per `task-workflow-orchestration.md`:

```
Task 1:   Assess source size and plan N chunks
Task 2:   Read chunk 1 (lines 1–800)    + write Section A   ← triplet
Task 3:   Read chunk 2 (lines 601–1400) + write Section B   ← triplet
Task 4:   Read chunk 3 (lines 1201–2000)+ write Section C   ← triplet
Task N+1: Post-process — cross-reference and validate
Task N+2: Final verification
```

Each triplet task is **atomic** — do not split "read chunk N" and "write section N" into separate tasks unless chunk N's output exceeds the 500-line write ceiling (in which case: N.a = read + write first half, N.b = write second half).

---

## Anti-Patterns

**❌ Read-all-then-write-all**

```
# WRONG
Read chunk 1 → Read chunk 2 → Read chunk 3 → Write everything
```

Bloats context, loses per-chunk coherence, and early chunks are forgotten by the time writing starts.

**❌ Write-without-reading**

```
# WRONG
Write section A from memory → Read chunk 1 → notice mismatch → rewrite
```

Always read the chunk before writing its corresponding output.

**❌ Unbounded writes per pass**

Writing 1,000 lines in a single Edit call. Apply `iterative-write.md` ceiling: ≤ 500 lines per write pass.

**❌ Skipping the process step**

Reading chunk N and immediately writing without analysis. The triplet is Read → **Process** → Write. The middle step is where understanding happens — skipping it produces mechanical output with no synthesis.

---

## Example 1: Raw-to-Formatted Markdown

**Source:** 3,103-line raw ChatGPT dump  
**Output:** formatted markdown (~900 lines)  
**Strategy:** Sequential (sections are independent)

```
Task 1: wc -l source → 3,103 lines → plan 6 chunks (stride=600)
Task 2: Read chunk 1 (0–600)    → identify §1–10  → Write Part I §1–10
Task 3: Read chunk 2 (600–1200) → identify §11–16 → Append Part I §11–16
Task 4: Read chunk 3 (1200–1800)→ identify Part II §1–14 → Append Part II §1–14
Task 5: Read chunk 4 (1800–2400)→ identify Part II §15–28 → Append Part II §15–28
Task 6: Read chunk 5 (2400–3000)→ identify Part III §1–20 → Append Part III §1–20
Task 7: Read chunk 6 (3000–3103 — EOF) → Part III §21–31 → Append Part III §21–31
Task 8: Post-process → verify 0 raw artifacts, check line count
```

Each task reads one chunk, identifies its sections, and writes immediately. The file grows chunk by chunk.

---

## Example 2: Architecture Reference with Cross-References

**Source:** 3,007-line formatted guide  
**Output:** 3,658-line architecture reference (33 mermaid diagrams, 20 ADRs, 27 TBDs)  
**Strategy:** Scaffold-then-Fill (cross-references require stable IDs before prose)

```
Pass 1:  Write full scaffold (~350 lines) — all chapter headers, ADR stubs (ADR-0001..0020),
         diagram placeholders (D1..D32), TBD stubs (TBD-01..TBD-27)
Pass 2:  Read source §I.1–§I.23   → Fill Part 1 Foundations (D1–D3)
Pass 3:  Read source §I.4–§I.5    → Fill Part 2 Runtime (D4–D6)
Pass 4:  Read source §II.2–§III.22 → Fill Part 3 Engine ch7–8 (D7–D11)
Pass 5:  Read source §II.7.C–§III.12 → Fill Part 3 Engine ch9–9A (D12–D14)
Pass 6:  Read source §I.11–§I.8   → Fill Part 4 Memory+Tools (D15–D20)
Pass 7:  Read source §I.12–§I.10  → Fill Part 4 Broker+Channels+Skills (D21–D24)
Pass 8:  Read source §II.8–§II.13 → Fill Part 5 Teams (D25–D30)
Pass 9:  Read source §III.23–§I.13 → Fill Part 6 Data+Security+Observability (D31)
Pass 10: Read source §I.19–§I.18  → Fill Part 7 Roadmap+ADRs+TBDs (D32)
Pass 11: Sweep — verify: 0 placeholders, all IDs present, balanced code fences
```

The scaffold locks in all stable identifiers (ADR-0001, TBD-07, D12) so any pass can reference them without knowing future pass content.

---

## Choosing Sequential vs. Scaffold-then-Fill

| Output type                                                           | Strategy                                                                           |
| --------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Independent sections (formatting, extraction, report chapters)        | **Sequential** — write each section completely before next chunk                   |
| Interconnected system (cross-references, numbered IDs, shared schema) | **Scaffold-then-Fill** — establish stable IDs in Pass 1, fill per chunk thereafter |

---

## Integration Summary

| Rule                             | Role in iterative processing                                                           |
| -------------------------------- | -------------------------------------------------------------------------------------- |
| `iterative-read.md`              | Chunk boundaries: 800-line limit, 200-line overlap, EOF detection                      |
| `iterative-write.md`             | Write ceiling: ≤500 lines/pass; strategy: Sequential vs Scaffold-then-Fill             |
| `task-workflow-orchestration.md` | Task structure, validation gates, dynamic adaptation mid-loop                          |
| **This rule**                    | Couples them: enforces the Read→Process→Write triplet; forbids read-all-then-write-all |
