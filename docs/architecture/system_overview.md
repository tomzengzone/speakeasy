# Whole-App System Overview

## PR-003 current lineage

本次只切换来源链，不改变本文的工程行为、架构结论或已接受实现事实。当前产品 lineage 仅由适用的 approved FR 解析；Engineering Artifact 之间的 direct/conditional inputs 和适用 Gate 继续仅由 Governance Contract 解析。文内旧 Product Base、Increment、Spec/AC、旧 TC/traceability、Increment SWC Allocation 及与旧链路绑定的 Gate/checker 表述均为 historical provenance，不是当前 authority、prerequisite 或 fallback。

## 状态
Proposed - whole-app architecture。本文基于 PM execution brief 进入第二轮架构产物更新，必须在 `document-traceability-check` 和 Product Object Governance Check Agent 通过后，才能作为下游实现依据。

完整 SWC 拓扑、稳定 `SWC-FLOW-*` 和局部变更参考基准在 `docs/architecture/software_component_architecture.md`。本文保留 whole-app 系统范围、覆盖矩阵、选型和跨域架构结论。

## 架构范围模式
`whole-app`。范围覆盖 Product Base、V2 Capability registry、P0 商业化订阅上线准备、P0.1 表达自动化训练、P0.2/P1/P2 未来边界和明确非目标。

## Source Inventory
| 来源 | 路径 | 架构用途 |
| --- | --- | --- |
| Product Base | `docs/product/base/` | 稳定 MVP 能力和回归边界 |
| Product Base traceability | `docs/product/base/traceability.md` | 已实现 Flutter 能力事实、代码证据和测试证据 |
| V2 Capability registry | `docs/product/feature_registry.md` | 稳定 Capability、一级 Sub-capability、Legacy Mapping 和长期业务边界；不作为行为输入 |
| Roadmap / status | `docs/product/roadmap.md`, `docs/product/development_status.md` | P0/P0.1 并行主线和 P0.2/P1/P2 边界 |
| P0 商业化 | `docs/product/stages/p0-commercial-readiness.md`, `docs/product/increments/commercial-subscription-readiness/`, `docs/product/increments/commercial-ai-provider-hardening/` | 订阅、权益、账号、AI provider 生产化、合规、风控和发布门禁 |
| P0.1 训练闭环 | `docs/product/stages/p0-1-expression-automation.md`, `docs/product/increments/p0-1-expression-automation-training/` | session 内训练 planner、micro-action、hint、pressure check |
| P0.2 记忆编排 | `docs/product/stages/p0-2-training-memory.md` | future boundary，不进入当前实现 |
| 现有代码 | `lib/`, `assets/data/`, `test/` | Flutter 前端、服务调用和本地状态事实 |
| 现有契约草案 | `docs/domain/`, `docs/ai_runtime/`, `docs/ux/`, `docs/release/` | 下游契约和缺口识别 |
| SWC 架构基准 | `docs/architecture/software_component_architecture.md`, `docs/architecture/swc_catalog.md` | 完整 SWC 拓扑、稳定 Flow ID、组件目录和局部变更参考基准 |

## Scope Inventory
- Product Base：启动/登录/首评、官方双场景、听力热身、推荐表达、收藏、语音场景模拟、学习沉淀、个人中心、会员入口。
- Product Base traceability：Flutter APP 已具备 TTS、录音、ASR/转写、LLM 教练反馈、基础评分、个人 Wiki、Apple IAP 前端雏形；尚无真实商业订阅闭环、后端权益事实、生产账号闭环和数据库迁移。
- Active stages：P0 商业化订阅上线准备；P0.1 session 内表达自动化训练闭环。
- Planned/future boundaries：P0.2 跨 session 训练编排和记忆引擎；P1 笔记本、评分产品化、场景包扩展；P2 A1-C2 内容体系和 CMS。
- Commercial/release constraints：付费发布前必须具备服务端权益、支付校验、用量风控、账号删除、AI provider 生产化、审计日志、发布密钥、商店审核材料、测试矩阵和回滚路径。

