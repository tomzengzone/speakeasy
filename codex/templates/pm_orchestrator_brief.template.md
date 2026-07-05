# PM-Orchestrator Brief

## User Request
<Plain-language request from the user；用户原始请求。>

## Product Decision
<accepted for current stage 当前阶段接受 | later-stage backlog 后续阶段待办 | rejected 拒绝 | needs clarification 需要澄清 | investigatory 调研>

## Product Classification
<baseline-consolidation 基线收敛 | new-feature 新能力 | feature-increment 能力增量 | bugfix 缺陷修复 | refactor 重构 | experiment 实验 | scope-change 范围变更>

## Product Object Check
- V2 capability registry（V2 能力注册表）: <confirmed | missing | not applicable>
- Baseline（基线）: <path or not applicable>
- Active stage（当前阶段）: <path or not applicable>
- Stage scope item IDs（阶段范围项 ID）: <confirmed | missing | not applicable>
- Increment definition（增量定义）: <path or missing | not applicable>
- Increment coverage（增量覆盖）: <covered | partially covered | missing | not applicable>

## Active Stage Goal
<Current product stage goal from docs/product/roadmap.md and docs/product/development_status.md；当前产品阶段目标。>

## Capability And Increment
- Primary capability（主能力）: <Capability ID, for example CAP-TRAIN>
- Primary sub-capability（主子能力）: <Sub-capability ID, for example CAP-TRAIN-02>
- Affected capabilities（受影响能力）: <Capability IDs, for example CAP-PRACTICE, CAP-COACH, or none>
- Affected sub-capabilities（受影响子能力）: <Sub-capability IDs, for example CAP-PRACTICE-03, CAP-COACH-01, or none>
- Increment id（增量 ID）: <increment id or not applicable>
- Covered Stage Scope Items（已覆盖阶段范围项）: <Stage Scope Item IDs or not applicable>
- Excluded Stage Scope Items（排除阶段范围项）: <Stage Scope Item IDs or not applicable>
- Uncovered required Stage Scope Items（未覆盖 required 阶段范围项）: <none | IDs with deferred/not-applicable reason | blocker>

## Priority
<P0 | P1 | P2 | Parking Lot 暂存 | Not Now 暂不处理>

## Scope
- <What is included in this execution request；本次执行包含什么。>

## Non-goals
- <What must not be pulled into this execution request；本次执行不得纳入什么。>

## Current Evidence
- <Existing requirements, specs, acceptance criteria, reports, tests, or implementation files；现有需求、规格、验收、报告、测试或实现文件。>

## Required Downstream Artifacts
- <requirements/spec/acceptance/domain/API/AI/UX/test/report artifacts required next；下一步需要的下游产物。>

## Question For Development Orchestrator
<What workflow decision or routing decision Product Manager needs；Product Manager 需要的 workflow 或 routing 决策。>

## Expected Orchestrator Output
- Current workflow stage（当前 workflow 阶段）
- Next legal workflow step（下一合法 workflow 步骤）
- Required specialist agent or skill（所需 specialist agent 或 skill）
- Missing artifacts or blockers（缺失产物或阻塞项）
- Validation expectations（验证期望）
- Product status update recommendation（产品状态更新建议）

---

# Orchestrator Execution Finding

## Current Workflow Stage
<Detected stage；检测到的阶段。>

## Next Legal Step
<One concrete next action；一个明确下一步动作。>

## Required Route
<Agent/skill/doc/code path to route next；下一步路由到的 agent、skill、文档或代码路径。>

## Missing Artifacts Or Blockers
- <Missing requirement/spec/contract/test/report, or none；缺失需求、规格、契约、测试、报告或无。>

## Validation Expectations
- <Expected tests, checks, or review evidence；预期测试、检查或复核证据。>

## Product Status Update Recommendation
<How Product Manager should update docs/product/development_status.md；Product Manager 应如何更新产品开发状态。>

## Risks
- <Risk or none；风险或无。>
