// @ts-nocheck
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { isToolCallEventType } from "@earendil-works/pi-coding-agent";
import registerToggleMode from "./_lib/toggle-mode.ts";

// Lightweight read-only brainstorming toggle for quick ad-hoc use. For a
// structured, reviewed plan use the /ship pipeline's planner stage instead.
const MUTATING_BASH =
	/^(rm|mv|cp|mkdir|touch|chmod|chown|git\s+(add|commit|push|reset|checkout|restore|clean|rebase|merge)|jj\s+(commit|describe|squash|abandon|new|restore|rebase)|npm\s+(install|ci)|nix\s+flake\s+update)\b/;

type TodoItem = {
	step: number;
	text: string;
	completed: boolean;
};

type ProgressState = {
	todos: TodoItem[];
	executing: boolean;
};

function textFromMessage(message: any): string {
	if (message?.role !== "assistant" || !Array.isArray(message.content)) return "";
	return message.content
		.filter((part: any) => part.type === "text")
		.map((part: any) => part.text)
		.join("\n");
}

function extractTodos(text: string): TodoItem[] {
	const header = text.match(/^\*{0,2}Plan:\*{0,2}\s*$/im);
	if (!header || header.index === undefined) return [];
	const section = text.slice(header.index + header[0].length);
	return [...section.matchAll(/^\s*(\d+)[.)]\s+(.+)$/gm)]
		.map((match, index) => ({
			step: index + 1,
			text: match[2].replace(/\*{1,2}|`/g, "").trim(),
			completed: false,
		}))
		.filter((item) => item.text.length > 3);
}

function markCompleted(text: string, todos: TodoItem[]): boolean {
	let changed = false;
	for (const match of text.matchAll(/\[DONE:(\d+)\]/gi)) {
		const item = todos.find((candidate) => candidate.step === Number(match[1]));
		if (item && !item.completed) {
			item.completed = true;
			changed = true;
		}
	}
	return changed;
}

export default function planModeExtension(pi: ExtensionAPI) {
	let todos: TodoItem[] = [];
	let executing = false;

	const mode = registerToggleMode(pi, {
		stateType: "plan-mode-state",
		commandName: "plan-mode",
		defaultEnabled: false,
		defaultEnforce: true,
		systemPromptAddition: () => `

IMPORTANT: plan mode is active. Do NOT modify any files or run mutating commands.
Investigate, read code, and produce a concrete written plan for the user to review.
End with a numbered section in this exact form:

Plan:
1. First implementation step
2. Second implementation step

Use \`/plan-mode off\` once the user approves before making changes.
`,
		blockToolCall: (event) => {
			if (isToolCallEventType("edit", event) || isToolCallEventType("write", event)) {
				return {
					block: true,
					reason: "Plan mode is active — no file edits. Use /plan-mode off once the plan is approved.",
				};
			}
			if (!isToolCallEventType("bash", event)) return undefined;
			const command = event.input.command?.trim();
			if (!command) return undefined;
			if (MUTATING_BASH.test(command)) {
				return {
					block: true,
					reason: "Plan mode is active — no mutating commands. Use /plan-mode off once the plan is approved.",
				};
			}
			return undefined;
		},
	});

	const persist = () => {
		pi.appendEntry("plan-progress-state", { todos, executing } satisfies ProgressState);
	};

	const updateUi = (ctx: any) => {
		if (!ctx.hasUI) return;
		if (!executing || todos.length === 0) {
			ctx.ui.setStatus("plan-progress", undefined);
			ctx.ui.setWidget("plan-progress", undefined);
			return;
		}
		const completed = todos.filter((item) => item.completed).length;
		ctx.ui.setStatus("plan-progress", ctx.ui.theme.fg("accent", `Plan ${completed}/${todos.length}`));
		ctx.ui.setWidget("plan-progress", todos.map((item) => {
			const marker = item.completed ? "☑" : "☐";
			return item.completed
				? `${ctx.ui.theme.fg("success", marker)} ${ctx.ui.theme.fg("muted", ctx.ui.theme.strikethrough(item.text))}`
				: `${ctx.ui.theme.fg("muted", marker)} ${item.text}`;
		}));
	};

	const restore = (ctx: any) => {
		const entry = [...ctx.sessionManager.getBranch()].reverse().find(
			(candidate: any) => candidate.type === "custom" && candidate.customType === "plan-progress-state",
		);
		if (entry?.data) {
			todos = Array.isArray(entry.data.todos) ? entry.data.todos : [];
			executing = entry.data.executing === true;
		} else {
			todos = [];
			executing = false;
		}
		updateUi(ctx);
	};

	pi.registerCommand("todos", {
		description: "Show plan execution progress",
		handler: async (_args, ctx) => {
			if (todos.length === 0) {
				ctx.ui.notify("No tracked plan", "info");
				return;
			}
			ctx.ui.notify(
				todos.map((item) => `${item.step}. ${item.completed ? "✓" : "○"} ${item.text}`).join("\n"),
				"info",
			);
		},
	});

	pi.on("before_agent_start", async () => {
		if (!executing || mode.isEnabled() || todos.length === 0) return undefined;
		const remaining = todos.filter((item) => !item.completed);
		return {
			message: {
				customType: "plan-execution-context",
				content: `[EXECUTING PLAN]\n\nRemaining steps:\n${remaining.map((item) => `${item.step}. ${item.text}`).join("\n")}\n\nExecute in order. After completing each step, include [DONE:n] in your response.`,
				display: false,
			},
		};
	});

	pi.on("turn_end", async (event, ctx) => {
		if (!executing || todos.length === 0) return;
		if (markCompleted(textFromMessage(event.message), todos)) {
			persist();
			updateUi(ctx);
		}
	});

	pi.on("agent_end", async (event, ctx) => {
		if (executing) {
			if (todos.length > 0 && todos.every((item) => item.completed)) {
				pi.sendMessage({
					customType: "plan-complete",
					content: `Plan complete: ${todos.length}/${todos.length} steps finished.`,
					display: true,
				}, { triggerTurn: false });
				todos = [];
				executing = false;
				persist();
				updateUi(ctx);
			}
			return;
		}
		if (!mode.isEnabled() || ctx.mode !== "tui") return;
		const lastAssistant = [...event.messages].reverse().find((message: any) => message.role === "assistant");
		const extracted = extractTodos(textFromMessage(lastAssistant));
		if (extracted.length === 0) return;
		todos = extracted;
		persist();
		const choice = await ctx.ui.select("Plan ready", [
			"Execute the plan",
			"Stay in plan mode",
			"Refine the plan",
		]);
		if (choice === "Execute the plan") {
			mode.setEnabled(false);
			executing = true;
			persist();
			updateUi(ctx);
			pi.sendUserMessage(
				`Execute this plan in order:\n\n${todos.map((item) => `${item.step}. ${item.text}`).join("\n")}\n\nAfter completing each step, include [DONE:n] in your response.`,
				{ deliverAs: "followUp" },
			);
			return;
		}
		if (choice === "Refine the plan") {
			const refinement = await ctx.ui.editor("How should the plan change?", "");
			if (refinement?.trim()) pi.sendUserMessage(refinement.trim(), { deliverAs: "followUp" });
		}
	});

	pi.on("session_start", async (_event, ctx) => restore(ctx));
	pi.on("session_tree", async (_event, ctx) => restore(ctx));
}
