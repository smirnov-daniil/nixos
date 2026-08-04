---
description: Review code with AI and write findings into the active tuicr session
argument-hint: "[jj revset or extra instructions]"
---
Use the `tuicr` skill's **Agent review of an AI-generated patch** workflow. Invoking this command is explicit approval to write agent-authored comments into tuicr.

Attach to the current repository's active tuicr session with `tuicr review list --repo`. Continue only when exactly one relevant session is active; otherwise ask the user to open tuicr, select the intended diff, and invoke `/ai-review` again.

Review the code without modifying repository files. In a Jujutsu repository, activate the Jujutsu workflow and use read-only `jj diff --git` inspection. Treat the following as an optional revset or additional review instruction:

$ARGUMENTS

Add every confident, actionable finding directly to the active session with `tuicr review add`. Prefer line comments, then file comments, and use review-level comments only for cross-cutting findings. Classify comments as `issue`, `suggestion`, `note`, or `praise`, and always pass `--username "Pi AI Reviewer"`. If there are no actionable findings, add one review-level `praise` comment stating that the AI review found no actionable issues.

Do not paste findings into the Pi editor and do not implement fixes. Finish by reporting the reviewed session slug and the number of AI comments added.
