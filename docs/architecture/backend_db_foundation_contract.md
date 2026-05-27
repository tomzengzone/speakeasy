# Backend / DB / Foundation Contract

## 状态
Proposed - P0/P0.1 共同技术前置。

本文定义 P0 商业化订阅上线准备与 P0.1 表达自动化训练闭环共享的后端、数据库和契约基础边界。它不是新产品 feature，不新增用户可见范围，不替代 Domain Schema、API Contract/OpenAPI、AI Runtime、UX、QA 或 DevOps 后续产物。本文通过 `document-traceability-check` 和 Product Object Governance Check Agent 复核前，不得作为实现开工依据。

## 架构范围模式
`increment` 范围内的 cross-increment foundation contract。覆盖两个已接受增量：

- `commercial-subscription-readiness`
- `p0-1-expression-automation-training`

本文不是 `whole-app` 架构重写，只落地 whole-app 架构中已确认的共同前置：Flutter client + modular backend + PostgreSQL + backend-owned AI/payment/security boundary。

## 上游依据
| 来源 | 路径 | 用途 |
| --- | --- | --- |
| PM handoff | `.codex_tmp_remote_patch/agent-handoffs/foundation_contract_pm_brief.md` | 确认本轮是 P0/P0.1 共同技术前置，不是新 feature |
| 当前基线 | `docs/product/baselines/current-mvp.md` | 确认当前是 Flutter APP，已有会员入口和本地学习闭环，但无真实后端/DB |
| Feature registry | `docs/product/feature_registry.md` | 确认受影响 feature 与 P0/P0.1 边界 |
| P0 stage | `docs/product/stages/p0-commercial-readiness.md` | 确认商业化账号、订阅、权益、用量、合规、发布门禁 |
| P0.1 stage | `docs/product/stages/p0-1-expression-automation.md` | 确认 session 内 planner、micro-action、hint、学习证据写回 |
| P0 traceability | `docs/product/increments/commercial-subscription-readiness/traceability.md` | 确认商业 Domain/API/Architecture/Security/QA/DevOps 仍待补 |
| P0.1 traceability | `docs/product/increments/p0-1-expression-automation-training/traceability.md` | 确认 TrainingSession、PlannerDecision、LearningEvidence 等契约仍待补 |
| Whole-app architecture | `docs/architecture/system_overview.md` | 继承推荐架构和缺口分类 |
| Module boundary | `docs/architecture/module_boundary.md` | 继承前后端、AI、数据事实源职责切分 |
| API contract | `docs/architecture/api_contract.md` | 继承 API-first、统一 error schema、generated Dart client 缺口 |
| Data flow | `docs/architecture/data_flow.md` | 继承支付、用量、训练、删除和观测流程边界 |
| Security design | `docs/architecture/security_design.md` | 继承 provider/payment secrets、用量、删除和日志安全边界 |
| Domain schema draft | `docs/domain/domain_schema.md` | 确认现有领域草案尚未覆盖 P0/P0.1 关键对象 |

## Scope Inventory
本 foundation contract 只覆盖下列基础决策：

1. backend 工程边界：未来后端工程的模块、层次、可信边界，以及与 Flutter 的责任切分。
2. PostgreSQL / migration 策略：数据库事实源、迁移治理、审计和删除任务边界。
3. OpenAPI source-of-truth：契约源文件、owner、breaking change 和 CI drift check。
4. generated Dart client policy：生成代码边界、手写例外、版本同步和错误模型。
5. 服务端事实源边界：用户、权益、用量、训练 session、学习证据。

## Omitted-Scope List
| Scope | 分类 | 原因 |
| --- | --- | --- |
| 修改 Flutter 业务代码或 Flutter 工程配置 | Non-goal | 本轮只产出架构文档正文 |
| 创建后端工程目录、Spring/FastAPI/NestJS 项目或部署配置 | Non-goal | 需等 foundation contract 和复核通过后进入实现计划 |
| 编写 PostgreSQL migration SQL | Non-goal | migration 需等 Domain Schema 通过后生成 |
| 创建 OpenAPI 实体文件 | Non-goal | OpenAPI 需等 Domain Schema 通过后进入 API Contract 阶段 |
| 定义 subscription、entitlement、usage、planner、learning evidence 的完整字段 | Explicitly deferred | 下一步 Domain Schema 负责 |
| 定义 P0/P0.1 endpoint request/response 细节 | Explicitly deferred | API Contract/OpenAPI 阶段负责 |
| 编写 AI prompt/schema/eval | Explicitly deferred | AI Runtime 阶段负责 |
| 设计训练页面 UX、付费墙 UX、错误态 UX | Explicitly deferred | UX/Screen Spec 阶段负责 |
| 编写 QA 测试矩阵或 DevOps release workflow | Explicitly deferred | QA、DevOps 阶段负责 |
| P0.2 跨 session 记忆编排、P1/P2 内容/CMS/评分产品化 | Explicitly deferred | 不属于 P0/P0.1 foundation contract |

