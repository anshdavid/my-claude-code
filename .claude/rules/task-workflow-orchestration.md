---
paths:
  - "/*"
---

```note
This rule builds on top of the other operational rule guides
- `@.claude/rules/iterative-read.md`: iterative chunked reading.
- `@.claude/rules/iterative-write.md`: iterative writing.
- `@.claude/rules/memory-update.md`: claude agent memory update
```

## Description

Unified guide for decomposing work into tracked tasks and composing multi-layer workflows (agent, skill, reference) into a single dependency-ordered task list. Covers planning and breakdown, dynamic adaptation, task validation and lifecycle, and workflow layer merging.

When source input or output is large, coordinate with `iterative-processing` rule to structure execution tasks as read→process→write triplets, one per chunk.

## Planning and breakdown

1. Identify deliverables: What concrete outputs are expected?
2. For each deliverable, list the smallest meaningful units of work.
3. Break down workflow steps into smaller tasks until each is a clear, actionable step with a specific outcome.
4. Order by dependency: Arrange tasks so prerequisites come first.
5. If a step is too large, split it further recursively.

## Dynamic adaptation

Plans change, handle it without losing progress:

1. Modify: Update titles/order of not-started tasks as needed.
2. Insert: Add new tasks with clear titles and descriptions.
3. Remove: Drop tasks that are no longer needed (mark completed with skip note).

## Task validation

Before marking any task done, verify all four:

1. Output exists: The expected outcomes (files, actions, etc.) are present and performed.
2. Output is correct: Outcome matches what the task intended.
3. No errors introduced: Check for errors, issues, broken references.
4. Next task can proceed: The output satisfies what downstream tasks need.

## Task lifecycle

1. After completing a task, mark it as done.
2. If a task is skipped, mark it as done with a note explaining why.
3. If a task is modified, update its title and description accordingly.
4. If a new task is added, insert it with a clear title and description.
5. If a task is removed, mark it as done with a note explaining why it was removed.

## Workflow composition

When an agent loads a skill (and optionally a reference file), multiple workflow layers exist. Merge them into a single flat task list before starting work.

1. Read ALL workflow layers (agent, skill, reference) before creating any tasks.
2. Map each layer's steps to where they fit in dependency order relative to the other layers.
3. Apply three merge operations:

- ADD: When a layer introduces new work alongside another layer's step, add it as a separate task.
- EXPAND: When a layer's step makes a generic step concrete, replace the generic step with specific tasks.
- KEEP BOTH: When layers cover similar ground but serve different concerns (e.g., agent validation vs. skill validation), keep both as separate tasks.

4. "Decompose into tasks" steps are not tasks themselves — they represent the act of creating the task list.
5. Validation runs per layer — each layer's checks run as separate tasks.

## Rules

1. One active task in progress at a time — do not start the next task before the current one is validated.
2. Task titles must be action-oriented and specific enough that progress is unambiguous.
3. Prefer smaller tasks with clear done criteria over large vague tasks.
4. Always validate task output before marking done — not just that the step ran, but that the outcome is correct.
5. Every step from every workflow layer must appear in the final task list. Nothing is dropped.
6. When in doubt about merge operation, KEEP BOTH — redundant validation is safer than skipped validation.

## Examples 1:

Scenario:

- Single-layer, agent-only workflow with dynamic adaptation:
- An agent runs its own 4-step workflow with no skill or reference file.
- Input is 3 short artifacts. Output is a single report.
- During execution, a new requirement is discovered after Task 3.

Agent workflow:

- A1: Load session rules, read arguments
- A2: Read input artifacts
- A3: Generate report
- A4: Validate output
- A1 is setup. A2 expands per input. A3 is one task (small output). A4 is validation.

Initial task list:

- Task 1: Load session rules and identify the task ............ [A1]
- Task 2: Read input artifact 1 .............................. [A2, expanded]
- Task 3: Read input artifact 2 .............................. [A2, expanded]
- Task 4: Read input artifact 3 .............................. [A2, expanded]
- Task 5: Write report ....................................... [A3]
- Task 6: Validate report against requirements ................ [A4]

Dynamic adaptation — after Task 3, a cross-reference issue is discovered:

- Task 1: Load session rules and identify the task ............ [completed]
- Task 2: Read input artifact 1 .............................. [completed]
- Task 3: Read input artifact 2 .............................. [completed]
- Task 4: Read input artifact 3 .............................. [in-progress]
- Task 5: Cross-reference artifacts 1 and 2 for consistency .... [inserted — new discovery]
- Task 6: Write report ....................................... [renumbered]
- Task 7: Validate report against requirements ................ [renumbered]

Validation gate applied to Task 4 before proceeding:

- [check] Output exists: artifact 3 content extracted
- [check] Output correct: matches source
- [check] No errors: no broken references
- [check] Next task can proceed: Task 5 has what it needs

Key takeaways:

- Single layer: all 4 agent steps mapped directly to tasks
- A2 expanded into 3 tasks (one per input artifact)
- Dynamic adaptation inserted Task 5 without losing progress
- Validation gate checked before moving past Task 4

## Example 2

Scenario:

- Two-layer: agent + skill workflow composition:
- An agent has a 5-step workflow. It loads a skill with a 4-step workflow.
- No reference file. Input is moderate. Output has 3 sections.

LAYER 1 — Agent workflow:

- A1: Load session rules, read arguments, identify what to do
- A2: Locate and read input files
- A3: Decompose work into tracked tasks
- A4: Execute the work
- A5: Validate final output

