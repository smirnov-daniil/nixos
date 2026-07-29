// @ts-nocheck
/**
 * Minimal one-shot subagent spawn for the /ship pipeline: run one named
 * role to completion in an isolated `pi` process and capture its final
 * text output. Deliberately separate from the vendored subagent/index.ts
 * (which is a richer interactive tool with TUI rendering, parallel/chain
 * modes, and streaming) so that file can be re-vendored from upstream
 * cleanly without touching pipeline-specific logic.
 */
import { spawn } from "node:child_process";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { getAgentDir } from "@earendil-works/pi-coding-agent";
import { type AgentModelContext, resolveAgentRuntime } from "./agent-runtime.ts";

interface AgentRole {
	model?: string;
	tools?: string[];
	thinking?: string;
	systemPrompt: string;
}

export type SpawnAgentModelContext = AgentModelContext;

export interface SpawnResult {
	exitCode: number;
	output: string;
	stderr: string;
}

function loadRole(name: string, context: AgentModelContext): AgentRole {
	const filePath = path.join(getAgentDir(), "agents", `${name}.md`);
	const content = fs.readFileSync(filePath, "utf-8");
	const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
	if (!match) throw new Error(`Agent role file ${filePath} is missing YAML frontmatter`);
	const [, frontmatter, body] = match;
	const fields: Record<string, string> = {};
	for (const line of frontmatter.split("\n")) {
		const fieldMatch = line.match(/^(\w+):\s*(.*)$/);
		if (fieldMatch) fields[fieldMatch[1]] = fieldMatch[2].trim();
	}
	const tools = fields.tools
		?.split(",")
		.map((t) => t.trim())
		.filter(Boolean);
	const runtime = resolveAgentRuntime(fields, context);
	return {
		model: runtime.model,
		tools: tools && tools.length > 0 ? tools : undefined,
		thinking: runtime.thinking,
		systemPrompt: body.trim(),
	};
}

// Mirrors getPiInvocation from the vendored subagent extension: re-invoke the
// same `pi` binary/runtime that's currently executing.
function getPiInvocation(args: string[]): { command: string; args: string[] } {
	const currentScript = process.argv[1];
	const isBunVirtualScript = currentScript?.startsWith("/$bunfs/root/");
	if (currentScript && !isBunVirtualScript && fs.existsSync(currentScript)) {
		return { command: process.execPath, args: [currentScript, ...args] };
	}
	const execName = path.basename(process.execPath).toLowerCase();
	if (!/^(node|bun)(\.exe)?$/.test(execName)) {
		return { command: process.execPath, args };
	}
	return { command: "pi", args };
}

export async function spawnAgent(
	roleName: string,
	task: string,
	cwd: string,
	modelContext: SpawnAgentModelContext,
): Promise<SpawnResult> {
	const role = loadRole(roleName, modelContext);
	const args: string[] = ["--mode", "json", "-p", "--no-session"];
	if (role.model) args.push("--model", role.model);
	if (role.tools) args.push("--tools", role.tools.join(","));
	if (role.thinking) args.push("--thinking", role.thinking);

	const tmpDir = await fs.promises.mkdtemp(path.join(os.tmpdir(), "pi-pipeline-"));
	const promptPath = path.join(tmpDir, "prompt.md");
	let output = "";
	let stderr = "";
	try {
		if (role.systemPrompt) {
			await fs.promises.writeFile(promptPath, role.systemPrompt, { encoding: "utf-8", mode: 0o600 });
			args.push("--append-system-prompt", promptPath);
		}
		args.push(`Task: ${task}`);

		const exitCode = await new Promise<number>((resolve) => {
			const invocation = getPiInvocation(args);
			const proc = spawn(invocation.command, invocation.args, {
				cwd,
				shell: false,
				stdio: ["ignore", "pipe", "pipe"],
			});
			let buffer = "";
			const processLine = (line: string) => {
				if (!line.trim()) return;
				let event: any;
				try {
					event = JSON.parse(line);
				} catch {
					return;
				}
				if (event.type === "message_end" && event.message?.role === "assistant") {
					for (const part of event.message.content ?? []) {
						if (part.type === "text") output = part.text;
					}
				}
			};
			proc.stdout.on("data", (data) => {
				buffer += data.toString();
				const lines = buffer.split("\n");
				buffer = lines.pop() || "";
				for (const line of lines) processLine(line);
			});
			proc.stderr.on("data", (data) => {
				stderr += data.toString();
			});
			proc.on("close", (code) => {
				if (buffer.trim()) processLine(buffer);
				resolve(code ?? 0);
			});
			proc.on("error", () => resolve(1));
		});

		return { exitCode, output, stderr };
	} finally {
		await fs.promises.rm(tmpDir, { recursive: true, force: true }).catch(() => {});
	}
}
