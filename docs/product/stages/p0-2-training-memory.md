# P0.2 阶段范围：目标驱动自动带练与跨 session 记忆引擎

## 状态
Downstream documentation design-ready / implementation gated with follow-up hardening scaffold - 用户目标驱动审查后，P0.2 不再只是跨 session 记忆调度；本阶段升级为 GoalProfile、DiagnosticAssessment、GoalBackplan、AutopilotTraining、MemoryCurvePolicy、ProgressForecast 和 OutcomeCheckpoint 的组合。三个目标驱动 increments 已完成 requirements/spec/acceptance/test_cases/traceability 下沉设计；本轮新增 Followup-A through Followup-D 正式 definition 和 WP traceability scaffold，用于把本地 deterministic 垂直切片剩余缺口拆成可实施、可审核、可追溯的小增量。旧单体记忆调度 artifact 已删除并被新的目标驱动 stage scope 吸收，不再作为 active source of truth、实现入口或可链接需求链。

## 阶段目标
在 P0.1 session 内训练闭环稳定后，把 APP 升级为目标驱动自动学习教练：用户输入目标类型、目标分数或能力、截止日期、每日可投入时间和强度偏好；系统诊断当前真实水平，倒排周计划/日计划/每次训练内容，并自动带用户完成训练、复习和周期复测，直到持续接近或达到目标。

## 目标驱动审查结论
| 用户期望链路 | 当前项目覆盖 | 结论 |
| --- | --- | --- |
| GoalProfile | Product Base 首评有目标方向、当前输出水平、每日分钟数；没有目标分数、截止日期、强度偏好和目标事实源 | P0.2 必须新增 |
| DiagnosticAssessment | Product Base 有轻量首评；P0.1 有训练反馈；没有真实口语诊断、rubric、弱项分解和置信度 | P0.2 必须新增 |
| GoalBackplan | 旧单体记忆调度设计有 daily/long-term planner，但不是从目标倒推 | P0.2 必须新增 |
| AutopilotTraining | P0.1 负责 session 内 micro-action；旧单体记忆调度设计允许 skip/defer，但没有自动开练和无自律执行模型 | P0.2 必须新增 |
| MemoryCurvePolicy | 旧单体记忆调度设计有 review schedule，但没有明确记忆曲线算法、遗忘风险、overlearning 和 interleaving | P0.2 必须新增 |
| ProgressForecast | P1 scoring 有评分产品化计划；没有距目标差距、ETA、风险和复测触发 | P0.2 必须新增，P1 可增强评分模型 |
| OutcomeCheckpoint | P0.1/旧单体记忆调度设计没有周/双周模拟考试或商务任务复测 | P0.2 必须新增 |

## 入口条件
- P0.1 训练型 Agent 已可验收。
- P0.1 学习证据写回稳定可追踪。
- P0.1 未完成项和测试缺口已记录。
- P0 commercial 和 paid AI release gates 不被 P0.2 规划替代。
- 代码实现启动前必须按新拆分补齐每个 P0.2 increment 的 requirements/spec/AC/TC/traceability、domain/API/AI/UX 契约和独立 checker 复核。
- 代码实现启动前必须先完成并审查 P02-PG-001 through P02-PG-005 横向 policy gates；三个 P0.2 increments 的 downstream docs 必须逐项引用适用 gate，不能只写功能存在。
- 若任一目标类型、诊断置信度、内容覆盖、AI 成本、用户控制、商业权益或数据治理无法满足 gate，P0.2 必须降级为 supported/partial/unsupported 状态，而不是生成看似完整的训练计划或达标承诺。

## 横向 Policy Gates
| Policy Gate ID | Gate | 必须解决的问题 | Owning downstream coverage | Implementation gate |
| --- | --- | --- | --- | --- |
| P02-PG-001 | GoalAchievementPolicy | 产品内达标定义、官方分数非承诺、诊断置信度、rubric 校准、低置信度降级、预测/完成声明 guard | `p0-2-goal-diagnostic-foundation`, `p0-2-autopilot-progress-checkpoint` | 未定义达标阈值、置信度和禁止声明前，不得展示达标、ETA 或考试分数等价承诺 |
| P02-PG-002 | SupportedGoalMatrix | 目标类型、目标能力/分数、rubric、场景/题型/内容资产覆盖、supported/partial/unsupported 决策 | `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint` | 目标或内容覆盖不足时必须限制目标、降级计划或标记 unsupported |
| P02-PG-003 | AutopilotControlPolicy | 自动带练用户控制、暂停/恢复、安静时段、missed-day recovery、疲劳/过载保护、planner feasibility、计划重算和 deterministic replay | `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint` | 自动执行、通知或计划重算缺少控制与回放证据前，不得进入实现 |
| P02-PG-004 | CommercialEntitlementAndCostPolicy | 免费/付费权益、会员价值展示、AI 用量预算、超额降级、成本指标、套餐边界、不得创建商业权益事实源 | `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint` | 未定义 entitlement/cost/downgrade 前，不得把 P0.2 作为付费承诺或开放高成本 AI 路径 |
| P02-PG-005 | DataGovernancePolicy | 目标画像、诊断录音、弱项、预测、checkpoint 的 consent、retention、deletion/export、audit trail、解释性和敏感数据最小化 | `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint` | 未定义数据治理和删除/保留策略前，不得持久化敏感目标、诊断或预测事实 |

