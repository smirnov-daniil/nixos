import { describe, expect, test } from "bun:test";
import { mkdirSync, mkdtempSync, rmSync, symlinkSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { selectProjectSession } from "./agent-project-session";
import { PANE_FIELD_SEP } from "../../lib/tmux-format";

const row = (id: string, path: string) => [id, path].join(PANE_FIELD_SEP);

describe("background-agent project placement", () => {
  test("a nested submodule belongs to its umbrella's space, not the caller's", () => {
    const directory = mkdtempSync(join(tmpdir(), "agent-project-"));
    try {
      const root = join(directory, "baloo with spaces");
      const nested = join(root, "modules", "app");
      mkdirSync(join(root, ".ff"), { recursive: true });
      writeFileSync(join(root, ".ff/repo.yml"), "nodes: {}\n");
      mkdirSync(nested, { recursive: true });
      // Submodule/worktree .git is a file, not necessarily a directory.
      writeFileSync(join(nested, ".git"), "gitdir: ../../.git/modules/app\n");
      const output = [row("$1", root), row("$3", join(directory, "flake")), row("$4", nested)].join("\n");
      expect(selectProjectSession(output, nested)).toBe("$1");
      expect(selectProjectSession(output, root)).toBe("$1");
      const alias = join(directory, "alias");
      symlinkSync(root, alias);
      expect(selectProjectSession(row("$1", alias), nested)).toBe("$1");
    } finally {
      rmSync(directory, { recursive: true, force: true });
    }
  });

  test("recognizes ordinary jj projects and refuses absent or ambiguous spaces", () => {
    const directory = mkdtempSync(join(tmpdir(), "agent-project-"));
    try {
      const root = join(directory, "project");
      const cwd = join(root, "src");
      mkdirSync(join(root, ".jj"), { recursive: true });
      mkdirSync(cwd);
      expect(selectProjectSession(row("$2", root), cwd)).toBe("$2");
      expect(selectProjectSession(row("$3", root + "-other"), cwd)).toBeNull();
      expect(selectProjectSession([row("$2", root), row("$3", root)].join("\n"), cwd)).toBeNull();
      expect(selectProjectSession(row("invalid", root), cwd)).toBeNull();
      expect(selectProjectSession("", cwd)).toBeNull();
    } finally {
      rmSync(directory, { recursive: true, force: true });
    }
  });
});
