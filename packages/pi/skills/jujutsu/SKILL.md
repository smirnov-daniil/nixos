---
name: jujutsu
description: "**REQUIRED** - Always activate FIRST on any git/VCS operations (commit, status, branch, push, etc.), especially when HEAD is detached. If `.jj/` exists -> this is a Jujutsu (jj) repo - raw git commands can corrupt data. Essential git safety instructions inside. DO NOT IGNORE."
allowed-tools: bash
---
# Jujutsu (jj) Version Control System

Skill help work with Jujutsu, Git-compatible VCS, mutable commits, automatic rebasing.

**Tested with jj v0.37.0** - Commands may differ other versions.

## Important: Automated/Agent Environment

Running as agent:

1. **Always use `--no-pager`** — prevent commands open interactive pager (like `less`), hangs agent:

```bash
# Always use --no-pager on commands that produce output
jj --no-pager log          # NOT: jj log
jj --no-pager diff         # NOT: jj diff
jj --no-pager show <id>    # NOT: jj show <id>
```

2. **Always use `-m` flags** — provide messages inline, skip editor prompts:

```bash
# Always use -m to avoid editor prompts
jj desc -m "message"      # NOT: jj desc
jj squash -m "message"    # NOT: jj squash (which opens editor)
```

Editor-based commands fail non-interactive environments.

3. **Verify operations with `jj st`** after mutations (`squash`, `abandon`, `rebase`, `restore`) — confirm operation succeeded.

## Core Concepts

### The Working Copy is a Commit

jj: working directory always commit (referenced `@`). Changes auto-snapshot on any jj command run. No staging area.

No need run `jj commit`.

### Commits Are Mutable

**CRITICAL**: Unlike git, jj commits freely modifiable after creation. Update descriptions, squash changes, rebase, absorb — all without new commits. See "Essential Workflow" below for recommended working pattern.

### Change IDs vs Commit IDs

- **Change ID**: stable identifier (like `tqpwlqmp`), persists when commit rewritten — prefer referencing commits
- **Commit ID**: content hash (like `3ccf7581`), changes when commit content changes

### Revsets

jj uses revset language select commits in commands. Common revsets:

- `@` — working copy commit
- `@-` — parent of working copy
- `::@` — all ancestors of `@`
- `@::` — all descendants of `@`
- `trunk()..@` — commits between trunk and `@` (your branch)
- `bookmarks()` — all commits with bookmarks

Use revsets with `-r` flags: `jj log -r 'trunk()..@'`

## Essential Workflow

### Starting Work: Describe First, Then Code

**Always create commit message before writing code:**

Validate on blank revision with `jj st`. Not blank, type:

```bash
jj new
```

```bash
# First, describe what you intend to do
jj desc -m "Add user authentication to login endpoint"

# Then make your changes - they automatically become part of this commit
# ... edit files ...

# Check status
jj st
```

### Creating Atomic Commits

Each commit = ONE logical change. Format for commit messages:

```
Examples:
- "Add validation to user input forms"
- "Fix null pointer in payment processor"
- "Remove deprecated API endpoints"
- "Update dependencies to latest versions"
```

### Viewing History

```bash
# View recent commits
jj --no-pager log

# View with patches
jj --no-pager log -p

# View specific commit
jj --no-pager show <change-id>

# View diff of working copy (use --git for familiar +/- format)
jj --no-pager diff --git
```

**IMPORTANT: `jj diff` output format**: default `jj diff` output uses side-by-side line number format (e.g. `26   26:`) — looks very different from git's `+`/`-` prefix format. **Normal and correct** — NOT corrupted or stale content. To avoid confusion, **always use `jj diff --git`** for standard unified diff format with `+`/`-` lines.

### Moving Between Commits

```bash
# Create a new empty commit on top of current
jj new

# Create new commit with message
jj new -m "Commit message"

# Edit an existing commit (working copy becomes that commit)
jj edit <change-id>

# Edit the previous commit
jj prev -e

# Edit the next commit
jj next -e
```

## Refining Commits

### Squashing Changes

Move changes from current commit into parent:

```bash
# Squash all changes into parent
jj squash
```

**Note**: `jj squash -i` opens interactive UI, hangs agent environments. Avoid.

### Splitting Commits

