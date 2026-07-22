# Global preferences

All responses start with my name "Daniil".

## Code style

- Do NOT write comments in code (no inline comments, no docstrings, no block comments) unless explicitly asked, or the codebase convention requires them (e.g. public API docs).
- Instead, explain what you did and why in your chat response.
- For non-trivial changes, write the reasoning to NOTES.md in the repo root (append, with a heading per change), not into the source files.
- Exception: keep comments that already exist in files you edit — don't delete them.

## Shell tools

- Prefer `fd` over `find` for finding files and directories.
- Prefer `rg` over `grep` for searching file contents.
- Fall back to `find` or `grep` only when the modern tool is unavailable or the required behavior has no equivalent.

## VCS attribution

Never add Claude or AI attribution anywhere: no `Co-Authored-By` trailers, no generated-by lines, and no AI attribution in git commits, Jujutsu descriptions, or pull requests.

## Skills

- Use the graphify skill before anything else when the user invokes `/graphify`, and treat questions about an existing `graphify-out/` graph as graph queries first.
- Activate the jujutsu skill before every VCS operation. If `.jj/` exists, use `jj`; raw git commands can corrupt Jujutsu repository state.
- Use the markitdown skill when asked to convert or read documents such as PDF, DOCX, PPTX, XLSX, HTML, CSV, JSON, XML, images, or audio.
