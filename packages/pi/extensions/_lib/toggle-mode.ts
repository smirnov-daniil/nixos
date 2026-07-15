// @ts-nocheck
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export type ToggleModeState = {
	enabled: boolean;
	enforce: boolean;
};

export interface ToggleModeConfig {
	stateType: string;
	commandName: string;
	label?: string;
	defaultEnabled?: boolean;
	defaultEnforce?: boolean;
	// Only used when no persisted state exists yet (e.g. prefer-jj auto-detecting .jj/).
	detectDefault?: (ctx: any) => boolean | Promise<boolean>;
	systemPromptAddition: (state: ToggleModeState) => string | undefined;
	blockToolCall?: (
		event: any,
		state: ToggleModeState,
	) => { block: true; reason: string } | undefined;
}

export default function registerToggleMode(pi: ExtensionAPI, cfg: ToggleModeConfig) {
	const label = cfg.label ?? cfg.commandName;
	const supportsEnforce = Boolean(cfg.blockToolCall);
	let enabled = cfg.defaultEnabled ?? true;
	let enforce = cfg.defaultEnforce ?? false;

	const persistState = () => {
		pi.appendEntry(cfg.stateType, { enabled, enforce } satisfies ToggleModeState);
	};

	pi.on("session_start", async (_event, ctx) => {
		for (const entry of [...ctx.sessionManager.getEntries()].reverse()) {
			if (
				entry.type === "custom" &&
				entry.customType === cfg.stateType &&
				entry.data &&
				typeof entry.data === "object"
			) {
				const data = entry.data as Partial<ToggleModeState>;
				enabled = data.enabled ?? enabled;
				enforce = data.enforce ?? enforce;
				return;
			}
		}
		if (cfg.detectDefault) {
			enabled = await cfg.detectDefault(ctx);
		}
	});

	pi.registerCommand(cfg.commandName, {
		description: `Configure ${label}: /${cfg.commandName} [on|off${supportsEnforce ? "|enforce-on|enforce-off" : ""}|status]`,
		handler: async (args, ctx) => {
			switch ((args || "status").trim()) {
				case "on":
					enabled = true;
					persistState();
					ctx.ui.notify(`${label} enabled`, "info");
					return;
				case "off":
					enabled = false;
					persistState();
					ctx.ui.notify(`${label} disabled`, "info");
					return;
				case "enforce-on":
					if (!supportsEnforce) break;
					enabled = true;
					enforce = true;
					persistState();
					ctx.ui.notify(`${label} enabled with enforcement`, "info");
					return;
				case "enforce-off":
					if (!supportsEnforce) break;
					enforce = false;
					persistState();
					ctx.ui.notify(`${label} enforcement disabled`, "info");
					return;
				case "status":
				case "":
					ctx.ui.notify(
						`${label}: ${enabled ? "on" : "off"}${supportsEnforce ? `, enforcement: ${enforce ? "on" : "off"}` : ""}`,
						"info",
					);
					return;
			}
			ctx.ui.notify(
				`Usage: /${cfg.commandName} [on|off${supportsEnforce ? "|enforce-on|enforce-off" : ""}|status]`,
				"warning",
			);
		},
	});

	pi.on("before_agent_start", async (event) => {
		if (!enabled) return undefined;
		const addition = cfg.systemPromptAddition({ enabled, enforce });
		if (!addition) return undefined;
		return { systemPrompt: event.systemPrompt + addition };
	});

	if (cfg.blockToolCall) {
		pi.on("tool_call", async (event) => {
			if (!enabled || !enforce) return undefined;
			return cfg.blockToolCall?.(event, { enabled, enforce });
		});
	}

	return {
		isEnabled: () => enabled,
		isEnforced: () => enforce,
	};
}
