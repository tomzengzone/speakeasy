# Module Boundary

## PR-003 current lineage

本次只切换来源链，不改变本文的工程边界或已接受实现事实。当前产品 lineage 仅由适用的 approved FR 解析；Engineering Artifact 之间的 direct/conditional inputs 和适用 Gate 继续仅由 Governance Contract 解析。文内旧 Product Base、Increment、Spec/AC、旧 TC/traceability、Increment SWC Allocation 及与旧链路绑定的 Gate/checker 表述均为 historical provenance，不是当前 authority、prerequisite 或 fallback。

## 状态
Proposed - whole-app architecture。本文定义模块边界，不改变产品范围，不替代领域模型、API 契约或实现计划。

SWC 级完整拓扑、稳定 `SWC-FLOW-*` 和局部变更参考基准在 `docs/architecture/software_component_architecture.md`。本文定义上下文和模块边界，供 SWC 架构基准引用。

## Boundary Principles
- Product Base、baseline、stage、increment 保持独立；架构不得把 stage name 当 feature。
- 前端负责用户体验和可恢复状态，不拥有支付权益、AI provider secrets、长期掌握状态的最终事实。
- 后端负责可信业务事实、授权、支付校验、用量控制、provider isolation、审计和数据删除。
- AI runtime 只提供结构化候选建议；训练推进、掌握更新和权益判断由 deterministic domain rules 裁决。
- 数据库 schema 只由后端 migrations 管控；客户端本地状态是缓存或离线兜底。

## Bounded Contexts
| Context | Owner | Responsibilities | Explicit non-responsibilities |
| --- | --- | --- | --- |
| Identity | Backend | 登录、token、用户资料、社交登录回调、测试登录发布关闭、账号删除入口 | 不决定训练计划或订阅权益内容 |
| Commerce / Entitlement | Backend | Apple/Google 校验、订阅状态、权益快照、退款/过期/宽限期、恢复购买 | 不把客户端本地 memberPlan 当事实 |
| Usage Control | Backend | AI/ASR/TTS/评分用量、quota、速率限制、滥用检测、用量账本 | 不由 Flutter 前端单独扣减高成本用量 |
| Content / Scenario | Product + Backend | 官方 Scenario/ScenarioVersion/ScenarioLevel；一等 Course/CourseVersion authored 与 published facts；目录可见性投影；后续 CourseContentBinding | 不承诺任意场景生成、通用 CMS 当前落地，且不拥有 practice/training/learning/AI/media 运行时事实 |
| Training Planner | Backend/domain, with frontend state rendering | session 内 action chain、micro-action、hint、retry、pressure check、planner decision | 不承担 P0.2 跨天长期调度 |
| Learning Evidence | Backend/domain, frontend cache | 学习证据、掌握/薄弱、复习项、个人素材、summary | LLM 不直接写最终 mastery |
| AI Gateway | Backend | LLM/ASR/TTS/评分 provider routing、schema validation、fallback、成本观测 | 不暴露 provider keys 给客户端 |
| Media Storage / Cache | Backend + object storage | 录音上传、signed media ref、TTS cache metadata、media lifecycle、object deletion hooks | 不让 Flutter 直接拥有对象存储 key、provider-accessible URL 或 cache key |
| AI Ops | Backend + DevOps/Ops | provider sandbox evidence、成本看板、budget alerts、retention jobs、redacted evidence refs | 不展示 raw audio、完整 transcript、raw provider payload 或 provider secrets |
| Admin / Ops | Backend + DevOps | 审计、发布门禁、商店配置、回滚、数据删除任务 | 不作为用户可见学习体验入口 |
| Flutter App | Frontend | UI、录音、播放、本地缓存、API 调用、错误/空/加载状态 | 不拥有后端事实、支付事实或 provider secrets |

