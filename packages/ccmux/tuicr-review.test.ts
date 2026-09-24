import { describe, expect, test } from "bun:test";
import { chmodSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { handbackCommand, isTuicrAvailable, reviewCommand, runTuicrReview } from "./tuicr-review";

describe("tuicr adapter", () => {
  test("passes repo paths as one argument and binds the selected agent", () => {
    expect(reviewCommand("/a repo/$x", { agent: "agent/123" })).toEqual([
      "reviewctl", "open", "--repo", "/a repo/$x", "--pick-repo", "--mode", "working", "--agent", "agent/123",
    ]);
    expect(reviewCommand("/repo", { target: "branch" })).toContain("branch");
  });
  test("handback names the exact review and comments, including fill mode", () => {
    expect(handbackCommand("agent-1", [{ ticket: "review-1", id: "comment-1", content: "fix", location: "a:1", author: "user" }], false)).toEqual([
      "reviewctl", "send", "review-1", "--agent", "agent-1", "--comment", "comment-1", "--no-enter",
    ]);
    expect(() => handbackCommand("agent-1", [], true)).toThrow("one review");
  });
  test("availability tests the actual adapter", () => {
    expect(isTuicrAvailable((name) => name === "reviewctl" ? "/bin/reviewctl" : null)).toBe(true);
  });
  test("restores the renderer and reads only the child's result file", async () => {
    const directory = mkdtempSync(join(tmpdir(), "tuicr-adapter-test-"));
    const original = process.env.PATH;
    try {
      const executable = join(directory, "reviewctl");
      writeFileSync(executable, `#!${process.execPath}\nconst out=process.argv[process.argv.indexOf('--result')+1];\nawait Bun.write(out, JSON.stringify({notes:[{ticket:'review-1',id:'own-comment',content:'finding'}]}));\n`);
      chmodSync(executable, 0o755);
      process.env.PATH = `${directory}:${original}`;
      const calls: string[] = [];
      const renderer = { suspend: () => { calls.push("suspend"); }, resume: () => { calls.push("resume"); } };
      const result = await runTuicrReview(renderer, directory, { agent: "chosen-agent" });
      expect(result).toMatchObject({ ok: true, notes: [{ id: "own-comment" }] });
      expect(calls).toEqual(["suspend", "resume"]);
      writeFileSync(executable, `#!${process.execPath}\nprocess.exit(1);\n`);
      calls.length = 0;
      expect(await runTuicrReview(renderer, directory)).toMatchObject({ ok: false });
      expect(calls).toEqual(["suspend", "resume"]);
    } finally {
      process.env.PATH = original;
      rmSync(directory, { recursive: true, force: true });
    }
  });
});
