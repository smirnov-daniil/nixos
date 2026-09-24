import { describe, expect, test } from "bun:test";
import { selectAttachedAgentPane } from "./existing-agent-pane";
import { PANE_FIELD_SEP } from "../../lib/tmux-format";

const row = (...fields: string[]) => fields.join(PANE_FIELD_SEP);

describe("existing Claude fleet frontend", () => {
  const cwd = "/nonexistent/baloo";
  test("finds the original frontend even though the background worker has no pane", () => {
    const panes = [
      row("%15", "native-compile", "claude", cwd),
      row("%17", "host", "claude", cwd),
      row("%20", "another-task", "claude", cwd),
      row("%13", "native-compile", "claude", "/nonexistent/flake"),
    ].join("\n");
    expect(selectAttachedAgentPane(panes, cwd, "native-compile")).toBe("%15");
  });
  test("does not confuse another agent, a shell, or ambiguous duplicate titles", () => {
    expect(selectAttachedAgentPane(row("%15", "other-task", "claude", cwd), cwd, "native-compile")).toBeNull();
    expect(selectAttachedAgentPane(row("%15", "native-compile", "zsh", cwd), cwd, "native-compile")).toBeNull();
    expect(selectAttachedAgentPane(row("%15", "", "claude", cwd), cwd, "")).toBeNull();
    expect(selectAttachedAgentPane([
      row("%15", "native-compile", "claude", cwd),
      row("%16", "native-compile", "claude", cwd),
    ].join("\n"), cwd, "native-compile")).toBeNull();
  });
});

import { openAgentAttachWindow } from "./tmux";
import { setPinnedTmuxClientTty } from "../../lib/tmux-client";

async function withTmux(responses: string[], action: (calls: string[][]) => Promise<void>) {
  const spawn = Bun.spawn;
  const which = Bun.which;
  const tmux = process.env.TMUX;
  const calls: string[][] = [];
  process.env.TMUX = "/tmp/isolated-ccmux-test,1,0";
  setPinnedTmuxClientTty("/dev/pts/5");
  Bun.which = (() => "/bin/claude") as typeof Bun.which;
  Bun.spawn = ((args: string[]) => {
    calls.push([...args]);
    return {
      stdout: new Blob([responses.shift() ?? ""]).stream(),
      stderr: new Blob([]).stream(),
      exited: Promise.resolve(0),
    };
  }) as unknown as typeof Bun.spawn;
  try {
    await action(calls);
  } finally {
    Bun.spawn = spawn;
    Bun.which = which;
    setPinnedTmuxClientTty(undefined);
    if (tmux === undefined) delete process.env.TMUX;
    else process.env.TMUX = tmux;
  }
}

const unknownAgent = "ccmux-test-no-native-job";
describe("background navigation versus explicit attachment", () => {
  test("Enter never creates a window when no existing interface can be identified", async () => {
    await withTmux([""], async (calls) => {
      const result = await openAgentAttachWindow(unknownAgent, "/nonexistent/baloo");
      expect(result.ok).toBe(false);
      if (!result.ok) expect(result.error).toContain("Attach agent");
      expect(calls.map((args) => args[1])).toEqual(["list-windows"]);
    });
  });
  test("reuses a named attachment and switches only the captured client", async () => {
    await withTmux([row("@17", `ccmux-agent-${unknownAgent}`), ""], async (calls) => {
      expect(await openAgentAttachWindow(unknownAgent, "/nonexistent/baloo"))
        .toEqual({ ok: true, clientSwitched: true });
      expect(calls[1]).toEqual(["tmux", "switch-client", "-c", "/dev/pts/5", "-t", "@17"]);
      expect(calls.some((args) => args.includes("new-window"))).toBe(false);
    });
  });
  test("explicit attachment creates its view in the agent's project, not the caller's", async () => {
    await withTmux([
      "", row("/dev/pts/5", "$3"),
      [row("$1", "/nonexistent/baloo"), row("$3", "/nonexistent/flake")].join("\n"),
      "%17\n", "",
    ], async (calls) => {
      expect(await openAgentAttachWindow(unknownAgent, "/nonexistent/baloo", true))
        .toEqual({ ok: true, clientSwitched: true });
      const create = calls.find((args) => args.includes("new-window"))!;
      expect(create[create.indexOf("-t") + 1]).toBe("$1");
      expect(create).toContain("-d");
      expect(calls.at(-1)).toEqual(["tmux", "switch-client", "-c", "/dev/pts/5", "-t", "%17"]);
    });
  });
});
