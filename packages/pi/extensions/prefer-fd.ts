// @ts-nocheck
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import registerToggleMode from "./_lib/toggle-mode.ts";

export default function preferFdExtension(pi: ExtensionAPI) {
	registerToggleMode(pi, {
		stateType: "prefer-fd-state",
		commandName: "prefer-fd",
		defaultEnforce: true,
		systemPromptAddition: () => `

IMPORTANT:
- When using shell file search commands, prefer \`fd\` over \`find\`.
- Use \`fd\` by default for finding files and directories.
- Only use \`find\` if the user explicitly asks for find or find-specific behavior (like -exec or complex predicates) is required.
- When proposing shell examples, prefer commands like \`fd "pattern" .\` instead of \`find . -name "*pattern*"\`.
`,
		blockToolCall: (event) => {
			if (!isToolCallEventType("bash", event)) return undefined;
			const command = event.input.command?.trim();
			if (!command) return undefined;
			if (/^find(\s|$)/.test(command)) {
				return {
					block: true,
					reason: "Use `fd` instead of `find` for file search commands unless find-specific behavior is required.",
				};
			}
			return undefined;
		},
	});
}
