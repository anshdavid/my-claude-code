# Pseudocode Analysis

One continuous pseudocode document in a single fenced code block.

## Output

`./output/code-analysis/analysis-pseudocode.md`

## Notation

| Operation   | Symbol              | Example                    |
| :---------- | :------------------ | :------------------------- |
| Assignment  | <- or :=            | total <- total + amount    |
| Comparison  | =, !=, <, >, <=, >= | if count >= maxLimit       |
| Arithmetic  | +, -, \*, /, mod    | result <- a \_ b + c mod d |
| Floor/Ceil  | ⌊ ⌋, ⌈ ⌉            | length / 2                 |
| Logical     | and, or, not        | if valid and count > 0     |
| Aggregation | Σ, Π                | total <- Σ items           |
| Index       | [ ]                 | items[i]                   |

### Control Structures

if ... then ... else ... end if
while ... do ... end while
for each ... in ... do ... end for
return
call FunctionName(args)

### Comments and Prefixes

Inline comment after line number: `[Line:125] // fetches account balance`
Block comment: `/* comment spanning multiple lines */`
DB: prefix for SQL and database operations
ERROR: prefix for error handling (raise, catch, propagate)

## Output Format

### Continuous Flow

The output MUST BE one unbroken flow of pseudocode. Use indentation alone for structure. Prohibited: Markdown headers, subheadings, bullet points, horizontal rules, block quotes, HTML tags.
Allowed: Hierarchical step numbers (1., 1.1., 1.1.1.), indentation, `/* */` and `//` comments, `DB:` and `ERROR:` prefixes.

### Line Annotations

Every step MUST include a source line reference:

- Single line: `[Line:125]`
- Range: `[Lines:100-115]`
- With comment: `[Line:125] // single-row fetch`

### Hierarchical Numbering

1. Top-level step
   1.1. Sub-step
   1.1.1. Nested sub-step
   1.2. Sub-step
2. Next top-level step

## Coverage

### Required Content

1. Every callable unit - expanded inline, none skipped.
2. Every conditional path - if/else, switch/case, all branches.
3. Every loop - while, for, do-while with iteration details.
4. All SQL operations - queries, inserts, updates, deletes, cursors.
5. All error handling - try/catch, error codes, raise/throw, propagation chains.
6. All transactions - commits, rollbacks, savepoints with error codes.
7. All external calls - API invocations, library calls, inter-module references.
8. Variable assignments - descriptive names, data transformations.

## Objectives

### Objectives 1 — Parse Source and Identify Callable Units

Identify callable units, boundaries, and line ranges within each chunk. Map declarations to definitions. Note entry points.

### Objectives 2 — Generate Pseudocode Incrementally

Start from the entry point, number steps hierarchically. Annotate every step with `[Line:N]` or `[Lines:N-M]`.
Recurssively expand all nested calls inline with full detail.

- Use `DB:` for SQL, `ERROR:` for error handling.
- Use `/* */` for context blocks, `// comment` after line numbers.
- Resolve all global error-handling directives at every applicable point as they are encountered.
- Document error codes, messages, and handling paths inline within the pseudocode flow.
- Mark transaction boundaries (commits, rollbacks, savepoints) with corresponding error codes as they appear.
- NEVER buffer all pseudocode for a final write.
- NEVER defer error handling or transaction annotation to a separate pass.

### Objectives 3 — Validate Completeness

- [ ] Every callable unit expanded or explicitly omitted with reason.
- [ ] Every conditional path - both branches shown.
- [ ] Every SQL operation with `DB:` prefix.
- [ ] Every error with `ERROR:` prefix.
- [ ] Every transaction boundary annotated.
- [ ] Line number annotations on every step.
- [ ] Output is one continuous block - no markdown formatting breaks.
- [ ] Detailed enough to serve as an implementation blueprint.

## Example

````markdown
## Metadata

Source:
Date:
Description:

```algorithm
processOrder is
  input: OrderRequest request, Database db
  output: OrderResponse
/* Processes an incoming order: validates input, fetches account, debits the balance, and returns a response. */
1. Validate input [Lines:100-115]
   1.1. if request = null then
      ERROR: raise ValidationError("Request is null") [Line:102] // null guard
   end if
   1.2. if request.amount <= 0 then
      ERROR: raise ValidationError("Invalid amount") [Line:108] // negative/zero guard
   end if
2. call fetchAccountDetails(request.accountId) [Lines:120-145]
   2.1. DB: SELECT balance, status FROM accounts WHERE id = accountId [Line:125] // single-row fetch
   2.2. if result = null then
      ERROR: raise AccountNotFoundError(accountId) [Line:130]
   end if
   2.3. currentBalance <- result.balance [Line:135]
   2.4. if result.status != "ACTIVE" then
      ERROR: raise AccountInactiveError(accountId, result.status) [Line:140]
   end if
3. Process transaction [Lines:150-180]
   3.1. newBalance <- currentBalance - request.amount [Line:155]
   3.2. if newBalance < 0 then
      ERROR: raise InsufficientFundsError(currentBalance, request.amount) [Line:160]
   end if
   3.3. DB: UPDATE accounts SET balance = newBalance WHERE id = accountId [Line:170]
   3.4. DB: COMMIT [Line:175] // end of transaction boundary
4. return OrderResponse(status <- "SUCCESS", balance <- newBalance) [Line:180]
```
````

## Rules

- **MUST** produce one continuous document - no breaks in logic flow.
- **MUST NOT** use markdown headers, subheadings, bullet points, or block quotes in output.
- **MUST** use `[Line:N] // comment` for inline and `/* */` for block comments.
- **MUST** include line number annotations on every step.
- **MUST NOT** skip any callable unit, nested call, conditional path, or error handler.
- **MUST** resolve all error-handling directives at every applicable instance.
- **MUST** annotate all transaction boundaries with corresponding error codes.