## 能力 / 阶段 / 增量覆盖矩阵
| 对象类型 | 产品对象 | 前端模块 | 后端限界上下文 | 数据所有权 | API 契约 | AI runtime | 安全 / 合规 | 测试 / 发布门禁 | 覆盖结果 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product Base | Product Base | 现有 `lib/pages/*`, `lib/features/interview/*`, `lib/application/*` | Identity, Content, Training, Learning Evidence | 本地缓存保留；服务端逐步成为用户、训练和学习证据事实源 | `/auth`, `/user/me`, `/scenarios`, `/practice`, `/training`, `/learning` | 保持结构化输出和 fallback | token、音频、学习数据保护 | Product Base 回归、release checklist | Covered with backend contract gaps |
| Capability | `CAP-ACC` | `app_root`, login/profile/settings pages, session coordinators | Identity | User, AuthIdentity, UserProfile, OnboardingPreference, AccountLifecycle | `/auth/*`, `/user/me`, `/user/profile`, `/user/delete` | N/A | token、登录方式、隐私授权、账号删除 | 登录/session/profile/data-right 回归、生产配置 gate | Product Base covered; P0 hardening required |
| Capability | `CAP-LEVEL` | onboarding assessment、oral assessment、level/profile surfaces | Learner Profile, Assessment | OnboardingAssessment, LearnerLevelProfile, ScoreSignal refs | assessment/profile API family | AI/评分只产候选信号，等级与置信度由确定性规则接受 | 测评数据最小化、claim guard | 首评/复测/低置信降级测试 | Product Base baseline; P0.2 speaking diagnostic planned |
| Capability | `CAP-INTENT` | onboarding goal/preference、profile settings | Intent, Preference | GoalProfile, learning preferences, availability constraints | profile/goal/preference API family | AI 不拥有目标或偏好最终事实 | 偏好和目标隐私、变更审计 | 目标录入、修改、暂停和恢复测试 | Product Base partial; P0.2 extension planned |
| Capability | `CAP-PLAN` | home next-action、plan/checkpoint/queue surfaces | Planning, Review Scheduling | LearningRoute, PlanVersion, DailyPlan, ReviewSchedule, PracticeQueueItem, ReviewItem | `/review/due`, `/review/result`, `/training/tasks`, plan/checkpoint API family | LLM 可生成候选；计划版本、重算和调度由规则裁决 | 防止无来源计划项和越权内容 | plan/replan/review/checkpoint tests | P0.1 session-local support; P0.2 planned |
| Capability | `CAP-CONTENT` | home catalog、scenario/course pages、bundled assets | Content, Scenario | Scenario, ScenarioLevel, ScenarioVersion, ContentVersion, Course, TrainingObject, TrainingFlow | `/scenarios`, `/scenarios/{id}`, content/catalog API family | Prompt 只引用已审核、可追踪版本内容 | 内容版本、版权、付费内容 gate | 双场景回归、内容版本审核 | Product Base covered; P1/P2 expansion deferred |
| Capability | `CAP-PRACTICE` | listening page、audio service、interview practice page、practice engine/scheduler/runtime | Practice Session, AI Gateway | PracticeSession, DialogueTurn, PracticeAttempt, ShadowingAttempt, AudioAssetRef | `/training/shadowing`, `/ai/transcribe`, `/ai/pronunciation`, `/training/sessions`, `/training/sessions/{id}/turns` | schema validation、ASR/LLM fallback | 音频/转写保护、provider secret 后端化 | turn/session recovery、audio fallback、schema tests | Product Base covered; runtime refactor and provider hardening active/planned |
| Capability | `CAP-TRAIN` | training session、micro-action、hint/pressure UI | Training Planner, Training Runtime | TrainingSession, ActionChainStep, MicroAction, HintState, PlannerDecision | `/training/planner/next`, `/training/evidence`, training session/hint API family | prompt/schema 只产候选；节奏和状态由确定性 planner 裁决 | LLM 不直接写掌握状态 | planner unit、widget、AI eval | P0.1 in-scope blocker |
| Capability | `CAP-COACH` | feedback、correction、score explanation UI | Coach/Assessment, AI Gateway | ScoreSignal, FeedbackRecord, Correction | `/ai/pronunciation`, `/ai/feedback`, feedback/assessment API family | 结构化评分、纠错、解释和 fallback | provider cost、滥用控制、claim guard | score unavailable、invalid schema、explanation tests | Product Base baseline; production hardening pending |
| Capability | `CAP-MEMORY` | Wiki/store、home cards、profile reports | Learning Evidence, Review | LearningEvidence, MasteryRecord, LearningHistory, SessionSummary | `/learning/evidence`, `/review/due`, `/review/result`, mastery/history API family | AI 只生成证据候选；接受与掌握更新由规则裁决 | 个人学习数据 retention/deletion | evidence write-back、dedupe、删除回归 | Product Base covered; P0.2 extension planned |
| Capability | `CAP-NOTE` | favorites、personal Wiki、future notebook/search | Learning Assets | FavoriteExpression, SavedExpression, NotebookItem | favorites/personal-assets API family | Future prompt support only through approved increment | 个人资产导出、删除和来源追踪 | 收藏去重、资产管理、P1 独立测试 | Product Base partial; P1 expansion deferred |
| Capability | `CAP-COM` | membership、paywall、entitlement、purchase recovery UI | Commerce/Entitlement, Usage Control, Audit | Subscription, Purchase, EntitlementSnapshot, UsageLedger, AuditLog | `/subscriptions/apple/verify`, `/subscriptions/google/verify`, `/usage/*`, entitlement API family | AI quota 在服务端可信边界执行 | 收据校验、退款/过期/宽限期、审计 | 商业边界矩阵、sandbox、release secrets、回滚 | P0 in-scope blocker |
| Capability | `CAP-ENGAGE` | reminder settings、home reminders、future streak/recall surfaces | Engagement, Notification | NotificationPreference, ReminderEligibility, StreakState | notification/preference API family | AI 不拥有触达资格或渠道决策 | consent、quiet hours、退订和最小化 payload | 提醒资格、时区、退订和恢复测试 | Product Base preference baseline; P0.2/P1 extension planned |
| Stage | `p0-commercial-readiness` | 商业入口、会员、付费墙、账号与发布状态 | Identity, Commerce, Usage, AI Ops, Release | P0 商业事实集合 | P0 auth/subscription/entitlement/usage/account API families | provider 调用受 entitlement/usage gate | 支付、隐私、审计、商店与回滚 | P0 stage scope 与商业 release gate | Active stage summary |
| Increment | `commercial-subscription-readiness` | 会员页、付费墙、恢复购买、超限态、账号注销反馈 | Identity, Commerce/Entitlement, Usage Control, Admin/Ops | Subscription, Purchase, EntitlementSnapshot, UsageLedger, AccountDeletionJob, AuditLog | Auth、entitlement、subscription、usage、account deletion API family | AI/ASR/TTS/评分调用必须先过 entitlement 和 usage gate | 支付凭据后端校验、生产账号、数据删除、审计、release secrets | 商业边界测试矩阵、商店审核、rollback plan | In-scope blocker |
| Technical Support | AI provider / media / cost support（非 Capability） | 录音上传、TTS 播放消费、ops 成本查看 | AI Gateway, Media Storage, Usage Control, Admin/Ops | MediaAsset, TtsCacheEntry, ProviderInvocationMetric, ProviderSandboxRun, RetentionPolicy | Media upload/signing、AI Gateway、cost dashboard、admin evidence API | DashScope live evidence、schema/fallback、provider cost metric | 对象存储 ACL、signed URL TTL、hash-only audit、retention/deletion | AI provider sandbox、media/cache/deletion tests、budget gate | Cross-capability technical blocker |
| Increment | `commercial-ai-provider-hardening` | 录音上传路径、TTS cache 消费、Ops/PM 成本视图 | AI Gateway, Media Storage, Cache, Retention, Cost Dashboard | MediaAsset, TtsCacheEntry, ProviderInvocationMetric, RetentionPolicy | Future media/cost/admin API contract before implementation | LLM/ASR/TTS real provider compatibility and fallback evidence | 音频/转写/provider payload 保留删除、日志脱敏、secret/object storage | TC-COM-AI-001..007, DashScope evidence ref | Planned blocker |
| Stage | `p0-1-expression-automation` | session 内训练、micro-action、hint、pressure、recap | Training Planner, Learning Evidence, AI Gateway | TrainingSession, PlannerDecision, LearningEvidence | training/planner/feedback/evidence API families | schema 化候选与确定性 planner | 音频/转写、provider secret、无效 schema gate | P0.1 stage scope、planner/widget/AI eval | Active stage summary |
| Increment | `p0-1-expression-automation-training` | training session view 或改造 practice page、micro-action UI、recap | Training Planner, Learning Evidence, AI Gateway | TrainingSession, ActionChainStep, MicroAction, HintLevel, PlannerDecision, LearningEvidence | Training session、planner、hint、learning evidence、AI feedback API family | LLM 输出结构化候选；planner 裁决 retry/hint/pressure/evidence | 音频/转写保护、provider secrets 后端化、无效 schema 不写证据 | planner unit、AI schema eval、widget/fallback tests | In-scope blocker |
| Increment | `scenario-practice-runtime-migration` | current main practice path、shared runtime extraction、legacy sandbox isolation | Existing practice/content/AI owner contexts | No new business fact ownership | No API/OpenAPI behavior change | No prompt behavior change | Preserve current privacy/secret boundaries | MIG-TC-001..011、SWC allocation gate | Behavior-preserving architecture support; no Primary Capability |
| Stage | `p0-2-training-memory` | 目标、诊断、计划、自动带练、记忆、预测、检查点 | Intent, Assessment, Planning, Training, Memory | GoalProfile, DiagnosticAssessment, PlanVersion, LearningEvidence | P0.2 goal/diagnostic/plan/training/memory API families | AI 只产候选，策略与状态由确定性规则裁决 | 目标/音频/学习数据、通知和 claim guard | P0.2 stage scope 与独立 gates | Stage summary; increment rows below are authoritative delivery references |
| Increment | `p0-2-goal-diagnostic-foundation` | goal intake、diagnostic、baseline/profile surfaces | Intent, Assessment, Learner Profile | GoalProfile, DiagnosticAssessment, LearnerLevelProfile | goal/diagnostic/profile API families | diagnostic candidate + deterministic confidence/claim guard | goal/assessment privacy | owning AC/TC/traceability | Planned increment coverage |
| Increment | `p0-2-goal-backplan-memory-policy` | backplan、daily/weekly plan、memory policy surfaces | Planning, Memory | GoalBackplan, PlanVersion, ReviewSchedule, MemoryPolicy | plan/backplan/review API families | AI proposal + deterministic plan/memory policy | plan/evidence audit | owning AC/TC/traceability | Planned increment coverage |
| Increment | `p0-2-autopilot-progress-checkpoint` | autopilot control、progress、checkpoint/forecast | Training, Planning, Memory | AutopilotControl, ProgressCheckpoint, Forecast | training control/progress/checkpoint API families | AI candidate + deterministic control/forecast rules | notification/entitlement/claim guard | owning AC/TC/traceability | Planned increment coverage |
| Increment | `p0-2-followup-a-goal-intake-diagnostic-hardening` | hardened goal intake、diagnostic fallback | Intent, Assessment | GoalProfile, DiagnosticAssessment | goal intake/diagnostic API families | validated diagnostic candidate/fallback | consent、data rights、claim guard | owning AC/TC/traceability | Follow-up increment coverage |
| Increment | `p0-2-followup-b-autopilot-control-planner-memory` | planner control、pause/resume、memory handoff | Planning, Training, Memory, Engagement | PlanVersion, AutopilotControl, MemoryItem, ReminderEligibility | planner/control/memory/notification API families | deterministic control around AI candidates | reminder eligibility、audit | owning AC/TC/traceability | Follow-up increment coverage |
| Increment | `p0-2-followup-c-checkpoint-forecast-surfaces` | checkpoint、forecast、progress explanation surfaces | Planning, Memory, Learner Profile | ProgressCheckpoint, Forecast, LearningEvidence refs | checkpoint/forecast/progress API families | explanation candidate + deterministic facts | claim guard、evidence provenance | owning AC/TC/traceability | Follow-up increment coverage |
| Increment | `p0-2-followup-d-release-gate-hardening` | release、entitlement、retention、telemetry states | Commerce, Identity, AI Ops, Release | EntitlementSnapshot, UsageLedger, RetentionPolicy, AuditLog | entitlement/usage/admin/release support APIs | provider/cost telemetry only | privacy、retention、audit、release secrets | release/security/provider gates | Cross-capability support increment coverage |
| Increment | `p0-2-followup-e-speaking-diagnostic-production` | audio-first speaking diagnostic、text fallback | Assessment, Learner Profile, Media/AI support | DiagnosticAudioSample, SpeakingDiagnosticResult | media upload/diagnostic/result API families | ASR/scoring candidates + deterministic confidence downgrade | audio privacy、deletion、claim guard | audio/provider/fallback/release gates | Follow-up increment coverage |
| Future Boundary | P1/P2 content and CMS | 场景包、评分卡、CMS 后台后置 | Content Ops, Scoring Product | ContentPackage, Rubric, CEFRMapping | Future APIs | Future authoring/eval | 内容审核、版权、安全 | Future release gates | Explicitly deferred |