## Backend 工程边界

### 推荐工程形态
后续实现推荐建立 modular backend，而不是把支付、AI、训练和学习证据继续放在 Flutter 本地逻辑中。推荐形态仍遵循 whole-app architecture：

```text
backend/
  api layer
    -> application services
    -> domain modules
    -> infrastructure adapters
    -> persistence / providers / workers
```

后端可以采用 Spring Boot modular monolith，或同等强类型、模块化、可观测的后端框架。当前 foundation contract 不创建工程，不锁死具体脚手架；但无论采用哪种框架，都必须满足以下边界：

- API-first：跨端契约从 OpenAPI 开始。
- PostgreSQL-first：核心业务事实由关系模型和 migration 管控。
- Backend-owned trust boundary：支付、权益、用量、provider secrets、审计、账号删除由服务端拥有。
- Deterministic domain rules：权益、用量、训练推进、学习证据写入不能由客户端或 LLM 自由决定。
- Observable operations：`request_id`、`trace_id`、结构化日志、错误统计和发布门禁必须在基础设计中保留。

### 后端分层
| 层 | 职责 | 禁止事项 |
| --- | --- | --- |
| API layer | 认证、DTO、OpenAPI schema、错误码、`request_id`、`idempotency_key` | 不承载复杂业务规则 |
| Application services | 编排购买校验、权益刷新、用量预留/提交、训练回合、学习证据写回、账号删除 | 不直接拼 SQL 或泄露 provider payload 给客户端 |
| Domain modules | 保存实体生命周期、状态机、规则和不变量 | 不依赖 Flutter 本地状态作为最终事实 |
| Infrastructure adapters | Apple/Google、LLM/ASR/TTS/评分 provider、对象存储、队列、缓存 | 不把 provider secret 暴露给客户端 |
| Persistence repositories | PostgreSQL 读写、事务边界、锁、查询优化 | 不绕过 migration 修改 schema |
| Worker / Ops jobs | 支付 webhook、账号删除、provider 重试、审计修复 | 不作为用户体验主入口 |

### Bounded Context 初始边界
| Context | P0/P0.1 责任 | Server fact-source |
| --- | --- | --- |
| Identity | 登录、token、用户资料、测试登录发布门禁、账号删除入口 | User、AuthIdentity、AccountLifecycle |
| Commerce / Entitlement | Apple/Google 校验、订阅状态、退款/过期/宽限期、权益快照 | Subscription、Purchase、EntitlementSnapshot |
| Usage Control | AI/ASR/TTS/评分 quota、reserve/commit/release、速率限制、滥用检测 | UsageLedger、UsageReservation、ProviderUsageEvent |
| Content / Scenario | 官方场景、内容版本、场景权益 gating | Scenario、ScenarioVersion |
| Training Session | session 生命周期、turn 提交、恢复、完成 | TrainingSession、TrainingTurn |
| Training Planner | session 内 action chain、micro-action、hint、retry、pressure decision | PlannerDecision、ActionChainStep、HintState |
| Learning Evidence | 学习证据、掌握/薄弱候选、复习触发依据 | LearningEvidence、EvidenceRuleTrace |
| AI Gateway | LLM/ASR/TTS/评分 provider routing、schema validation、fallback、成本观测 | ProviderRequestLog、AIResultRef |
| Admin / Ops | 审计、删除任务、发布健康、人工重试 | AuditLog、AccountDeletionJob |

### 与 Flutter 的责任切分
| 领域 | Flutter 可做 | 服务端必须拥有 |
| --- | --- | --- |
| 用户 | 登录 UI、token 展示状态、profile cache | 用户身份、token refresh/logout、账号删除状态 |
| 权益 | 购买入口、恢复购买入口、权益展示缓存、超限态展示 | 购买校验、权益快照、退款/过期/宽限期处理 |
| 用量 | 展示剩余额度、处理超限 UI、请求重试 | quota 计算、reserve/commit/release、滥用检测 |
| 训练 session | 渲染当前动作、录音/播放、本地恢复草稿 | session 状态、turn 事实、planner decision |
| 学习证据 | 展示、离线缓存、失败重试提示 | evidence 接收、去重、rule trace、最终 mastery 更新 |
| AI provider | 采集音频、展示反馈、展示 fallback | provider secrets、调用、schema validation、成本观测 |
| 数据删除 | 展示确认和结果、本地清理 | 删除 job、云端删除/匿名化、审计 |

## PostgreSQL / Migration 策略

