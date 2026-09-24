import { existsSync, realpathSync } from "node:fs";
import { dirname, isAbsolute, join, resolve } from "node:path";
import { PANE_FIELD_SEP } from "../../lib/tmux-format";
import { tmuxArgv } from "../../lib/tmux-exec";

function canonical(path: string): string {
  try {
    return realpathSync(path);
  } catch {
    return resolve(path);
  }
}

// Match mux's project-root rules: an umbrella owns its nested repositories.
export function projectRoot(cwd: string): string {
  const parents: string[] = [];
  let path = canonical(cwd);
  for (;;) {
    parents.push(path);
    const parent = dirname(path);
    if (parent === path) break;
    path = parent;
  }
  return parents.find((path) => existsSync(join(path, ".ff/repo.yml")))
    ?? parents.find((path) => existsSync(join(path, ".jj")) || existsSync(join(path, ".git")))
    ?? parents[0]!;
}

export function selectProjectSession(output: string, cwd: string): string | null {
  const root = projectRoot(cwd);
  const matches = new Set<string>();
  for (const row of output.split("\n")) {
    const separator = row.indexOf(PANE_FIELD_SEP);
    if (separator < 0) continue;
    const id = row.slice(0, separator);
    const path = row.slice(separator + PANE_FIELD_SEP.length);
    if (/^\$\d+$/.test(id) && isAbsolute(path) && canonical(path) === root) {
      matches.add(id);
    }
  }
  // Do not guess between two task spaces for the same project.
  return matches.size === 1 ? [...matches][0]! : null;
}

export async function findAgentProjectSession(cwd: string): Promise<string | null> {
  try {
    const proc = Bun.spawn(tmuxArgv("list-sessions", "-F",
      ["#{session_id}", "#{session_path}"].join(PANE_FIELD_SEP)),
    { stdout: "pipe", stderr: "ignore" });
    const output = await new Response(proc.stdout).text();
    if (await proc.exited !== 0) return null;
    return selectProjectSession(output, cwd);
  } catch {
    return null;
  }
}
