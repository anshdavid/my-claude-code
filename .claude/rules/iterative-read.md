---
paths:
  - "**/*"
---

# Iterative Reading Rule

For files over 600 lines, read in 800-line chunks with a 200-line overlap (stride = 600).

## Chunk table

| Chunk | Offset | Limit | Lines Covered |
| ----- | ------ | ----- | ------------- |
| 1     | 0      | 800   | 1–800         |
| 2     | 600    | 800   | 601–1400      |
| 3     | 1200   | 800   | 1201–2000     |
| 4     | 1800   | 800   | 1801–2600     |

Stop when a chunk returns fewer than 800 lines — that's EOF.

**Example** — reading a 1,500-line file:

- `Read(offset=0, limit=800)` → lines 1–800
- `Read(offset=600, limit=800)` → lines 601–1400 _(200-line overlap)_
- `Read(offset=1200, limit=800)` → lines 1201–1500 _(returns 300 → EOF)_

## Rules

- Synthesize all chunks before acting or editing
- If the last chunk returns exactly 800 lines, read one more — file may still be truncated