### 数据库定位
PostgreSQL 是 P0/P0.1 服务端业务事实源。JSONB 只允许用于 provider raw payload 摘要、audit details、低频扩展字段或第三方事件原文索引，不得替代核心业务实体建模。

### 初始 schema 分区方向
| Schema / table group | 负责上下文 | 说明 |
| --- | --- | --- |
| `identity_*` | Identity | users、auth_identities、sessions、account_lifecycle |
| `commerce_*` | Commerce / Entitlement | subscription_plans、purchases、subscriptions、entitlement_snapshots、payment_events |
| `usage_*` | Usage Control | usage_ledgers、usage_reservations、provider_usage_events、rate_limit_events |
| `content_*` | Content / Scenario | scenarios、scenario_versions、scenario_access_rules |
| `training_*` | Training Session / Planner | training_sessions、training_turns、planner_decisions、action_chain_steps |
| `learning_*` | Learning Evidence | learning_evidence、mastery_records、review_items、evidence_rule_traces |
| `ops_*` | Admin / Ops | audit_logs、account_deletion_jobs、release_health_events |

最终表名和字段不在本文定稿，必须由下一步 Domain Schema 定义。

### Migration 工具和版本规则
后续后端工程应使用 Flyway、Liquibase 或同等 migration 工具。若采用 Spring Boot，优先使用 Flyway 或 Liquibase 与 CI/CD 集成。

基础规则：

- 所有 schema 变更必须通过 versioned migration。
- 禁止在生产数据库手工改表后再补 migration。
- 一个 migration 应对应一个清晰领域变更或一次可审查的兼容变更。
- 命名应可排序、可追踪，例如 `V202605260001__create_identity_foundation.sql`。
- destructive migration 必须先有备份、回滚或双写/迁移窗口方案。
- seed/test data 与 production migration 分离。
- migration PR 必须说明关联 Domain Schema、API Contract 和回滚影响。
- migration 执行结果必须进入 release evidence 或 deployment log。

### 事务和一致性原则
| 流程 | 事务边界 |
| --- | --- |
| 购买校验 | provider verify 成功后，同一事务写 Purchase、Subscription projection、EntitlementSnapshot、AuditLog |
| 支付 webhook | 使用 provider event id 去重，幂等更新 subscription state |
| 用量 reserve/commit/release | reserve 创建冻结额度；commit 确认消耗；provider 失败按规则 release 或标记 failed |
| training turn | turn 写入、planner decision、AI result ref、learning evidence candidate 保持可追踪关联 |
| evidence write-back | 只由 deterministic evidence rules 写入 accepted evidence，保留 source turn 和 rule trace |
| account deletion | 删除 job 独立状态机，按数据类别删除或匿名化，失败可重试并审计 |

### 审计、删除和保留
- Payment audit 保留最小必要字段，避免记录完整 receipt 或敏感凭据。
- Provider logs 只保留 `request_id`、provider、latency、status、schema version、cost class，不记录 raw audio 或完整敏感对话。
- Audio/transcript retention 需在后续 Security / DevOps 阶段定义具体时长。
- Account deletion job 必须定义 hard delete、anonymize、retain-for-audit 三类处理策略。
- Learning evidence 删除或匿名化不得破坏剩余审计日志的合规可读性。

## OpenAPI Source-of-Truth

### 契约源文件
后续 API Contract 阶段应创建唯一 OpenAPI source-of-truth。建议路径：

`docs/architecture/openapi/speakeasy-api.yaml`

该文件创建前，本文只定义策略，不创建 OpenAPI 实体文件。

### Owner 和变更原则
| 项 | 决策 |
| --- | --- |
| Source of truth | OpenAPI 文件，而不是后端 controller 或 Flutter 手写 client |
| Owner | API Contract / Backend owner，System Architect 维护边界原则 |
| Downstream consumers | Backend implementation、generated Dart client、contract tests、QA test cases |
| Breaking change | 必须有 ADR 或 migration plan，并说明客户端兼容策略 |
| Versioning | API schema 使用 `schema_version` 或等价版本字段；路径版本化按后续 API Contract 决策 |
| Error model | 继承统一 error schema：`error.code`、`error.message`、`request_id`、`details` |
| Idempotency | 支付、用量、账号删除、训练 turn replay 必须定义 idempotency key 或 provider event id |

### CI Drift Check
后续进入实现前必须建立 drift check：

1. 校验 OpenAPI 语法和 schema 引用。
2. 根据 OpenAPI 生成 Dart client。
3. 检查 generated output 是否与仓库一致。
4. 后端 controller contract test 对齐 OpenAPI。
5. 若 OpenAPI、后端 DTO、generated Dart client 不一致，CI 阻断。
6. API breaking change 必须更新 traceability 和 release notes。