## Frontend Module Boundary
| Module | Current evidence | Boundary decision |
| --- | --- | --- |
| Bootstrap/routing | `lib/main.dart`, `lib/core/bootstrap/`, `lib/core/routing/` | 继续负责门禁路由和启动状态；生产账号策略由后端/API 契约决定 |
| Login/onboarding/profile | `lib/pages/login_page.dart`, `onboarding_page.dart`, `profile_page.dart` | 展示和收集用户输入；token、账号删除、测试登录发布 gate 由后端和 release gate 控制 |
| Content catalog/course detail | target `lib/features/content/`, `lib/application/content/` | 归属 `FE-CONTENT`；只编排已批准 001/002 的目录、Course summary 与 version-pinned detail，复用 `FE-API-CLIENT` 和 `FE-LOCAL-CACHE`；不得复制 DTO/client/cache/version resolver，也不得拥有 practice、training、learning、AI 或 media runtime |
| Scenario practice main flow | `lib/features/interview/` during migration | 当前主练习流程，归属 `FE-SCENARIO-PRACTICE`；保留面试/onboarding 表达图谱、mastery、wiki、queue、reviewed content、listening/shadowing；物理路径暂为 legacy-compatible，不再把 `interview` 作为新 SWC 语义 |
| Practice runtime | target `lib/application/practice_runtime/`; migration source `lib/application/scene/` | 归属 `FE-PRACTICE-RUNTIME`；只承载可复用 frontend mechanics：session recovery、voice capture shell、message loop、TTS/playback、hint shell、feedback recorder、practice history recorder；不得拥有表达图谱、最终 mastery、Training source of truth 或 provider facts |
| Legacy scenario sandbox | `lib/features/scenario/` | 归属 `FE-LEGACY-SCENARIO-SANDBOX`；旧版通用场景 sandbox，legacy / non-main-flow，只允许维护和复用 runtime adapter，禁止新增主流程功能 |
| Training frontend | `lib/features/training/`, `test/features/training/` | 承载 Training contract、backend adapter、session loop page、session view 和 Training 专项测试；不得使用 `interview_training_*` 或 `InterviewTraining*` 命名 |
| Audio/payment services | `lib/services/audio_service.dart`, `apple_payment_service.dart`, `android_payment_service.dart` | 调起平台能力和提交凭据；校验、权益和 provider 调用不得只在客户端执行 |
| Local storage | `lib/services/storage_service.dart`, stores/models | 本地优先缓存和降级；服务端上线后需要同步边界和冲突策略 |

## Backend Module Boundary
```text
api layer
  -> application services
  -> domain modules
  -> repositories / providers
```

- API layer：处理认证、DTO、OpenAPI schema、错误码、idempotency key、request_id。
- Application services：编排用例，例如购买校验、训练回合、学习证据写回、账号删除。
- Domain modules：保存实体生命周期和 deterministic rules，例如 entitlement 状态机、planner decision、usage ledger。
- Repositories/providers：隔离 PostgreSQL、Redis/queue、Apple/Google、LLM/ASR/TTS/评分 provider。

## Data Ownership
| Data | Source of truth | Frontend role |
| --- | --- | --- |
| User / auth session | Backend Identity | 保存短期 token 和展示 profile cache |
| Subscription / entitlement | Backend Commerce | 展示 entitlement snapshot，发起刷新和购买 |
| Usage / quota | Backend Usage Control | 展示剩余额度和超限态 |
| Scenario / Course content | `BE-CONTENT-SCENARIO`；后续持久化归属 `DB-IDENTITY-CONTENT` | 展示已审核、已发布且可见的 Scenario/Course 内容；缓存必须以稳定 Course/CourseVersion identity 为键，且不得成为发布、可见性或版本事实源 |
| Training session | Backend Training source of truth only | 渲染后端当前状态；后端不可用时关闭入口或展示服务不可用 |
| Learning evidence / mastery | Backend Learning Evidence when synced; local baseline during transition | 只缓存和展示，不直接覆盖最终事实 |
| Media assets / audio_ref | Backend Media Storage | Flutter 上传录音并保存返回的 media id/audio_ref；不得生成生产 ASR ref |
| TTS cache metadata | Backend Media Cache | Flutter 只消费可播放 media ref 和 cache status，不读取 cache key |
| AI provider metrics/evidence | Backend AI Ops | Flutter 不访问；PM/Ops 通过受限 admin API 查看脱敏指标 |
| Provider raw payload | Backend audit/provider tables | 不保存完整敏感 provider payload |

## Content Catalog And Course Detail Boundary

本节只承接已批准的 `US-CONTENT-001`、`US-CONTENT-002` 及适用 FR。`US-CONTENT-003` 至 `US-CONTENT-012` 仍是 draft compatibility input；不得从本节推导可执行 endpoint、字段、状态、表、provider 或验收。

