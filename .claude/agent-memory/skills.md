# Skills

## 2026-04-07 — java-converter: COBOL to Quarkus conversion

First run of the `java-converter` agent converting `01_select.cbl`.

Key patterns established:

- ESQL `DECLARE CURSOR / OPEN / FETCH UNTIL SQLCODE=100 / CLOSE` → JDBC `PreparedStatement` + `try-with-resources` + `while (rs.next())`. No explicit end-of-cursor check needed.
- `SQLSTATE-CHECK` copybook (missing) → infer as "negative SQLCODE = halt"; Java equivalent is `catch (SQLException e) { throw new RuntimeException(...) }` with SQLState and ErrorCode in the message.
- `EXEC SQL CONNECT TO :BUFFER` (hardcoded ODBC string) → `@Inject DataSource dataSource` + `application.properties` with `${DB_PASSWORD}` env var reference. Never hardcode passwords.
- COBOL group item with FILLER separators used for DISPLAY formatting → `formatKingRow()` method with explicit `String.format` padding matching PIC clause widths: `%010d` for PIC 9(10), `%-50s` for PIC X(50), `%04d` for PIC 9(4).
- `PIC 9(10)` → `long` (can exceed int range). `PIC 9(4)` → `int`. `PIC X(n)` → `String`.
- Output destination change: COBOL `DISPLAY` → method returns `List<String>` + nested static `@Path` JAX-RS resource with both JSON (`@Produces(APPLICATION_JSON)`) and plain-text (`/plain`) endpoints.
- `EXEC SQL CONNECT RESET` → implicit via `try-with-resources` closing `Connection`.
- Added `ORDER BY id` when original SELECT had no ORDER BY — document this behavioral change explicitly in conversion notes.
- Nested static REST class (`KingsResource`) keeps JAX-RS annotations out of the `@ApplicationScoped` service class.
- Confidence 0.85 for this program: missing copybook and output-destination decision are the two uncertain areas.

## 2026-04-07 — java-converter: 02_insert_update.cbl → InsertUpdate.java

Second conversion in the kings_of_poland suite (DML: INSERT + UPDATE).

Key patterns and decisions:

- No-transaction COBOL (two separate auto-committed EXEC SQL statements) → single `@Transactional` method wrapping both; atomicity is a deliberate correctness improvement, not a behavioral change.
- `insertAndUpdateKing()` is the primary service method; a `@POST` REST endpoint delegates to it and maps `SQLException` to HTTP 500.
- `EXEC SQL INSERT` that omits AUTO_INCREMENT id column → `PreparedStatement` with positional params only; rowcount asserted to be exactly 1 via `getUpdateCount()`.
- Unguarded COBOL `UPDATE` (could rename multiple rows silently) → Java version throws `IllegalStateException` if `rowsAffected != 1`, triggering transaction rollback.
- COBOL count-delta success check (`cnt-new > cnt-old` → DISPLAY "SUCESS!" / "FAILD!") retained as log-output parity, but real correctness comes from exception propagation. Typos corrected to "SUCCESS!" / "FAILED!".
- Name-staging pattern preserved: local variable `filterKingName` captures the original name before `kingName` is overwritten — exact COBOL `MOVE king-name TO filter-king-name` equivalent.
- `king` group's five FILLER `" | "` fields discarded; `King` inner DTO exposes only the six data fields; `toString()` replicates the display format.
- `king-id` (dead field — never set before INSERT in original) present on `King` DTO for completeness but never passed to `insertKing()`; documented clearly.
- Unused import risk: checked after writing; removed stray `DataSourceDefinition` import before delivery.
- Confidence 0.85: missing SQLSTATE-CHECK copybook and fixed demo data are the two uncertain areas.

## 2026-04-07 — java-converter: 03_delete.cbl → Delete.java

Third conversion in the kings_of_poland suite (DELETE with count verification).

Key patterns and decisions:

- Three-round-trip COBOL pattern (`SELECT count(*)` before + `DELETE` + `SELECT count(*)` after) → single `PreparedStatement.executeUpdate()` return value. Eliminates two extra DB round trips.
- PIC X(50) host variable trailing-space bug: `MOVE 'Rudolf' TO king-name` right-pads to 50 chars; `WHERE name = :king-name` silently matches zero rows against a VARCHAR column. Fix: `name.trim()` before JDBC bind. Document as a correctness fix, not a behavioral change.
- Broken success criterion `cnt-new <= cnt-old` (true even on zero rows deleted) → corrected to `rowsDeleted > 0`. This is a deliberate bug fix; note it in conversion notes with the original line reference (line 69).
- Hardcoded delete target `'Rudolf'` → method parameter `String name`; REST endpoint uses `@PathParam("name")` so callers can pass `/kings/Rudolf` to reproduce original behaviour.
- `EXEC SQL CONNECT RESET` → implicit `Connection.close()` via try-with-resources; same as prior programs.
- Result DTO (`DeleteResult`) carries name, rowsDeleted, success flag, and message — replaces three COBOL DISPLAY lines.
- REST layer: `@DELETE @Path("/kings/{name}")` → 204 on success, 404 on zero-rows-deleted, 400 on blank name.
- Typos "SUCESS!" / "FAILD!" corrected to "SUCCESS!" / "FAILED!" — document original COBOL line numbers (70, 72) in conversion notes for traceability.
- Unused host variable sub-fields (`king-id`, year fields) omitted from the Java service entirely; only `king-name` was used by the DELETE.
- ODBC typo `COMPERSSED_PROTO` not carried over to `application.properties`.
- Confidence 0.88: slightly higher than prior programs because program logic is simpler (CC=2) and the only uncertainty is the missing SQLSTATE-CHECK copybook reconstruction.

## 2026-04-07 — java-converter: 04_ddl.cbl → Ddl.java

Fourth conversion in the kings_of_poland suite (pure DDL: CREATE TABLE + DROP TABLE).

Key patterns and decisions:

- PROGRAM-ID mismatch (`02_ddl` vs filename `04_ddl.cbl`): use filename as canonical, class named `Ddl`.
- `PIC X(1024) BUFFER` used for both connection string assembly and DDL text → eliminated entirely in Java. Connection goes to `application.properties`; DDL goes to `static final String` constants. No field needed.
- `IF SQLSTATE='42S01'` after CREATE → `catch (SQLException e) { if ("42S01".equals(e.getSQLState())) ...`. Returns `boolean` to distinguish "created" vs "already existed".
- Stale second `EXEC SQL EXECUTE IMMEDIATE :BUFFER` at COBOL lines 57-59 (duplicate DROP on already-dropped table) → intentionally omitted. Documented in Javadoc with original line numbers.
- Symmetric idempotency added to DROP path: SQLSTATE `42S02` (table does not exist) treated as warning+false return, matching CREATE's `42S01` handling. Original COBOL had no such guard.
- `EXEC SQL CONNECT RESET` → implicit `Connection.close()` via try-with-resources; no explicit disconnect.
- `PERFORM SQLSTATE-CHECK` (missing copybook, 3 calls) → `throw new DdlException(...)` static inner class. Method signatures declare `throws DdlException`.
- No `@Transactional` — DDL auto-commits in MariaDB; documenting this explicitly in class Javadoc is important.
- REST layer: `@POST /ddl/create` returns 200/409; `@DELETE /ddl/drop` returns 200/404.
- ODBC typo `COMPERSSED_PROTO` not carried over.
- Confidence 0.75: lower than prior programs due to missing copybook and HIGH migration complexity rating from analysis report.
