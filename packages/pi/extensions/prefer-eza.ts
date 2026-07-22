// @ts-nocheck
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import registerToggleMode from "./_lib/toggle-mode.ts";

export default function preferEzaExtension(pi: ExtensionAPI) {
	registerToggleMode(pi, {
		stateType: "prefer-eza-state",
		commandName: "prefer-eza",
		defaultEnforce: true,
		systemPromptAddition: () => `

IMPORTANT:
- When listing directory contents, prefer \`eza\` over \`ls\`.
- Use \`eza\` by default for human-readable directory listings.
- Only use \`ls\` if the user explicitly asks for ls or ls-specific behavior is required.
- When proposing shell examples, prefer commands like \`eza --group-directories-first --icons=always --git\` instead of \`ls -la\`.
`,
		blockToolCall: (event) => {
			if (event.toolName === "ls") {
				return {
					block: true,
					reason: "Use `bash` with `eza` instead of the built-in `ls` tool unless ls-specific behavior is required.",
				};
			}
			if (!isToolCallEventType("bash", event)) return undefined;
			const command = event.input.command?.trim();
			if (!command) return undefined;
			if (/^ls(\s|$)/.test(command)) {
				return {
					block: true,
					reason: "Use `eza` instead of `ls` for directory listings unless ls-specific behavior is required.",
				};
			}
			return undefined;
		},
	});
}
