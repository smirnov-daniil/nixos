import type { AgentMessage } from "@earendil-works/pi-agent-core";
import { complete, type Message } from "@earendil-works/pi-ai/compat";
import type { ExtensionAPI, SessionEntry } from "@earendil-works/pi-coding-agent";
import { BorderedLoader, convertToLlm, serializeConversation } from "@earendil-works/pi-coding-agent";

const SYSTEM_PROMPT = `You are a context transfer assistant. Given a conversation history and the user's goal for a new thread, generate a focused prompt that:

1. Summarizes relevant context, decisions, approaches, and findings
2. Lists relevant files that were discussed or modified
3. Clearly states the next task based on the user's goal
4. Is self-contained so the new thread can proceed without the old conversation

Return only the prompt. Keep it concise while preserving all necessary context.

Use this format:
## Context
[Relevant context, decisions, and files]

## Task
[Clear next task]`;

function entryToMessage(entry: SessionEntry): AgentMessage | undefined {
	if (entry.type === "message") return entry.message;
	if (entry.type !== "compaction") return undefined;
	return {
		role: "compactionSummary",
		summary: entry.summary,
		tokensBefore: entry.tokensBefore,
		timestamp: new Date(entry.timestamp).getTime(),
	};
}

function handoffMessages(branch: SessionEntry[]): AgentMessage[] {
	let compactionIndex = -1;
	for (let index = branch.length - 1; index >= 0; index--) {
		if (branch[index].type === "compaction") {
			compactionIndex = index;
			break;
		}
	}
	if (compactionIndex < 0) {
		return branch.map(entryToMessage).filter((message) => message !== undefined);
	}
	const compaction = branch[compactionIndex];
	const firstKeptIndex = compaction.type === "compaction"
		? branch.findIndex((entry) => entry.id === compaction.firstKeptEntryId)
		: -1;
	const compactedBranch = [
		compaction,
		...(firstKeptIndex >= 0 ? branch.slice(firstKeptIndex, compactionIndex) : []),
		...branch.slice(compactionIndex + 1),
	];
	return compactedBranch.map(entryToMessage).filter((message) => message !== undefined);
}

export default function handoffExtension(pi: ExtensionAPI) {
	pi.registerCommand("handoff", {
		description: "Transfer relevant context to a new focused session",
		handler: async (args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("handoff requires interactive mode", "error");
				return;
			}
			if (!ctx.model) {
				ctx.ui.notify("No model selected", "error");
				return;
			}
			const goal = args.trim();
			if (!goal) {
				ctx.ui.notify("Usage: /handoff <goal for new session>", "warning");
				return;
			}
			const messages = handoffMessages(ctx.sessionManager.getBranch());
			if (messages.length === 0) {
				ctx.ui.notify("No conversation to hand off", "warning");
				return;
			}
			const conversationText = serializeConversation(convertToLlm(messages));
			const currentSessionFile = ctx.sessionManager.getSessionFile();
			const generated = await ctx.ui.custom<{ prompt?: string; error?: string } | null>((tui, theme, _kb, done) => {
				const loader = new BorderedLoader(tui, theme, "Generating handoff prompt...");
				loader.onAbort = () => done(null);
				const generate = async () => {
					const auth = await ctx.modelRegistry.getApiKeyAndHeaders(ctx.model!);
					if (!auth.ok || !auth.apiKey) {
						throw new Error(auth.ok ? `No API key for ${ctx.model!.provider}` : auth.error);
					}
					const userMessage: Message = {
						role: "user",
						content: [{
							type: "text",
							text: `## Conversation History\n\n${conversationText}\n\n## Goal for the New Session\n\n${goal}`,
						}],
						timestamp: Date.now(),
					};
					const response = await complete(
						ctx.model!,
						{ systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
						{ apiKey: auth.apiKey, headers: auth.headers, env: auth.env, signal: loader.signal },
					);
					if (response.stopReason === "aborted") return null;
					return response.content
						.filter((content): content is { type: "text"; text: string } => content.type === "text")
						.map((content) => content.text)
						.join("\n");
				};
				generate()
					.then((prompt) => done(prompt === null ? null : { prompt }))
					.catch((error) => done({ error: error instanceof Error ? error.message : String(error) }));
				return loader;
			});
			if (generated === null) {
				ctx.ui.notify("Handoff cancelled", "info");
				return;
			}
			if (generated.error || !generated.prompt) {
				ctx.ui.notify(`Handoff failed: ${generated.error ?? "empty prompt"}`, "error");
				return;
			}
			const editedPrompt = await ctx.ui.editor("Edit handoff prompt", generated.prompt);
			if (editedPrompt === undefined) {
				ctx.ui.notify("Handoff cancelled", "info");
				return;
			}
			const result = await ctx.newSession({
				parentSession: currentSessionFile,
				withSession: async (replacementCtx) => {
					replacementCtx.ui.setEditorText(editedPrompt);
					replacementCtx.ui.notify("Handoff ready. Submit when ready.", "info");
				},
			});
			if (result.cancelled) ctx.ui.notify("New session cancelled", "info");
		},
	});
}
