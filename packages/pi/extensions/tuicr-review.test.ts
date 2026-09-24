import { afterEach, expect, mock, test } from "bun:test";
import extension from "./tuicr-review";

const original = process.env.TMUX_PANE;
afterEach(() => {
  if (original === undefined) delete process.env.TMUX_PANE;
  else process.env.TMUX_PANE = original;
});

function setup(response: { code: number; stdout: string; stderr: string }) {
  let handler: any;
  const exec = mock(async () => response);
  extension({ registerCommand: (_name: string, options: any) => { handler = options.handler; }, exec } as any);
  const ui = { notify: mock((..._args: any[]) => {}), setStatus: mock((..._args: any[]) => {}), pasteToEditor: mock((..._args: any[]) => {}) };
  return { exec, ui, invoke: (args = "") => handler(args, { mode: "tui", cwd: "/repo with spaces", ui, sessionManager: { getSessionId: () => "own-session" } }) };
}

test("opens beside Pi and fills the editor with this review's comments", async () => {
  process.env.TMUX_PANE = "%5";
  const test = setup({ code: 0, stderr: "", stdout: JSON.stringify({ ticket: "exact-review", notes: [{ id: "c1", key: "key-1", location: "a.cpp:2", content: "Fix it" }] }) });
  await test.invoke("trunk()..@");
  expect(test.exec).toHaveBeenCalledWith("reviewctl", ["open", "--repo", "/repo with spaces", "--pane", "--wait", "--agent", "pi:own-session", "--revset", "trunk()..@"]);
  expect(test.exec).toHaveBeenCalledWith("reviewctl", ["ack", "exact-review", "--agent", "pi:own-session", "--key", "key-1"]);
  expect(test.ui.pasteToEditor).toHaveBeenCalledTimes(1);
  expect(test.ui.pasteToEditor.mock.calls[0]?.[0]).toContain("exact-review");
  expect(test.ui.setStatus.mock.calls.at(-1)).toEqual(["tuicr-review", undefined]);
});

test("failed or stale review cannot paste feedback", async () => {
  process.env.TMUX_PANE = "%5";
  const test = setup({ code: 1, stderr: "Review is stale", stdout: "" });
  await test.invoke();
  expect(test.ui.pasteToEditor).not.toHaveBeenCalled();
  expect(test.ui.notify.mock.calls[0]?.[0]).toContain("stale");
});

test("requires tmux without executing shell login probes", async () => {
  delete process.env.TMUX_PANE;
  const test = setup({ code: 0, stdout: "", stderr: "" });
  await test.invoke();
  expect(test.exec).not.toHaveBeenCalled();
});
