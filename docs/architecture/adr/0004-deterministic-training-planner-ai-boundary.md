# ADR 0004: Deterministic Training Planner And AI Boundary

## Status
Proposed - pending document traceability and Product Object Governance checks.

## Context
P0.1 要把现有语音场景模拟升级为 session 内训练型 Agent，覆盖 action chain、micro-action、hint ladder、retry、in-session pressure check 和学习证据写回。产品边界明确要求 AI 不直接拥有持久化掌握状态的最终变更权。

## Decision
P0.1 训练推进采用 deterministic Training Planner。LLM 只生成结构化候选反馈、提示、追问和表达建议；planner/domain rules 决定当前 micro-action、hint level、retry、pressure check、step completion 和 learning evidence write-back。

Core objects:
- TrainingSession
- ActionChainStep
- MicroAction
- HintLevel
- PlannerDecision
- PressureCheck
- LearningEvidence
- EvidenceRuleTrace

AI output must:
- match `docs/ai_runtime/llm_output_schema.md` or successor schema;
- include schema version;
- be validated before UI rendering;
- never directly mark mastery or entitlement state final.

## Alternatives
- Free-form LLM conversation drives training：拒绝。不可测试，容易越过阶段边界，难以追踪学习证据。
- Client-only planner：条件接受为短期 UI prototype，但 P0.1 可验收版本需要可测试 domain rules，并为后端同步预留。
- Fully server-side planner from day one：推荐方向，但可按风险切片先把 planner rules 独立成可测试模块，再接入后端事实源。

## Consequences
- 训练体验可以保持“一个下一步动作”，同时保留可测试性和可追溯性。
- AI provider 故障不会直接破坏 session 状态或学习证据。
- P0.1 需要补齐 domain model、AI prompt/schema、screen spec 和 planner tests。
- P0.2 的跨 session / L0-L5 / daily planner 可以复用 evidence 和 planner 边界扩展。

## Risks
- Planner 规则过硬可能降低对话自然度。Mitigation：LLM 可生成候选追问和表达建议，但最终流转由规则裁决。
- 现有 `interview_practice_page.dart` 逻辑较重，改造风险高。Mitigation：优先抽出 planner decision 和 state transition 单元测试，再逐步收敛 UI。
- 学习证据过多或低质。Mitigation：evidence write-back 需要 confidence、source turn、rule trace 和去重规则。

## Rollback
如 P0.1 planner 首版过重，可回退到更小 micro-action set，但不得回退到 free-form LLM 直接推进训练和写最终掌握状态。
