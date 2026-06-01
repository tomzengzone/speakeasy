# Module Boundary

## 状态
Proposed - whole-app architecture。本文定义模块边界，不改变产品范围，不替代领域模型、API 契约或实现计划。

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
| Content / Scenario | Product + Backend | 官方场景、等级、内容版本、场景包 gating | 不承诺任意场景生成或 CMS 当前落地 |
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
| Scenario/interview | `lib/features/interview/`, `lib/application/scene/` | 保留学习主流程；P0.1 可新增 training view 或收敛 practice page，但 planner 规则必须可测试 |
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
| Scenario content | Backend or bundled reviewed assets during transition | 展示已审核内容；缓存内容版本 |
| Training session | Backend Training when online; local draft for recoverable session | 渲染当前状态，失败时可恢复 |
| Learning evidence / mastery | Backend Learning Evidence when synced; local baseline during transition | 只缓存和展示，不直接覆盖最终事实 |
| Media assets / audio_ref | Backend Media Storage | Flutter 上传录音并保存返回的 media id/audio_ref；不得生成生产 ASR ref |
| TTS cache metadata | Backend Media Cache | Flutter 只消费可播放 media ref 和 cache status，不读取 cache key |
| AI provider metrics/evidence | Backend AI Ops | Flutter 不访问；PM/Ops 通过受限 admin API 查看脱敏指标 |
| Provider raw payload | Backend audit/provider tables | 不保存完整敏感 provider payload |

## AI Runtime Boundary
- Prompt/schema 由 `docs/ai_runtime/` 定义并经 eval 验证。
- LLM 输出必须通过 schema validation 后才能进入 UI 或候选反馈。
- Planner、hint level、retry、pressure check、evidence write-back 的最终裁决属于 deterministic domain rules。
- Invalid JSON、provider timeout、ASR/TTS/评分失败必须产生 typed fallback，而不是阻塞整条学习主流程。

## P0.1 Training Planner Increment Boundary

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`。

### Boundary Decision

P0.1 第一版实现应采用 **frontend-rendered, deterministic planner module, local-first session draft** 的切片方式：
- 新增或抽取可测试的 `Training Planner` domain/application 模块，承接 action chain、micro-action、hint ladder、retry、pressure check 和 recap state transition。
- 现有 `lib/features/interview/interview_practice_page.dart` 可作为入口或承载页面，但不得继续把 planner 决策、AI 候选解析、学习证据写回和 UI rendering 混成不可测试的页面内逻辑。
- 现有 `interview_engine`、`interview_models`、`interview_wiki_store`、`audio_service`、`voice_chat_service`、`oral_assessment_service` 可复用，但必须通过 planner/application boundary 调用。
- P0.1 本轮实现不强制新增后端 migration；如果选择 repository-backed sync 或新增后端 API，必须先补 API contract 和后端 test cases。

### Module Responsibilities

| Module | Owns | Must not own |
| --- | --- | --- |
| Training planner rules | next micro-action, hint level transition, retry/continue/pressure/recap decision, reason code | AI free-form parsing, UI layout, provider secret, final commercial entitlement |
| Training session state | session status, current action step, current micro-action, resumable local draft | cross-day schedule, full L0-L5, arbitrary scene generation |
| Training feedback adapter | maps schema-valid `TrainingFeedbackCandidate` into planner-readable signals | final mastery write, unsupported next action application |
| Training screen | renders one active micro-action, hint, recorder/text fallback, feedback, recap, recoverable error | planner rules, AI schema validation, backend facts |
| Existing practice/session services | audio playback, recording, ASR/TTS/scoring calls, Product Base practice compatibility | direct P0.1 state advancement without planner decision |
| Learning evidence adapter | converts accepted planner/evidence rule output to local wiki/home/queue recap input | accepting raw LLM candidates as final mastery |
| Backend AI provider adapter | maps configured provider calls to `AiProviderGateway` results for LLM/TTS/ASR/scoring, keeps provider secrets server-side, emits typed fallback | exposing provider credentials to Flutter, copying old backend routes, bypassing usage reservation, treating local file path as successful ASR input |

### Integration Boundaries

| Existing area | P0.1 integration rule |
| --- | --- |
| `interview_practice_page.dart` | May route into a dedicated training session view or host it behind a clearly separated widget/controller; page must not become the planner source of truth. |
| `interview_engine.dart` | May provide content lookup, target expression selection and existing session helpers; P0.1 planner decisions should be extracted into a small testable module. |
| `interview_llm_scheduler.dart` / coach schema | May request AI feedback candidates; output must validate against `TrainingFeedbackCandidate` before UI consumption. |
| `interview_wiki_store.dart` | May receive accepted evidence/recap updates; raw AI candidates must not be persisted as final mastery. |
| `audio_service.dart` and `ApiClient.transcribeAudio` | Provide voice-first input and ASR fallback; ASR failure returns recoverable state, not learner failure. |
| OpenAPI Training family | Existing documented future/server contract remains available only if implementation chooses backend sync; local-first P0.1 does not require consuming all endpoints. |
| Current Spring Boot AI Gateway | Owns real provider adapter selection. `deterministic` remains test/dev default; `dashscope` implements Qwen LLM, DashScope TTS and Paraformer ASR behind the existing AI REST API. |

### Forbidden Couplings

- UI widget directly decides final mastery, review schedule, entitlement, or billing state.
- LLM output directly advances action chain or writes accepted learning evidence.
- Training planner creates third official scene, arbitrary scene prompt, cross-day schedule, or L0-L5 state.
- P0.1 implementation closes commercial release blockers or depends on P0 commercial payment evidence.
- Backend API expansion starts without API contract, tests, and governance review.
- DashScope, VolcEngine, OpenAI or LiveKit credentials are sent to Flutter or accepted from Flutter request bodies.
- A client local file path is treated as a provider-accessible `audio_ref` and converted into a successful ASR transcript.

## P0 Commercial AI Provider Hardening Boundary

Owning increment: `docs/product/increments/commercial-ai-provider-hardening/`。

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

## Cross-Boundary Rules
- 新 API 必须先更新 `docs/architecture/api_contract.md` 或后续 OpenAPI source。
- 新持久化事实必须先更新 domain schema 和 migration 计划。
- 新 AI 输出字段必须先更新 prompt/schema/eval。
- 新付费权益必须先更新 Commerce/Entitlement、UX、QA 和 release gate。
- 任何跨边界实现必须在 implementation report 中列出 changed files、validation commands、test gaps 和 residual risks。
