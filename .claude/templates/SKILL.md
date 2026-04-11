# Skill File Authoring Guide

A SKILL.md teaches Claude a reusable workflow through YAML frontmatter (when to load) and a Markdown body (what to do). Each skill is self-contained within its own folder.

## When to Create a Skill

- Repeatable multi-step workflow that recurs across sessions
- Domain expertise or best practices to embed consistently
- MCP enhancement — workflow guidance layered on top of raw tool access
- Consistent output format required across runs

## Folder Layout

```
<skill-name>/
├── SKILL.md          # Required — exact name, case-sensitive
├── scripts/          # Optional — Python, Bash, etc.
├── references/       # Optional — documentation loaded on demand
└── assets/           # Optional — templates, fonts, icons
```

- Folder name: kebab-case only — `my-skill` ✅ · `My Skill` ❌ · `my_skill` ❌
- `name` field in frontmatter MUST match folder name exactly
- MUST NOT start with `claude` or `anthropic` (reserved)
- MUST NOT contain a `README.md` — all docs go in `SKILL.md` or `references/`

## Canonical Section Order

Every authored SKILL.md must contain these sections in order:

1. **YAML frontmatter** (`---` fences) — required
2. **Title** (`#`) — required
3. **Lead paragraph** (no heading) — required
4. **`## Instructions`** with `### Step N — <Imperative>` subsections (≥2) — required
5. **`## Bundled Resources`** — conditional: required iff `scripts/`, `references/`, or `assets/` exist; omit otherwise
6. **`## Example`** — required
7. **`## Troubleshooting`** — recommended; omit only for trivial skills
8. **`## Rules`** — required; `**MUST**` / `**MUST NOT**` bullets only

## Section-by-Section Instructions

### 1. YAML Frontmatter

- Delimiters: opening and closing `---`
- `name` — kebab-case; matches folder name exactly
- `description` — WHAT it does + WHEN to use it + trigger phrases users would say; ≤1024 chars; no XML angle brackets
- Optional: `license`, `compatibility` (1–500 chars), `allowed-tools`, `metadata` (arbitrary key-value pairs)
- Zero XML angle brackets (`<` or `>`) anywhere in frontmatter (security restriction)

### 2. Title

- Level: `#`
- Single-line noun or verb phrase matching skill purpose
- No XML tags

### 3. Lead Paragraph

- No heading — appears directly below title
- 1–2 sentences describing what the skill produces or does
- Do not repeat trigger phrases here (those belong in frontmatter only)

### 4. Instructions

- Level: `## Instructions`
- Subsections: `### Step 1 — <Imperative>`, `### Step 2 — <Imperative>`, … (≥2 required)
- Non-obvious runtime constraints go as **bold callouts** before Step 1
- Final step MUST be a validation checklist (`- [ ]` items) when the skill produces an output artifact
- Reference scripts via backtick code spans: `` `scripts/<name>.py` ``

### 5. Bundled Resources

- Level: `## Bundled Resources`
- Omit entirely when no bundled files exist — no empty sections
- Scripts/assets: `` - `<path>` — <when to use> ``
- References: `- [label](./references/<name>.md) — <when to consult>`
- This section is the level-3 progressive disclosure entry point — every bundled file must appear here

### 6. Example

- Level: `## Example`
- Body: 4-backtick outer fence with `markdown` language tag
- Content: realistic user request → numbered action trace → concrete result
- Inner code blocks use 3-backtick fences

### 7. Troubleshooting

- Level: `## Troubleshooting`
- Format: `**Error:**` / `**Cause:**` / `**Solution:**` triples
- Cover: MCP connection failures, invalid inputs, unexpected outputs
- Omit only for trivial skills with no external dependencies

### 8. Rules

- Level: `## Rules`
- Bullet list — one constraint per bullet
- Vocabulary: `- **MUST** <rule>` or `- **MUST NOT** <rule>` only
- No "should", "try to", or "prefer"

## Skeleton

`````markdown
---
name: <skill-name-in-kebab-case>
description: <What it does>. Use when user asks to <trigger phrase 1>, <trigger phrase 2>, or mentions <keyword>.
---

# <Skill Title>

<1–2 sentence summary of what this skill produces or does.>

## Instructions

**Critical:** <Non-obvious runtime requirement. Delete if none.>

### Step 1 — <Imperative Action>

<Concise explanation. Reference scripts with backticks: `scripts/<name>.py`.>

### Step 2 — <Imperative Action>

<Concise explanation. Include expected outputs where useful.>

### Step N — Validate <Something>

- [ ] <Verifiable criterion>
- [ ] <Verifiable criterion>

## Bundled Resources

- `scripts/<name>.py` — <when to run>
- [<label>](./references/<name>.md) — <when to consult>
- `assets/<name>` — <purpose>

## Example

````markdown
User: <realistic request that triggers this skill>

Actions:
1. <tool call or step>
2. <tool call or step>

Result: <concrete outcome>
````

## Troubleshooting

**Error:** <symptom>
**Cause:** <why it happens>
**Solution:** <how to fix>

## Rules

- **MUST** match folder name to `name` field (kebab-case)
- **MUST** keep this file under 5,000 words
- **MUST NOT** include XML angle brackets anywhere in frontmatter
- **MUST NOT** include a `README.md` in the skill folder
- **MUST NOT** start `name` with `claude` or `anthropic`
`````

## Conventions

- File name: exactly `SKILL.md` (case-sensitive) — `skill.md`, `SKILL.MD` are invalid
- Folder name: kebab-case, matches `name`; MUST NOT start with `claude` or `anthropic`
- YAML `description`: WHAT + WHEN + trigger phrases; ≤1024 chars; no XML angle brackets
- Body: ≤5,000 words — move detail to `references/` for progressive disclosure
- Headings: `#` (title only), `##` (sections), `###` (subsections) — no `####` or deeper
- Imperative voice; bullet/numbered lists beat paragraphs
- Rules vocabulary: `**MUST**` / `**MUST NOT**` only — no "should", "prefer", "try to"
- Example outer fence: 4 backticks + `markdown` tag; inner code blocks: 3 backticks
- No XML or custom tags anywhere in the file

## Authoring Checklist

- [ ] Folder named in kebab-case, matches `name` field
- [ ] Folder name does not start with `claude` or `anthropic`
- [ ] File is named exactly `SKILL.md` (case-sensitive)
- [ ] No `README.md` inside the skill folder
- [ ] YAML frontmatter wrapped in `---` delimiters
- [ ] `name` field present, kebab-case, matches folder
- [ ] `description` present — WHAT + WHEN + trigger phrases, ≤1024 chars, no XML angle brackets
- [ ] Title is `#` level, single line
- [ ] Lead paragraph present directly below title (no heading)
- [ ] `## Instructions` present with ≥2 `### Step N — <Name>` subsections
- [ ] Final step is a validation step with `- [ ]` body when skill produces an output artifact
- [ ] `## Bundled Resources` present iff bundled files exist; omitted otherwise
- [ ] All `references/` links use relative `./references/<file>.md` paths
- [ ] `## Example` present — user request + action trace + concrete result
- [ ] `## Troubleshooting` present with Error/Cause/Solution triples (omit for trivial skills)
- [ ] `## Rules` present — `**MUST**` / `**MUST NOT**` bullets only
- [ ] Body under 5,000 words
- [ ] No heading level deeper than `###`
- [ ] Zero XML or custom tags in the file