**Warning**: `jj split` interactive, hangs agent environments. To divide commit, use `jj restore` move changes out, then create separate commits manually.

### Absorbing Changes

Auto-distribute changes to commits that last modified those lines:

```bash
# Absorb working copy changes into appropriate ancestor commits
jj absorb
```

### Abandoning Commits

Remove commit entirely (descendants rebased to its parent):

```bash
jj abandon <change-id>
```

### Undoing Operations

Reverse last jj operation:

```bash
jj undo
```

Reverts repository to state before previous command. Useful recover from mistakes like accidental `abandon`, `squash`, `rebase`.

### Rebasing Commits

Move commits to different parent:

```bash
# Rebase current branch onto a destination
jj rebase -d <destination>

# Rebase a specific revision (without descendants) onto a destination
jj rebase -r <change-id> -d <destination>

# Rebase a revision and all its descendants
jj rebase -s <change-id> -d <destination>

# Rebase onto trunk (common: update your branch to latest main)
jj rebase -d main
```

### Restoring Files

Discard changes to specific files or restore files from another revision:

```bash
# Discard all uncommitted changes in working copy (restore from parent)
jj restore

# Discard changes to specific files
jj restore path/to/file.txt

# Restore files from a specific revision
jj restore --from <change-id> path/to/file.txt
```

## Working with Bookmarks (Branches)

Bookmarks = jj's equivalent to git branches:

```bash
# Create a bookmark at current commit
jj bookmark create my-feature -r@

# Move bookmark to a different commit
jj bookmark move my-feature --to <change-id>

# List bookmarks
jj --no-pager bookmark list

# Delete a bookmark
jj bookmark delete my-feature
```

## Workspaces

**Workspace** = working copy plus associated repo. One repo, multiple workspaces — each own working directory + working-copy commit (`@`) — all share same commits, operations, bookmarks. jj's equivalent of `git worktree`.

