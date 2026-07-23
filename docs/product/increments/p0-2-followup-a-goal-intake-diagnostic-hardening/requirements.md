# P0.2 Followup-A Requirements：目标录入与诊断加固

## 状态
FR-001..009 implemented locally / release-gated - Followup-A 本地实现已覆盖无目标浏览模式；完整 P0.2 release 仍受 Followup-B/C/D 和商业发布门禁约束。

## Product Object
- Classification: `feature-increment`
- Increment: `p0-2-followup-a-goal-intake-diagnostic-hardening`
- Active stage: `docs/product/stages/p0-2-training-memory.md`
- Primary Capability ID：`CAP-INTENT`
- Primary Sub-capability ID：`CAP-INTENT-01`
- Affected Capability IDs：`CAP-LEVEL`、`CAP-PLAN`、`CAP-MEMORY`、`CAP-COACH`、`CAP-CONTENT`、`CAP-ACC`
- Affected Sub-capability IDs：`CAP-INTENT-04`、`CAP-INTENT-06`、`CAP-LEVEL-02`、`CAP-LEVEL-04`、`CAP-LEVEL-05`、`CAP-PLAN-06`、`CAP-PLAN-07`、`CAP-MEMORY-02`、`CAP-MEMORY-03`、`CAP-COACH-03`、`CAP-COACH-04`、`CAP-CONTENT-01`、`CAP-CONTENT-02`、`CAP-ACC-03`

## 上游来源
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/definition.md`
- `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/traceability.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/requirements.md`
- `docs/reports/quality_report.md#2026-06-04-p02-goal-autopilot-local-implementation-independent-review`
- P02-PG-001 GoalAchievementPolicy
- P02-PG-002 SupportedGoalMatrix
- P02-PG-003 AutopilotControlPolicy
- P02-PG-004 CommercialEntitlementAndCostPolicy
- P02-PG-005 DataGovernancePolicy

## Scope Decision
Followup-A is a hardening increment for the already designed P0.2 diagnostic foundation. It does not create a new feature and does not replace the original diagnostic increment. It closes the product gap where backend/API can accept GoalProfile fields but the Flutter user path only starts a default IELTS goal.
This addendum extends Followup-A with a no-goal browsing boundary. Users who are exploring the app without setting a goal must not be forced into GoalProfile creation or goal-autopilot facts.

## Stage Scope And WP Coverage
| Stage Scope ID | WP ID | Requirement ID | Coverage status |
| --- | --- | --- | --- |
| P02-SI-007 | P02-FUA-WP-001 | P02-FUA-FR-001 | Covered |
| P02-SI-007 | P02-FUA-WP-002 | P02-FUA-FR-002 | Covered |
| P02-SI-008 | P02-FUA-WP-003 | P02-FUA-FR-003 | Covered |
| P02-SI-008 | P02-FUA-WP-004 | P02-FUA-FR-004 | Covered |
| P02-SI-007, P02-SI-009 | P02-FUA-WP-005 | P02-FUA-FR-005 | Covered |
| P02-SI-007, P02-SI-008 | P02-FUA-WP-006 | P02-FUA-FR-006 | Covered |
| P02-SI-007, P02-SI-008 | P02-FUA-WP-007 | P02-FUA-FR-007 | Covered |
| P02-SI-007, P02-SI-008 | P02-FUA-WP-008 | P02-FUA-FR-008 | Covered |
| P02-SI-007 | P02-FUA-WP-009 | P02-FUA-FR-009 | Covered / implemented locally |

## 用户目标
学习者能够在 APP 内输入真实短期口语目标，提交足够的初始诊断样本，看到目标是否被支持、置信度和限制说明，并在目标修改后明确知道旧计划需要刷新，而不是被固定默认目标或不透明降级路径误导。

## 用户路径
1. 用户进入 Goal Autopilot 面板。
2. 若没有 active goal，用户先看到 no active goal 空状态，而不是固定默认目标或立即被迫填写表单。
3. 用户可以选择 `Set a goal` 进入可编辑 GoalProfile 表单，也可以选择 `Explore practice` 或 `Try a sample drill` 进行普通浏览/试练。
4. 如果用户选择设定目标，用户输入目标类型、目标分数或能力、截止日期、每日分钟数和强度偏好。
5. 用户填写至少一组诊断样本；若样本不足，系统允许提交但必须展示低置信度或保守诊断，不得伪造高置信度。
6. 系统提交 GoalProfile 和 diagnostic samples，后端返回 SupportedGoalMatrix、DiagnosticAssessment、confidence band、claim guard 和 forecast。
7. 用户在计划生成前看到 supported/partial/unsupported、限制说明、置信度和 prohibited-claim 边界。
8. 用户修改目标后，GoalProfile revision 变化；旧 daily/weekly plan 不得继续伪装为当前目标的可用计划。
9. 如果用户只进行普通浏览/试练，系统不得创建 GoalProfile、DiagnosticAssessment、ETA、forecast、plan、autopilot 或 memory schedule。
10. Followup-A 完成前，所有需求必须映射到 AC、TC、代码证据、测试证据和独立审核结论。

## Functional Requirements

### P02-FUA-FR-001 Editable GoalProfile Intake
- 系统必须在用户选择 `Set a goal` 或编辑目标时显示完整可编辑 GoalProfile 表单。
- 表单必须包含 goal type、target score 或 target ability、deadline、daily minutes 和 intensity preference。
- 表单必须阻止明显无效输入提交：空 goal type、过去或当天 deadline、daily minutes 低于 5 或高于 240、非法 intensity。
- 表单提交不得调用 default-goal-only 路径；发送给后端的 payload 必须来自用户输入。

