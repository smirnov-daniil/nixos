import { afterEach, beforeEach, describe, expect, mock, test } from "bun:test";
import { EventEmitter } from "node:events";
import { PassThrough } from "node:stream";

class FakeProcess extends EventEmitter {
	stdout = new PassThrough();
	stderr = new PassThrough();
	exitCode: number | null = null;
	signalCode: NodeJS.Signals | null = null;
	finished = false;

	finish(code: number | null = 0, signal: NodeJS.Signals | null = null) {
		if (this.finished) return;
		this.finished = true;
		this.exitCode = code;
		this.signalCode = signal;
		this.stdout.end();
		this.stderr.end();
		queueMicrotask(() => this.emit("close", code));
	}

	kill(signal: NodeJS.Signals = "SIGTERM") {
		this.finish(null, signal);
		return true;
	}
}

class FakeText {
	constructor(private text = "") {}
	render() {
		return this.text.split("\n");
	}
}

const spawned: FakeProcess[] = [];

mock.module("node:child_process", () => ({
	spawn: () => {
		const process = new FakeProcess();
		spawned.push(process);
		return process;
	},
}));
mock.module("@earendil-works/pi-ai", () => ({ StringEnum: (values: unknown) => values }));
mock.module("@earendil-works/pi-coding-agent", () => ({
	CONFIG_DIR_NAME: ".pi",
	getAgentDir: () => "/tmp/pi-subagent-status-test",
	getMarkdownTheme: () => ({}),
	withFileMutationQueue: async (_path: string, operation: () => unknown) => operation(),
}));
mock.module("@earendil-works/pi-tui", () => ({
	Container: class {},
	Markdown: class {},
	Spacer: class {},
	Text: FakeText,
}));
mock.module("typebox", () => ({ Type: new Proxy({}, { get: () => (...args: unknown[]) => args }) }));
mock.module("./agents.ts", () => ({
	discoverAgents: () => ({
		agents: [
			{
				name: "probe",
				description: "probe",
				source: "user",
				filePath: "/tmp/probe.md",
				systemPrompt: "",
			},
		],
		projectAgentsDir: null,
	}),
}));

const { default: extension } = await import("./index.ts");
let tool: any;
extension({ registerTool(value: unknown) { tool = value; } } as any);

const context = {
	cwd: "/tmp",
	hasUI: false,
	model: undefined,
	modelRegistry: { getAvailable: () => [] },
};
const theme = {
	fg: (_color: string, text: string) => text,
	bold: (text: string) => text,
};

async function waitFor(predicate: () => boolean) {
	for (let attempt = 0; attempt < 100; attempt++) {
		if (predicate()) return;
		await new Promise((resolve) => setTimeout(resolve, 1));
	}
	throw new Error("condition was not reached");
}

function statuses(update: any) {
	return update.details.results.map((result: any) => result.status);
}

beforeEach(() => {
	spawned.length = 0;
});

afterEach(() => {
	for (const process of spawned) process.finish(1);
});

describe("subagent lifecycle", () => {
	test("single runs transition from running to done", async () => {
		const updates: any[] = [];
		const execution = tool.execute("single", { agent: "probe", task: "probe" }, undefined, (update: any) => updates.push(update), context);
		await waitFor(() => spawned.length === 1);
		expect(statuses(updates[0])).toEqual(["running"]);
		spawned[0].finish(0);
		const result = await execution;
		expect(statuses(updates.at(-1))).toEqual(["done"]);
		expect(updates.at(-1).content[0].text).toBe("(done; no output)");
		expect(result.details.results[0].status).toBe("done");
	});

	test("parallel runs distinguish pending, running, and done", async () => {
		const updates: any[] = [];
		const tasks = Array.from({ length: 5 }, () => ({ agent: "probe", task: "probe" }));
		const execution = tool.execute("parallel", { tasks }, undefined, (update: any) => updates.push(update), context);
		await waitFor(() => spawned.length === 4);
		expect(updates.some((update) => statuses(update).filter((status: string) => status === "running").length === 4 && statuses(update).includes("pending"))).toBeTrue();
		spawned[0].finish(0);
		await waitFor(() => spawned.length === 5);
		for (const process of spawned) process.finish(0);
		const result = await execution;
		expect(updates.some((update) => statuses(update).includes("done"))).toBeTrue();
		expect(result.details.results.map((item: any) => item.status)).toEqual(Array(5).fill("done"));
	});

	test("chain cancellation skips work that has not started", async () => {
		const controller = new AbortController();
		const updates: any[] = [];
		const chain = [
			{ agent: "probe", task: "first" },
			{ agent: "probe", task: "second" },
		];
		const execution = tool.execute("chain", { chain }, controller.signal, (update: any) => {
			updates.push(update);
			if (!controller.signal.aborted && statuses(update)[0] === "done") controller.abort();
		}, context);
		await waitFor(() => spawned.length === 1);
		spawned[0].finish(0);
		await expect(execution).rejects.toThrow("Subagent chain was aborted");
		expect(spawned).toHaveLength(1);
		expect(statuses(updates.at(-1))).toEqual(["done", "skipped"]);
	});

	test("parallel cancellation fails active work and skips queued work", async () => {
		const controller = new AbortController();
		const updates: any[] = [];
		const tasks = Array.from({ length: 5 }, () => ({ agent: "probe", task: "probe" }));
		const execution = tool.execute("parallel", { tasks }, controller.signal, (update: any) => updates.push(update), context);
		await waitFor(() => spawned.length === 4);
		controller.abort();
		await expect(execution).rejects.toThrow("Parallel subagents were aborted");
		expect(spawned).toHaveLength(4);
		expect(statuses(updates.at(-1))).toEqual(["failed", "failed", "failed", "failed", "skipped"]);
	});
});

describe("subagent rendering", () => {
	const usage = { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, cost: 0, contextTokens: 0, turns: 0 };
	const result = (status: string | undefined, exitCode: number) => ({
		agent: "probe",
		agentSource: "user",
		task: "probe",
		status,
		exitCode,
		messages: [],
		stderr: "",
		usage,
	});
	const render = (mode: string, results: any[]) => tool.renderResult(
		{ content: [{ type: "text", text: "probe" }], details: { mode, agentScope: "user", projectAgentsDir: null, results } },
		{ expanded: false },
		theme,
		{},
	).render(200).join("\n");

	test("labels active, completed, and historical results correctly", () => {
		expect(render("single", [result("running", -1)])).toContain("[running]");
		expect(render("single", [result("done", 0)])).toContain("[done]");
		expect(render("single", [result(undefined, -1)])).toContain("[running]");
		expect(render("single", [result(undefined, 0)])).toContain("[done]");
		expect(render("parallel", [result("done", 0), result("running", -1), result("pending", -1)]))
			.toContain("1 done, 1 running, 1 pending");
	});
});
