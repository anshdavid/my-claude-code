# Plan: CLAW Architecture Reference Document

## Context

The previous plan (formatting `elixir-claw-raw.md` → `elixir-claw.md`) is **complete**. That file now exists as a 3,007-line, 82-section formatted reference.

**New task:** Produce a comprehensive implementation-grade _architecture reference_ derived from `chatgpt/elixir-claw.md`. This document is what an engineer will use as the primary guide to implement the CLAW agent platform in Elixir (an OpenClaw / Codex CLI / Gemini CLI-equivalent agentic harness).

**Why this deliverable exists:** The source document is a conversational guide — principles, code sketches, prose. It is organized by conversation turns, not by concept. Memory is discussed in 3 different places; run lifecycle in 4; tools in 3. An implementer cannot pick it up and start coding chapter-by-chapter. The architecture reference **merges scattered concepts into single-concept chapters**, adds **Mermaid diagrams** for every structural/flow concept, formalizes **Architecture Decision Records (ADRs)** with stable IDs, and explicitly **catalogs gaps (TBDs)** the source left open.

**Intended outcome:** A 2,400–2,900-line markdown file with 32 Mermaid diagrams, 20 ADRs, and 27+ tracked TBDs. Structured so a reader implementing chapter N has everything they need in chapter N alone.

---

## Output

**File:** `/workspace/chatgpt/elixir-claw-architecture.md` (new file)  
**Size target:** ~2,540 lines (headroom to 2,900)  
**Diagrams:** 32 Mermaid blocks (graph, flowchart, sequenceDiagram, stateDiagram-v2, erDiagram, classDiagram, gantt)  
**ADRs:** 20 in MADR format with stable IDs `ADR-0001..ADR-0020`  
**TBDs:** 27+ with stable IDs `TBD-01..TBD-27+`

---

## Source Inventory (from Explore agent)

The source (`chatgpt/elixir-claw.md`, 3,007 lines, 82 `###` sections, 3 parts) contains:

- **9 systems/containers** (Phoenix Gateway, Session Runtime, Channel Adapters, Orchestrator, LLM Broker, Tool Runtime, Memory+Retrieval, Jobs, Postgres/Blob)
- **8 bounded contexts** (Gateway, Sessions, Orchestrator, Tools, Memory, Channels, Jobs, Observability) each with module lists
- **Full OTP tree**: ApplicationSupervisor → TelemetrySupervisor, Repo, PubSub, Presence, Registry, DynamicSupervisor(Session/Channel/ToolWorker), Oban, CacheSupervisor, Endpoint
- **10+ core structs**: SessionState, AgentDefinition, RunState, Run, Session, Step, Handoff, InboundEvent, OutboundEvent, ToolSpec + DB tables (runs, steps, artifacts, approvals, agents)
- **2 interlocking state machines**: run lifecycle (NEW→PREPARE→PLAN→VALIDATE→EXECUTE→RECORD→DECIDE→COMPLETE/WAIT/FAIL/HANDOFF) and run statuses (`:new`, `:starting`, `:running`, `:waiting_approval`, `:waiting_child`, `:waiting_user`, `:waiting`, `:completed`, `:failed`, `:cancelled`)
- **Core flows**: tick loop, create_run, context build, plan_next_step, policy.validate, step_executor.execute branches, spawn_child_run, merge_child_result
- **4 team patterns**: Coordinator/Worker, Planner/Executor/Critic, Map/Reduce, Pipeline + Code Team preset
- **Tool taxonomy**: pure/read/write/dangerous + safety model
- **Channel contract**: InboundEvent/OutboundEvent normalization
- **LLM broker**: provider behavior + failover + cost routing
- **6 planner action types**: tool_call, handoff, ask_user, final_response, wait, noop
- **7-phase roadmap**: Phase 0 Discovery → Phase 7 Multi-agent
- **17 anti-patterns**

Each category mapped to source section line ranges (available in Explore agent report if needed during fill passes).

---

## Document Structure