### P02-FUA-FR-002 SupportedGoalMatrix Boundary
- 系统必须在 goal 创建后、plan 生成前显示 support status、reason code、limitation message 和 content/rubric coverage 中可用信息。
- `unsupported` 目标不得显示 full plan、ETA 或达标路径入口；只能显示目标缩窄或修改目标入口。
- `partial` 目标必须显示限制说明，并阻止高精度 ETA 或 goal-complete 文案。

### P02-FUA-FR-003 Diagnostic Sample Capture
- 系统必须提供诊断样本输入区域，至少允许三条文本诊断样本进入 goal intake payload。
- 系统必须显示已提供样本数量，并把少于三条样本的诊断结果视为可能低置信度或保守输入。
- 样本文本为空时不得作为有效 diagnostic sample 发送。

### P02-FUA-FR-004 Diagnostic Transport And Governance Boundary
- Diagnostic sample payload 必须保留 `sample_ref`、`transcript` 和可选 `audio_ref`/`duration_seconds` 边界，不得把 UI 展示文案伪装成诊断事实。
- 若本地没有生产音频采集或可信 audio_ref，Followup-A 只能发送 text fallback diagnostic samples，并在 UI 或报告中保留 paid AI/audio diagnostic gate 未关闭的事实。
- Diagnostic candidate、claim guard、rubric 和 weakness persistence 仍由后端/应用规则接受，Flutter 不得写入最终诊断事实。

### P02-FUA-FR-005 Goal Revision And Stale Visibility
- 用户修改目标并提交后，GoalProfile revision 必须在 UI 可见或可测试地进入 summary model。
- 当 active goal revision 变化且旧计划被后端标记 stale 后，UI 不得继续显示旧 next action 为当前可执行目标行动。
- UI 必须提供重新生成计划或继续诊断/修改目标的恢复路径。
- Followup-A 不得在目标修改后自动执行、自动通知或自动重排训练队列；这些行为必须等待 Followup-B 的 AutopilotControlPolicy、planner replay 和 MemoryCurvePolicy 闭环。

### P02-FUA-FR-006 Downgrade, Claim Guard And User Copy
- 低置信度、partial 或 unsupported 结果必须以用户可见方式说明限制原因。
- 所有 IELTS/TOEFL-like 目标都必须显示产品内 rubric/进度口径，不得显示官方认证分数或 guaranteed outcome。
- 当 forecast claim guard 禁止官方等价或 goal completion claim 时，Flutter 不能用本地文案绕过该限制。

### P02-FUA-FR-007 Test, Performance And Coverage Gate
- Followup-A 后续实现必须提供 Flutter widget/adapter tests，覆盖表单输入、payload、sample filtering、support status、claim guard、revision/stale 和 downgrade states。
- 后端已有诊断 foundation 覆盖可复用，但 Followup-A 若改动后端/API/domain，必须新增对应 unit/integration tests。
- 变更代码必须满足项目 P0.2 覆盖率门禁：后端 changed-code line/branch >=80%，Flutter feature line >=80%；性能预算沿用 diagnostic foundation 的 goal support decision p95 <=500 ms 和 deterministic diagnostic result retrieval p95 <=800 ms。

### P02-FUA-FR-008 Independent Review And Traceability
- Followup-A 每个 FR 必须至少映射一个 AC，每个 AC 必须映射稳定 TC ID 或明确允许例外。
- Traceability 必须包含 Stage Scope ID、Policy Gate、WP、FR、Spec、AC、TC、Contract Evidence、Code Evidence、Test Evidence 和 Status。
- 完成前必须把独立需求/规格/验收/测试/实现审核结果写入 `docs/reports/quality_report.md`。

### P02-FUA-FR-009 No-goal Explore Mode
- 当用户没有 active goal 且暂不设定目标时，系统必须显示 no active goal 空状态，包含主 CTA `Set a goal` 和次级入口 `Explore practice` 或 `Try a sample drill`。
- 用户进入 Explore Mode 或 sample drill 时，系统不得创建或持久化 GoalProfile、DiagnosticAssessment、ProgressForecast、GoalBackplan、DailyPlan、AutopilotAction 或 MemoryCurve schedule。
- Explore Mode 产生的练习数据只能进入普通 practice/session 证据，不得作为 goal-autopilot evidence、目标差距、ETA 或达标预测的输入。
- Explore Mode UI 只能展示普通练习反馈，不得显示“距目标还差多少”“预计达标日期”“goal achieved”“guaranteed outcome”或官方考试等价承诺。
- `createDefaultGoal()` 不得作为浏览模式 fallback；它只能作为测试 fixture 或显式兼容 helper，不能被生产浏览路径调用。

## 非目标
- 不实现 Followup-B 的 pause/resume、notification scheduler、missed-day recovery 或 item-level memory algorithm。
- 不实现 Followup-C 的 Queue/Wiki surface projection、checkpoint cadence/task library 或 forecast model hardening。
- 不实现 Followup-D 的 feature flag、kill switch、entitlement/cost telemetry、export/retention UI 或 release approval。
- 不承诺官方 IELTS/TOEFL 分数认证、保证达标或完整 A1-C2 内容体系。
- 不在 Followup-A 中实现完整 Explore Practice 内容库、推荐系统或普通练习闭环；本轮只定义 no-goal 与 goal-autopilot 的事实边界和测试入口。

## Requirement Independent Review
Result: pass after implementation evidence update. P02-FUA-FR-009 remains the correct product requirement for no-goal browsing, and local Flutter code/test evidence now covers the empty state, explicit `Set a goal` transition and Explore Mode fact boundary.
