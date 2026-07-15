---
description: One-shot check of PR/CI/deploy status; report a short status line
argument-hint: "[what to check]"
---
Check the status of ${1:-open PRs, CI runs, and any pending deploys for this repo}. Use whatever CLI is available (`gh`, `jj`, deploy tooling) to gather current state.

Report a single short status line per item: what it is, its state, and whether it needs human attention. Don't take any action beyond reporting — this is a read-only check.

To run this automatically on an interval, wrap it externally, e.g. a `systemd --user` timer calling:

    pi -p "$(cat ~/.pi/agent/prompts/babysit.md)"