## Omitted-Scope List
| Type | Scope | Reason |
| --- | --- | --- |
| Explicitly deferred | P0.2 跨 session、跨天、跨场景训练编排和完整 L0-L5 | P0.1 只负责 session 内训练接管 |
| Explicitly deferred | P1 笔记本、任意短语/单词查询、评分产品化、3-5 个场景包 | 不阻塞 P0/P0.1 当前主线 |
| Explicitly deferred | P2 A1-C2 内容体系、CMS、内容生产工具 | 需要内容治理和运营能力后置 |
| Non-goal | 任意场景生成、公开社区、真人导师市场、课程市场 | 已被 roadmap 明确排除 |
| Non-goal | 把商业 gating 作为 P0.1 训练闭环前置条件 | P0 商业化与 P0.1 训练价值体验并行 |
| In-scope blocker | 后端工程、PostgreSQL schema、OpenAPI、AI schema、商业测试矩阵、release secrets gate、AI media lifecycle、persistent TTS cache、DashScope evidence、cost dashboard、AI data retention | 需要在实现前补齐下游契约 |

## Mainstream Option Comparison
| Area | Option A | Option B | Option C | Decision |
| --- | --- | --- | --- | --- |
| App architecture | 继续 Flutter 单体页面 | Flutter + feature/application/service 分层 | 原生 iOS/Android 双端 | 保持 Flutter 分层，避免重写双端 |
| Backend style | Client-only/local-first | BaaS/functions | Modular monolith | 推荐 modular monolith；client-only 无法承载支付/AI/审计可信边界 |
| Backend framework | Spring Boot | FastAPI | Node/NestJS | 推荐 Spring Boot 或同等强类型 modular backend；FastAPI 适合小团队快速原型但需补强治理 |
| Database | NoSQL document store | PostgreSQL | Polyglot persistence | 推荐 PostgreSQL 为主，JSONB 仅用于 provider raw payload 和低频扩展字段 |
| Async/cost control | 全同步 API | Queue/worker | Event streaming | P0 采用 managed queue/worker；Kafka 等 event streaming 后置 |
| AI runtime | 客户端直连 provider | 后端 AI Gateway | 独立 AI runtime service | P0/P0.1 推荐后端 AI Gateway；独立服务在规模化后拆分 |
| Deployment | 手动 VM | Managed container platform | Kubernetes | 推荐 managed container platform；Kubernetes 后置到团队有运维需求 |
| Observability | 只用日志 | Sentry + structured logs | OpenTelemetry + metrics/traces/logs | 推荐 Sentry + OpenTelemetry 逐步落地 |
| Release ops | 手动发包 | CI checklist | CI/CD + release gates + rollback | 推荐 CI/CD gate，付费发布必须阻断错误配置 |

