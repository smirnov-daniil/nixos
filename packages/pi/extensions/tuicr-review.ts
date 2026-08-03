import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

type ReviewSession = {
	slug: string;
};

type ReviewComment = {
	id: string;
	location?: string;
	path?: string;
	start_line?: number;
	end_line?: number;
	side?: "old" | "new";
	comment_type?: string;
	lifecycle_state?: string;
	content: string;
};

type CommentRecord = {
	session: string;
	comment: ReviewComment;
};

type CommentSnapshot = {
	fingerprints: Map<string, string>;
	records: CommentRecord[];
};

function parseJson<T>(value: string, label: string): T {
	try {
		return JSON.parse(value) as T;
	} catch {
		throw new Error(`${label} returned invalid JSON`);
	}
}

function commentKey(session: string, comment: ReviewComment): string {
	return `${session}\0${comment.id}`;
}

function commentFingerprint(comment: ReviewComment): string {
	return JSON.stringify([
		comment.content,
		comment.comment_type,
		comment.location,
		comment.path,
		comment.start_line,
		comment.end_line,
		comment.side,
		comment.lifecycle_state,
	]);
}

async function commentSnapshot(pi: ExtensionAPI, cwd: string): Promise<CommentSnapshot> {
	const list = await pi.exec("tuicr", ["review", "list", "--repo", cwd]);
	if (list.code !== 0) throw new Error(list.stderr.trim() || "tuicr review list failed");
	const sessions = parseJson<ReviewSession[]>(list.stdout, "tuicr review list");
	const fingerprints = new Map<string, string>();
	const records: CommentRecord[] = [];
	for (const session of sessions) {
		if (!session.slug) continue;
		const result = await pi.exec("tuicr", [
			"review",
			"comments",
			"--repo",
			cwd,
			"--session",
			session.slug,
		]);
		if (result.code !== 0) continue;
		const comments = parseJson<ReviewComment[]>(result.stdout, `tuicr session ${session.slug}`);
		for (const comment of comments) {
			if (!comment.id || !comment.content?.trim()) continue;
			if (comment.lifecycle_state && comment.lifecycle_state !== "local_draft") continue;
			fingerprints.set(commentKey(session.slug, comment), commentFingerprint(comment));
			records.push({ session: session.slug, comment });
		}
	}
	return { fingerprints, records };
}

function formatLocation(comment: ReviewComment): string {
	if (comment.location) return comment.location;
	if (!comment.path) return "review";
	if (comment.start_line === undefined) return comment.path;
	const line = comment.end_line && comment.end_line !== comment.start_line
		? `${comment.start_line}-${comment.end_line}`
		: String(comment.start_line);
	return `${comment.path}:${line}${comment.side ? ` (${comment.side})` : ""}`;
}

function formatFeedback(records: CommentRecord[]): string {
	const lines = ["Please address the following tuicr review feedback:", ""];
	records.forEach(({ comment }, index) => {
		const rawType = comment.comment_type?.trim().toUpperCase();
		const type = rawType && rawType !== "NONE" ? ` **[${rawType.replace(/[^A-Z0-9_-]/g, "")}]**` : "";
		lines.push(`${index + 1}.${type} \`${formatLocation(comment)}\``);
		lines.push(`   ${comment.content.trim().replace(/\n/g, "\n   ")}`);
		lines.push("");
	});
	return lines.join("\n").trim();
}

async function runTuicrInHerdr(pi: ExtensionAPI, cwd: string): Promise<void> {
	const wrapper = process.env.TUICR_HERDR_WRAPPER;
	if (!wrapper) throw new Error("the packaged tuicr Herdr wrapper is unavailable");
	const result = await pi.exec(wrapper, [cwd]);
	if (result.code !== 0) {
		throw new Error(result.stderr.trim() || result.stdout.trim() || "tuicr Herdr wrapper failed");
	}
}

export default function tuicrReviewExtension(pi: ExtensionAPI) {
	pi.registerCommand("diff-review", {
		description: "Select and review a diff in tuicr via Herdr",
		handler: async (_args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("diff-review requires interactive mode", "error");
				return;
			}
			if (process.env.HERDR_ENV !== "1") {
				ctx.ui.notify("diff-review requires Pi to run inside Herdr", "error");
				return;
			}
			const executableResult = await pi.exec("sh", ["-lc", "command -v tuicr"]);
			const executable = executableResult.stdout.trim();
			if (executableResult.code !== 0 || !executable) {
				ctx.ui.notify("tuicr is unavailable; launch Pi through the flake environment", "error");
				return;
			}
			const version = await pi.exec(executable, ["--version"]);
			if (version.code !== 0) {
				ctx.ui.notify("tuicr could not start", "error");
				return;
			}

			ctx.ui.setStatus("tuicr-review", ctx.ui.theme.fg("accent", "tuicr review"));
			try {
				const before = await commentSnapshot(pi, ctx.cwd);
				await runTuicrInHerdr(pi, ctx.cwd);
				const after = await commentSnapshot(pi, ctx.cwd);
				const changed = after.records.filter(({ session, comment }) =>
					before.fingerprints.get(commentKey(session, comment)) !== commentFingerprint(comment),
				);
				if (changed.length === 0) {
					ctx.ui.notify("tuicr review finished with no new comments", "info");
					return;
				}
				ctx.ui.pasteToEditor(formatFeedback(changed));
				ctx.ui.notify(`Imported ${changed.length} tuicr comment(s)`, "info");
			} catch (error) {
				ctx.ui.notify(`tuicr review failed: ${error instanceof Error ? error.message : String(error)}`, "error");
			} finally {
				ctx.ui.setStatus("tuicr-review", undefined);
			}
		},
	});
}
