# Whole-App System Overview

## 状态
Proposed - whole-app architecture。本文基于 PM execution brief 进入第二轮架构产物更新，必须在 `document-traceability-check` 和 Product Object Governance Check Agent 通过后，才能作为下游实现依据。

## 架构范围模式
`whole-app`。范围覆盖 Product Base、feature registry、P0 商业化订阅上线准备、P0.1 表达自动化训练、P0.2/P1/P2 未来边界和明确非目标。

## Source Inventory
| 来源 | 路径 | 架构用途 |
| --- | --- | --- |
| Product Base | `docs/product/base/` | 稳定 MVP 能力和回归边界 |
| Product Base traceability | `docs/product/base/traceability.md` | 已实现 Flutter 能力事实、代码证据和测试证据 |
| Feature registry | `docs/product/feature_registry.md` | 稳定 feature、planned feature 和长期边界 |
| Roadmap / status | `docs/product/roadmap.md`, `docs/product/development_status.md` | P0/P0.1 并行主线和 P0.2/P1/P2 边界 |
| P0 商业化 | `docs/product/stages/p0-commercial-readiness.md`, `docs/product/increments/commercial-subscription-readiness/` | 订阅、权益、账号、合规、风控和发布门禁 |
| P0.1 训练闭环 | `docs/product/stages/p0-1-expression-automation.md`, `docs/product/increments/p0-1-expression-automation-training/` | session 内训练 planner、micro-action、hint、pressure check |
| P0.2 记忆编排 | `docs/product/stages/p0-2-training-memory.md` | future boundary，不进入当前实现 |
| 现有代码 | `lib/`, `assets/data/`, `test/` | Flutter 前端、服务调用和本地状态事实 |
| 现有契约草案 | `docs/domain/`, `docs/ai_runtime/`, `docs/ux/`, `docs/release/` | 下游契约和缺口识别 |

## Scope Inventory
- Product Base：启动/登录/首评、官方双场景、听力热身、推荐表达、收藏、语音场景模拟、学习沉淀、个人中心、会员入口。
- Product Base traceability：Flutter APP 已具备 TTS、录音、ASR/转写、LLM 教练反馈、基础评分、个人 Wiki、Apple IAP 前端雏形；尚无真实商业订阅闭环、后端权益事实、生产账号闭环和数据库迁移。
- Active stages：P0 商业化订阅上线准备；P0.1 session 内表达自动化训练闭环。
- Planned/future boundaries：P0.2 跨 session 训练编排和记忆引擎；P1 笔记本、评分产品化、场景包扩展；P2 A1-C2 内容体系和 CMS。
- Commercial/release constraints：付费发布前必须具备服务端权益、支付校验、用量风控、账号删除、审计日志、发布密钥、商店审核材料、测试矩阵和回滚路径。

