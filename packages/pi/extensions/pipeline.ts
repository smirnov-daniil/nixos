// @ts-nocheck
/**
 * Deterministic research -> plan -> implement -> review -> commit pipeline.
 * Retry/escalation/review-fix looping is real control flow here, not prose
 * an LLM orchestrator is trusted to count correctly. Each stage runs as an
 * isolated `pi -p --no-session` subprocess (see _lib/spawn-agent.ts); only
 * this driver carries state across stages, and that state is just file
 * paths and small counters.
 */
import * as fs from "node:fs";
import * as path from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { spawnAgent } from "./_lib/spawn-agent.ts";

const MAX_REVIEW_ROUNDS = 3;

function scratchpadDir(cwd: string): string {
	return path.join(cwd, "scratchpad");
}

function writeScratch(cwd: string, name: string, content: string) {
	const dir = scratchpadDir(cwd);
	fs.mkdirSync(dir, { recursive: true });
	fs.writeFileSync(path.join(dir, name), content, "utf-8");
}

function readScratch(cwd: string, name: string): string {
	return fs.readFileSync(path.join(scratchpadDir(cwd), name), "utf-8");
}

// Planner is instructed (see agents/planner.md) to emit a literal markdown
// checklist so it's parseable with a plain regex, not another LLM call.
function parsePlanItems(plan: string): string[] {
	return [...plan.matchAll(/^- \[ \] (.+)$/gm)].map((m) => m[1].trim());
}

function parseStatus(output: string): "PASS" | "FAIL" {
	return /## Status\s*\n\s*PASS/i.test(output) ? "PASS" : "FAIL";
}

function parseCritical(review: string): string {
	const match = review.match(/## Critical[^\n]*\n([\s\S]*?)(?:\n## |$)/);
	const body = (match?.[1] ?? "").trim();
	return body && !/^none\.?$/i.test(body) ? body : "";
}

export default function pipelineExtension(pi: ExtensionAPI) {
	pi.registerCommand("ship", {
		description: "Run the research -> plan -> implement -> review -> commit pipeline: /ship <task>",
		handler: async (args, ctx) => {
			const task = (args || "").trim();
			if (!task) {
				ctx.ui.notify("Usage: /ship <task description>", "warning");
				return;
			}
			const cwd = ctx.cwd;

			ctx.ui.notify("ship: scout...", "info");
			const scout = await spawnAgent("scout", task, cwd);
			writeScratch(cwd, "research.md", scout.output || "(no findings)");

			ctx.ui.notify("ship: planner...", "info");
			const planner = await spawnAgent(
				"planner",
				`${task}\n\n---\nResearch findings (scratchpad/research.md):\n${readScratch(cwd, "research.md")}`,
				cwd,
			);
			writeScratch(cwd, "plan.md", planner.output || "");
			const items = parsePlanItems(readScratch(cwd, "plan.md"));
			if (items.length === 0) {
				ctx.ui.notify("ship: planner produced no checklist items, stopping. See scratchpad/plan.md.", "error");
				return;
			}

			for (const item of items) {
				ctx.ui.notify(`ship: implementing "${item}"...`, "info");
				let result = await spawnAgent(
					"implementer",
					`Plan item: ${item}\n\nFull plan (scratchpad/plan.md):\n${readScratch(cwd, "plan.md")}`,
					cwd,
				);
				let status = parseStatus(result.output);

				if (status === "FAIL") {
					ctx.ui.notify(`ship: "${item}" failed, retrying...`, "warning");
					result = await spawnAgent(
						"implementer",
						`Plan item: ${item}\n\nPrevious attempt failed:\n${result.output}\n\nFull plan:\n${readScratch(cwd, "plan.md")}`,
						cwd,
					);
					status = parseStatus(result.output);
				}

				if (status === "FAIL") {
					ctx.ui.notify(`ship: "${item}" failed twice, escalating...`, "warning");
					result = await spawnAgent(
						"implementer-escalated",
						`Plan item: ${item}\n\nTwo prior attempts failed. Last failure:\n${result.output}\n\nFull plan:\n${readScratch(cwd, "plan.md")}`,
						cwd,
					);
					status = parseStatus(result.output);
					if (status === "FAIL") {
						ctx.ui.notify(`ship: "${item}" still failing after escalation. Stopping for manual review.`, "error");
						return;
					}
				}
			}

			let round = 0;
			while (round < MAX_REVIEW_ROUNDS) {
				round++;
				ctx.ui.notify(`ship: reviewer (round ${round})...`, "info");
				const reviewer = await spawnAgent(
					"reviewer",
					`Review the changes against the plan (scratchpad/plan.md):\n${readScratch(cwd, "plan.md")}`,
					cwd,
				);
				writeScratch(cwd, "review.md", reviewer.output || "");
				const critical = parseCritical(reviewer.output || "");
				if (!critical) break;
				if (round >= MAX_REVIEW_ROUNDS) {
					ctx.ui.notify(
						`ship: reviewer still flags critical issues after ${MAX_REVIEW_ROUNDS} rounds. See scratchpad/review.md, resolve manually.`,
						"error",
					);
					return;
				}
				ctx.ui.notify("ship: implementer fixing review feedback...", "info");
				await spawnAgent(
					"implementer",
					`Fix the following review feedback (scratchpad/review.md):\n${critical}\n\nFull plan:\n${readScratch(cwd, "plan.md")}`,
					cwd,
				);
			}

			ctx.ui.notify("ship: committer...", "info");
			const committer = await spawnAgent(
				"committer",
				`Plan (scratchpad/plan.md):\n${readScratch(cwd, "plan.md")}\n\nReview (scratchpad/review.md):\n${readScratch(cwd, "review.md")}`,
				cwd,
			);
			ctx.ui.notify(committer.output || "ship: done.", "info");
		},
	});
}