| Owner | Owns | Forbidden duplicates / runtime facts |
| --- | --- | --- |
| `FE-CONTENT` | 目录与详情 UI 编排、稳定 Course/CourseVersion 选择、loading、真实空内容、typed failure 和 last-known display context | 不复制 `FE-API-CLIENT`、generated DTO、`FE-LOCAL-CACHE`、Course repository 或 version resolver；不拥有 session、turn、attempt、progress、evidence、recording、transcript、score 或 provider state |
| `BE-CONTENT-SCENARIO` | authored/published Scenario、ScenarioVersion、ScenarioLevel、Course、CourseVersion；服务端可见性编排；后续 CourseContentBinding resolution | 不创建第二套 Course store/service；不把 entitlement、practice、training、learning、AI 或 media facts 纳入 Content；不把 `ScenarioLevel` 解释为 Course |
| `BE-COMMERCE-ENTITLEMENT` | 若可见性规则适用，提供既有 entitlement decision input | 不拥有 Course metadata、CourseVersion 或 Content publication facts；Content 不复制 entitlement truth |
| `DB-IDENTITY-CONTENT` | 在 Domain Model、migration 和 API contract 后续批准后，承载 Content owner 的 additive persistence | 本轮不定义表；禁止 frontend/direct cross-domain write，禁止持久化 runtime session/progress/evidence/provider facts |
| Practice / Training / Learning / AI / Media owners | 分别继续拥有 session/turn/attempt、planner、progress/evidence、prompt/provider、recording/transcript/score/media lifecycle | 不复制 Course/CourseVersion authored 或 publication truth；只能消费稳定 Course/version/content reference |

Identity rules：
- `Course` 是稳定的学习者可见课程单位，`CourseVersion` 是其不可变发布版本；`Course != Scenario`，现有 `ScenarioLevel` 保留其 CEFR/场景轨道语义。
- 后续 `CourseContentBinding` 把一个 CourseVersion 关联到匹配的 `ScenarioVersion` 与 `ScenarioLevel`。本轮不定义 binding 字段、基数、表或 API schema；这些必须由后续 Domain Model 与 API Contract 决定。
- 本架构不定义 Course inventory 的数量、标题或时长；真实库存必须来自 owning approved product/content source。已批准 001/002 只授权完整 published/visible collection 与 detail semantics，不授权具体库存，也不承诺 A1-C2 或 A1/C1/C2 覆盖。

Failure and operational rules：
- catalog 的真实空内容与读取失败必须可区分；published theme 可保留零 Course，不得用伪造内容掩盖空状态。
- detail 必须精确解析请求的 CourseVersion；不可用时返回 typed failure，不得静默切换 latest 或把 `ScenarioLevel` 当替代版本。
- 前端缓存只可保留 last-known display context；服务端 publication 与 visibility decision 仍是事实源。
- 观测传播 request/trace identity、结果类别与匿名化 Course/version reference；不记录 raw authored content、用户音频、transcript 或 provider secret。
- rollout 使用后续 additive contract/migration 与 feature flag；rollback 关闭新 catalog/detail 读取入口并保留 additive data，不回写或重解释现有 ScenarioLevel/practice/training 数据。

## AI Runtime Boundary
- Prompt/schema 由 `docs/ai_runtime/` 定义并经 eval 验证。
- LLM 输出必须通过 schema validation 后才能进入 UI 或候选反馈。
- Planner、hint level、retry、pressure check、evidence write-back 的最终裁决属于 deterministic domain rules。
- Invalid JSON、provider timeout、ASR/TTS/评分失败必须产生 typed fallback，而不是阻塞整条学习主流程。