## 缺陷闭环审查矩阵
| 缺陷 | 最优解决方案 | Gate coverage | 当前状态 |
| --- | --- | --- | --- |
| 达标判定与承诺边界不清 | 使用产品内 achievement rubric + confidence band + claim guard；官方考试只可作为目标类型，不可声明认证等价 | P02-PG-001 | Closed at planning gate / downstream docs required |
| 诊断可信度不足 | 采用 rubric calibration、minimum sample、low-confidence downgrade、periodic reassessment 和 diagnostic audit | P02-PG-001, P02-PG-005 | Closed at planning gate / downstream docs required |
| 自动带练可能过度自动化 | 采用 no-choice execution + user control contract：暂停、恢复、安静时段、疲劳保护和 missed-day recovery | P02-PG-003 | Closed at planning gate / downstream docs required |
| 商业边界不足 | 采用 entitlement + AI budget + cost telemetry + downgrade policy；会员页只能展示价值，不能创建权益事实源 | P02-PG-004 | Closed at planning gate / downstream docs required |
| 计划引擎缺少可执行约束 | 采用 deterministic planner constraints、time budget、overload guard、priority conflict rules、replay fixture 和 plan recalculation rules | P02-PG-003 | Closed at planning gate / downstream docs required |
| 内容覆盖与目标类型未绑定 | 使用 SupportedGoalMatrix，把目标分为 supported/partial/unsupported，并强制校验场景/题型/rubric/content coverage | P02-PG-002 | Closed at planning gate / downstream docs required |
| 隐私、数据保留和解释性缺口 | 使用 consent、retention/deletion/export、sensitive data minimization、audit trail 和 forecast explanation policy | P02-PG-005 | Closed at planning gate / downstream docs required |

## 阶段范围
- GoalProfile：目标类型、目标分数或能力、截止日期、每日可投入时间、强度偏好。
- DiagnosticAssessment：初始口语测评、目标 rubric、弱项分解、置信度。
- GoalBackplan：从目标倒推周计划、日计划和每次训练内容。
- AutopilotTraining：系统自动开练、自动切换训练/复习/复测，不依赖用户自律。
- MemoryCurvePolicy：明确间隔复习算法、遗忘风险、复现、过度学习和 interleaving。
- ProgressForecast：当前距目标差距、预计达标日期、风险提醒、阶段复测。
- OutcomeCheckpoint：每周或每两周模拟考试/商务任务复测，更新计划。
- 原 P0.2 记忆范围：Daily planner、cross-session pressure、L0-L5 mastery、long-term planner、训练证据进入首页/表达队列/Wiki。

## Stage Scope Items
| Stage Scope ID | Capability / obligation | Required status | Target increment | Current status |
| --- | --- | --- | --- | --- |
| P02-SI-001 | Daily training planner | required | `p0-2-goal-backplan-memory-policy` | Planned - absorbed into goal-driven backplan docs |
| P02-SI-002 | Cross-session pressure ladder | required | `p0-2-goal-backplan-memory-policy` | Planned - absorbed into goal-driven memory policy docs |
| P02-SI-003 | L0-L5 mastery ladder | required | `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy` | Planned - requires diagnostic, rubric and mastery transition docs |
| P02-SI-004 | Long-term session planner | required | `p0-2-goal-backplan-memory-policy` | Planned - requires goal backplan docs |
| P02-SI-005 | 到期复习、薄弱表达、未完成 session 和当前目标场景的跨天编排 | required | `p0-2-goal-backplan-memory-policy` | Planned - requires goal priority and memory-risk docs |
| P02-SI-006 | 训练证据进入首页推荐、表达队列和个人 Wiki | required | `p0-2-autopilot-progress-checkpoint` | Planned - requires progress projection and surface-routing docs |
| P02-SI-007 | GoalProfile：目标类型、目标分数/能力、截止日期、每日可投入时间、强度偏好 | required | `p0-2-goal-diagnostic-foundation` | Planned - new scope |
| P02-SI-008 | DiagnosticAssessment：初始口语测评、目标 rubric、弱项分解、置信度 | required | `p0-2-goal-diagnostic-foundation` | Planned - new scope |
| P02-SI-009 | GoalBackplan：从目标倒推周计划、日计划、每次训练内容 | required | `p0-2-goal-backplan-memory-policy` | Planned - new scope |
| P02-SI-010 | AutopilotTraining：自动开练、自动切换训练/复习/复测，不依赖用户自律 | required | `p0-2-autopilot-progress-checkpoint` | Planned - new scope |
| P02-SI-011 | MemoryCurvePolicy：间隔复习算法、遗忘风险、复现、过度学习、interleaving | required | `p0-2-goal-backplan-memory-policy` | Planned - new scope |
| P02-SI-012 | ProgressForecast：距目标差距、预计达标日期、风险提醒、阶段复测 | required | `p0-2-autopilot-progress-checkpoint` | Planned - new scope |
| P02-SI-013 | OutcomeCheckpoint：每周/双周模拟考试或商务任务复测并更新计划 | required | `p0-2-autopilot-progress-checkpoint` | Planned - new scope |

