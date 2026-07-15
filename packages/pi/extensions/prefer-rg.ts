// @ts-nocheck
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import registerToggleMode from "./_lib/toggle-mode.ts";

export default function preferRgExtension(pi: ExtensionAPI) {
	registerToggleMode(pi, {
		stateType: "prefer-rg-state",
		commandName: "prefer-rg",
		defaultEnforce: true,
		systemPromptAddition: () => `

IMPORTANT:
- When using shell search commands, prefer ripgrep (\`rg\`) over grep.
- Use \`rg\` by default for recursive text and code search.
- Only use \`grep\` if the user explicitly asks for grep or grep-specific behavior is required.
- When proposing shell examples, prefer commands like \`rg "pattern" .\` instead of \`grep -R "pattern" .\`.
`,
		blockToolCall: (event) => {
			if (!isToolCallEventType("bash", event)) return undefined;
			const command = event.input.command?.trim();
			if (!command) return undefined;
			if (/^grep(\s|$)/.test(command)) {
				return {
					block: true,
					reason:
						"Use ripgrep (`rg`) instead of `grep` for search commands unless grep-specific behavior is required.",
				};
			}
			return undefined;
		},
	});
}
