import type { CliRenderer } from "@opentui/core";
import { mkdtemp, readFile, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";

export const TUICR_INSTALL_HINT = "reviewctl not found: install the flake terminal environment";

export interface TuicrReviewNote {
  ticket: string;
  id: string;
  location: string;
  content: string;
  author: string;
}

export function isTuicrAvailable(which = (name: string) => Bun.which(name, { PATH: process.env.PATH })): boolean {
  return which("reviewctl") !== null;
}

export function reviewCommand(cwd: string, options: { target?: string; agent?: string } = {}): string[] {
  return ["reviewctl", "open", "--repo", cwd, "--pick-repo",
    "--mode", options.target ? "branch" : "working",
    ...(options.agent ? ["--agent", options.agent] : [])];
}

export async function runTuicrReview(
  renderer: Pick<CliRenderer, "suspend" | "resume">,
  cwd: string,
  options: { target?: string; agent?: string } = {},
): Promise<{ ok: true; notes: TuicrReviewNote[] } | { ok: false; error: string; empty?: true }> {
  if (!isTuicrAvailable()) return { ok: false, error: TUICR_INSTALL_HINT };
  const directory = await mkdtemp(join(tmpdir(), "ccmux-tuicr-"));
  let suspended = false;
  try {
    const resultFile = join(directory, "result.json");
    renderer.suspend();
    suspended = true;
    const proc = Bun.spawn([...reviewCommand(cwd, options), "--result", resultFile], {
      cwd, env: process.env, stdin: "inherit", stdout: "inherit", stderr: "inherit",
    });
    const code = await proc.exited;
    if (code !== 0) return { ok: false, error: `tuicr review exited ${code}; comments are saved (reviewctl list)` };
    const result = JSON.parse(await readFile(resultFile, "utf8"));
    if (!Array.isArray(result.notes) || result.notes.some((note: TuicrReviewNote) =>
      typeof note.id !== "string" || typeof note.ticket !== "string" || typeof note.content !== "string")) {
      throw new Error("Invalid reviewctl result");
    }
    return { ok: true, notes: result.notes };
  } catch (error) {
    return { ok: false, error: error instanceof Error ? error.message : String(error) };
  } finally {
    if (suspended) renderer.resume();
    await rm(directory, { recursive: true, force: true });
  }
}

export function handbackCommand(sessionId: string, notes: TuicrReviewNote[], enter: boolean): string[] {
  const tickets = new Set(notes.map(note => note.ticket));
  if (tickets.size !== 1) throw new Error("Expected comments from one review");
  return ["reviewctl", "send", notes[0]!.ticket, "--agent", sessionId,
    ...notes.flatMap(note => ["--comment", note.id]), ...(enter ? [] : ["--no-enter"])];
}

export async function deliverTuicrNotes(sessionId: string, notes: TuicrReviewNote[], enter: boolean): Promise<void> {
  const proc = Bun.spawn(handbackCommand(sessionId, notes, enter), {
    stdin: "ignore", stdout: "ignore", stderr: "pipe",
  });
  const error = await new Response(proc.stderr).text();
  if (await proc.exited !== 0) throw new Error(error.trim() || "Review handoff failed");
}