## Recommended Stack And Trade-offs
| Layer | Recommendation | Trade-off |
| --- | --- | --- |
| Frontend | 保持 Flutter；继续使用 feature/application/service 分层；API client 由 OpenAPI 生成 | 需要约束页面内业务逻辑继续膨胀 |
| Backend | Spring Boot modular monolith 或同等强类型框架；模块按 bounded context 隔离 | 初期建设成本高于纯 BaaS |
| Database | PostgreSQL + Flyway/Liquibase migrations；JSONB 限于 raw provider payload、audit details 和低频扩展 | 需要认真建模核心实体，不能把业务事实都塞 JSON |
| Cache/queue | Redis 或托管缓存；托管队列/worker 处理支付 webhook、删除任务、AI 异步任务 | 增加运维组件，但能隔离重试和成本控制 |
| API | OpenAPI-first；统一 error schema、request_id、idempotency key、schema_version | 需要维护契约和生成客户端 |
| AI runtime | Backend-owned AI Gateway；LLM 输出 schema 校验；deterministic planner 决策；生产化阶段补对象存储 media refs、persistent TTS cache 和 provider cost metrics | 比客户端直连慢一步，但可审计、可限流、可降级、可控成本 |
| Security | 服务端拥有 provider/payment secrets；客户端只持短期 token 和展示缓存 | 需要补生产账号和 token 刷新 |
| Observability | Sentry for Flutter + backend structured logs + OpenTelemetry traces/metrics/logs | 需要定义 request_id 和 trace propagation |
| Release | CI/CD release gates、商业边界测试矩阵、商店配置检查、回滚计划 | 发布前工作量增加，但能阻断付费事故 |

