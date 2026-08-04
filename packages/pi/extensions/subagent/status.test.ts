import { describe, expect, test } from "bun:test";
import { getResultStatus, summarizeResultStatuses } from "./status.ts";

describe("getResultStatus", () => {
	test("preserves explicit lifecycle states", () => {
		expect(getResultStatus({ status: "pending", exitCode: -1 })).toBe("pending");
		expect(getResultStatus({ status: "running", exitCode: -1 })).toBe("running");
		expect(getResultStatus({ status: "done", exitCode: 0 })).toBe("done");
		expect(getResultStatus({ status: "failed", exitCode: 1 })).toBe("failed");
		expect(getResultStatus({ status: "skipped", exitCode: -1 })).toBe("skipped");
	});

	test("infers states from historical results", () => {
		expect(getResultStatus({ exitCode: -1 })).toBe("running");
		expect(getResultStatus({ exitCode: 0 })).toBe("done");
		expect(getResultStatus({ exitCode: 1 })).toBe("failed");
		expect(getResultStatus({ exitCode: 0, stopReason: "error" })).toBe("failed");
		expect(getResultStatus({ exitCode: 0, stopReason: "aborted" })).toBe("failed");
	});
});

describe("summarizeResultStatuses", () => {
	test("reports every non-empty state explicitly", () => {
		expect(
			summarizeResultStatuses([
				{ status: "done", exitCode: 0 },
				{ status: "failed", exitCode: 1 },
				{ status: "running", exitCode: -1 },
				{ status: "pending", exitCode: -1 },
				{ status: "skipped", exitCode: -1 },
			]),
		).toBe("1 done, 1 failed, 1 running, 1 pending, 1 skipped");
	});
});
