---
name: code-review
description: Review the current diff for correctness bugs and reuse/simplification/efficiency cleanups. Use when the user asks to review a diff, PR, or branch.
---

# Code Review

Review the pending changes (`jj diff --git`, or `git diff` if not jj-managed) for two kinds of findings:

1. **Correctness bugs** - logic errors, edge cases, security issues, race conditions.
2. **Simplification/efficiency** - reused-or-reinventable helpers, unnecessary abstractions, dead code, obvious efficiency wins.

## Process

1. Get the diff and read the full context of each changed file (not just the hunks).
2. For each finding, note: file:line, one-sentence summary, a concrete failure scenario (correctness) or what to cut/replace (simplification).
3. Rank most-severe first. Skip formatting nits unless they change meaning.
4. Report — don't apply fixes (that's `/skill:simplify` for cleanups, or just ask to fix a specific bug).

## Output

One line per finding: `path:line: <severity>: <problem>. <fix>.`
End with a one-line verdict: ship as-is, ship with fixes, or needs rework.
