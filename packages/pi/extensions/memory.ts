// @ts-nocheck
/**
 * Hermes-style layered memory: a bounded, always-injected MEMORY.md at both
 * global and project scope, plus a rule nudging the model to write a SKILL.md
 * after solving anything non-obvious. Pi's own session JSONL + session
 * search/tree already serve as the episodic layer, so nothing to build there.
 */
import * as fs from "node:fs";
import * as path from "node:path";
import { CONFIG_DIR_NAME, type ExtensionAPI, getAgentDir } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const MAX_CHARS = 4000;

function findProjectRoot(cwd: string): string {
	let dir = cwd;
	while (true) {
		if (fs.existsSync(path.join(dir, ".jj")) || fs.existsSync(path.join(dir, ".git"))) return dir;
		const parent = path.dirname(dir);
		if (parent === dir) return cwd;
		dir = parent;
	}
}

function globalMemoryDir(): string {
	return path.join(getAgentDir(), "memory");
}

function projectMemoryDir(cwd: string): string {
	return path.join(findProjectRoot(cwd), CONFIG_DIR_NAME, "memory");
}

function globalSkillsDir(): string {
	return path.join(getAgentDir(), "skills");
}

function projectSkillsDir(cwd: string): string {
	return path.join(findProjectRoot(cwd), CONFIG_DIR_NAME, "skills");
}

function readBounded(filePath: string): string | undefined {
	let content: string;
	try {
		content = fs.readFileSync(filePath, "utf-8");
	} catch {
		return undefined;
	}
	if (content.length <= MAX_CHARS) return content;
	return `[earlier memory truncated]\n${content.slice(-MAX_CHARS)}`;
}

const RememberParams = Type.Object({
	scope: Type.Union([Type.Literal("global"), Type.Literal("project")], {
		description: "global: ~/.pi/agent/memory/MEMORY.md (cross-project). project: <repo>/.pi/memory/MEMORY.md",
	}),
	content: Type.String({ description: "The fact/preference/convention to remember, in a few plain sentences." }),
	mode: Type.Optional(
		Type.Union([Type.Literal("append"), Type.Literal("replace")], {
			description: "append (default): add a new bullet. replace: rewrite the whole file (use to curate/trim).",
			default: "append",
		}),
	),
});

const WriteSkillParams = Type.Object({
	scope: Type.Union([Type.Literal("global"), Type.Literal("project")]),
	name: Type.String({ description: "lowercase-hyphenated skill name, e.g. 'debug-flaky-tests'" }),
	description: Type.String({ description: "One line: what this skill is for and when to use it." }),
	body: Type.String({ description: "The skill's procedure: approach, commands, gotchas that worked." }),
});

export default function memoryExtension(pi: ExtensionAPI) {
	pi.on("before_agent_start", async (event, ctx) => {
		const globalMd = readBounded(path.join(globalMemoryDir(), "MEMORY.md"));
		const projectMd = readBounded(path.join(projectMemoryDir(ctx.cwd), "MEMORY.md"));
		if (!globalMd && !projectMd) return undefined;

		let addition = "\n\n# Memory\n";
		if (globalMd) addition += `\n## Global memory\n${globalMd}\n`;
		if (projectMd) addition += `\n## Project memory\n${projectMd}\n`;
		addition += `
When you learn a durable fact, preference, or convention, call \`remember\`.
After solving anything non-obvious, call \`write_skill\` so future sessions reuse the approach.
`;

		return { systemPrompt: event.systemPrompt + addition };
	});

	pi.registerTool({
		name: "remember",
		label: "Remember",
		description: "Persist a durable fact/preference/convention to MEMORY.md (global or project scope).",
		parameters: RememberParams,
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			const dir = params.scope === "global" ? globalMemoryDir() : projectMemoryDir(ctx.cwd);
			const filePath = path.join(dir, "MEMORY.md");
			fs.mkdirSync(dir, { recursive: true });
			if (params.mode === "replace") {
				fs.writeFileSync(filePath, params.content.trim() + "\n", "utf-8");
			} else {
				const bullet = `- ${params.content.trim()}\n`;
				fs.appendFileSync(filePath, bullet, "utf-8");
			}
			return { content: [{ type: "text", text: `Saved to ${filePath}` }] };
		},
	});

	pi.registerTool({
		name: "write_skill",
		label: "Write skill",
		description: "Write a procedural SKILL.md capturing how a non-obvious task was solved.",
		parameters: WriteSkillParams,
		async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
			if (!/^[a-z0-9][a-z0-9-]{0,62}$/.test(params.name)) {
				return {
					content: [{ type: "text", text: `Invalid skill name "${params.name}": use lowercase letters, digits, hyphens.` }],
					isError: true,
				};
			}
			const dir = params.scope === "global" ? globalSkillsDir() : projectSkillsDir(ctx.cwd);
			const skillDir = path.join(dir, params.name);
			fs.mkdirSync(skillDir, { recursive: true });
			const content = `---\nname: ${params.name}\ndescription: ${params.description}\n---\n\n${params.body.trim()}\n`;
			fs.writeFileSync(path.join(skillDir, "SKILL.md"), content, "utf-8");
			return { content: [{ type: "text", text: `Wrote ${path.join(skillDir, "SKILL.md")}` }] };
		},
	});
}