## Feature / Stage Coverage Matrix
| Product object | Frontend modules | Backend bounded context | Data ownership | API contract | AI runtime | Security / compliance | Tests / release gate | Coverage result |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Product Base | 现有 `lib/pages/*`, `lib/features/interview/*`, `lib/application/*` | Identity, Content, Training, Learning Evidence | 本地缓存保留；服务端逐步成为用户、训练和学习证据事实源 | `/auth`, `/user/me`, `/scenarios`, `/practice|training`, `/learning` | 保持结构化输出和 fallback | token、音频、学习数据保护 | Product Base 回归、release checklist | Covered with backend contract gaps |
| `access-onboarding` | `app_root`, `login_page`, `onboarding_page`, session coordinators | Identity | User, Profile, OnboardingPreference | `/auth/*`, `/user/me`, `/user/profile` | N/A | 登录 token、测试登录发布门禁、账号删除 | 登录/首评路由测试、生产配置 gate | Covered, P0 hardening required |
| `official-scenario-library` | `home_page`, scenario/interview pages, assets | Content/Scenario | Scenario, ScenarioLevel, ContentVersion | `/scenarios`, `/scenarios/{id}` | P0.1 训练 prompt 只引用已审核场景 | 官方内容版本、付费场景 gating | 双场景回归、内容版本审核 | Covered, P1/P2 expansion deferred |
| `listening-shadowing` | listening page, audio service | Training, AI Gateway | ShadowingAttempt, AudioAssetRef | `/training/shadowing`, `/ai/transcribe`, `/ai/pronunciation` | ASR/评分失败可降级 | 音频 retention、provider secrets 后端化 | 音频失败回归、外部服务人工验收 | Covered, provider boundary needed |
| `expression-practice-queue` | expression queue/coordinator/pages | Training Planner, Review | PracticeQueueItem, ReviewItem | `/review/due`, `/training/tasks` | P0.1 可用结构化建议生成任务候选 | 防止无来源任务和越权内容 | queue 生成/去重测试 | Covered, planner contract needed |
| `voice-scenario-practice` | interview practice page, engine, scheduler | Training Session, AI Gateway | PracticeSession, DialogueTurn, Correction | `/training/sessions`, `/training/sessions/{id}/turns` | LLM 只返回 schema 化反馈和下一步候选 | 音频、转写、敏感对话脱敏 | 会话恢复、schema/fallback 测试 | Covered, P0.1 refactor needed |
| `expression-automation-training` | 新 training session view 或改造 practice page | Training Planner | ActionChainStep, MicroAction, HintLevel, PlannerDecision, LearningEvidence | `/training/planner/next`, `/training/evidence` | prompt/schema 支持 hint、retry、pressure prompt | LLM 不直接写掌握状态 | planner unit、widget、AI eval | In-scope blocker |
| `learning-memory-review` | Wiki/store, home cards, profile results | Learning Evidence, Review | LearningEvidence, MasteryRecord, ReviewSchedule | `/learning/evidence`, `/review/due`, `/review/result` | P0.1 只生成候选证据；P0.2 长期调度后置 | 个人学习数据 retention/deletion | evidence write-back 和删除回归 | Covered for Product Base, P0.2 deferred |
| `scoring-feedback` | oral assessment service, shadow scoring, feedback UI | AI Gateway, Training | ScoreSignal, FeedbackRecord | `/ai/pronunciation`, `/ai/feedback` | 评分不作为唯一通关条件 | provider cost、滥用控制 | score unavailable fallback | Covered, P1 score productization deferred |
| `profile-membership` | profile/membership/settings pages | Commerce/Entitlement, Identity | EntitlementSnapshot, AccountLifecycle | `/entitlements`, `/subscriptions/*`, `/user/delete` | 权益不足时 AI 调用降级 | 支付、账号删除、文案一致性 | 商业边界测试矩阵 | In-scope blocker |
| `commercial-subscription` | 付费墙、权益刷新、超限态、恢复购买 UI | Commerce/Entitlement, Usage Control, Audit | Subscription, Purchase, Entitlement, UsageLedger, AuditLog | `/subscriptions/apple/verify`, `/subscriptions/google/verify`, `/usage/*` | AI quota 在可信边界执行 | 收据校验、退款/过期/宽限期、审计 | 沙盒/内测、release secrets、回滚 | In-scope blocker |
| `commercial-subscription-readiness` increment | 会员页、付费墙、恢复购买、超限态、账号注销反馈 | Identity, Commerce/Entitlement, Usage Control, Admin/Ops | Subscription, Purchase, EntitlementSnapshot, UsageLedger, AccountDeletionJob, AuditLog | Auth、entitlement、subscription、usage、account deletion API family | AI/ASR/TTS/评分调用必须先过 entitlement 和 usage gate | 支付凭据后端校验、生产账号、数据删除、审计、release secrets | 商业边界测试矩阵、商店审核、rollback plan | In-scope blocker |
| `notebook-vocabulary` | 未来 notebook/search UI | Notebook/Learning Assets | NotebookItem, VocabularyLookup | Future API | Future prompt support | Future data retention | P1 独立测试 | Explicitly deferred |
| `p0-1-expression-automation-training` increment | training session view 或改造 practice page、micro-action UI、recap | Training Planner, Learning Evidence, AI Gateway | TrainingSession, ActionChainStep, MicroAction, HintLevel, PlannerDecision, LearningEvidence | Training session、planner、hint、learning evidence、AI feedback API family | LLM 输出结构化候选；planner 裁决 retry/hint/pressure/evidence | 音频/转写保护、provider secrets 后端化、无效 schema 不写证据 | planner unit、AI schema eval、widget/fallback tests | In-scope blocker |
| P0.2 memory stage | 首页推荐、表达队列、Wiki 延展 | Long-term Planner | DailyPlan, MasteryLadder, CrossSessionSchedule | Future `/training/daily-plan` | LLM 不拥有最终 mastery | 记忆调度审计 | P0.2 独立 gate | Explicitly deferred |
| P1/P2 content and CMS | 场景包、评分卡、CMS 后台后置 | Content Ops, Scoring Product | ContentPackage, Rubric, CEFRMapping | Future APIs | Future authoring/eval | 内容审核、版权、安全 | Future release gates | Explicitly deferred |

