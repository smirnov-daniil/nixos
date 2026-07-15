---
name: simplify
description: Review changed code for reuse, simplification, and efficiency, then apply the fixes directly. Quality only, not bug-hunting. Use when the user asks to simplify, clean up, or de-bloat a diff.
---

# Simplify

Review the pending changes (`jj diff --git`, or `git diff` if not jj-managed) for:

- Reinvented helpers that already exist in this codebase or the standard library
- Unneeded abstractions (interface/factory/config for one implementation or one value)
- Dead code, unused exports, speculative flexibility nothing uses yet
- Obvious efficiency wins (redundant passes, avoidable allocations)

## Process

1. Read the diff and the surrounding file context.
2. For each finding, apply the fix directly — don't just report it (that's `/skill:code-review`'s job).
3. Keep diffs minimal: delete over add, boring over clever.
4. After applying fixes, re-check the diff once more for anything the fixes themselves introduced.

## Output

Short summary: what was simplified and why, one line per change. No essay.
