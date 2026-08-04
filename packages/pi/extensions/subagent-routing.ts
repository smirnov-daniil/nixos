import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { discoverAgents } from "./_lib/agent-discovery.ts";
import { type AgentComplexity, resolveAgentRuntime } from "./_lib/agent-runtime.ts";

const BUILTIN_COMPLEXITY: Record<string, AgentComplexity> = {
	"general-purpose": "medium",
	Explore: "low",
	Plan: "high",
};

export default function subagentRoutingExtension(pi: ExtensionAPI) {
	pi.on("tool_call", async (event, ctx) => {
		if (event.toolName !== "Agent") return;
		const input = event.input as Record<string, unknown>;
		const name = typeof input.subagent_type === "string" ? input.subagent_type : undefined;
		if (!name || (input.model !== undefined && input.thinking !== undefined)) return;
		const models = ctx.modelRegistry.getAvailable();
		const { agents } = discoverAgents(ctx.cwd, "both", models, ctx.model);
		const role = agents.find((agent) => agent.name === name);
		const runtime = role ?? (BUILTIN_COMPLEXITY[name]
			? resolveAgentRuntime({ complexity: BUILTIN_COMPLEXITY[name] }, { models, currentModel: ctx.model })
			: undefined);
		if (!runtime) return;
		if (input.model === undefined && runtime.model) input.model = runtime.model;
		if (input.thinking === undefined && runtime.thinking) input.thinking = runtime.thinking;
	});
}
