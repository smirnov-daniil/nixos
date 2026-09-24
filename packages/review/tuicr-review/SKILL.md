---
name: tuicr-review
description: Review a local diff with tuicr, publish AI findings into its review session, or address comments handed back from tuicr. Supports Claude Code, Codex and Pi with jj or Git repositories and multi-repository tasks.
---

Use `reviewctl` from the packaged environment. A review ID binds one repository,
diff snapshot and tuicr session. Never choose a session by newest timestamp or
collect comments from every session in a repository.

## Open a human review

In tmux, run `reviewctl open --repo "$PWD" --pane`. This opens tuicr beside the
calling pane and returns a review ID. Use `--mode branch` for the whole branch
(`trunk()..@` in jj), or `--revset REVSET` for a jj range plus the working change. The default
reviews the jj working change / Git working tree. Use `--pick-repo` for the
interactive umbrella-repository picker when the user is operating the terminal.

The human may also open a review from ccmux with `d`/`D`, or with tmux `Ctrl+b r`.
`reviewctl list` lists review IDs and repository paths. When no ID was supplied,
select only an unambiguous review for the requested repository and scope;
otherwise ask which ID to use. Do not poll indefinitely unless asked to wait.

## AI review in the same tuicr session

Read `reviewctl context REVIEW_ID`. Inspect its `diff_file` and the corresponding
repository files. Respect the selected scope and the repository's jj workflow.
The tuicr session must have been opened at least once and retain that scope.
Review code without implementing fixes when the user asked for review only.

Write confident, actionable findings through `reviewctl add`. It checks that
the diff is still current and uses tuicr's locking/merge protocol. Example:

```sh
reviewctl add REVIEW_ID --author "Codex AI Reviewer" <<'JSON'
{"file":"src/example.cpp","line":42,"side":"new","type":"issue","content":"Explain the concrete failure and the condition that triggers it."}
JSON
```

Use `Claude AI Reviewer` or `Pi AI Reviewer` for those agents. Preserve the
` AI Reviewer` suffix: automatic handback excludes these comments so the human
can assess them first. Omit `file` and `line` for a cross-cutting finding.
Use `end_line` for a range and `side: "old"` for removed lines. Check existing
comments before adding duplicates. No findings means no added comments.
The open tuicr pane refreshes when comments arrive.

## Handback and fixes

`reviewctl comments REVIEW_ID` reads comments from that exact session.
`reviewctl handoff REVIEW_ID [ANOTHER_ID ...]` lets the human choose comments
(including AI findings), a recipient and whether to fill its composer or run.
Several reviews from Baloo's submodules can travel in one message.

For an explicitly requested programmatic handoff, use
`reviewctl send REVIEW_ID --agent CCMUX_SESSION_ID [--no-enter]`.
It includes undelivered human comments by default; use repeated `--comment ID`
to send selected findings, or `--include-ai` only when requested. Sending requires
an idle agent in the same project and an unchanged diff. Do not bypass a stale
review error: open a new review of the changed code. A filled composer counts
as delivered; the user still presses Enter in that agent.

When receiving feedback, validate findings against the current code, implement
the requested corrections and run appropriate checks. Report what was addressed
and any finding you could not reproduce. Do not delete the human's comments or
call them resolved merely because they were delivered. Open a new review for
the corrected diff when requested.
