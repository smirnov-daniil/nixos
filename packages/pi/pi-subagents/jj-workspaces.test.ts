import { afterEach, beforeEach, describe, expect, test } from "vitest";
import { chmodSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { execFileSync } from "node:child_process";
import { cleanupWorktree, createWorktree } from "../src/worktree.js";

function jj(cwd: string, args: string[]): string {
  return execFileSync("jj", ["--no-pager", ...args], { cwd, stdio: "pipe" }).toString().trim();
}

describe("Jujutsu workspace isolation", () => {
  let root: string;
  let repo: string;
  let originalPath: string | undefined;

  beforeEach(() => {
    root = mkdtempSync(join(tmpdir(), "pi-jj-workspace-"));
    repo = join(root, "repo");
    mkdirSync(join(repo, "packages", "api"), { recursive: true });
    jj(repo, ["git", "init", "--colocate"]);
    writeFileSync(join(repo, "packages", "api", "index.ts"), "base\n");
    jj(repo, ["describe", "-m", "Base"]);
    jj(repo, ["st"]);
    originalPath = process.env.PATH;
  });

  afterEach(() => {
    process.env.PATH = originalPath;
    rmSync(root, { recursive: true, force: true });
  });

  test("preserves changes as a Jujutsu change without invoking Git", () => {
    const bin = join(root, "bin");
    const marker = join(root, "git-invoked");
    mkdirSync(bin);
    const git = join(bin, "git");
    writeFileSync(git, `#!/bin/sh\ntouch '${marker}'\nexit 1\n`);
    chmodSync(git, 0o755);
    process.env.PATH = `${bin}:${originalPath ?? ""}`;

    const workspace = createWorktree(join(repo, "packages", "api"), "job")!;
    expect(workspace.kind).toBe("jujutsu");
    expect(workspace.workPath).toBe(join(workspace.path, "packages", "api"));
    writeFileSync(join(workspace.workPath, "index.ts"), "base\nagent\n");
    const result = cleanupWorktree(repo, workspace, "agent change");

    expect(result.kind).toBe("jujutsu");
    expect(result.hasChanges).toBe(true);
    expect(result.changeId).toBeTruthy();
    expect(result.baseSha).toBe(workspace.baseSha);
    expect(existsSync(workspace.path)).toBe(false);
    expect(jj(repo, ["workspace", "list"])).not.toContain(workspace.workspaceName);
    expect(jj(repo, ["diff", "-r", result.changeId!, "--git"])).toContain("+agent");
    expect(existsSync(marker)).toBe(false);

    jj(repo, ["squash", "--from", `${result.baseSha}..${result.changeId}`, "--into", "@", "-m", "Integrate agent"]);
    jj(repo, ["abandon", result.baseSha!]);
    expect(readFileSync(join(repo, "packages", "api", "index.ts"), "utf8")).toBe("base\nagent\n");
  });

  test("abandons an empty workspace commit", () => {
    const workspace = createWorktree(repo, "empty")!;
    const changeId = workspace.branch;
    const result = cleanupWorktree(repo, workspace, "empty");
    expect(result).toMatchObject({ hasChanges: false, kind: "jujutsu" });
    expect(existsSync(workspace.path)).toBe(false);
    expect(() => jj(repo, ["log", "-r", changeId, "--no-graph"])).toThrow();
    expect(() => jj(repo, ["log", "-r", workspace.snapshotChangeId!, "--no-graph"])).toThrow();
  });

  test("stays fresh when the main working-copy commit changes concurrently", () => {
    const workspace = createWorktree(repo, "concurrent")!;
    writeFileSync(join(workspace.path, "agent.txt"), "agent\n");
    writeFileSync(join(repo, "main.txt"), "main\n");
    jj(repo, ["st"]);
    const result = cleanupWorktree(repo, workspace, "concurrent");
    expect(result.hasChanges).toBe(true);
    expect(jj(repo, ["diff", "-r", result.changeId!, "--git"])).toContain("agent.txt");
    expect(jj(repo, ["log", "-r", result.changeId!, "--no-graph", "-T", "divergent"])).toBe("false");
  });

  test("returns every non-empty change in an isolated stack", () => {
    const workspace = createWorktree(repo, "stack")!;
    writeFileSync(join(workspace.path, "first.txt"), "first\n");
    jj(workspace.path, ["st"]);
    jj(workspace.path, ["new", "-m", "Second"]);
    writeFileSync(join(workspace.path, "second.txt"), "second\n");
    const result = cleanupWorktree(repo, workspace, "stack");
    expect(result.changeIds).toHaveLength(2);
    expect(result.changeId).toBe(result.changeIds?.[0]);
    expect(jj(repo, ["log", "-r", `${result.baseSha}..${result.changeId}`, "--no-graph", "-T", "change_id.short() ++ \"\\n\""])).toContain(result.changeIds?.[1]);
  });
});