## Architecture Summary
- Frontend：Flutter 保持现有主流程，新增或收敛训练 session UI、付费墙、权益刷新、超限态、账号删除反馈；本地存储只作为缓存和离线兜底。
- Backend：以 modular monolith 建立 Identity、Commerce/Entitlement、Usage Control、Content/Scenario、Training Planner、Learning Evidence、AI Gateway、Admin/Ops 上下文。
- Database：PostgreSQL 保存用户、订阅、权益、用量、训练 session、学习证据、审计和删除任务；通过 migration 管控 schema 演进。
- API：OpenAPI-first，Dart client generated，所有跨层变更先更新契约。
- AI runtime：LLM、ASR、TTS、评分全部通过后端可信边界，schema validation 和 fallback 先于 UI 渲染；paid AI voice 还必须具备对象存储上传、持久化 TTS cache、真实 provider evidence、成本看板和数据保留删除证据。
- Security：支付凭据、provider keys、AI quota、审计和数据删除均在服务端执行。
- Observability：客户端 crash/performance、后端 request logs、trace、metrics 统一 request_id/trace_id。
- Release operations：付费发布前必须完成商业边界测试矩阵、release secrets gate、商店元数据、回滚计划和质量报告。

## Architecture Acceptance Gate
本架构可以作为后续契约补齐的候选方案，但不能直接启动实现。进入实现前必须补齐：
- P0 commercial subscription：Domain Schema、API Contract、Architecture/Security、UX、QA/Test Plan、DevOps/Release。
- P0 commercial AI provider hardening：Media/Storage/API/Security、AI Runtime sandbox matrix、Cost Dashboard、Retention/Deletion、QA/Test Plan、DevOps/Release。
- P0.1 training：Training domain model、AI prompt/schema、dialogue state machine、screen spec、planner tests。
- `document-traceability-check` 和 Product Object Governance Check Agent 均返回 pass。