## P0.1 Training Planner Increment Boundary

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`。

归属 increment：`docs/product/increments/p0-1-expression-automation-training/`。

### Boundary Decision

P0.1 第一版本地验证切片曾采用 **frontend-rendered, deterministic planner module, local-first session draft**；2026-06-03 backend-only correction 后，Product Base 合入或生产模式必须使用 backend-owned Training source of truth，Flutter local Training 状态机不再作为可进入路径：
- 新增或抽取可测试的 `Training Planner` domain/application 模块，承接 action chain、micro-action、hint ladder、retry、pressure check 和 recap state transition。
- 现有 `lib/features/interview/interview_practice_page.dart` 可作为普通练习入口或承载页面，但 P0.1 Training 生产 UI/adapter/contract 必须位于 `lib/features/training/`；不得继续把 planner 决策、AI 候选解析、学习证据写回和 UI rendering 混成不可测试的页面内逻辑。
- 现有 `interview_engine`、`interview_models`、`interview_wiki_store`、`audio_service`、`voice_chat_service` 可复用，但必须通过 planner/application boundary 调用；本地 oral assessment provider 服务已退役，生产发音评分必须走 trusted upload + Backend AI Gateway。
- Local-first 只允许作为本地草稿、demo 和可恢复 fallback；Product Base 合入、商业生产训练或 release readiness 必须实现 OpenAPI Training family 对应的后端 controller/service/repository/test，或在 release/Product Base 状态中显式标记 blocked。
- 后端 Training implementation 不新增 stage；它关闭同一 P0.1 increment 的 `P01-GAP-009` through `P01-GAP-014`。

### Module Responsibilities

| Module | Owns | Must not own |
| --- | --- | --- |
| Training planner rules | next micro-action, hint level transition, retry/continue/pressure/recap decision, reason code | AI free-form parsing, UI layout, provider secret, final commercial entitlement |
| Training session state | backend session status, current action step, current micro-action, server-synced resumable state | cross-day schedule, full L0-L5, arbitrary scene generation, Flutter local draft session |
| Training feedback adapter | maps schema-valid `TrainingFeedbackCandidate` into planner-readable signals | final mastery write, unsupported next action application |
| Training screen | renders one active micro-action, hint, recorder/text fallback, feedback, recap, recoverable error | planner rules, AI schema validation, backend facts |
| Existing practice/session services | audio playback, recording, ASR/TTS/scoring calls, Product Base practice compatibility | direct P0.1 state advancement without planner decision |
| Learning evidence adapter | converts accepted planner/evidence rule output to local wiki/home/queue recap input | accepting raw LLM candidates as final mastery |
| Backend Training service | authenticated TrainingSession/TrainingTurn source of truth, idempotency, owner scope, planner replay refs, rule-traced evidence handoff, redacted metrics | UI layout, cross-day schedule, full L0-L5 mastery, billing/entitlement truth |
| Backend AI provider adapter | maps configured provider calls to `AiProviderGateway` results for LLM/TTS/ASR/scoring, keeps provider secrets server-side, emits typed fallback | exposing provider credentials to Flutter, copying old backend routes, bypassing usage reservation, treating local file path as successful ASR input |

### Integration Boundaries

| Existing area | P0.1 integration rule |
| --- | --- |
| `interview_practice_page.dart` | May route into `lib/features/training/training_session_loop_page.dart` or host it behind a clearly separated widget/controller; page must not become the planner source of truth. |
| `interview_engine.dart` | May provide content lookup, target expression selection and existing session helpers; P0.1 planner decisions should be extracted into a small testable module. |
| `interview_llm_scheduler.dart` / coach schema | May request AI feedback candidates; output must validate against `TrainingFeedbackCandidate` before UI consumption. |
| `interview_wiki_store.dart` | May receive accepted evidence/recap updates; raw AI candidates must not be persisted as final mastery. |
| `audio_service.dart`, `voice_chat_service.dart`, and `ApiClient.transcribeTrustedAudioRef` | Provide recording/playback/runtime preview surfaces; production ASR must consume trusted `media://audio/...`, and unavailable upload/ASR returns recoverable state rather than a learner failure. |
| OpenAPI Training family | Required contract for Product Base/production readiness. Flutter P0.1 Training must not bypass it with local draft state, local planner decisions or synthetic feedback. |
| Current Spring Boot AI Gateway | Owns real provider adapter selection. `deterministic` remains test/dev default; `dashscope` implements Qwen LLM, DashScope TTS and Paraformer ASR behind the existing AI REST API. |

### Forbidden Couplings

- UI widget directly decides final mastery, review schedule, entitlement, or billing state.
- LLM output directly advances action chain or writes accepted learning evidence.
- Training planner creates third official scene, arbitrary scene prompt, cross-day schedule, or L0-L5 state.
- P0.1 implementation closes commercial release blockers or depends on P0 commercial payment evidence.
- Backend API expansion starts without API contract, tests, and governance review.
- Flutter local route evidence or local draft state is treated as Product Base/production-ready Training source of truth.
- DashScope, VolcEngine, OpenAI or LiveKit credentials are sent to Flutter or accepted from Flutter request bodies.
- A client local file path is treated as a provider-accessible `audio_ref` and converted into a successful ASR transcript.

