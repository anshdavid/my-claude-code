---
name: cobol-migrate
description: "Run a full COBOL to Java Quarkus migration using the Claude Code native agent pipeline. Launches dependency-mapper, cobol-analyzer, and java-converter agents coordinated by migration-orchestrator."
---

You are orchestrating a COBOL → Java Quarkus migration using the native Claude Code agent pipeline.

## When Invoked

If the user provided arguments (`$ARGUMENTS`), parse them:

- First argument → COBOL source directory
- Second argument → Java output directory

If arguments are missing or incomplete, ask:

1. "What is the path to your COBOL source directory?" (suggest `./cobol-source` as default)
2. "Where should the Java output be written?" (suggest `./java-output` as default)

## Pre-flight Check

Before launching the migration, do:

```bash
# Check COBOL source exists and has files (recursive)
find <cobol_source> \( -name "*.cbl" -o -name "*.cpy" -o -name "*.cob" \) 2>/dev/null | head -5
```

Report what you found:

- "Found X COBOL files in `<source>`"
- If empty: "No COBOL files found in `<source>`. Please check the path."

Ask for confirmation:

> "Ready to migrate **X COBOL files** from `<source>` → `<output>`.
> This will run: dependency analysis → COBOL analysis → Java conversion → report.
> Proceed? (yes/no)"

If the user says no, stop.

## Launch the Pipeline

Once confirmed, launch the `migration-orchestrator` agent:

```
Task: Run the full COBOL to Java migration pipeline.
COBOL_SOURCE: <cobol_source_path>
JAVA_OUTPUT: <java_output_path>

Execute all 6 steps:
1. Discover COBOL files
2. Map dependencies (dependency-mapper agent)
3. Analyze each COBOL file (cobol-analyzer agent)
4. Convert each file to Java (java-converter agent)
5. Verify outputs
6. Write MIGRATION_REPORT.md
```

## After Completion

Once the orchestrator finishes, read `<java_output>/MIGRATION_REPORT.md` and present a summary:

```
Migration Complete!

Files processed: X
Java files generated: Y
Manual review required: Z

Output directory: <java_output>/
  ├── MIGRATION_REPORT.md          ← Full report
  ├── dependency-map.md            ← COPY/CALL dependency graph
  ├── analysis/                    ← Per-file COBOL analysis reports
  └── java/
      ├── com/example/.../         ← Generated Java source files
      └── *_conversion_notes.md   ← Per-file conversion decisions + review items

Next steps:
1. Review MIGRATION_REPORT.md for any files needing manual attention
2. Check *_conversion_notes.md files for conversion decisions
3. Run: cd <java_output>/java && mvn compile (if Maven project set up)
```

If the migration failed or was partial, show what succeeded and what needs attention.