- P0 commercial subscription：需要补齐 Domain Schema、API Contract、Architecture/Security、UX、QA/Test Plan、DevOps/Release。
- P0 commercial AI provider hardening：需要补齐 Media/Storage/API/Security、AI Runtime sandbox matrix、Cost Dashboard、Retention/Deletion、QA/Test Plan、DevOps/Release。
- P0.1 training：需要补齐 Training domain model、AI prompt/schema、dialogue state machine、screen spec、planner tests。
- `document-traceability-check` 和 Product Object Governance Check Agent 都必须返回 pass。

## P0.1 Training Increment Architecture Gate

Architecture scope mode: `increment` for `docs/product/increments/p0-1-expression-automation-training/`。

架构范围模式：`increment`，适用于 `docs/product/increments/p0-1-expression-automation-training/`。

| Stage Scope ID | Architecture boundary | Evidence path | Gate status |
| --- | --- | --- | --- |
| P01-SI-001 | Training entry is limited to `job_interview` and `onboarding_introduction`; unsupported scenes fail closed in UX | `docs/ux/screen_spec.md`, `docs/architecture/module_boundary.md` | Contract-ready |
| P01-SI-002 | Deterministic Training Planner owns next action, retry, hint, pressure and recap decisions | `docs/domain/training_model.md`, ADR 0004, `docs/architecture/module_boundary.md` | Contract-ready |
| P01-SI-003 | Action chain is content/domain input, not LLM-generated scope | `docs/domain/training_model.md`, `docs/domain/entity_relationship.md` | Contract-ready |
| P01-SI-004 | Micro-action UI renders one active action; planner/application module owns state transition | `docs/ux/screen_spec.md`, `docs/architecture/module_boundary.md` | Contract-ready |
| P01-SI-005 | Hint ladder is domain state rendered by UI; AI may propose hint wording only | `docs/domain/training_model.md`, `docs/ai_runtime/llm_output_schema.md` | Contract-ready |
| P01-SI-006 | Pressure check is session-only and cannot become P0.2 cross-day scheduling | `docs/domain/training_model.md`, `docs/ux/user_flow.md` | Contract-ready |
| P01-SI-007 | Voice-first path uses existing audio/ASR boundary with text fallback only for failure/debug | `docs/ux/screen_spec.md`, `docs/ai_runtime/fallback_strategy.md` | Contract-ready |
| P01-SI-008 | AI runtime returns schema-valid candidate feedback; planner rules decide final progression | `docs/ai_runtime/prompt_contract.md`, `docs/ai_runtime/llm_output_schema.md`, ADR 0004 | Contract-ready |
| P01-SI-009 | Learning evidence write-back requires accepted rule output and recap preservation | `docs/domain/training_model.md`, `docs/architecture/module_boundary.md` | Contract-ready |
| P01-SI-010 | Non-goals remain blocked at architecture boundary | `docs/product/stages/p0-1-expression-automation.md`, `docs/product/increments/p0-1-expression-automation-training/acceptance.md` | Contract-ready |
| P01-SI-011 | Recoverable failures preserve session/input/recap and return to previous valid state or retry | `docs/ai_runtime/fallback_strategy.md`, `docs/ux/screen_spec.md` | Contract-ready |

