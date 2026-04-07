---
paths:
  - "**/*"
---

# Iterative Writing Rule

If the output is going to be very large, ~500+ lines, Don’t generate everything at once. Break it into controlled passes and iteratively append the file, artifact, or output. This improves clarity, correctness, maintainability, and ability to review or adjust mid-way.

## 1. Strategy: Sequential Strategy

You fully complete one section at a time, in order.

### Steps

1. List all sections (outline)
2. Write Section A completely
3. Write Section B completely
4. Continue until all sections are done

### When to use

Use this when:

- Sections are independent
- One section does not depend on another

### Example

A report:

- Chapter 1: Market Overview
- Chapter 2: Competitors
- Chapter 3: Strategy

Each chapter can be written independently then use Sequential.

### Key Property

- Each section is final when written
- No need to revisit earlier sections

## 2. Strategy: Scaffold then Fill Strategy

You build the entire structure first, then gradually fill it in.

### Steps

Pass 1 (Scaffold):

- Create structure recurssively:
  - headings
  - sections
  - method signatures
  - placeholders like `TODO`

Pass N+ (Fill):

- Replace one placeholder at a time
- Recursivelly key adding placeholder if needed
- Continue until all placeholders are filled

### Example

```python
class Engine:
    def start(self):
        # TODO

    def stop(self):
        # TODO
```

Then:

- Pass 2: implement `start`
- Pass 3: implement `stop`

### When to use

Use this when:

- Sections are interdependent
- You need the full structure visible before writing details

### Key Property

- Structure comes before detail
- Refinement happens incrementally
- Do NOT declare completion while any placeholder (`TODO`, stub, empty section) remains.

Completion requires:

- All sections fully written
- No placeholders remaining

## When to Choose Which

| Situation                  | Strategy           |
| -------------------------- | ------------------ |
| Independent sections       | Sequential         |
| Interconnected system      | Scaffold then Fill |
| Writing a report/book      | Sequential         |
| Writing code/system design | Scaffold then Fill |

## Mental Model

- Sequential = Finish one section completely before moving on
- Scaffold then Fill = Build sections, then fill them step by step
