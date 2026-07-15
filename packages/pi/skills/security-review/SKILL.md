---
name: security-review
description: Security review of the pending changes on the current branch. Checks for injection, authz, secrets, and deserialization issues scoped to the diff. Explicit-invocation only given blast radius.
disable-model-invocation: true
---

# Security Review

Review the pending changes (`jj diff --git`, or `git diff` if not jj-managed) for security issues, scoped to what actually changed (not a whole-repo audit).

## Checklist

- Injection: SQL, command, path traversal, template/SSRF — anywhere user input reaches a sink
- AuthZ/authn: missing checks, privilege confusion, IDOR
- Secrets: hardcoded credentials, keys logged or committed, secrets in error messages
- Deserialization: unsafe parsing of untrusted input (YAML/pickle-equivalents, prototype pollution)
- Insecure defaults introduced by the diff itself

## Output

One line per finding: `path:line: <severity>: <problem>. <fix>.` No praise, no scope creep beyond the diff. End with a one-line verdict.