P0.1-ARCH-001 结论：increment 级 architecture/module boundary 已建立。实现路由仍必须等待 `docs/product/increments/p0-1-expression-automation-training/test_cases.md` 建立并通过 AC-to-TC gate。

## P0 Commercial Stage Architecture Gate

Architecture scope mode: `stage` for `docs/product/stages/p0-commercial-readiness.md` and increment `commercial-subscription-readiness`.

架构范围模式：`stage`，适用于 `docs/product/stages/p0-commercial-readiness.md` 和 increment `commercial-subscription-readiness`。

| Stage Scope ID | Architecture boundary | Evidence path | Gate status |
| --- | --- | --- | --- |
| COM-SI-001 | Commerce/Entitlement backend owns subscription and entitlement facts | `docs/domain/domain_schema.md`, `docs/architecture/api_contract.md`, ADR 0003 | Contract-ready |
| COM-SI-002 | Apple verify/restore/webhook are backend/provider boundaries, not client entitlement facts | `docs/architecture/api_contract.md`, `docs/architecture/data_flow.md` | Contract-ready; provider sandbox evidence pending |
| COM-SI-003 | Google Play Billing uses client purchase token submission plus backend verification | `docs/architecture/api_contract.md`, `docs/architecture/data_flow.md` | Contract-ready; Play internal test evidence pending |
| COM-SI-004 | Identity backend owns login/session/token and release disables test login | `docs/architecture/module_boundary.md`, `docs/architecture/security_design.md` | Contract-ready; release gate pending |
| COM-SI-005 | Social login production config is a platform/release boundary with backend token verification | `docs/architecture/security_design.md`, `docs/architecture/api_contract.md` | Contract-ready; platform config evidence pending |
| COM-SI-006 | Account deletion is an Identity/Admin/Ops state machine with local cleanup requirements | `docs/domain/domain_schema.md`, `docs/architecture/data_flow.md` | Contract-ready |
| COM-SI-007 | Entitlement and usage gates protect paid features and high-cost calls | ADR 0003, `docs/architecture/module_boundary.md` | Contract-ready |
| COM-SI-008 | Scenario gating uses EntitlementRule and must be consistent across list/detail/training entry | `docs/domain/entity_relationship.md`, `docs/ux/screen_spec.md` | Contract-ready |
| COM-SI-009 | Commercial copy consistency is a UX/release gate tied to SubscriptionPlan and EntitlementRule | `docs/ux/copywriting_guideline.md`, `docs/release/release_checklist.md` | Contract-ready; release evidence pending |
| COM-SI-010 | Usage Control reserves/commits/releases quota before provider calls | `docs/domain/domain_schema.md`, `docs/architecture/api_contract.md`, `docs/architecture/security_design.md` | Contract-ready |
| COM-SI-011 | Commercial boundary testing is a QA gate across provider, account, network and quota states | `docs/product/increments/commercial-subscription-readiness/test_cases.md` | Test design ready after P0-COM-QA-001 |
| COM-SI-012 | Release readiness is Admin/Ops + DevOps, including secrets, signing, symbols and rollback | `docs/architecture/security_design.md`, `docs/release/rollback_plan.md` | Contract-ready; DevOps evidence pending |

