# Reference File Authoring Guide

A reference file describes how a skill produces a specific analytical artifact. It defines the notation, workflow, and validation criteria an agent needs to execute the skill. Each reference file is self-contained.

## When to Create a Reference File

Create a reference file when a skill produces a distinct analytical artifact with its own notation, step-by-step workflow, and verification criteria. If a skill produces multiple artifact types, create one reference file per type.

## Canonical Section Order

Every reference file must contain these 7 sections in order:

1. **Title** (`#`) — skill/artifact name
2. **Lead paragraph** (no heading) — 1–2 sentences describing what the skill produces
3. **Output** (`## Output`) — output file path
4. **Domain guide sections** (`##`) — skill-specific knowledge required to produce the artifact
5. **Objectives** (`## Objectives`) — ordered workflow steps
6. **Example** (`## Example`) — concrete sample output
7. **Rules** (`## Rules`) — hard constraints

## Section-by-Section Instructions

### 1. Title

- Level: `#`
- Format: noun phrase identifying the artifact type
- One line only

### 2. Lead Paragraph

- No heading — appears directly below the title
- 1–2 sentences describing what the skill produces
- Describe the output shape (e.g., "one overview diagram + one detail diagram per callable unit")

### 3. Output

- Level: `## Output`
- Body: a single line — the output path in a backtick code span
- Path pattern: `./output/<skill-category>/analysis-<skill-name>.md`
- Optional trailing `— <note>` if the file type warrants brief clarification
- No other content in this section

### 4. Domain Guide Sections

- Level: `##` for each section; `###` for subsections — no deeper
- One or more sections covering what the agent needs to know: notation, syntax, conventions, format rules, coverage requirements, exclusions
- Name them to match the domain (examples: `## Syntax`, `## Notation`, `## Hierarchy Format`)
- Use tables for lookup content (operators, element types, symbols)
- Use numbered lists for ordered rules; bullet lists for unordered rules
- Use fenced code blocks for literal character examples (tree-drawing characters, control structures)
- Do not include workflow steps here — those belong in Objectives

### 5. Objectives

- Level: `## Objectives`
- Body: numbered sub-sections using `### Objectives N — <Name>`
- Each sub-section is one workflow step with a short bullet or prose body
- Final sub-section is always validation:
  - Heading: `### Objectives N — Validate <Something>`
  - Body: `- [ ]` checklist items only — no prose
- Minimum 3 Objectives; 4 is typical

### 6. Example

- Level: `## Example`
- Body: a 4-backtick outer code fence with language tag `markdown`
- First heading inside the fence: `## Metadata`
- Metadata fields with blank values on their own lines: `Source:` / `Date:` / `Description:`
- After Metadata: one complete, realistic example of the artifact
- Inner code blocks inside the fence use 3-backtick fences with the appropriate language tag
- See the Skeleton below for the exact nesting structure

### 7. Rules

- Level: `## Rules`
- Body: bullet list — one constraint per bullet
- Vocabulary: `- **MUST** <rule>` or `- **MUST NOT** <rule>` only
- No "should", "try to", or "prefer"

## Skeleton

`````markdown
# <Skill Name>

<1–2 sentence description of what this skill produces.>

## Output

`./output/<skill-category>/analysis-<skill-name>.md`

## <Domain Guide Section>

<Notation, syntax, conventions, format rules, coverage, or exclusions. Use tables, bullet lists, and code blocks as needed. Add ### subsections as needed. Repeat this block for each additional domain area.>

## Objectives

### Objectives 1 — <Imperative Name>

<Bullet list or short prose describing this workflow step.>

### Objectives 2 — <Imperative Name>

<Bullet list or short prose describing this workflow step.>

### Objectives N — Validate <Something>

- [ ] <Verifiable criterion>
- [ ] <Verifiable criterion>

## Example

````markdown
## Metadata

Source:
Date:
Description:

```<lang>
<example artifact content>
```
````

## Rules

- **MUST** <rule>
- **MUST NOT** <rule>
`````

## Conventions

- Headings: `#` (title only), `##` (sections), `###` (subsections) — no `####` or deeper
- No XML or custom tags anywhere in the file
- Output path: single backtick-quoted code span, pattern `./output/<skill-category>/analysis-<skill-name>.md`
- Validation Objective: `- [ ]` checklist body only — never prose
- Example outer fence: 4 backticks with `markdown` language tag; inner code blocks: 3 backticks
- Example always begins with `## Metadata` containing `Source:` / `Date:` / `Description:` fields
- Rules: `**MUST**` / `**MUST NOT**` vocabulary only — no "should", "prefer", "try to"
- Imperative voice throughout

## Authoring Checklist

- [ ] Title is `#` level — noun phrase, no XML
- [ ] Lead paragraph present directly below title, no heading
- [ ] `## Output` present — single backtick-quoted path, no other content
- [ ] One or more `##` domain guide sections between Output and Objectives
- [ ] `## Objectives` present with `### Objectives N — <Name>` sub-sections
- [ ] Final Objective is `### Objectives N — Validate <Something>` with `- [ ]` checklist body
- [ ] `## Example` present, wrapped in 4-backtick outer fence
- [ ] Example begins with `## Metadata` and `Source:` / `Date:` / `Description:` fields
- [ ] Inner code blocks inside Example use 3-backtick fences
- [ ] `## Rules` present — `**MUST**` / `**MUST NOT**` bullets only
- [ ] Zero XML or custom tags in the file
- [ ] No heading level deeper than `###`
