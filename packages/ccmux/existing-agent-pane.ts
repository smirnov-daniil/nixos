import { readFile } from "node:fs/promises";
import { join } from "node:path";
import { JOBS_DIR } from "../../lib/config";
import { PANE_FIELD_SEP } from "../../lib/tmux-format";
import { tmuxArgv } from "../../lib/tmux-exec";
import { projectRoot } from "./agent-project-session";

/** Claude's fleet frontend has a different PID/session ID from its worker.
 * Its live pane title is the job's name. Require a unique Claude pane with
 * that exact title in the same project; never identify an agent by cwd alone.
 * If the title/schema is unavailable, ordinary navigation must not spawn a
 * duplicate: the caller falls back to an existing named attach window only.
 */
export function selectAttachedAgentPane(
  output: string, cwd: string, name: string,
): string | null {
  if (!name.trim()) return null;
  const root = projectRoot(cwd);
  const matches = new Set<string>();
  for (const row of output.split("\n")) {
    const [pane, title, command, ...path] = row.split(PANE_FIELD_SEP);
    const directory = path.join(PANE_FIELD_SEP);
    if (pane && /^%\d+$/.test(pane) && title === name && command === "claude"
      && directory.startsWith("/") && projectRoot(directory) === root) {
      matches.add(pane);
    }
  }
  return matches.size === 1 ? [...matches][0]! : null;
}

export async function findAttachedAgentPane(shortId: string, cwd: string): Promise<string | null> {
  try {
    const state = JSON.parse(await readFile(join(JOBS_DIR, shortId, "state.json"), "utf8"));
    if (typeof state?.name !== "string" || !state.name.trim()) return null;
    const proc = Bun.spawn(tmuxArgv("list-panes", "-a", "-F",
      ["#{pane_id}", "#{pane_title}", "#{pane_current_command}", "#{pane_current_path}"].join(PANE_FIELD_SEP)),
    { stdout: "pipe", stderr: "ignore" });
    const output = await new Response(proc.stdout).text();
    if (await proc.exited !== 0) return null;
    return selectAttachedAgentPane(output, cwd, state.name);
  } catch {
    return null;
  }
}
