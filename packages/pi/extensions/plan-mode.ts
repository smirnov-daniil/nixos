// @ts-nocheck
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import registerToggleMode from "./_lib/toggle-mode.ts";

// Lightweight read-only brainstorming toggle for quick ad-hoc use. For a
// structured, reviewed plan use the /ship pipeline's planner stage instead.
const MUTATING_BASH =
	/^(rm|mv|cp|mkdir|touch|chmod|chown|git\s+(add|commit|push|reset|checkout|restore|clean|rebase|merge)|jj\s+(commit|describe|squash|abandon|new|restore|rebase)|npm\s+(install|ci)|nix\s+flake\s+update)\b/;

export default function planModeExtension(pi: ExtensionAPI) {
	registerToggleMode(pi, {
		stateType: "plan-mode-state",
		commandName: "plan-mode",
		defaultEnabled: false,
		defaultEnforce: true,
		systemPromptAddition: () => `

IMPORTANT: plan mode is active. Do NOT modify any files or run mutating commands.
Investigate, read code, and produce a concrete written plan (files to touch, changes, risks) for the user to review.
Use \`/plan-mode off\` once the user approves before making changes.
`,
		blockToolCall: (event) => {
			if (isToolCallEventType("edit", event) || isToolCallEventType("write", event)) {
				return {
					block: true,
					reason: "Plan mode is active — no file edits. Use /plan-mode off once the plan is approved.",
				};
			}
			if (!isToolCallEventType("bash", event)) return undefined;
			const command = event.input.command?.trim();
			if (!command) return undefined;
			if (MUTATING_BASH.test(command)) {
				return {
					block: true,
					reason: "Plan mode is active — no mutating commands. Use /plan-mode off once the plan is approved.",
				};
			}
			return undefined;
		},
	});
}
