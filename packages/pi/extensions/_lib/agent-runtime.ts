import type { Api, Model } from "@earendil-works/pi-ai";

export const AGENT_COMPLEXITIES = ["low", "medium", "high", "max"] as const;
export const AGENT_THINKING_LEVELS = ["off", "minimal", "low", "medium", "high", "xhigh", "max"] as const;

export type AgentComplexity = (typeof AGENT_COMPLEXITIES)[number];
export type AgentThinkingLevel = (typeof AGENT_THINKING_LEVELS)[number];

export interface AgentModelContext {
	models: Model<Api>[];
	currentModel?: Model<Api>;
}

export interface AgentRuntime {
	model?: string;
	thinking?: AgentThinkingLevel;
	complexity?: AgentComplexity;
}

const EFFICIENT_MODEL = /(?:^|[\W_])(nano|mini|micro|haiku|flash(?:-lite)?|luna|spark|small|fast)(?:$|[\W_])/i;
const CAPABLE_MODEL = /(?:^|[\W_])(opus|pro|sol|ultra|large|max)(?:$|[\W_])/i;
const TIER_NAME = /(?:^|[\W_])(nano|mini|micro|haiku|flash(?:-lite)?|luna|spark|small|fast|sonnet|terra|standard|opus|pro|sol|ultra|large|max)(?:$|[\W_])/gi;

function isAgentComplexity(value: string | undefined): value is AgentComplexity {
	return AGENT_COMPLEXITIES.some((complexity) => complexity === value);
}

function isThinkingLevel(value: string | undefined): value is AgentThinkingLevel {
	return AGENT_THINKING_LEVELS.some((level) => level === value);
}

function modelTier(model: Model<Api>): number {
	const name = `${model.id} ${model.name}`;
	if (EFFICIENT_MODEL.test(name)) return 0;
	if (CAPABLE_MODEL.test(name)) return 2;
	return 1;
}

function modelProduct(model: Model<Api>): string {
	return model.id
		.toLowerCase()
		.replace(TIER_NAME, "-")
		.replace(/\d.*$/, "")
		.replace(/[^a-z/]+/g, "-")
		.replace(/^-+|-+$/g, "");
}

function modelVersion(model: Model<Api>): number[] {
	return [...model.id.matchAll(/\d+/g)].map((match) => Number(match[0]));
}

function compareVersion(a: Model<Api>, b: Model<Api>): number {
	const left = modelVersion(a);
	const right = modelVersion(b);
	for (let index = 0; index < Math.max(left.length, right.length); index++) {
		const difference = (right[index] ?? 0) - (left[index] ?? 0);
		if (difference !== 0) return difference;
	}
	return 0;
}

function modelCost(model: Model<Api>): number {
	return model.cost.input + model.cost.output;
}

function compareCandidates(a: Model<Api>, b: Model<Api>, complexity: AgentComplexity): number {
	const version = compareVersion(a, b);
	if (version !== 0) return version;
	if (complexity === "low") {
		const cost = modelCost(a) - modelCost(b);
		if (cost !== 0) return cost;
	} else {
		if (a.reasoning !== b.reasoning) return a.reasoning ? -1 : 1;
		const cost = modelCost(b) - modelCost(a);
		if (cost !== 0) return cost;
	}
	const context = b.contextWindow - a.contextWindow;
	if (context !== 0) return context;
	return a.id.localeCompare(b.id);
}

export function selectModelForComplexity(
	models: Model<Api>[],
	currentModel: Model<Api> | undefined,
	complexity: AgentComplexity,
): Model<Api> | undefined {
	if (!currentModel) return undefined;
	const product = modelProduct(currentModel);
	if (!product) return currentModel;
	const candidates = models.filter(
		(model) => model.provider === currentModel.provider && modelProduct(model) === product,
	);
	if (!candidates.some((model) => model.id === currentModel.id)) candidates.push(currentModel);
	const tiers = new Set(candidates.map(modelTier));
	if (tiers.size < 2) return currentModel;
	if (complexity === "medium") {
		const balanced = candidates.filter((model) => modelTier(model) === 1);
		if (balanced.length === 0) return currentModel;
		return balanced.sort((a, b) => compareCandidates(a, b, complexity))[0];
	}
	const targetTier = complexity === "low" ? Math.min(...tiers) : Math.max(...tiers);
	return candidates
		.filter((model) => modelTier(model) === targetTier)
		.sort((a, b) => compareCandidates(a, b, complexity))[0];
}

export function resolveAgentRuntime(
	fields: { model?: string; complexity?: string; effort?: string },
	context: AgentModelContext,
): AgentRuntime {
	const complexity = isAgentComplexity(fields.complexity) ? fields.complexity : undefined;
	const selected = fields.model
		? undefined
		: complexity
			? selectModelForComplexity(context.models, context.currentModel, complexity)
			: context.currentModel;
	return {
		model: fields.model ?? (selected ? `${selected.provider}/${selected.id}` : undefined),
		thinking: isThinkingLevel(fields.effort) ? fields.effort : complexity,
		complexity,
	};
}