**7 Parts, 24 chapters.** Progressive disclosure: principles → runtime → engine → capabilities → multi-agent → cross-cutting → delivery.

### Part 0 — Front Matter (~80 lines, 0 diagrams)

- **0.1** Title, Abstract, How to Read (audience-specific reading paths)
- **0.2** Glossary (Run, Session, Step, Handoff, Tool, Agent, Team, Scope, Broker, Channel, Policy, Scratchpad)

### Part 1 — Foundations (~260 lines, 3 diagrams)

- **Ch 1** Product Definition & Non-Goals — source §I.1, §I.23
- **Ch 2** Architectural Principles — source §I.7 (Execution), §I.13 (Security), §II.31, §III.31, §I.18 (Anti-patterns)
- **Ch 3** System Context & Containers — source §I.3, §I.15
  - D1: C4 System Context (graph)
  - D2: C4 Container Diagram (graph)
  - D3: Module Dependency Graph (graph, directed-only)

### Part 2 — Runtime Architecture (~260 lines, 4 diagrams)

- **Ch 4** OTP Supervision Tree — source §I.4, §III.3, §II.14
  - D4: Supervision Tree (graph TD)
- **Ch 5** Session Lifecycle — source §I.4, §II.4, §I.6
  - D5: Session State Machine (stateDiagram-v2)
  - D6: Session Lifecycle Sequence (sequenceDiagram)
- **Ch 6** Bounded Contexts & Module Layout — source §I.5, §I.15, §II.14, §III.1
  - _Shares D3 from Ch 3_

### Part 3 — The Engine (~520 lines, 7 diagrams)

- **Ch 7** Run Lifecycle & State Machine — source §II.2, §II.7.A, §III.5, §III.22, §II.20
  - D7: Run Lifecycle State Machine (stateDiagram-v2) — must show `:waiting_*` fan-out
  - D8: Run Parent/Child Tree (graph TD, dashed=awaits, solid=spawned)
- **Ch 8** The Tick Loop — source §II.3, §II.7.B–G, §III.7, §III.30
  - D9: Tick Loop Flowchart (flowchart TD with decision diamonds)
  - D10: Happy-Path Sequence (sequenceDiagram with PubSub lanes)
  - D11: Engine Function Call Graph (graph) — module structure, complements D9
- **Ch 9** Planner, Policy, Executor — source §II.7.C/D/E, §III.9–§III.12, §III.21
  - D12: Policy Engine Decision Tree (flowchart TD)
  - D13: Action Parser Decision Tree (flowchart TD)
- **Ch 9A** Approvals, Failures, Cancellation — source §II.19, §II.20, §III.15
  - D14: Approval Flow Sequence (sequenceDiagram with inline sub-state note)

### Part 4 — Capabilities (~480 lines, 8 diagrams)

- **Ch 10** Memory Architecture — source §I.11, §II.12, §III.17
  - D15: Four-Layer Memory Stack (graph TD, stacked subgraphs)
  - D16: Memory Scope Hierarchy (graph TD, nested subgraphs)
  - D17: Memory Write Policy Activity (flowchart TD)
  - D18: Memory Retrieval Sequence (sequenceDiagram)
- **Ch 11** Tool System — source §I.8, §II.7.E, §III.13
  - D19: Tool Category Tree (graph TD)
  - D20: Tool Execution Sequence with Approval Branch (sequenceDiagram with `alt`)
- **Ch 12** LLM Broker & Providers — source §I.12, §I.14, §II.14
  - D21: Provider Class Diagram (classDiagram)
  - D22: LLM Failover Sequence (sequenceDiagram)
- **Ch 13** Channels & Event Contract — source §I.10, §II.1.L4, §I.6
  - D23: Channel Event Fanout (graph, bidirectional)
  - D24: Channel Adapter Sequence (sequenceDiagram)
- **Ch 14** Skills & Plugin Architecture — source §I.9 (no diagrams)

### Part 5 — Multi-Agent (~340 lines, 6 diagrams)

