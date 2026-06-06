# P0.2 Followup-D Requirements：发布门禁与商业软件加固

## 状态
S000 documentation chain validated - 本文件定义 `p0-2-followup-d-release-gate-hardening` 的需求边界，并把 Followup-D 拆分为 S000-S011 小粒度 implementation slices。S000 只关闭 requirements/spec/acceptance/test_cases/traceability routing；S001-S011 在本文件中均为 planned，不得解释为代码实现、商业发布、paid AI external evidence 或 Product Base merge approval。

## Product Object
- 分类：`feature-increment`
- Increment：`p0-2-followup-d-release-gate-hardening`
- Active stage：`docs/product/stages/p0-2-training-memory.md`
- Primary feature：`goal-driven-learning-autopilot`
- Affected features：`commercial-subscription`、`ai-provider-operations`、`profile-membership`、`learning-memory-review`、`scoring-feedback`

## 需求假设
- Followup-A 已关闭 GoalProfile、DiagnosticAssessment、no-goal Explore Mode、目标 revision/stale 可见化和低置信度/unsupported 降级的本地实现审核。
- Followup-B 已关闭 UserAutopilotControl、pause/resume/update-control、notification eligibility/outbox、missed-day recovery、item-level MemoryCurvePolicy、L0-L5 transition、replay/performance/coverage/traceability gates 的本地证据。
- Followup-C 已关闭 ProgressForecast、OutcomeCheckpoint、checkpoint-to-plan、backend projection、Home/Queue/Wiki surface propagation、downgrade/data governance 和 quality gates 的本地证据。
- Followup-D 不重新实现 A/B/C 功能，只把上述能力接入 release/commercial/data/ops gates，使后续软件落地时可以安全开关、控量、审计、回滚和发布决策。
- P0 commercial、paid AI external evidence、store/native/release secrets、Product Base merge approval 仍是独立门禁，不能由本地 deterministic P0.2 实现自动关闭。

