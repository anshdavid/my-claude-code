# Static Call Hierarchy Analysis

Generates an ASCII tree showing every callable-unit call from the entrypoint through all nested levels. Each node includes the name and source line range.

## Output

`./output/code-analysis/analysis-static-call-hierarchy.md`

## Hierarchy Format

### Node Format

Each node: `functionName [lines X-Y]` — Name only, no parameters, return types, or modifiers. Line range in square brackets.

### Tree Characters

```
├── sibling with more below
└── last sibling
│ vertical continuation (pipe + 3 spaces)
  indentation under last-sibling branch (4 spaces)
```

### Exclusions

Exclude from the hierarchy:

- Framework utility functions (logging, debugging, tracing)
- Infrastructure/boilerplate (memory allocation, initialization)
- Only include meaningful business logic or data flow calls

## Extraction Process

### Identification

1. Identify all callable-unit definitions and their line ranges.
2. Determine the entrypoint(s).
3. If multiple entrypoints exist, create a separate tree for each.

### Recursive Tracing

For each entrypoint:

1. Find every callable-unit call within the body.
2. Recurse into each called unit to find nested calls.
3. Maintain source order (top-to-bottom).
4. Annotate recursive calls with `(recursive)`.
5. Annotate external/unresolved calls with `(external)`.

## Objectives

### Objectives 1 — Identify All Callable Units and Entrypoints

Map all definitions with name and line range. Identify entrypoint(s).

### Objectives 2 — Trace Call Tree Recursively from Each Root

Trace every call in source order, recurse into nested calls. Exclude framework utility and debug calls. Annotate `(recursive)` and `(external)` where applicable.

### Objectives 3 — Format as ASCII Tree and Write Output

Render using box-drawing characters with `[lines X-Y]` on every node. Consistent 4-character indentation per nesting level.

### Objectives 4 — Validate Completeness

- [ ] All entrypoints identified as roots
- [ ] All calls traced recursively to leaf level
- [ ] Framework/debug functions excluded
- [ ] Line ranges on every node
- [ ] No parameters in names
- [ ] ASCII tree format (not JSON/YAML)
- [ ] Recursive and external calls annotated

## Example

````markdown
## Metadata

Source:
Date:
Description:

```
Single entry point:
processOrder [lines 100-500]
├── validateInput [lines 102-120]
├── checkNullRequest [lines 105-108]
│ └── checkAmountRange [lines 110-118]
├── fetchAccountDetails [lines 125-180]
│ ├── executeQuery [lines 130-145]
│ │ └── mapResultToAccount [lines 150-175]
│ └── parseBalance [lines 155-165]
├── calculateNewBalance [lines 185-210]
│ ├── applyFees [lines 190-205]
│ └── lookupFeeSchedule [lines 195-200] (external)
├── updateAccountBalance [lines 215-260]
│ ├── executeUpdate [lines 220-240]
│ │ └── commitTransaction [lines 245-255]
└── buildResponse [lines 265-290]
├── formatAmount [lines 270-278]
└── setResponseStatus [lines 280-288]

Multiple entry points:
== Entry Point 1 ==
handleRequest [lines 50-300]
├── parseInput [lines 55-80]
└── dispatchAction [lines 85-295]
├── actionCreate [lines 100-180]
└── actionDelete [lines 185-290]

== Entry Point 2 ==
handleCallback [lines 310-450]
├── validateCallback [lines 315-340]
└── processResult [lines 345-445]
```
````

## Rules

- **MUST** include every in-scope business-logic call.
- **MUST** exclude framework utility, debug, and infrastructure calls.
- **MUST** use ASCII box-drawing tree format.
- **MUST** include `[lines X-Y]` on every node.
- **MUST NOT** include parameters, return types, or modifiers.
- **MUST** annotate `(recursive)` and `(external)` calls.