## Generated Dart Client Policy

### 基本原则
Flutter 业务代码不得长期依赖手写 API DTO 作为跨端事实。后续 API Contract 阶段创建 OpenAPI 后，应生成 Dart client，并逐步替换或包裹现有 `lib/services/api_client.dart` 这类手写调用。

建议生成路径：

`lib/generated/api/`

本轮不创建该目录，不修改 Flutter 代码。

### 生成代码规则
- generated files 不得手写修改。
- 每次 OpenAPI 变更必须重新生成并通过 drift check。
- 生成 client 只处理 HTTP、DTO、序列化、统一错误解码。
- Flutter service/application 层可保留薄 wrapper，用于 UI 友好的状态映射、缓存、重试和 feature flag。
- wrapper 不得重新定义与 OpenAPI 冲突的 DTO 字段含义。
- `request_id`、`idempotency_key`、`schema_version` 必须按 OpenAPI 生成或由 wrapper 明确注入。
- error code 映射必须使用统一枚举或受控字符串集合，避免页面散落魔法字符串。

### 手写例外
允许手写的范围：

- 平台 SDK 调用：Apple IAP、Google Play Billing、Apple/WeChat 登录、录音、播放。
- UI 状态模型：loading、empty、recoverable error、offline cache。
- 本地缓存 adapter：只缓存服务端可刷新快照，不改写服务端事实。
- 调试或 mock adapter：必须在生产构建和 release gate 中关闭或隔离。

不允许手写的范围：

- subscription/entitlement 的最终状态计算。
- usage quota 的最终扣减。
- training session 的服务端状态机字段。
- learning evidence 的最终写入 schema。
- payment receipt/webhook 的服务端校验结果模型。

## 服务端事实源边界

### 用户
服务端拥有：

- user id、登录身份绑定、token refresh/logout、账号状态。
- 测试登录关闭策略和生产账号门禁。
- 账号删除 job 状态。

Flutter 只拥有：

- 当前登录展示状态。
- 短期 token 或 secure storage 中的客户端凭据。
- 可清理的 profile cache。

### 权益
服务端拥有：

- subscription plan、purchase、subscription state、entitlement snapshot。
- Apple/Google verify、restore、webhook 去重。
- 退款、撤销、过期、宽限期和账号切换后的权益结果。

Flutter 只拥有：

- 购买入口和平台 purchase token 提交。
- entitlement snapshot 展示缓存。
- 超限态、恢复购买为空、退款后降级等 UI 状态。

### 用量
服务端拥有：

- AI/ASR/TTS/评分 quota。
- usage reserve/commit/release。
- rate limit、budget alert、abuse detection。
- provider usage audit。

Flutter 只拥有：

- 请求发起。
- 剩余额度展示。
- provider unavailable 或 usage limit 的可恢复 UI。

### 训练 Session
服务端拥有：

- TrainingSession、TrainingTurn、PlannerDecision 的最终状态。
- session resume、complete、abandon、retry 的可追踪规则。
- planner decision 与 source turn 的关联。

Flutter 只拥有：

- 当前动作渲染。
- 录音、播放、文本兜底。
- 网络失败时的本地草稿和重试提示。

### 学习证据
服务端拥有：

- accepted LearningEvidence。
- EvidenceRuleTrace。
- MasteryRecord / ReviewItem 的最终更新。
- 去重、置信度、来源 turn、schema version。

Flutter 只拥有：

- 学习结果展示缓存。
- 离线兜底和同步失败提示。
- 用户可理解 recap，不直接覆盖最终 mastery。

## 后续执行顺序
本 foundation contract 通过复核后，下一步才进入 Domain Schema，覆盖：

- subscription
- entitlement
- usage
- account deletion
- training session
- planner
- learning evidence

Domain Schema 通过 `document-traceability-check` 和 Product Object Governance Check Agent 后，才能进入 API Contract / OpenAPI。之后才允许进入 AI Runtime、UX、QA、DevOps 分步契约补齐。最后才进入代码实现。

## Foundation Acceptance Checklist
本文件作为下游输入前，必须满足：

- 已明确它是 P0/P0.1 共同技术前置，不是新产品 feature。
- 已覆盖 backend 工程边界。
- 已覆盖 PostgreSQL / migration 策略。
- 已覆盖 OpenAPI source-of-truth。
- 已覆盖 generated Dart client policy。
- 已覆盖用户、权益、用量、训练 session、学习证据的服务端事实源边界。
- 已明确 omitted scope。
- 已明确不修改 Flutter 业务代码、不创建后端工程、不写 migration、不写 OpenAPI 实体文件。
- 已通过 `document-traceability-check`。
- 已通过 Product Object Governance Check Agent。