LAYER 2 — Skill workflow:

- S1: Load session rules and read the skill scope
- S2: Read input artifacts and assess size
- S3: Process inputs and produce output sections
- S4: Validate output against skill checks

Merge mapping:

- S1 -> ADD AFTER A1 (both are setup — agent loads rules, skill reads scope)
- S2 -> ADD AFTER A2 (agent locates inputs, skill assesses them)
- S3 -> EXPANDS A4 (A4 is generic "execute"; S3 specifies 3 output sections)
- S4 -> KEEP BOTH A5 (agent validates generically, skill validates specifically)
- A3 -> not a task (it is the act of creating this list)

Merged task list:

- Task 1: Load session rules, read arguments, identify what to do .. [A1]
- Task 2: Read skill scope and guidelines .......................... [S1 — ADD]
- Task 3: Locate and read input files ............................. [A2]
- Task 4: Read input artifacts and assess size .................... [S2 — ADD]
- Task 5: Process inputs and write output section 1 ............... [S3 — EXPAND A4]
- Task 6: Process inputs and write output section 2 ............... [S3 — EXPAND A4]
- Task 7: Process inputs and write output section 3 ............... [S3 — EXPAND A4]
- Task 8: Validate final output against agent checks .............. [A5 — KEEP BOTH]
- Task 9: Validate output against skill checks .................... [S4 — KEEP BOTH]

Key takeaways:

- 5 agent + 4 skill = 9 base steps -> 9 tasks (A3 excluded as meta-step)
- ADD placed S1 and S2 alongside their agent counterparts
- EXPAND turned generic A4 into 3 concrete tasks via S3
- KEEP BOTH preserved both validation layers as separate tasks
- Every step from both layers is represented — nothing dropped

## Example 3

Scenario:

- Three-layer: agent + skill + reference with large I/O:
- An agent loads a skill, the skill loads a reference file.
- Source is large (needs chunking). Output is multi-section (needs iterative writing).
- Iterative-processing rules apply to the expanded task list.

LAYER 1 — Agent workflow (5 steps):

- A1: Load session rules, identify task
- A2: Locate source files
- A3: Decompose work into tracked tasks
- A4: Execute incrementally
- A5: Validate final output

LAYER 2 — Skill workflow (6 steps):

- S1: Read session rules and skill scope
- S2: Load the reference file
- S3: Assess source size, plan chunks
- S4: Create task list
- S5: Execute per chunk: read, process, write
- S6: Validate against skill checks

LAYER 3 — Reference workflow (4 steps):

- R1: Parse source and extract structures
- R2: Write output section incrementally
- R3: Post-process and cross-reference
- R4: Validate completeness

Merge mapping:

- S1 -> ADD AFTER A1 (both setup)
- S2 -> ADD AFTER S1 (skill loads reference — new work)
- S3 -> ADD AFTER A2 (assess size after locating files)
- S5 -> EXPANDS A4 (A4 is generic; S5 + R1 + R2 make it concrete per chunk)
- R3 -> ADD AFTER chunks (post-processing is new work from reference layer)
- R4, S6, A5 -> KEEP ALL (three validation layers — all run separately)
- A3, S4 -> not tasks (meta-steps: creating the task list)

Iterative-processing applied:

- Source is 2400 lines -> 3 chunks (800 lines each, 200 overlap).
- Output has sections per chunk -> iterative write after each chunk read.

Merged task list (3 chunks):

- Task 1: Load session rules and identify the task ................ [A1]
- Task 2: Read skill scope and guidelines .......................... [S1 — ADD]
- Task 3: Load reference file and read its workflow ................ [S2 — ADD]
- Task 4: Locate source files ..................................... [A2]
- Task 5: Assess source size, plan 3 chunks ....................... [S3 — ADD]
- Task 6: Read chunk 1 (lines 1-800) — parse and extract .......... [R1 — EXPAND]
- Task 7: Write output section for chunk 1 findings ............... [R2 — EXPAND]
- Task 8: Read chunk 2 (lines 601-1400) — parse and extract ....... [R1 — EXPAND]
- Task 9: Write output section for chunk 2 findings ............... [R2 — EXPAND]
- Task 10: Read chunk 3 (lines 1201-2400) — parse and extract ..... [R1 — EXPAND]
- Task 11: Write output section for chunk 3 findings .............. [R2 — EXPAND]
- Task 12: Post-process — cross-reference and reconcile sections .. [R3 — ADD]
- Task 13: Validate completeness against reference checks .......... [R4 — KEEP ALL]
- Task 14: Validate against skill checks .......................... [S6 — KEEP ALL]
- Task 15: Validate final output against agent checks .............. [A5 — KEEP ALL]
- Task 16: Cleanup temporary files ................................ [cleanup rule]

Key takeaways:

- 3 layers (15 base steps) -> 16 tasks. Every step represented, nothing dropped
- EXPAND created paired read+write tasks per chunk (Tasks 6-11) from generic "execute"
- Iterative-processing rules determined chunk boundaries and paired task structure
- Three separate validation tasks (R4, S6, A5) — one per layer, KEEP ALL
- ADD placed reference-loading, size-assessment, and post-processing as distinct tasks
- Cleanup task added per cleanup-finalization rule
- Dynamic adaptation: if chunk 2 reveals unexpected structure, insert a reconciliation
- task between Tasks 9 and 10 without losing progress on completed tasks