## Omitted-Scope List
| Type | Scope | Reason |
| --- | --- | --- |
| Explicitly deferred | P0.2 跨 session、跨天、跨场景训练编排和完整 L0-L5 | P0.1 只负责 session 内训练接管 |
| Explicitly deferred | P1 笔记本、任意短语/单词查询、评分产品化、3-5 个场景包 | 不阻塞 P0/P0.1 当前主线 |
| Explicitly deferred | P2 A1-C2 内容体系、CMS、内容生产工具 | 需要内容治理和运营能力后置 |
| Non-goal | 任意场景生成、公开社区、真人导师市场、课程市场 | 已被 roadmap 明确排除 |
| Non-goal | 把商业 gating 作为 P0.1 训练闭环前置条件 | P0 商业化与 P0.1 训练价值体验并行 |
| In-scope blocker | 后端工程、PostgreSQL schema、OpenAPI、AI schema、商业测试矩阵、release secrets gate | 需要在实现前补齐下游契约 |

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
| AI runtime | Backend-owned AI Gateway；LLM 输出 schema 校验；deterministic planner 决策 | 比客户端直连慢一步，但可审计、可限流、可降级 |
| Security | 服务端拥有 provider/payment secrets；客户端只持短期 token 和展示缓存 | 需要补生产账号和 token 刷新 |
| Observability | Sentry for Flutter + backend structured logs + OpenTelemetry traces/metrics/logs | 需要定义 request_id 和 trace propagation |
| Release | CI/CD release gates、商业边界测试矩阵、商店配置检查、回滚计划 | 发布前工作量增加，但能阻断付费事故 |

## Architecture Summary
- Frontend：Flutter 保持现有主流程，新增或收敛训练 session UI、付费墙、权益刷新、超限态、账号删除反馈；本地存储只作为缓存和离线兜底。
- Backend：以 modular monolith 建立 Identity、Commerce/Entitlement、Usage Control、Content/Scenario、Training Planner、Learning Evidence、AI Gateway、Admin/Ops 上下文。
- Database：PostgreSQL 保存用户、订阅、权益、用量、训练 session、学习证据、审计和删除任务；通过 migration 管控 schema 演进。
- API：OpenAPI-first，Dart client generated，所有跨层变更先更新契约。
- AI runtime：LLM、ASR、TTS、评分全部通过后端可信边界，schema validation 和 fallback 先于 UI 渲染。
- Security：支付凭据、provider keys、AI quota、审计和数据删除均在服务端执行。
- Observability：客户端 crash/performance、后端 request logs、trace、metrics 统一 request_id/trace_id。
- Release operations：付费发布前必须完成商业边界测试矩阵、release secrets gate、商店元数据、回滚计划和质量报告。

## Architecture Acceptance Gate
本架构可以作为后续契约补齐的候选方案，但不能直接启动实现。进入实现前必须补齐：
- P0 commercial：Domain Schema、API Contract、Architecture/Security、UX、QA/Test Plan、DevOps/Release。
- P0.1 training：Training domain model、AI prompt/schema、dialogue state machine、screen spec、planner tests。
- `document-traceability-check` 和 Product Object Governance Check Agent 均返回 pass。

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
