import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function tuicrReviewExtension(pi: ExtensionAPI) {
  pi.registerCommand("diff-review", {
    description: "Review a diff in a tmux pane and import its human comments",
    handler: async (args, ctx) => {
      if (ctx.mode !== "tui" || !process.env.TMUX_PANE) {
        ctx.ui.notify("diff-review requires interactive Pi inside tmux", "error");
        return;
      }
      ctx.ui.setStatus("tuicr-review", "tuicr review");
      try {
        const recipient = `pi:${ctx.sessionManager.getSessionId()}`;
        const result = await pi.exec("reviewctl", [
          "open", "--repo", ctx.cwd, "--pane", "--wait", "--agent", recipient,
          ...(args.trim() ? ["--revset", args.trim()] : []),
        ]);
        if (result.code !== 0) throw new Error(result.stderr.trim() || "reviewctl failed");
        const review = JSON.parse(result.stdout);
        if (!Array.isArray(review.notes)) throw new Error("Invalid reviewctl result");
        if (review.notes.length === 0) {
          ctx.ui.notify(`No human comments; review ${review.ticket}`, "info");
          return;
        }
        const lines = review.notes.map((note: { id: string; location: string; content: string }) =>
          `[${note.id}] ${note.location}\n${note.content}`);
        ctx.ui.pasteToEditor(`Please address the tuicr feedback for review ${review.ticket} in ${ctx.cwd}.\n\n${lines.join("\n\n")}`);
        const acknowledged = await pi.exec("reviewctl", ["ack", review.ticket, "--agent", recipient,
          ...review.notes.flatMap((note: { key: string }) => ["--key", note.key])]);
        if (acknowledged.code !== 0) throw new Error(`Comments imported, but delivery tracking failed: ${acknowledged.stderr.trim()}`);
        ctx.ui.notify(`Imported ${review.notes.length} comments; press Enter to send`, "info");
      } catch (error) {
        ctx.ui.notify(`tuicr review failed: ${error instanceof Error ? error.message : String(error)}`, "error");
      } finally {
        ctx.ui.setStatus("tuicr-review", undefined);
      }
    },
  });
}
