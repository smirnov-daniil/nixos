import { afterEach, describe, expect, test } from "bun:test";
import { mkdtempSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import subagentRoutingExtension from "./subagent-routing.ts";

const roots: string[] = [];
const originalAgentDir = process.env.PI_CODING_AGENT_DIR;

afterEach(() => {
	for (const root of roots.splice(0)) rmSync(root, { recursive: true, force: true });
	if (originalAgentDir === undefined) delete process.env.PI_CODING_AGENT_DIR;
	else process.env.PI_CODING_AGENT_DIR = originalAgentDir;
});

function setup() {
	let handler: ((event: any, ctx: any) => Promise<any>) | undefined;
	subagentRoutingExtension({
		on(event: string, callback: typeof handler) {
			if (event === "tool_call") handler = callback;
		},
	} as any);
	return (event: any, ctx: any) => handler!(event, ctx);
}

function model(id: string, name: string, input: number, output: number) {
	return {
		provider: "provider",
		id,
		name,
		api: "test",
		reasoning: true,
		contextWindow: 100000,
		maxTokens: 10000,
		cost: { input, output, cacheRead: 0, cacheWrite: 0 },
	};
}

test("routes custom agents from complexity without pinning a provider", async () => {
	const root = mkdtempSync(join(tmpdir(), "pi-routing-"));
	roots.push(root);
	const agentDir = join(root, "agent");
	mkdirSync(join(agentDir, "agents"), { recursive: true });
	writeFileSync(join(agentDir, "agents", "scout.md"), "---\nname: scout\ndescription: Scout\ncomplexity: low\n---\nScout");
	process.env.PI_CODING_AGENT_DIR = agentDir;
	const current = model("suite-standard-2", "Suite standard", 2, 4);
	const efficient = model("suite-mini-2", "Suite mini", 0.2, 0.4);
	const input = { subagent_type: "scout", prompt: "inspect", run_in_background: true };
	await setup()(
		{ toolName: "Agent", input },
		{ cwd: root, model: current, modelRegistry: { getAvailable: () => [current, efficient] } },
	);
	expect(input).toMatchObject({ model: "provider/suite-mini-2", thinking: "low" });
});

test("preserves explicit runtime overrides", async () => {
	const root = mkdtempSync(join(tmpdir(), "pi-routing-"));
	roots.push(root);
	const agentDir = join(root, "agent");
	mkdirSync(join(agentDir, "agents"), { recursive: true });
	writeFileSync(join(agentDir, "agents", "scout.md"), "---\nname: scout\ndescription: Scout\ncomplexity: low\n---\nScout");
	process.env.PI_CODING_AGENT_DIR = agentDir;
	const current = model("suite-standard-2", "Suite standard", 2, 4);
	const input = { subagent_type: "scout", prompt: "inspect", model: "other/model", thinking: "xhigh" };
	await setup()(
		{ toolName: "Agent", input },
		{ cwd: root, model: current, modelRegistry: { getAvailable: () => [current] } },
	);
	expect(input).toMatchObject({ model: "other/model", thinking: "xhigh" });
});

test("routes built-in roles without provider-specific defaults", async () => {
	const root = mkdtempSync(join(tmpdir(), "pi-routing-"));
	roots.push(root);
	process.env.PI_CODING_AGENT_DIR = join(root, "missing-agent-dir");
	const current = model("suite-standard-2", "Suite standard", 2, 4);
	const efficient = model("suite-mini-2", "Suite mini", 0.2, 0.4);
	const input = { subagent_type: "Explore", prompt: "inspect" };
	await setup()(
		{ toolName: "Agent", input },
		{ cwd: root, model: current, modelRegistry: { getAvailable: () => [current, efficient] } },
	);
	expect(input).toMatchObject({ model: "provider/suite-mini-2", thinking: "low" });
});
