// @ts-nocheck
import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

type PreferFdState = {
	enabled: boolean;
	enforce: boolean;
};

const STATE_TYPE = "prefer-fd-state";

export default function preferFdExtension(pi: ExtensionAPI) {
	let enabled = true;
	let enforce = true;

	const persistState = () => {
		pi.appendEntry(STATE_TYPE, {
			enabled,
			enforce,
		} satisfies PreferFdState);
	};

	pi.on("session_start", async (_event, ctx) => {
		for (const entry of [...ctx.sessionManager.getEntries()].reverse()) {
			if (
				entry.type === "custom" &&
				entry.customType === STATE_TYPE &&
				entry.data &&
				typeof entry.data === "object"
			) {
				const data = entry.data as Partial<PreferFdState>;
				enabled = data.enabled ?? true;
				enforce = data.enforce ?? false;
				return;
			}
		}
	});

	pi.registerCommand("prefer-fd", {
		description:
			"Configure fd preference: /prefer-fd [on|off|enforce-on|enforce-off|status]",
		handler: async (args, ctx) => {
			switch ((args || "status").trim()) {
				case "on":
					enabled = true;
					persistState();
					ctx.ui.notify("prefer-fd enabled", "info");
					return;
				case "off":
					enabled = false;
					persistState();
					ctx.ui.notify("prefer-fd disabled", "info");
					return;
				case "enforce-on":
					enabled = true;
					enforce = true;
					persistState();
					ctx.ui.notify("prefer-fd enabled with bash enforcement", "info");
					return;
				case "enforce-off":
					enforce = false;
					persistState();
					ctx.ui.notify("prefer-fd enforcement disabled", "info");
					return;
				case "status":
				case "":
					ctx.ui.notify(
						`prefer-fd: ${enabled ? "on" : "off"}, enforcement: ${enforce ? "on" : "off"}`,
						"info",
					);
					return;
				default:
					ctx.ui.notify(
						"Usage: /prefer-fd [on|off|enforce-on|enforce-off|status]",
						"warning",
					);
			}
		},
	});

	pi.on("before_agent_start", async (event) => {
		if (!enabled) return undefined;

		return {
			systemPrompt:
				event.systemPrompt +
				`

IMPORTANT:
- When using shell file search commands, prefer \`fd\` over \`find\`.
- Use \`fd\` by default for finding files and directories.
- Only use \`find\` if the user explicitly asks for find or find-specific behavior (like -exec or complex predicates) is required.
- When proposing shell examples, prefer commands like \`fd "pattern" .\` instead of \`find . -name "*pattern*"\`.
`,
		};
	});

	pi.on("tool_call", async (event) => {
		if (!enabled || !enforce) return;
		if (!isToolCallEventType("bash", event)) return;

		const command = event.input.command?.trim();
		if (!command) return;

		if (/^find(\s|$)/.test(command)) {
			return {
				block: true,
				reason:
					"Use \`fd\` instead of \`find\` for file search commands unless find-specific behavior is required.",
			};
		}
	});
}