- **Ch 15** Teams Mode Overview — source §II.8, §II.9, §II.10, §II.21
  - D25: Team Topology (graph)
- **Ch 16** Handoffs & Child Runs — source §II.11, §II.18, §III.14–§III.16
  - D26: Handoff Sequence (sequenceDiagram)
  - D27: Parallel Children Sequence (sequenceDiagram with `par`/`and`)
- **Ch 17** Coordination Patterns — source §II.13, §II.22, §III.19, §III.28
  - D28: Coordinator/Worker Pattern (graph) — Map/Reduce folded in as caption
  - D29: Planner/Executor/Critic Pattern (graph with cycle)
  - D30: Pipeline Pattern / Code Team Preset (graph LR)

### Part 6 — Cross-Cutting (~320 lines, 3 diagrams)

- **Ch 18** Data Architecture & Schema — source §I.6, §III.23
  - D31: ER Diagram (erDiagram with FKs and cardinality)
- **Ch 19** Security & Policy — source §I.13, §II.19, §I.8
  - Permission/Scope Matrix (table + graph hybrid)
- **Ch 20** Observability & Telemetry — source §I.14, §I.5.H
  - Telemetry Flow Diagram

### Part 7 — Delivery & Reference (~280 lines, 1 diagram)

- **Ch 21** Delivery Roadmap — source §I.19, §I.22, §II.25, §III.29
  - D32: Roadmap Gantt (gantt — shows parallel phase streams)
- **Ch 22** Anti-Patterns Catalog — source §I.18, §II.24, §III.27 (consolidated from 17 scattered anti-patterns)
- **Ch 23** Architecture Decision Records — 20 ADRs in MADR format
- **Ch 24** Open Questions & TBDs — 27+ TBDs with IDs

**Totals:** ~2,540 lines, 32 diagrams.

---

## Diagram Catalog (32 total)

| ID  | Chapter | Type            | Title                                       |
| --- | ------- | --------------- | ------------------------------------------- |
| D1  | 3       | graph           | C4 System Context                           |
| D2  | 3       | graph           | C4 Container Diagram                        |
| D3  | 3       | graph           | Module Dependency Graph (directed-only)     |
| D4  | 4       | graph TD        | OTP Supervision Tree                        |
| D5  | 5       | stateDiagram-v2 | Session State Machine                       |
| D6  | 5       | sequenceDiagram | Session Lifecycle Sequence                  |
| D7  | 7       | stateDiagram-v2 | Run Lifecycle State Machine                 |
| D8  | 7       | graph TD        | Run Parent/Child Tree                       |
| D9  | 8       | flowchart TD    | Tick Loop Flowchart                         |
| D10 | 8       | sequenceDiagram | Happy-Path Sequence                         |
| D11 | 8       | graph           | Engine Function Call Graph                  |
| D12 | 9       | flowchart TD    | Policy Engine Decision Tree                 |
| D13 | 9       | flowchart TD    | Action Parser Decision Tree                 |
| D14 | 9A      | sequenceDiagram | Approval Flow (with inline sub-states)      |
| D15 | 10      | graph TD        | Four-Layer Memory Stack                     |
| D16 | 10      | graph TD        | Memory Scope Hierarchy                      |
| D17 | 10      | flowchart TD    | Memory Write Policy Activity                |
| D18 | 10      | sequenceDiagram | Memory Retrieval Sequence                   |
| D19 | 11      | graph TD        | Tool Category Tree                          |
| D20 | 11      | sequenceDiagram | Tool Execution with Approval (`alt` branch) |
| D21 | 12      | classDiagram    | LLM Provider Behavior + Implementations     |
| D22 | 12      | sequenceDiagram | LLM Failover Sequence                       |
| D23 | 13      | graph           | Channel Event Fanout (bidirectional)        |
| D24 | 13      | sequenceDiagram | Channel Adapter Sequence                    |
| D25 | 15      | graph           | Team Topology                               |
| D26 | 16      | sequenceDiagram | Handoff Sequence                            |
| D27 | 16      | sequenceDiagram | Parallel Children (`par`/`and`)             |
| D28 | 17      | graph           | Coordinator/Worker Pattern                  |
| D29 | 17      | graph           | Planner/Executor/Critic Pattern             |
| D30 | 17      | graph LR        | Pipeline / Code Team Preset                 |
| D31 | 18      | erDiagram       | Data Model ER                               |
| D32 | 21      | gantt           | Delivery Roadmap                            |