P0-COM-ARCH-001 结论：stage 级架构覆盖矩阵已建立；它允许进入测试用例库和后续实现路由，但不等同于支付 provider、DevOps release 或商业发布 ready。

## ADR Index
- `docs/architecture/adr/0002-whole-app-architecture-stack.md`
- `docs/architecture/adr/0003-server-owned-entitlement-and-usage.md`
- `docs/architecture/adr/0004-deterministic-training-planner-ai-boundary.md`

## External Reference Notes
- Spring Boot Actuator provides production observability and management endpoints, and Spring documents OpenTelemetry/Micrometer integration.
- PostgreSQL supports structured relational modeling plus `jsonb` for indexed semi-structured payloads when used selectively.
- OpenTelemetry is a vendor-neutral observability framework for traces, metrics, and logs.
- Sentry provides Flutter error and performance monitoring.
- Cloud Run is a managed container platform with request-based autoscaling; equivalent managed container platforms are acceptable if release gates and observability are preserved.

- Spring Boot Actuator 提供 production observability 和 management endpoints，Spring 也记录了 OpenTelemetry/Micrometer integration。
- PostgreSQL 支持 structured relational modeling；在选择性使用时，`jsonb` 可承载带索引的 semi-structured payloads。
- OpenTelemetry 是 vendor-neutral observability framework，覆盖 traces、metrics 和 logs。
- Sentry 提供 Flutter error 和 performance monitoring。
- Cloud Run 是带 request-based autoscaling 的 managed container platform；只要保留 release gates 和 observability，也可以使用等价的 managed container platforms。
