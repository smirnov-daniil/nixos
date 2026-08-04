import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { type SpawnAgentModelContext, spawnAgent } from "./_lib/spawn-agent.ts";

const MAX_REVIEW_ROUNDS = 3;

type PlanItem = {
	task: string;
};

type TestResult = {
	task: string;
	testFile: string;
	testDescription: string;
	targetFiles: string[];
	changeId: string;
	confirmedFailing: boolean;
};

type ItemResult = {
	task: string;
	status: "PASS" | "FAIL";
	summary: string;
	filesChanged: string[];
};

function section(text: string, heading: string): string {
	const match = text.match(new RegExp(`^#{2,3} ${heading}[^\\n]*\\n([\\s\\S]*?)(?=^#{2,3} |(?![\\s\\S]))`, "mi"));
	return match?.[1]?.trim() ?? "";
}

function itemBlocks(text: string): Array<{ task: string; body: string }> {
	return [...text.matchAll(/^## Item:\s*(.+)\n([\s\S]*?)(?=^## Item:|(?![\s\S]))/gm)].map((match) => ({
		task: match[1].trim(),
		body: match[2],
	}));
}

function listPaths(text: string): string[] {
	return [...text.matchAll(/`([^`]+)`/g)].map((match) => match[1]);
}

function parsePlan(plan: string): { items: PlanItem[]; batches: number[][] } {
	const items = [...plan.matchAll(/^- \[ \] (.+)$/gm)].map((match) => ({ task: match[1].trim() }));
	const rawBatches = section(plan, "Batches")
		.split("\n")
		.map((line) => [...line.matchAll(/\d+/g)].map((match) => Number(match[0]) - 1))
		.filter((batch) => batch.length > 0);
	const indices = rawBatches.flat();
	const valid = indices.length === items.length
		&& new Set(indices).size === items.length
		&& indices.every((index) => index >= 0 && index < items.length);
	return { items, batches: valid ? rawBatches : items.map((_, index) => [index]) };
}

function parseTests(output: string): TestResult[] {
	return itemBlocks(output).map(({ task, body }) => {
		const test = section(body, "Test");
		const targetFiles = section(body, "Target Files");
		const confirmed = section(body, "Confirmed Failing");
		return {
			task,
			testFile: listPaths(test)[0] ?? "",
			testDescription: test.replace(/`[^`]+`\s*-?\s*/, "").trim(),
			targetFiles: listPaths(targetFiles),
			changeId: section(body, "Change ID").replace(/`/g, "").trim(),
			confirmedFailing: /^yes\b/i.test(confirmed),
		};
	});
}

function parseResults(output: string, expected: PlanItem[]): ItemResult[] {
	const byTask = new Map(itemBlocks(output).map(({ task, body }) => [task, {
		task,
		status: /^pass\b/i.test(section(body, "Status")) ? "PASS" as const : "FAIL" as const,
		summary: section(body, "Completed") || section(body, "Notes") || "No result reported",
		filesChanged: listPaths(section(body, "Files Changed")),
	}]));
	return expected.map((item) => byTask.get(item.task) ?? {
		task: item.task,
		status: "FAIL",
		summary: "Agent did not report this item",
		filesChanged: [],
	});
}

function parseCritical(review: string): string[] {
	const body = section(review, "Critical");
	if (!body || /^none\.?$/i.test(body.replace(/^[-*]\s*/, "").trim())) return [];
	return body.split("\n").map((line) => line.replace(/^[-*]\s*/, "").trim()).filter(Boolean);
}

function mergeResults(base: ItemResult[], updates: ItemResult[]): ItemResult[] {
	const byTask = new Map(base.map((result) => [result.task, result]));
	for (const result of updates) byTask.set(result.task, result);
	return [...byTask.values()];
}

function describeItem(item: PlanItem, test: TestResult | undefined, isJujutsu: boolean): string {
	const editHint = isJujutsu && test?.changeId ? ` Before touching files, run \`jj edit ${test.changeId}\`.` : "";
	const targetHint = test?.targetFiles.length ? ` Source files: ${test.targetFiles.join(", ")}.` : "";
	const testHint = test?.confirmedFailing
		? ` Pinned test: ${test.testFile} - ${test.testDescription} (currently failing; make it pass).${targetHint}`
		: ` Pinned test: ${test?.testFile || "(none)"} - ${test?.testDescription || "no runnable test surface"}.${targetHint}`;
	return `- ${item.task}.${editHint}${testHint}`;
}

async function runRole(
	role: string,
	prompt: string,
	cwd: string,
	modelContext: SpawnAgentModelContext,
): Promise<string> {
	const result = await spawnAgent(role, prompt, cwd, modelContext);
	if (result.exitCode !== 0) {
		throw new Error(`${role} failed: ${result.stderr || result.output || `exit ${result.exitCode}`}`);
	}
	return result.output;
}

export default function pipelineExtension(pi: ExtensionAPI) {
	pi.registerCommand("ship", {
		description: "Research, plan, pin tests, implement in batches, review, and finalize commits",
		handler: async (args, ctx) => {
			const task = args.trim();
			if (!task) {
				ctx.ui.notify("Usage: /ship <task description>", "warning");
				return;
			}

			const cwd = ctx.cwd;
			const modelContext = { models: ctx.modelRegistry.getAvailable(), currentModel: ctx.model };
			const run = (role: string, prompt: string) => runRole(role, prompt, cwd, modelContext);
			try {
				ctx.ui.notify("ship: scout", "info");
				const scout = await run("scout", `Task: ${task}\n\nInvestigate the codebase and return a structured handoff in your final response.`);

				ctx.ui.notify("ship: plan", "info");
				const plan = await run("planner", `Task: ${task}\n\nScout findings:\n${scout || "(no findings)"}\n\nReturn the complete plan in your final response. Include a final ## Batches section with one line per implementation batch, using one-based item numbers such as \`- 1, 2\`.`);
				const { items, batches } = parsePlan(plan);
				if (items.length === 0) throw new Error("planner produced no checklist items in its final response");

				ctx.ui.notify("ship: repository check", "info");
				const repoCheck = await run("committer", "Check whether the repository root has a .jj directory. Reply Yes or No only.");
				const isJujutsu = /^yes\b/i.test(repoCheck.trim());

				ctx.ui.notify(`ship: pinning tests for ${items.length} item(s)`, "info");
				const itemList = items.map((item, index) => `${index + 1}. ${item.task}`).join("\n");
				const testPrompt = `Plan items, in order:\n${itemList}\n\nFull plan:\n${plan}\n\n${isJujutsu ? "This is a jj repo: open one commit per item before writing its test and report the change ID. " : ""}Process every item in one pass. For each output block include ### Target Files and ### Change ID in addition to the documented format.`;
				const tester = await run("tester", testPrompt);
				const tests = parseTests(tester);

				for (const batchIndices of batches) {
					const batchItems = batchIndices.map((index) => items[index]).filter(Boolean);
					if (batchItems.length === 0) continue;
					const descriptions = batchItems.map((item) => describeItem(item, tests.find((test) => test.task === item.task), isJujutsu)).join("\n");
					ctx.ui.notify(`ship: implement ${batchItems.map((item) => item.task).join("; ")}`, "info");
					let output = await run("implementer", `Implement these independent items in order:\n${descriptions}\n\nFull plan:\n${plan}`);
					let results = parseResults(output, batchItems);
					let failing = batchItems.filter((item) => results.find((result) => result.task === item.task)?.status !== "PASS");

					if (failing.length > 0) {
						const failures = failing.map((item) => {
							const result = results.find((candidate) => candidate.task === item.task);
							return `${describeItem(item, tests.find((test) => test.task === item.task), isJujutsu)} Previous failure: ${result?.summary}.${result?.filesChanged.length ? ` Files touched: ${result.filesChanged.join(", ")}.` : ""}`;
						}).join("\n");
						output = await run("implementer", `Retry these failed items without repeating the same approach:\n${failures}\n\nFull plan:\n${plan}`);
						results = mergeResults(results, parseResults(output, failing));
						failing = failing.filter((item) => results.find((result) => result.task === item.task)?.status !== "PASS");
					}

					if (failing.length > 0) {
						const failures = failing.map((item) => {
							const result = results.find((candidate) => candidate.task === item.task);
							return `${describeItem(item, tests.find((test) => test.task === item.task), isJujutsu)} Two attempts failed. Last failure: ${result?.summary}.${result?.filesChanged.length ? ` Files touched: ${result.filesChanged.join(", ")}.` : ""}`;
						}).join("\n");
						output = await run("implementer-escalated", `Diagnose and implement these still-failing items:\n${failures}\n\nFull plan:\n${plan}`);
						results = mergeResults(results, parseResults(output, failing));
						failing = failing.filter((item) => results.find((result) => result.task === item.task)?.status !== "PASS");
					}

					if (failing.length > 0) throw new Error(`items failed after escalation: ${failing.map((item) => item.task).join("; ")}`);
				}

				let critical: string[] = [];
				let review = "";
				for (let round = 1; round <= MAX_REVIEW_ROUNDS; round++) {
					ctx.ui.notify(`ship: review ${round}/${MAX_REVIEW_ROUNDS}`, "info");
					review = await run("reviewer", `Review all changes against this plan:\n${plan}`);
					critical = parseCritical(review);
					if (critical.length === 0) break;
					if (round === MAX_REVIEW_ROUNDS) throw new Error(`critical review findings remain: ${critical.join("; ")}`);
					await run("implementer", `Fix these review findings:\n${critical.join("\n")}\n\nFull plan:\n${plan}${isJujutsu ? "\n\nAfter fixing, run jj absorb to distribute fixes into their originating commits." : ""}`);
				}

				ctx.ui.notify("ship: finalize", "info");
				const handoff = `Plan:\n${plan}\n\nReview:\n${review}`;
				const finalizePrompt = isJujutsu
					? `${handoff}\n\nVerify every per-item commit is atomic and well described, and absorb stray review fixes.`
					: `${handoff}\n\nSplit the accumulated diff into one commit per semantic block.`;
				const committed = await run("committer", finalizePrompt);
				ctx.ui.notify(committed || "ship: done", "info");
			} catch (error) {
				ctx.ui.notify(`ship: ${error instanceof Error ? error.message : String(error)}`, "error");
			}
		},
	});
}