**Density:** 1 diagram per ~80 lines. Chapters 8 (3 diagrams) and 10 (4 diagrams) are densest — intentional, they cover the highest-concept material.

---

## ADR List (20 total, stable IDs)

All ADRs in Chapter 23 in MADR format: Status / Context / Decision / Consequences / Alternatives.

| ID       | Title                                                          |
| -------- | -------------------------------------------------------------- |
| ADR-0001 | Elixir/OTP as runtime                                          |
| ADR-0002 | Phoenix for gateway + realtime                                 |
| ADR-0003 | Postgres + pgvector as primary store                           |
| ADR-0004 | Oban for background/scheduled work                             |
| ADR-0005 | One GenServer per run under DynamicSupervisor                  |
| ADR-0006 | Model-proposes / engine-executes separation                    |
| ADR-0007 | Strict run state machine with explicit wait states             |
| ADR-0008 | Planner returns JSON actions, not free-form text               |
| ADR-0009 | Policy engine as separate stage, not inside planner            |
| ADR-0010 | Four-layer memory model                                        |
| ADR-0011 | LLM broker behavior with per-request failover                  |
| ADR-0012 | Tools as Elixir modules implementing a behavior                |
| ADR-0013 | Dangerous tools run in external OS/container workers           |
| ADR-0014 | Channel adapters normalize to unified In/OutboundEvent         |
| ADR-0015 | Handoffs spawn new RunServer children, never re-use parent     |
| ADR-0016 | Approvals persist to DB and resume via async message           |
| ADR-0017 | Every step persists before and after execution                 |
| ADR-0018 | Session isolation — no shared mutable state between sessions   |
| ADR-0019 | Capability tokens over ambient authority for tool invocation   |
| ADR-0020 | Single-node local-first first; no service split until Phase 8+ |

---

## TBD List (27 gaps the source leaves open)

All live in Chapter 24, referenced inline by stable ID. Each entry: _what is missing_ / _chapter that needs it_ / _recommended interim_ / _blocking or non-blocking for v1_.

**Security & identity**

- TBD-01 Auth model (JWT vs Phoenix session vs API tokens)
- TBD-02 Multi-tenancy isolation (workspace boundaries)
- TBD-03 Capability token format
- TBD-04 Approval authorization (who can approve what)

**Limits & budgets**

- TBD-05 Rate limits (per-session/user/workspace/provider)
- TBD-06 Budget enforcement (soft vs hard, cumulative across children)
- TBD-07 Concurrency caps (runs per session/workspace/team)

**Data & schema**

- TBD-08 Exact column types, nullability, indexes
- TBD-09 Retention policy (runs/steps/memory TTLs)
- TBD-10 Migrations strategy (online schema change)
- TBD-11 Blob storage specifics (S3/FS/MinIO)

**LLM integration**

- TBD-12 Provider API adapters (versions, streaming protocol, tokenizers)
- TBD-13 Context window management strategy
- TBD-14 Streaming semantics (broker → RunServer → PubSub → channel)
- TBD-15 Cost accounting schema

**Tool execution**

- TBD-16 Sandbox implementation (port/NIF/OS process/container)
- TBD-17 Tool schema validation format (JSON Schema/Ecto/custom)
- TBD-18 Tool timeout handling (kill/fail/re-plan)

**Channels**

- TBD-19 Idempotency for adapter webhooks
- TBD-20 Outbound delivery guarantees

**Memory**