- UI widget 不得直接决定 final mastery、review schedule、entitlement 或 billing state。
- LLM output 不得直接推进 action chain 或写入 accepted learning evidence。
- Training planner 不得创建第三个 official scene、arbitrary scene prompt、cross-day schedule 或 L0-L5 state。
- P0.1 implementation 不得关闭 commercial release blockers，也不得依赖 P0 commercial payment evidence。
- Backend API expansion 不得在缺少 API contract、tests 和 governance review 的情况下启动。
- Flutter local route evidence 或 local draft state 不得被视为 Product Base/production-ready Training source of truth。
- DashScope、VolcEngine、OpenAI 或 LiveKit credentials 不得发送给 Flutter，也不得从 Flutter request bodies 接收。
- Client local file path 不得被当成 provider-accessible `audio_ref`，也不得被转换为 successful ASR transcript。

## P0 Commercial AI Provider Hardening Boundary

Owning increment: `docs/product/increments/commercial-ai-provider-hardening/`。

归属 increment：`docs/product/increments/commercial-ai-provider-hardening/`。

| Module | Owns | Must not own |
| --- | --- | --- |
| Flutter recorder/audio service | Local recording, MIME/duration metadata collection, upload initiation, retry UI, playback of returned media refs | Object storage credentials, final media validation, provider-accessible signed URL creation, ASR success decision |
| Media service | `POST /media/audio/uploads`, `POST /media/audio/uploads/{media_id}/complete`, media metadata validation, trusted `audio_ref`, object lifecycle status | TTS synthesis, cost aggregation, raw transcript storage |
| AI Gateway | Resolving validated `audio_ref`, provider routing, ASR/TTS/LLM/scoring fallback, usage reservation/commit/release | Accepting local paths or unsigned URLs, exposing provider secrets, owning retention policy approval |
| TTS cache service | normalized text hash/model/voice/language cache key, persistent cache metadata, object ref reuse, expiry/delete hook | Storing raw sensitive text as cache key, deciding commercial plan entitlement |
| AI Ops metrics | ProviderInvocationMetric aggregation, cost dashboard, budget status, provider anomaly flags | Raw payload inspection through public API, user-facing learning feedback |
| AI provider evidence | DashScope sandbox/controlled live evidence metadata, reviewer status, release gate refs | Replacing automated code tests, storing provider credentials in evidence docs |
| Retention service | RetentionPolicy execution, AiRetentionJob retry/manual failure state, redacted evidence refs | Deleting payment audit obligations, hiding deletion failures |

Boundary result for `P0-AI-ARCH-001`: API, domain and security ownership are separated enough for Backend, QA, Ops and Security work packages to proceed without guessing cross-module ownership. Backend implementation must stay inside `Media service`, `AI Gateway`, `TTS cache service`, `AI Ops metrics` and `Retention service` boundaries and keep Flutter limited to upload/playback orchestration.

`P0-AI-ARCH-001` 的边界结论：API、domain 和 security ownership 已经拆分到足以让 Backend、QA、Ops 和 Security work packages 在不猜测跨模块归属的情况下继续推进。Backend implementation 必须保持在 `Media service`、`AI Gateway`、`TTS cache service`、`AI Ops metrics` 和 `Retention service` 边界内，并让 Flutter 只负责 upload/playback orchestration。

## Cross-Boundary Rules
- 新 API 必须先更新 `docs/architecture/api_contract.md` 或后续 OpenAPI source。
- 新持久化事实必须先更新 domain schema 和 migration 计划。
- Course/CourseVersion 或 CourseContentBinding 的新事实必须由 Content owner 落地，并先完成相应 Domain Model、API Contract 和 migration decision；其他 SWC 只能持稳定 reference。
- `US-CONTENT-003` 至 `US-CONTENT-012` 在批准后必须先执行 `software_component_architecture.md` 的逐行 impact check；未触发全局评审条件时仅增加对应 Engineering Contract，触发时先完成全局架构评审或 ADR。
- 新 AI 输出字段必须先更新 prompt/schema/eval。
- 新付费权益必须先更新 Commerce/Entitlement、UX、QA 和 release gate。
- 任何跨边界实现必须在 implementation report 中列出 changed files、validation commands、test gaps 和 residual risks。