Useful running long build/test in one workspace while editing another. Rarely-needed feature; consult [official docs](https://docs.jj-vcs.dev/latest/working-copy/#workspaces) for anything beyond basics below.

### Common commands

```bash
# Create a new workspace (defaults: name = basename of path, parent = current @'s parent)
jj workspace add ../my-tests
jj workspace add --name tests -r <change-id> ../my-tests   # explicit name and base

# Inspect
jj --no-pager workspace list
jj workspace root [--name <ws>]

# Remove (does NOT delete files on disk — rm the directory separately)
jj workspace forget [<ws>]

# Rename current workspace
jj workspace rename <new-name>
```

In `jj log`, each workspace's `@` appears as `<workspace-name>@`.

### Key semantics

- **Isolation by default.** `jj workspace add` gives new workspace own fresh empty commit; workspaces don't start sharing `@`, on-disk files never live-mirrored between them.
- **Propagation at command boundaries.** Each jj command snapshots current workspace's files, reads op log — sees commits/bookmarks made by other workspaces. No filesystem watcher.
- **Stale working copy.** If another workspace rewrites this workspace's `@` (e.g. via `jj squash`, `rebase`, `abandon`), jj refuses commands here until `jj workspace update-stale` run. Same recovery path if command interrupted mid-update.
- **Shared `@` sharp-edged.** `jj edit <id>` lets two workspaces point same change without warning. One mutates it, other goes stale; if stale one had un-snapshotted edits, `update-stale` preserves them as **divergent commit** (same change ID, shown `xyz??` in `jj log`) — must resolve. Avoid sharing `@` unless both workspaces read-only.

### Agent guidance

- Always pass `--no-pager` to `jj workspace list`.
- Don't `jj edit` change another workspace already has as its `@` — main cause accidental divergence.
- Don't `rm -rf` workspace directory without also running `jj workspace forget <name>`.

## Git Integration

### Working with Existing Git Repos

```bash
# Clone a git repository
jj git clone <url>

# Initialize jj in an existing git repo
jj git init --colocate
```

### Fetching Remote Changes

```bash
# Fetch all branches from the default remote
jj git fetch

# Fetch from a specific remote
jj git fetch --remote <remote-name>

# Fetch specific branches
jj git fetch -b <branch-name>
```

After fetching, rebase work onto updated trunk: `jj rebase -d main`

### Switching Between jj and git (Colocated Repos Only)

**This section only applies to colocated repos** (both `.jj/` and `.git/` exist). Non-colocated repos: don't use git commands — corrupt jj state.

Colocated repository: use both jj and git commands with care:

**Switching to git mode** (e.g., merge workflows):
```bash
# First, ensure your jj working copy is clean
jj st

# Then checkout a branch with git
git checkout <branch-name>
```

**Switching back to jj mode**:
```bash
# Use jj edit to resume working with jj
jj edit <change-id>
```

**Important notes:**
- Git may complain uncommitted changes if jj's working copy differs from git HEAD
- ALWAYS ensure work committed in jj before switching to git
- After git operations, jj detects and incorporates changes on next command

### Pushing Changes

User asks push changes:

```bash
# Push a specific bookmark to the remote
jj git push -b <bookmark-name>

# Example: push the main bookmark
jj git push -b main
```

**Before pushing, ensure:**
1. Bookmark points to correct commit (bookmarks don't auto-advance like git branches)
2. Commits refined and atomic
3. User explicitly requested push

**IMPORTANT**: Unlike git branches, jj bookmarks don't auto-move on new commits. Must manually update before pushing:

```bash
# Move an existing bookmark to the current commit
jj bookmark move my-feature --to @

# Then push it
jj git push -b my-feature
```

No bookmark exists for changes, create one first:

```bash
# Create a bookmark at the current commit
jj bookmark create my-feature

# Then push it
jj git push -b my-feature
```

## Handling Conflicts

jj allows committing conflicts — resolve later:

```bash
# View conflicts
jj st
```

**Agent conflict resolution**: Don't use `jj resolve` (interactive). Instead edit conflicted files directly remove conflict markers, then run `jj st` verify resolution.

## Preserving Commit Quality

**IMPORTANT**: Commits mutable — always refine before considering work done:

1. **Review your commit**: `jj --no-pager show @` or `jj --no-pager diff --git`
2. **Is it atomic?** One logical change per commit
3. **Is the message clear?** Use imperative verb phrase, sentence case, no full stop: e.g. "Add login endpoint", "Fix null pointer in payment processor", "Remove deprecated API endpoints"
4. **Unrelated changes?** Use `jj restore` move changes out, create separate commits
5. **Changes belong elsewhere?** Use `jj squash` or `jj absorb`
6. **Rethink comments before finalizing**: Re-read every comment added/touched in this commit's diff (`jj --no-pager diff --git`). Remove any just restating what next line does (e.g. `// Loop through users`, `# Set the flag`) — comment explains *what* code does → code should be self-explanatory instead (better names, extraction). Keep only comments explaining non-obvious *why*: hidden constraint, workaround, design tradeoff. Do this pass every time before commit ready, not just first draft.

## Quick Reference

| Action | Command |
|--------|---------|
| Describe commit | `jj desc -m "message"` |
| Rethink comments before commit | `jj --no-pager diff --git` (then edit files) |
| View status | `jj st` |
| View log | `jj --no-pager log` |
| View diff | `jj --no-pager diff --git` |
| New commit | `jj new -m "message"` (use `jj st` first; skip if `@` is empty) |
| Edit commit | `jj edit <id>` |
| Squash to parent | `jj squash` |
| Auto-distribute | `jj absorb` |
| Rebase | `jj rebase -d <destination>` |
| Abandon commit | `jj abandon <id>` |
| Undo last operation | `jj undo` |
| Restore files | `jj restore [paths]` |
| Create bookmark | `jj bookmark create <name>` |
| Fetch remote | `jj git fetch` |
| Push bookmark | `jj git push -b <name>` |
| Add workspace | `jj workspace add <path>` |
| List workspaces | `jj --no-pager workspace list` |
| Forget workspace | `jj workspace forget [name]` |
| Fix stale working copy | `jj workspace update-stale` |

## Best Practices Summary

1. **Describe first**: Set commit message before coding
2. **One change per commit**: Keep commits atomic, focused
3. **Use change IDs**: Stable across rewrites
4. **Refine commits**: Leverage mutability for clean history
5. **Rethink comments**: Before finalizing, strip "what"-narration comments; keep only non-obvious "why"
6. **Embrace the workflow**: No staging area, no stashing - just commits