- TBD-21 Embedding model choice (dimensions fixed at schema time)
- TBD-22 Summarization strategy (trigger + provider)
- TBD-23 Memory scope promotion rules (run → task → session)

**Operational**

- TBD-24 Deployment topology (clustering, libcluster)
- TBD-25 Backup and disaster recovery
- TBD-26 Telemetry event taxonomy
- TBD-27 Health checks and graceful shutdown

---

## Reasoning Embedding Strategy

**Both inline and dedicated**, with a strict division of labor.

### Inline — "Rationale" callouts

Every chapter has a blockquoted **Rationale** block immediately after the first concept introduction and before code/implementation details. Format:

```markdown
> **Rationale.** We chose one GenServer per run rather than a worker
> pool because: (1) run state (messages, scratchpad, child refs) is
> long-lived and sticky, (2) OTP supervision gives per-run crash
> isolation for free, (3) Registry lookups are O(1). Trade-off:
> slightly higher memory footprint. See ADR-0005.
```

Rules:

- 3–8 lines, blockquoted, always before code
- Names the alternative considered
- Names the trade-off accepted
- Links to the full ADR (`see ADR-NNNN`) — never duplicates

### Dedicated — Chapter 23 ADRs

20 ADRs in MADR format with stable IDs. Only load-bearing, system-wide decisions. Local decisions (e.g., "why `:via` Registry for run names") stay inline.

**Why both:**

- _Inline only_ → ADRs impossible to find during design review
- _ADR-chapter only_ → first-time readers forced into annoying cross-references
- _Both_ → best of each, matches successful technical docs (Kubernetes design proposals, AWS whitepapers)

### Anti-Patterns chapter is the inverse

Chapter 22 consolidates all 17 source anti-patterns with "why not" reasoning. Enables "anti-pattern audit" reviews in one chapter read.

---

## Writing Strategy — Scaffold-then-Fill, 11 passes

**Strategy: Scaffold-then-Fill** (per `iterative-write.md`). Justification:

1. This is system-design work, not a report → the rule mandates scaffold-first
2. Cross-chapter references (ADRs cited from 5+ chapters) require stable IDs before prose
3. Diagram placement affects line count — must be allocated upfront

### 11 Passes

| Pass | Content                                                                                                                                                         | New lines | Cumulative |
| ---- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ---------- |
| 1    | **Full scaffold** — all 24 chapter headers, every subsection, 20 ADR stubs with `Status: Proposed`, every diagram with `TODO: diagram D##`, glossary stubs, ToC | 350       | 350        |
| 2    | Part 0 front matter + Part 1 Foundations (Ch 1–3, D1–D3)                                                                                                        | 340       | 690        |
| 3    | Part 2 Runtime (Ch 4–6, D4–D6)                                                                                                                                  | 260       | 950        |
| 4    | Part 3 Engine — Ch 7 and Ch 8 only (D7–D11)                                                                                                                     | 260       | 1,210      |
| 5    | Part 3 Engine — Ch 9 and Ch 9A (D12–D14)                                                                                                                        | 260       | 1,470      |
| 6    | Part 4 Capabilities — Ch 10 and Ch 11 (D15–D20)                                                                                                                 | 250       | 1,720      |
| 7    | Part 4 Capabilities — Ch 12, 13, 14 (D21–D24)                                                                                                                   | 230       | 1,950      |
| 8    | Part 5 Multi-Agent (Ch 15–17, D25–D30)                                                                                                                          | 340       | 2,290      |
| 9    | Part 6 Cross-Cutting (Ch 18–20, D31 + matrix)                                                                                                                   | 320       | 2,610      |
| 10   | Part 7 Delivery & Reference (Ch 21–24, D32, all 20 ADR bodies, all 27 TBDs)                                                                                     | 280       | 2,890      |
| 11   | **Sweep** — ToC link verification, ADR cross-link integrity, mermaid syntax lint, TBD backlink audit                                                            | 0 net     | 2,890      |

