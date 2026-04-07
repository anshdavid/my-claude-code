# COBOL → Java Quarkus Migration Plan

## Context

Migrating 4 COBOL programs from `/workspace/database/mariadb/` to Java Quarkus, outputting to `/workspace/java-output/`. The programs are a complete CRUD demo suite for MariaDB access via embedded SQL (EXEC SQL). All 4 files share one copybook (`SQLSTATE-CHECK.cpy`) for error handling — but that `.cpy` file was **not found** in the source directory (only the 4 `.cbl` files exist). The pipeline must handle this gracefully.

---

## Source Files

| File | Program | Purpose | Complexity | LOC |
|------|---------|---------|------------|-----|
| `01_select.cbl` | 01_select | Cursor-based SELECT of kings table | Low | 81 |
| `02_insert_update.cbl` | 02_insert_update | INSERT + UPDATE with row count verification | Medium | 110 |
| `03_delete.cbl` | 03_delete | DELETE by name with verification | Low | 83 |
| `04_ddl.cbl` | 02_ddl (mismatch) | CREATE TABLE + DROP TABLE DDL | Medium | 70 |

**Shared dependency:** All 4 programs `COPY 'SQLSTATE-CHECK.cpy'` — a missing copybook that must be noted in the dependency map and handled in conversion.

---

## Migration Wave Order

- **Wave 1:** `SQLSTATE-CHECK.cpy` ← shared copybook (missing — flag as manual)
- **Wave 2:** All 4 `.cbl` programs (no inter-program dependencies; process in filename order)

---

## Pipeline Steps

### Step 1 — File Discovery ✓ (already done)
Files: 4 `.cbl` files found in `/workspace/database/mariadb/`. No `.cpy` files present.

### Step 2 — Dependency Analysis
**Agent:** `dependency-mapper` (subagent_type: "dependency-mapper")
**Input:** `/workspace/database`, output dir `/workspace/java-output`
**Output:** `/workspace/java-output/dependency-map.md`
- Will discover all 4 files share COPY 'SQLSTATE-CHECK.cpy' (missing)
- No CALL statements between programs → no inter-program dependencies
- Migration wave: Wave 1 = copybook (missing), Wave 2 = all 4 programs

### Step 3 — COBOL Analysis (sequential, 4 agents)
**Agent:** `cobol-analyzer` (subagent_type: "cobol-analyzer") × 4
**Order:** 01_select → 02_insert_update → 03_delete → 04_ddl
**Outputs:** `/workspace/java-output/analysis/<filename>_analysis.md`

### Step 4 — Java Conversion (sequential, 4 agents)
**Agent:** `java-converter` (subagent_type: "java-converter") × 4
**Inputs:** COBOL file + corresponding analysis report
**Outputs per file:**
- `/workspace/java-output/java/com/example/database/<ClassName>.java`
- `/workspace/java-output/java/<ClassName>_conversion_notes.md`

**Key conversion decisions:**
- `EXEC SQL` → Quarkus Panache / `@Inject EntityManager` / raw JDBC
- `SQLSTATE` error handling → Java exception handling (copybook missing → implement inline)
- COBOL cursor loop → Java `ResultSet` or `List<Entity>` iteration
- `PIC X(n)` → `String`, `PIC 9(n)` → `int`/`long`, `PIC X(1024)` buffer → not needed in Java
- DDL execution → `@Transactional` service method with `EntityManager.createNativeQuery()`

### Step 5 — Output Verification
- Check 4 `.java` files exist (one per `.cbl`)
- Check 4 `_analysis.md` files exist
- Check 4 `_conversion_notes.md` files exist
- Flag any empty or stub-only Java files

### Step 6 — Migration Report
Write `/workspace/java-output/MIGRATION_REPORT.md` with:
- Executive summary, wave table, file mapping, manual review items
- Note: `SQLSTATE-CHECK.cpy` not found — copybook logic inlined into each Java class

---

## Output Directory Structure

```
/workspace/java-output/
├── MIGRATION_REPORT.md
├── dependency-map.md
├── analysis/
│   ├── 01_select_analysis.md
│   ├── 02_insert_update_analysis.md
│   ├── 03_delete_analysis.md
│   └── 04_ddl_analysis.md
└── java/
    ├── com/example/database/
    │   ├── Select.java
    │   ├── InsertUpdate.java
    │   ├── Delete.java
    │   └── Ddl.java
    ├── Select_conversion_notes.md
    ├── InsertUpdate_conversion_notes.md
    ├── Delete_conversion_notes.md
    └── Ddl_conversion_notes.md
```

---

## Risk Notes

| Risk | Mitigation |
|------|-----------|
| `SQLSTATE-CHECK.cpy` missing | Inline equivalent Java exception handling; flag in report |
| `04_ddl.cbl` PROGRAM-ID mismatch (`02_ddl`) | Note in conversion; use filename as class name |
| EXEC SQL → Java: no direct equivalent | Use Quarkus Panache or raw JDBC; document decisions in notes |
| MariaDB ODBC connection string | Replace with Quarkus `application.properties` datasource config |

---

## Verification

After pipeline completes, confirm:
1. `/workspace/java-output/MIGRATION_REPORT.md` exists and has all 4 files mapped
2. All 4 `.java` files are present and non-empty
3. Confidence scores in conversion notes are ≥ 0.5 for all files