## 上游来源
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/definition.md`
- `docs/product/increments/p0-2-followup-d-release-gate-hardening/traceability.md`
- `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/`
- `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`
- `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`
- `docs/product/increments/commercial-subscription-readiness/`
- `docs/product/increments/commercial-ai-provider-hardening/`
- `docs/release/release_checklist.md`
- `docs/release/commercial_release_runbook.md`
- P02-PG-001 GoalAchievementPolicy
- P02-PG-002 SupportedGoalMatrix
- P02-PG-003 AutopilotControlPolicy
- P02-PG-004 CommercialEntitlementAndCostPolicy
- P02-PG-005 DataGovernancePolicy

## Scope Decision
Followup-D 是 P0.2 目标驱动自动带练的 release-gate hardening 增量。它把 A/B/C 已有的 goal/autopilot/progress facts 接入 feature flag、kill switch、server-owned entitlement、usage quota、cost telemetry、quota downgrade、data export/retention、consent UX、operational telemetry、contract drift、release checklist 和 Product Base decision gates。D 的完成标准是“具备可审核的发布和商业软件门禁”，不是“批准发布”。

## Scope
- S000：补齐 Followup-D requirements、spec、acceptance、test_cases，并把 S000-S011 routing 写入 definition 和 traceability。
- S001：建立 P0.2 后端 runtime feature flag、kill switch 和 fail-closed mutation gate。
- S002：建立 Flutter goal-autopilot entry/surface rollback gate，flag off 或后端 disabled 时不得本地兜底。
- S003：建立 entitlement/free-paid depth policy，使 diagnostic、planner、checkpoint、explanation depth 由服务端决定。
- S004：把 P0.2 高成本写路径或 AI-backed 路径接入 usage reservation、commit、release 和 quota ledger。
- S005：把 P0.2 provider/candidate explanation、policy rejection 和 fallback 接入 cost telemetry。
- S006：quota exhausted、entitlement blocked、cost limited 时输出一致 downgrade state 和用户可见限制。
- S007：建立 P0.2 goal/control/diagnostic/forecast/checkpoint/export/retention backend evidence。
- S008：建立 consent/privacy UX，使数据用途、导出、删除和通知同意状态可见且不制造商业承诺。
- S009：建立 goal autopilot health/error/funnel telemetry，覆盖 intake、plan、action、checkpoint、projection 和 blocked events。
- S010：建立 Followup-D contract/traceability/release checklist drift gate。
- S011：汇总 Product Base gate、release checklist、rollback plan、implementation/test/quality report 和独立审核。

## Stage Scope And Slice Coverage
| Stage Scope ID | Slice ID | Requirement ID | Policy Gate | Coverage status |
| --- | --- | --- | --- | --- |
| P02-SI-001..013 | P02-FUD-S000 | P02-FUD-FR-000 | P02-PG-001..005 | Validated for documentation chain and routing only |
| P02-SI-001..013 | P02-FUD-S001 | P02-FUD-FR-001 | P02-PG-003, P02-PG-004 | Planned |
| P02-SI-006, P02-SI-010 | P02-FUD-S002 | P02-FUD-FR-002 | P02-PG-003, P02-PG-004 | Planned |
| P02-SI-007..013 | P02-FUD-S003 | P02-FUD-FR-003 | P02-PG-002, P02-PG-004 | Planned |
| P02-SI-008..013 | P02-FUD-S004 | P02-FUD-FR-004 | P02-PG-004 | Planned |
| P02-SI-008, P02-SI-012, P02-SI-013 | P02-FUD-S005 | P02-FUD-FR-005 | P02-PG-001, P02-PG-004 | Planned |
| P02-SI-007..013 | P02-FUD-S006 | P02-FUD-FR-006 | P02-PG-002, P02-PG-004 | Planned |
| P02-SI-001..013 | P02-FUD-S007 | P02-FUD-FR-007 | P02-PG-005 | Planned |
| P02-SI-007..013 | P02-FUD-S008 | P02-FUD-FR-008 | P02-PG-005 | Planned |
| P02-SI-001..013 | P02-FUD-S009 | P02-FUD-FR-009 | P02-PG-003, P02-PG-004, P02-PG-005 | Planned |
| P02-SI-001..013 | P02-FUD-S010 | P02-FUD-FR-010 | P02-PG-001..005 | Planned |
| P02-SI-001..013 | P02-FUD-S011 | P02-FUD-FR-011 | P02-PG-001..005 | Planned |

## Stage Scope Detail Coverage
| Stage Scope ID | Stage obligation | Prior functional evidence boundary | Followup-D release-gate routing |
| --- | --- | --- | --- |
| P02-SI-001 | Daily training planner | Followup-B planner/recovery/memory evidence | S001 runtime gate, S004 usage, S007 data governance, S009 telemetry, S010 drift, S011 release review |
| P02-SI-002 | Cross-session pressure ladder | Followup-B memory/replay evidence | S001 runtime gate, S007 retention/deletion, S009 telemetry, S010 drift, S011 release review |
| P02-SI-003 | L0-L5 mastery ladder | Followup-B mastery transition evidence | S003 entitlement depth, S005 AI/cost guard, S007 data governance, S010 drift, S011 release review |
| P02-SI-004 | Long-term session planner | Followup-B missed-day recovery and planner evidence | S001 runtime gate, S004 usage/idempotency, S009 telemetry, S010 drift, S011 release review |
| P02-SI-005 | Cross-day unfinished-session/current-goal orchestration | Followup-B recovery, notification and memory evidence | S001 runtime gate, S006 downgrade, S007 data governance, S009 telemetry, S011 release review |
| P02-SI-006 | Home, expression queue and personal Wiki evidence surfaces | Followup-C projection and surface propagation evidence | S002 Flutter rollback, S006 stale-cache downgrade, S009 telemetry, S010 drift, S011 release review |
| P02-SI-007 | GoalProfile facts | Followup-A goal intake, support and no-goal boundary evidence | S003 entitlement/support interaction, S007 export/retention/deletion, S008 consent UX, S011 release review |
| P02-SI-008 | DiagnosticAssessment facts | Followup-A diagnostic capture, confidence and claim-guard evidence | S003 depth policy, S004 usage, S005 cost/AI guard, S007 data governance, S008 consent UX |
| P02-SI-009 | GoalBackplan facts | Followup-A/B plan revision, stale plan and recovery evidence | S001 runtime gate, S004 usage/idempotency, S006 downgrade, S009 telemetry, S010 drift |
| P02-SI-010 | AutopilotTraining control and execution | Followup-B control/notification and Followup-C checkpoint/projection evidence | S001 kill switch, S002 entry rollback, S006 downgrade, S009 telemetry, S011 release review |
| P02-SI-011 | MemoryCurvePolicy | Followup-B memory curve and replay evidence | S003 entitlement/depth guard, S007 retention/deletion, S009 telemetry, S010 drift |
| P02-SI-012 | ProgressForecast | Followup-C forecast hardening and projection evidence | S005 AI/cost fallback, S006 quota downgrade, S007 data governance, S010 drift, S011 review |
| P02-SI-013 | OutcomeCheckpoint | Followup-C checkpoint task/result/update evidence | S003 checkpoint depth, S004 usage reservation, S005 cost telemetry, S006 downgrade, S007 deletion/export, S009 telemetry |

## Policy Gate Coverage
| Policy Gate ID | Requirement coverage |
| --- | --- |
| P02-PG-001 | P02-FUD-FR-000, P02-FUD-FR-005, P02-FUD-FR-010, P02-FUD-FR-011 |
| P02-PG-002 | P02-FUD-FR-000, P02-FUD-FR-003, P02-FUD-FR-006, P02-FUD-FR-010, P02-FUD-FR-011 |
| P02-PG-003 | P02-FUD-FR-000, P02-FUD-FR-001, P02-FUD-FR-002, P02-FUD-FR-009, P02-FUD-FR-010, P02-FUD-FR-011 |
| P02-PG-004 | P02-FUD-FR-000, P02-FUD-FR-001, P02-FUD-FR-002, P02-FUD-FR-003, P02-FUD-FR-004, P02-FUD-FR-005, P02-FUD-FR-006, P02-FUD-FR-009, P02-FUD-FR-010, P02-FUD-FR-011 |
| P02-PG-005 | P02-FUD-FR-000, P02-FUD-FR-007, P02-FUD-FR-008, P02-FUD-FR-009, P02-FUD-FR-010, P02-FUD-FR-011 |

## 用户目标
学习者可以安全使用 P0.2 自动带练能力：功能可被产品方逐步开放或关闭；免费/付费深度和额度限制来自服务端；额度、成本或政策阻断时能看到一致的降级；目标、诊断、计划、复测和进度数据可导出、删除、保留和审计；产品不展示未被证据支持的达标、官方分数或商业承诺。

## 用户路径
1. 用户进入 Home、goal autopilot panel、Queue 或 Wiki。
2. 系统读取后端 runtime gate 和 projection 状态；若 P0.2 disabled 或 kill switch active，入口关闭或降级，不创建本地 goal/planner/checkpoint state。
3. 用户创建或更新目标、生成计划、完成行动、提交 checkpoint 或查看 forecast 时，服务端先应用 entitlement、quota、cost 和 data governance policy。
4. 若允许执行，服务端对高成本或 AI-backed 路径 reserve usage，成功后 commit，失败或 provider unavailable 后 release 或记录 policy rejection。
5. 若 quota exhausted、entitlement blocked、cost limited、unsupported、partial 或 low-confidence，服务端返回 typed downgrade state，Flutter surface 只渲染服务端状态。
6. 用户或运营方可以追踪 goal autopilot funnel、error、downgrade、cost 和 release gate evidence。
7. 用户发起导出或删除时，P0.2 goal/control/diagnostic/forecast/checkpoint/projection facts 有 redacted export、retention rule 和 deletion proof。
8. PM/Release reviewer 只在 D 的 AC/TC、traceability、reports、release checklist 和 external gate status 全部可审查时，才可做 Product Base 或 release 决策。

## Functional Requirements

### P02-FUD-FR-000 S000 文档链和 slice routing
- 系统必须在任何 Followup-D 代码或 release-gate 变更前补齐 `requirements.md`、`spec.md`、`acceptance.md`、`test_cases.md`，并更新 `definition.md` 与 `traceability.md`。
- 文档链必须包含 S000-S011 routing、FR/Spec/AC/TC mapping、Stage Scope ID、Policy Gate、gap register、test/report evidence 入口和 non-goal/release boundary。
- S000 只能声明 documentation-chain ready；S001-S011 只能声明 planned，直到对应代码、测试和独立 review 实际完成。
- S000 必须通过产品工程师和软件工程师双视角独立审核，确认需求清晰、无歧义、上游覆盖完整、足够支撑后续开发。

### P02-FUD-FR-001 后端 feature flag 和 kill switch
- P0.2 goal autopilot runtime 必须有服务端 feature flag 和 kill switch；关闭时所有 mutation 路径 fail-closed。
- Mutation 路径至少包括 goal create/update、plan generate、control update/pause/resume、recovery replan、item-policy decisions、action complete、checkpoint submit。
- Read/projection 路径必须返回安全 `disabled`、`unavailable` 或 `service_disabled` 状态，不得暴露过期目标、ETA、goal-complete 或 checkpoint conclusion。
- Kill switch 必须保留 reason code、request id 或 audit evidence，支持 rollback review。

### P02-FUD-FR-002 Flutter entry 和 surface rollback gate
- Flutter 入口、Home/Queue/Wiki surface 和 goal autopilot panel 必须消费服务端 runtime/projection 状态。
- 当后端 disabled、unavailable 或 kill switch active 时，Flutter 必须关闭入口或显示服务不可用/降级状态，不得创建本地 goal、plan、forecast、checkpoint 或 final mastery fallback。
- Flutter 不得本地推断商业权益、额度、goal completion、ETA、official-score equivalence 或 release readiness。
- Entry rollback 必须覆盖 cached projection replacement，避免关闭后继续显示旧进度。

### P02-FUD-FR-003 Entitlement/free-paid depth gate
- 服务端必须定义 P0.2 entitlement depth policy，覆盖 diagnostic sample depth、planner horizon/session count、checkpoint task depth、forecast/checkpoint/mastery explanation depth。
- 免费、付费、过期、grace、revoked 或 unknown entitlement 必须有明确 depth/downgrade 结果。
- Entitlement decision 必须由服务端拥有，Flutter 只能展示返回结果，不得创建或覆盖 entitlement facts。
- Entitlement blocked 不得生成 full plan、full checkpoint、precise ETA 或 high-depth AI explanation。

### P02-FUD-FR-004 Usage reservation、quota 和 idempotency
- P0.2 高成本或 AI-backed 路径必须接入 usage reserve/commit/release，避免无额度时继续执行。
- Usage family、source ref、idempotency key、reservation ttl、commit/release event ref 必须可追踪。
- Provider unavailable、validation failure、policy rejection 或 partial downgrade 时必须 release reservation 或记录不计费原因。
- 重放请求不得重复扣量；idempotency conflict 必须返回 typed error。

### P02-FUD-FR-005 Cost telemetry 和 AI fallback
- P0.2 AI-backed explanation、provider candidate 或 policy rejection 必须记录 sanitized cost metric。
- Cost metric 至少包含 user hash、plan、provider family、model/capability、status、estimated units/cost、budget bucket、margin risk 和 fallback reason。
- 当 P0.2 当前使用 deterministic/no-provider path 时，必须明确记录 `N/A - deterministic no provider call` 或 policy rejection，不得伪造 live provider evidence。
- AI output 只能作为 candidate，不得写入 entitlement、quota、final mastery、goal-complete、official score 或 release approval facts。

### P02-FUD-FR-006 Quota exhausted downgrade
- Quota exhausted、entitlement blocked、cost budget limited 必须输出一致的 backend downgrade reason。
- 受影响路径必须安全降级或阻断，不得继续显示 full checkpoint、precise ETA、high-depth explanation 或 paid-only copy。
- Flutter Home/Queue/Wiki/Panel 必须展示服务端 downgrade，不得从本地缓存恢复旧的高权限内容。
- Downgrade 必须对 partial、unsupported、low-confidence 和 stale plan 保持现有 Followup-A/B/C 语义。

### P02-FUD-FR-007 Data export、retention 和 deletion backend evidence
- P0.2 goal profile、diagnostic、control、plan、memory, forecast、checkpoint、projection、outbox、replay、mastery、usage/cost references 必须纳入 export/retention/deletion evidence。
- Export 必须 redacted，隐藏 raw diagnostic transcript、raw audio、provider payload、idempotency key、notification payload 和敏感目标细节，除非下游合同明确允许。
- Account deletion 必须清理或匿名化 P0.2 user-owned tables，并保留最小 redacted audit proof。
- Retention rules 必须列出 table、retention policy、deletion trigger、export family 和 evidence note。

### P02-FUD-FR-008 Consent/privacy UX
- 用户路径必须能看到 P0.2 数据用途、通知同意、导出/删除/保留边界和降级状态。
- Consent UI 不得暗示购买即保证达标、官方分数认证、无限 AI 或无限 checkpoint。
- 用户撤回通知或相关 consent 后，相关 reminder/notification/autopilot prompt 必须进入 blocked/downgraded state。
- Privacy copy 必须和 backend retention/export behavior、release checklist 和 store/privacy evidence 保持一致。

### P02-FUD-FR-009 Telemetry health/error/funnel metrics
- 系统必须记录 P0.2 intake、diagnostic、plan generation、control update、next action、action complete、checkpoint、projection read、downgrade、quota/error 和 kill-switch events。
- Metrics 必须 redacted，不含 raw transcript/audio/provider payload。
- Metrics 必须支持 release review 判断 rollout health、error concentration、quota pressure、provider fallback 和 data governance health。
- Telemetry 失败不得阻断用户主流程，但必须有 fallback audit 或 error metric。

### P02-FUD-FR-010 Contract、traceability 和 release drift gates
- Followup-D 必须有 dedicated traceability checker 或等价 gate，验证 requirements/spec/acceptance/test_cases/traceability/report/release checklist 一致。
- 若 API 或 DTO 改变，必须运行 OpenAPI、generated Dart drift 和 API contract checks。
- 若 Flutter source-of-truth 或 entry gate 改变，必须有 frontend source-of-truth guard，防止本地推断后端事实。
- Release checklist、rollback plan、commercial/paid AI evidence refs 和 Product Base decision 状态必须可追踪，不得过期或互相矛盾。

### P02-FUD-FR-011 Product Base、release checklist 和 independent review gate
- Followup-D 最终关闭前必须更新 implementation_report、test_report、quality_report、release_checklist、rollback_plan 或明确 N/A。
- Quality review 必须区分 local deterministic completion、commercial release decision、paid AI external evidence、Product Base merge approval。
- Product Base merge 只能由 PM/release governance 显式批准；D 的本地测试通过不得自动合入 Product Base。
- Independent review 必须分别从产品工程师和软件工程师角度确认需求、实现证据、测试证据、release risk 和 residual blockers。

## 需求到验收交接备注
| Requirement ID | 验收生成时必须关注的可观察行为 | 必须保留的追溯字段 |
| --- | --- | --- |
| P02-FUD-FR-000 | 文档链完整、S000-S011 routing 存在、未实现 slice 未被误标实现 | Stage Scope ID、Slice ID、Policy Gate、S000 review evidence |
| P02-FUD-FR-001 | 服务端 flag/kill switch 关闭 mutation 并安全降级 read/projection | flag state、kill reason、audit ref、affected endpoint |
| P02-FUD-FR-002 | Flutter 不本地兜底 goal/autopilot/progress state | backend runtime state、projection state、cache replacement evidence |
| P02-FUD-FR-003 | Entitlement depth 由服务端决定 | plan/status、depth decision、downgrade reason |
| P02-FUD-FR-004 | Usage reserve/commit/release 可回放且不重复扣量 | reservation id、source ref、idempotency key、usage family |
| P02-FUD-FR-005 | Cost telemetry redacted 且 AI output candidate-only | metric id、provider status、fallback reason、forbidden field guard |
| P02-FUD-FR-006 | quota/cost/entitlement downgrade 一致传播到 surface | downgrade reason、safe fields、cache cleanup |
| P02-FUD-FR-007 | export/retention/deletion 覆盖 P0.2 sensitive facts | export family、retention rule、deletion table、redaction proof |
| P02-FUD-FR-008 | consent/privacy UX 和后端数据治理一致 | consent state、copy source、release/privacy evidence |
| P02-FUD-FR-009 | telemetry 可证明 rollout health 且不泄漏敏感数据 | metric event、status、source path、redaction proof |
| P02-FUD-FR-010 | drift gates 阻断过期合同和报告 | checker path、command、result、release checklist refs |
| P02-FUD-FR-011 | final review 不混淆 local completion 和 release/Product Base approval | review id、PM decision、external evidence status、residual risk |

## 下游交接边界
- `spec.md`、`acceptance.md`、`test_cases.md`、`traceability.md`、domain/API/OpenAPI/UX/AI/Ops contracts 和 reports may consume this file as the Followup-D requirement source of truth, but they must not renumber or redefine P02-FUD-FR-000 through P02-FUD-FR-011 without a versioned Followup-D change.
- Implementation and test execution status belongs in `test_cases.md`, `traceability.md`, `docs/reports/test_report.md`, `docs/reports/implementation_report.md` and `docs/reports/quality_report.md`; this file may summarize workflow status but must not replace executable evidence.
- S000 documentation-chain completion does not approve S001-S011 implementation, commercial release, paid AI external evidence, store release, Product Base merge or official-score claims.

## Excluded Stage Scope Items
- None at release-gate level. Followup-D release hardening applies across P02-SI-001..013.
- Followup-D does not replace Followup-A GoalProfile/Diagnostic UI and data capture implementation.
- Followup-D does not replace Followup-B control/planner/memory/mastery implementation.
- Followup-D does not replace Followup-C forecast/checkpoint/projection/surface implementation.

## 非目标
- 不新增官方场景、任意场景生成、完整 A1-C2 内容体系或 P1/P2 scoring productization。
- 不承诺官方 IELTS/TOEFL 认证分数、官方分数等价或 guaranteed achievement。
- 不绕过 P0 commercial external/native/store/release gates。
- 不把 controlled-live local report、deterministic fallback 或本地测试误记为 paid AI external evidence。
