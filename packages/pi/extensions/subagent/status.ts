export type AgentRunStatus = "pending" | "running" | "done" | "failed" | "skipped";

export interface AgentStatusResult {
	status?: AgentRunStatus;
	exitCode: number;
	stopReason?: string;
}

export function getResultStatus(result: AgentStatusResult): AgentRunStatus {
	if (result.status) return result.status;
	if (result.exitCode === -1) return "running";
	if (result.exitCode !== 0 || result.stopReason === "error" || result.stopReason === "aborted") return "failed";
	return "done";
}

export function summarizeResultStatuses(results: AgentStatusResult[]): string {
	const order: AgentRunStatus[] = ["done", "failed", "running", "pending", "skipped"];
	return order
		.map((status) => [status, results.filter((result) => getResultStatus(result) === status).length] as const)
		.filter(([, count]) => count > 0)
		.map(([status, count]) => `${count} ${status}`)
		.join(", ");
}
