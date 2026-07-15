---
name: verify
description: Exercise a code change end-to-end before calling it done, driving the actual flow rather than relying only on tests or type checks. Use before committing a nontrivial change to product code.
---

# Verify

Type checks and test suites verify code correctness, not feature correctness. This skill drives the actual change to observe real behavior.

## Process

1. Identify what kind of project this is (CLI, server, TUI, library, web app) and how it's normally run/built.
2. Start/build it if needed.
3. Drive the specific flow the change touches — the golden path first, then the edge cases the change was meant to handle.
4. Watch for regressions in adjacent features the change could plausibly affect.
5. If you can't actually exercise the change (no runtime surface, e.g. a docs-only or test-only diff), say so explicitly rather than claiming it works.

## Output

One line: what was exercised, what was observed, pass/fail. If it fails, describe the concrete symptom, not just "didn't work."