**No pass exceeds 500 new lines** (the iterative-write ceiling). Parts 3 and 4 split intentionally because each would land near ceiling in one pass.

### Cut-point reasoning

- **Part boundaries are natural cut points** — each Part has its own prerequisite graph:
  - Part 1 depends on nothing
  - Part 2 depends on Part 1 ("what is CLAW")
  - Part 3 depends on Part 2 (supervision + session)
  - Part 4 depends on Part 3 (tools/memory plug into the engine)
  - Part 5 depends on Part 4 (handoffs use memory scopes + broker)
  - Part 6 depends on Parts 2–5 (secures/observes/schemas everything)
  - Part 7 depends on all prior (ADRs reference all chapters)

### What NOT to do

- ❌ **Do not write Parts out of dependency order.** Forward references break the reader.
- ❌ **Do not combine passes.** Parts 3+4 unified would hit the 500-line ceiling.
- ❌ **Do not skip the scaffold pass.** Without stable IDs, every fill pass renumbers.
- ❌ **Do not write ADR bodies during scaffold.** Only titles + IDs. Bodies filled in Pass 10 when all chapters can be accurately cited.

### Mid-pass invariants

Between passes the file must always:

1. Parse as valid markdown (no dangling code fences)
2. Have a working ToC (every entry resolves)
3. Contain only tokens: `TODO:`, `<!-- diagram: D## -->`, `<!-- adr-body -->`
4. Never reference an ADR ID or diagram ID not in the scaffold

### Iterative read during fill passes

Each fill pass re-reads the relevant source sections from `chatgpt/elixir-claw.md` (not the 3,007-line raw — the cleaned version) in 600-line chunks per `iterative-read.md`. Do not rely on memory — the source is the truth.

---

## Critical Files

| Path                                             | Role                                                                |
| ------------------------------------------------ | ------------------------------------------------------------------- |
| `/workspace/chatgpt/elixir-claw.md`              | **Source** (3,007 lines, 82 sections) — read during every fill pass |
| `/workspace/chatgpt/elixir-claw-architecture.md` | **Output** — created Pass 1, filled Passes 2–11                     |
| `/workspace/.claude/rules/iterative-write.md`    | Governs 500-line pass ceiling                                       |
| `/workspace/.claude/rules/iterative-read.md`     | Governs 800/600-chunk re-read                                       |

---

## Verification

After Pass 11, verify:

1. **Line count:** `wc -l /workspace/chatgpt/elixir-claw-architecture.md` → expect 2,400–2,900
2. **Chapter count:** `grep -c "^## " chatgpt/elixir-claw-architecture.md` → expect 7 Parts + ToC heading + ADR heading = ~9
3. **Section count:** `grep -c "^### " chatgpt/elixir-claw-architecture.md` → expect ≥24 chapters
4. **Diagram count:** `grep -c '^```mermaid' chatgpt/elixir-claw-architecture.md` → expect 32
5. **Diagram IDs:** grep each of D1–D32 → every ID must appear exactly once
6. **ADR IDs:** grep each of ADR-0001..ADR-0020 → must appear in Ch 23 once + at least one inline reference
7. **TBD IDs:** grep each of TBD-01..TBD-27 → must appear in Ch 24 once + at least one inline reference
8. **No placeholder tokens:** `grep -E 'TODO:|<!-- (diagram|adr-body) -->'` → must return empty
9. **No raw artifacts:** `grep -E 'planmode|deepthinkmode'` → must return empty
10. **Markdown validity:** opening and closing code fences balanced (`grep -c '^```'` is even)
11. **Mermaid syntax:** spot-check 5 diagrams render (validate via `mcp__claude_ai_Mermaid_Chart__validate_and_render_mermaid_diagram` if available — optional but recommended)
12. **Cross-link integrity:** every `(see ADR-NNNN)` resolves; every `(see TBD-NN)` resolves; every `see §N.N` resolves to a real heading

If any verification fails, Pass 11 (sweep) is repeated targeted at the failure before declaring done.