## 阶段非目标
- 不在 P0.2 承诺完整 A1-C2 内容体系。
- 不在 P0.2 承诺任意公开场景生成。
- 不把笔记本和完整评分产品化作为 P0.2 阻塞项。
- 不承诺官方 IELTS/TOEFL 认证分数；P0.2 只能提供产品内 rubric 和目标进度预测。
- 不绕过 P0 商业发布、真实支付、store 或 paid AI voice evidence gates。

## 纳入 increment
### 原始目标驱动增量
- `p0-2-goal-diagnostic-foundation`：目标画像与初始诊断基础。
- `p0-2-goal-backplan-memory-policy`：目标倒排计划与记忆曲线策略。
- `p0-2-autopilot-progress-checkpoint`：自动带练、进度预测与周期复测。

### Follow-up 加固增量
- `p0-2-followup-a-goal-intake-diagnostic-hardening`：完整可编辑 GoalProfile 表单、诊断样本采集、目标 revision/stale 可见化和低置信度/unsupported 降级。
- `p0-2-followup-b-autopilot-control-planner-memory`：UserAutopilotControl、pause/resume/update-control、通知调度语义、missed-day recovery、item-level MemoryCurvePolicy 和 L0-L5 转移。
- `p0-2-followup-c-checkpoint-forecast-surfaces`：ProgressForecast、OutcomeCheckpoint、checkpoint cadence/task library 和 Home/Queue/Wiki 多产品面 projection。
- `p0-2-followup-d-release-gate-hardening`：P0.2 feature flag/kill switch、entitlement/cost/usage、quota downgrade、consent/export/retention、telemetry、contract drift 和 release/Product Base gates。

## 当前文档链路
- `docs/product/increments/p0-2-goal-diagnostic-foundation/definition.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/requirements.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/spec.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/acceptance.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/test_cases.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/traceability.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/definition.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/requirements.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/spec.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/acceptance.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/test_cases.md`
- `docs/product/increments/p0-2-goal-backplan-memory-policy/traceability.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/definition.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/requirements.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/spec.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/acceptance.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/test_cases.md`
- `docs/product/increments/p0-2-autopilot-progress-checkpoint/traceability.md`
- `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/definition.md`
- `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/traceability.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/definition.md`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/traceability.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/definition.md`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/traceability.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/definition.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/traceability.md`

## 历史 artifact 处理
旧单体记忆调度 artifact 已删除并 superseded。其 P02-SI-001..006 设计意图只通过本 stage scope 保留，后续必须在上述三个新 increment 的 requirements、spec、acceptance、test_cases 和 traceability 中重新生成、吸收或明确排除，不能直接进入实现。

## 出口条件
- 三个目标驱动 P0.2 increments 均完成 requirements、spec、acceptance、test_cases、traceability 和独立审查。
- GoalProfile 和 DiagnosticAssessment 能为 planner 提供可信目标和当前水平输入。
- GoalBackplan 能输出周计划、日计划和每次训练内容，并能根据每日可投入时间自适应。
- AutopilotTraining 能自动带用户进入训练、复习和复测，不依赖用户选择下一步。
- ProgressForecast 和 OutcomeCheckpoint 能周期性更新目标差距、达标预测和计划。
- L0-L5 状态推进规则有明确 domain model 和测试覆盖。
- 长期记忆调度不由 LLM 直接写入最终持久化状态。
- P02-PG-001 through P02-PG-005 均在对应 increment requirements/spec/acceptance/test_cases/traceability、domain/API/AI/UX 契约和质量报告中闭环；若只能 partial 支持，必须有用户可见降级和商业/数据治理说明。
- Followup-A through Followup-D 均完成 requirements、spec、acceptance、test_cases、traceability、独立审查和实现证据；不得用原本地 deterministic 垂直切片替代完整 GoalProfile UI、pause/resume/notification、Queue/Wiki propagation、commercial/cost/data/release gates。
