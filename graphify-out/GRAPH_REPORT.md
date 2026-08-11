# Graph Report - .  (2026-08-13)

## Corpus Check
- 62 files · ~29,774 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 257 nodes · 340 edges · 23 communities (21 shown, 2 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 10 edges (avg confidence: 0.73)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Graphify Pipeline
- Agent Discovery
- Agent Execution
- Repository Configuration
- Review and Jujutsu
- Plan Mode
- Pi Roles and Prompts
- Tuicr Review
- Graph Querying
- Pi Memory
- SkillOpt Safety Tests
- Runtime Verification
- Notifications
- SkillOpt Workflow
- NixOS Deployment
- Conversation Handoff
- Status Babysitting
- OpenSpec Workflow
- Herdr Integration
- Graph Watch Mode
- Graph Extraction Role
- Learned Guidance

## God Nodes (most connected - your core abstractions)
1. `registerToggleMode()` - 12 edges
2. `resolveAgentRuntime()` - 10 edges
3. `pipelineExtension()` - 8 edges
4. `invoke()` - 7 edges
5. `Graphify full pipeline` - 7 edges
6. `Graphify extraction subagent prompt` - 7 edges
7. `selectModelForComplexity()` - 6 edges
8. `Graphify outputs` - 6 edges
9. `Graph query traversal` - 6 edges
10. `Security review` - 6 edges

## Surprising Connections (you probably didn't know these)
- `Project memory` ----> `Pi package integration`  [EXTRACTED]
  .pi/memory/MEMORY.md → packages/pi/README.md
- `Pi package integration` ----> `Environment package`  [EXTRACTED]
  packages/pi/README.md → CLAUDE.md
- `selectModelForComplexity()` --indirect_call--> `model()`  [INFERRED]
  packages/pi/extensions/_lib/agent-runtime.ts → packages/pi/extensions/subagent-routing.test.ts
- `Dendritic Nix flake extension skill` ----> `Explicit host composition`  [EXTRACTED]
  .pi/skills/extend-dendritic-nix-flake/SKILL.md → README.md
- `Dendritic Nix flake extension skill` ----> `Independent NixOS feature leaf`  [EXTRACTED]
  .pi/skills/extend-dendritic-nix-flake/SKILL.md → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **h-flake-extension-contract** — recursive-flake-parts, nixos-module-leaf, nixos-aggregate, per-system-package, explicit-host-composition, flake-validation [INFERRED]
- **h-pi-agent-pipeline** — doc-scout, doc-planner, doc-tester, doc-implementer, doc-reviewer, doc-committer, ship-pipeline, structured-handoff [INFERRED]
- **h-pi-package-boundaries** — pi-integration, provider-portable-routing, tuicr-review, environment-package, graphify-chunk-output [INFERRED]
- **h-herdr-verification** — herdr-plugin-bundle, clean-herdr-verification, tuicr-review [INFERRED]
- **h-read-write-separation** — read-only-role-boundary, doc-scout, doc-planner, doc-reviewer, doc-ai-review, doc-implementer, doc-tester, graphify-chunk-output [INFERRED]
- **h-nixos-deployment** — nixos-module-leaf, nixos-aggregate, explicit-host-composition, deploy-rs-roles, sanctum-explicit-membership, host-set [INFERRED]
- **Graphify extraction pipeline** — packages_pi_skills_graphify_full_pipeline, packages_pi_skills_graphify_structural_ast_extraction, packages_pi_skills_graphify_semantic_extraction [EXTRACTED 1.00]
- **Review and quality workflow** — packages_pi_skills_code_review_code_review, packages_pi_skills_security_review_security_review, packages_pi_skills_simplify_simplify_skill [INFERRED 0.85]
- **Runtime verification workflow** — packages_pi_skills_run_run_skill, packages_pi_skills_run_golden_path, packages_pi_skills_verify_verify_skill [INFERRED 0.85]

## Communities (23 total, 2 thin omitted)

### Community 0 - "Graphify Pipeline"
Cohesion: 0.06
Nodes (36): Graphify URL ingestion, Graph build merge, Cluster-only rebuild, Code-only incremental update, Community detection, Extraction confidence rubric, Cross-repository graph merge, Graphify extraction subagent prompt (+28 more)

### Community 1 - "Agent Discovery"
Cohesion: 0.12
Nodes (27): AgentConfig, AgentDiscoveryResult, AgentScope, discoverAgents(), findNearestProjectAgentsDir(), isDirectory(), loadAgentsFromDir(), AGENT_COMPLEXITIES (+19 more)

### Community 2 - "Agent Execution"
Cohesion: 0.17
Nodes (21): AgentModelContext, AgentRole, getPiInvocation(), loadRole(), spawnAgent(), SpawnAgentModelContext, SpawnResult, describeItem() (+13 more)

### Community 3 - "Repository Configuration"
Cohesion: 0.12
Nodes (21): Push and pull-request CI, Clean Herdr protocol verification, Repository agent guidance, Pi appended system prompt, GitHub check workflow, Claude repository guide, Project memory, Pi package README (+13 more)

### Community 4 - "Review and Jujutsu"
Cohesion: 0.10
Nodes (21): Code review, Correctness bug, Code review finding report, Pending diff, Simplification and efficiency cleanup, Review verdict, Jujutsu git diff, Jujutsu version-control workflow (+13 more)

### Community 5 - "Plan Mode"
Cohesion: 0.18
Nodes (14): registerToggleMode(), ToggleModeConfig, ToggleModeState, extractTodos(), markCompleted(), planModeExtension(), ProgressState, textFromMessage() (+6 more)

### Community 6 - "Pi Roles and Prompts"
Cohesion: 0.15
Nodes (16): AI review prompt, Committer role, Implementer role, Escalated implementer role, Project notes, Output semantics role, Planner role, Reviewer role (+8 more)

### Community 7 - "Tuicr Review"
Cohesion: 0.29
Nodes (11): commentFingerprint(), commentKey(), CommentRecord, CommentSnapshot, formatFeedback(), formatLocation(), parseJson(), ReviewComment (+3 more)

### Community 8 - "Graph Querying"
Cohesion: 0.20
Nodes (11): Breadth-first graph traversal, Native CLAUDE.md integration, Depth-first graph traversal, Existing graph fast path, Graph reflection lessons, Graphify MCP server, Node explanation, Query result feedback (+3 more)

### Community 9 - "Pi Memory"
Cohesion: 0.31
Nodes (8): findProjectRoot(), globalMemoryDir(), memoryExtension(), projectMemoryDir(), projectSkillsDir(), readBounded(), RememberParams, WriteSkillParams

### Community 10 - "SkillOpt Safety Tests"
Cohesion: 0.33
Nodes (7): invoke(), test_harvest_artifacts_are_private(), test_memory_proposal_cannot_be_adopted(), test_missing_target_is_rejected(), test_staged_target_must_match_explicit_target(), test_task_metadata_cannot_select_target(), test_unsafe_commands_are_unavailable()

### Community 11 - "Runtime Verification"
Cohesion: 0.33
Nodes (7): Golden-path exercise, Run-process cleanup, Project type detection, Run skill, Edge-case regression check, End-to-end exercise, Verify skill

### Community 12 - "Notifications"
Cohesion: 0.80
Nodes (4): notifyExtension(), notifyOsc777(), notifyOsc99(), oscText()

### Community 13 - "SkillOpt Workflow"
Cohesion: 0.50
Nodes (5): SkillOpt harvest and dry-run, Declarative Nix boundary, Reviewed skill adoption, SkillOpt safety contract, SkillOpt-Sleep

### Community 14 - "NixOS Deployment"
Cohesion: 0.50
Nodes (4): Independent deploy-rs roles, NixOS module README, Compatibility aggregate module, Explicit Sanctum service membership

### Community 15 - "Conversation Handoff"
Cohesion: 0.83
Nodes (3): entryToMessage(), handoffExtension(), handoffMessages()

### Community 16 - "Status Babysitting"
Cohesion: 0.50
Nodes (4): Babysit status-check prompt, Open PR, CI, and deploy status, Read-only status reporting, Systemd user timer

### Community 17 - "OpenSpec Workflow"
Cohesion: 0.50
Nodes (4): OpenSpec directory layout, openspec init command, OpenSpec spec-driven workflow, OpenSpec opsx commands

### Community 18 - "Herdr Integration"
Cohesion: 0.50
Nodes (4): Herdr mirror integration, Herdr plugin colocation, Herdr version bump, Pi output-semantics role

### Community 19 - "Graph Watch Mode"
Cohesion: 0.67
Nodes (3): Code-only watch rebuild, Document watch update flag, Graphify folder watch

## Knowledge Gaps
- **79 isolated node(s):** `AgentScope`, `AgentDiscoveryResult`, `AgentThinkingLevel`, `AgentRuntime`, `AgentRole` (+74 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `resolveAgentRuntime()` connect `Agent Discovery` to `Agent Execution`?**
  _High betweenness centrality (0.010) - this node is a cross-community bridge._
- **What connects `AgentScope`, `AgentDiscoveryResult`, `AgentThinkingLevel` to the rest of the system?**
  _79 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Graphify Pipeline` be split into smaller, more focused modules?**
  _Cohesion score 0.05873015873015873 - nodes in this community are weakly interconnected._
- **Should `Agent Discovery` be split into smaller, more focused modules?**
  _Cohesion score 0.11693548387096774 - nodes in this community are weakly interconnected._
- **Should `Repository Configuration` be split into smaller, more focused modules?**
  _Cohesion score 0.11904761904761904 - nodes in this community are weakly interconnected._
- **Should `Review and Jujutsu` be split into smaller, more focused modules?**
  _Cohesion score 0.10476190476190476 - nodes in this community are weakly interconnected._