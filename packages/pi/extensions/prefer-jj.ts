// @ts-nocheck
import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import registerToggleMode from "./_lib/toggle-mode.ts";

function hasJj(cwd: string): boolean {
	let dir = cwd;
	while (true) {
		if (fs.existsSync(path.join(dir, ".jj"))) return true;
		const parent = path.dirname(dir);
		if (parent === dir) return false;
		dir = parent;
	}
}

// Only commands that actually mutate repo/working-copy state; read-only git
// (log/show/diff for inspection) is left alone since jj repos are commonly
// colocated with a jj-managed .git dir.
const MUTATING_GIT =
	/^git\s+(add|commit|push|reset|checkout|restore|clean|rebase|merge|cherry-pick|revert|stash|branch\s+-[dD]|tag\s+-d)\b/;

export default function preferJjExtension(pi: ExtensionAPI) {
	registerToggleMode(pi, {
		stateType: "prefer-jj-state",
		commandName: "prefer-jj",
		defaultEnforce: true,
		detectDefault: (ctx) => hasJj(ctx.cwd),
		systemPromptAddition: () => `

IMPORTANT: this repository uses Jujutsu (jj), not plain git, for version control.
- Use \`jj st\` / \`jj diff --git\` / \`jj log\` / \`jj describe -m\` / \`jj new\` instead of \`git status\` / \`git diff\` / \`git log\` / \`git commit\` / \`git checkout\`.
- The working copy is always a commit (\`@\`) — there is no staging area and no need to \`git add\`.
- Never run mutating raw \`git\` commands (add/commit/push/reset/checkout/restore/clean/rebase/merge/stash) directly; a colocated \`.git\` dir may exist but is jj-managed. Read-only git commands (e.g. \`git log\` for inspection) are fine if truly needed, but prefer the jj equivalents above.
- Always pass \`--no-pager\` and \`-m "message"\` on jj commands that would otherwise open a pager or editor.
`,
		blockToolCall: (event) => {
			if (!isToolCallEventType("bash", event)) return undefined;
			const command = event.input.command?.trim();
			if (!command) return undefined;
			if (MUTATING_GIT.test(command)) {
				return {
					block: true,
					reason:
						"This repo uses jj (Jujutsu), not git. Use the jj equivalent (jj new/describe/squash/rebase/restore) instead of mutating git commands directly.",
				};
			}
			return undefined;
		},
	});
}
