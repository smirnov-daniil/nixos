import { basename } from "node:path";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function oscText(value: string): string {
	return value.replace(/[\u0000-\u001f\u007f;]/g, " ");
}

function notifyOsc777(title: string, body: string): void {
	process.stdout.write(`\x1b]777;notify;${oscText(title)};${oscText(body)}\x07`);
}

function notifyOsc99(title: string, body: string): void {
	process.stdout.write(`\x1b]99;i=pi:d=0;${oscText(title)}\x1b\\`);
	process.stdout.write(`\x1b]99;i=pi:p=body;${oscText(body)}\x1b\\`);
}

export default function notifyExtension(pi: ExtensionAPI) {
	pi.on("agent_settled", async (_event, ctx) => {
		if (ctx.mode !== "tui" || !process.stdout.isTTY) return;
		const title = `Pi · ${basename(ctx.cwd)}`;
		if (process.env.KITTY_WINDOW_ID) {
			notifyOsc99(title, "Ready for input");
			return;
		}
		notifyOsc777(title, "Ready for input");
	});
}
