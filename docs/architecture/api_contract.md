# API Contract / API 契约

## 状态

Proposed - API Contract/OpenAPI source-of-truth 已建立。本文是人读的 API 契约总览；机器可校验的 OpenAPI source of truth 是 `docs/architecture/openapi/speakeasy-api.yaml`。

提议状态 - API Contract/OpenAPI 事实源已经建立；本文面向人工阅读，机器校验以 `docs/architecture/openapi/speakeasy-api.yaml` 为准。

本文不替代领域模型、数据库 migration、AI prompt/schema、UX screen spec、QA test plan 或代码实现。Backend、Frontend、QA 在消费 OpenAPI 前，必须先完成 OpenAPI lint、契约追溯检查和 Product Object Governance Check。

## Source Of Truth / 事实源

| Artifact / 产物 | Path / 路径 | Ownership / 归属 |
| --- | --- | --- |
| API contract overview<br>API 契约总览 | `docs/architecture/api_contract.md` | API family、产品对象追溯、统一错误模型、版本策略、兼容性、deferred boundary |
| OpenAPI source of truth<br>OpenAPI 机器事实源 | `docs/architecture/openapi/speakeasy-api.yaml` | paths、components、request/response schema、examples、lint input |

`api_contract.md` 不复制完整 OpenAPI schema；OpenAPI YAML 不承载 roadmap priority 或未批准 future-stage endpoint。

## Upstream / 上游依据

| Source / 来源 | Path / 路径 | API use / API 用途 |
| --- | --- | --- |
| Product Base requirements/spec/acceptance/traceability | `docs/product/base/` | 稳定能力的 server-backed contract 输入 |
| P0 commercial subscription increment | `docs/product/increments/commercial-subscription-readiness/` | 订阅、权益、用量、账号删除、审计和 release gate API |
| P0 commercial AI provider hardening increment | `docs/product/increments/commercial-ai-provider-hardening/` | media upload/signing、persistent TTS cache、provider evidence、cost dashboard and retention API planning |
| P0.1 training increment | `docs/product/increments/p0-1-expression-automation-training/` | training session、turn、planner、hint、pressure、evidence API |
| P0.2 goal autopilot increments | `docs/product/increments/p0-2-goal-diagnostic-foundation/`, `docs/product/increments/p0-2-goal-backplan-memory-policy/`, `docs/product/increments/p0-2-autopilot-progress-checkpoint/`, `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`, `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/` | goal intake、diagnostic、backplan、daily plan、memory policy、autopilot action、control、reminder eligibility/outbox、recovery replan、item-policy decision、mastery transition audit、forecast、checkpoint API |
| Domain schema | `docs/domain/domain_schema.md` | 实体、状态机、事实源、API boundary recommendations |
| Entity relationship | `docs/domain/entity_relationship.md` | ownership、cardinality、cross-domain references |
| Foundation contract | `docs/architecture/backend_db_foundation_contract.md` | OpenAPI source-of-truth、generated Dart client、server fact boundary |
| Path governance and traceability findings | `docs/reports/quality_report.md` | OpenAPI path decision and Product Base/P0/P0.1 eligibility |

## Scope Classification / 范围分类

| Scope / 范围 | OpenAPI treatment / OpenAPI 处理方式 | Reason / 原因 |
| --- | --- | --- |
| Product Base stable behavior<br>Product Base 稳定行为 | Implementation-level paths allowed<br>允许实现级 path | Accepted Product Base artifacts and traceability exist<br>Product Base 已有接受产物和可追溯依据 |
| P0 commercial subscription readiness<br>P0 商业订阅上线准备 | Implementation-level paths allowed<br>允许实现级 path | Approved increment artifacts exist<br>已有获批增量产物 |
| P0 commercial AI provider hardening<br>P0 商业 AI provider 加固 | Implementation-level paths allowed for media upload/signing, provider evidence, cost metrics and retention operations<br>允许为媒体上传/签名、provider evidence、成本指标和保留任务定义实现级 path | Approved increment artifacts exist and `P0-AI-ARCH-001` records the API/security contract gate<br>已有获批增量产物，且 `P0-AI-ARCH-001` 记录 API/安全契约门禁 |
| P0.1 expression automation training<br>P0.1 表达自动化训练 | Implementation-level paths allowed where server-backed behavior is required<br>仅在需要服务端支撑的行为上允许实现级 path | Approved increment artifacts exist; local-only behavior must not be over-promoted<br>已有获批增量产物；纯本地行为不能被提升为服务端产品能力 |
| P0.2 goal-driven learning autopilot<br>P0.2 目标驱动学习 autopilot | Implementation-level paths allowed for goal intake, diagnostic summary, backplan, daily plan, next action, autopilot control, reminder eligibility/outbox, recovery replan, item-policy decision, mastery transition audit, progress forecast and checkpoint operations<br>允许为 goal intake、diagnostic summary、backplan、daily plan、next action、autopilot control、reminder eligibility/outbox、recovery replan、item-policy decision、mastery transition audit、progress forecast、checkpoint 操作定义实现级 path | Owning P0.2 increments, including Followup-B, have requirements/spec/AC/TC/traceability and P02 policy gates<br>P0.2 归属增量（含 Followup-B）已有 requirements/spec/AC/TC/traceability 和 P02 policy gate |
| P1 notebook/scoring/content expansion<br>P1 笔记/评分/内容扩展 | Deferred boundary only<br>仅保留 deferred boundary | Roadmap/future V2 Capability boundary only<br>仅属于 roadmap/future V2 Capability 边界 |
| P2 A1-C2/CMS/content production<br>P2 A1-C2/CMS/内容生产 | Deferred boundary only<br>仅保留 deferred boundary | Roadmap/future V2 Capability boundary only<br>仅属于 roadmap/future V2 Capability 边界 |

## Contract Rules / 契约规则

- API-first：跨端实现前必须先有 request/response/error schema。
- 所有响应使用 JSON；所有错误使用统一 `ErrorResponse` schema。
- OpenAPI schema 必须能生成或校验 Dart client；Flutter 手写 wrapper 不得重新定义 DTO 语义。
- OpenAPI 3.0 nullable object references must not use `$ref` plus `nullable` as siblings; use an explicit `type` with `allOf` so Redocly example validation and generated client drift checks stay warning-free.
- OpenAPI 3.0 的 nullable object reference 不得把 `$ref` 和 `nullable` 放在同一层；应使用显式 `type` 配合 `allOf`，确保 Redocly example validation 和 generated client drift check 不再产生告警。
- 支付、用量、账号删除、训练 turn replay 必须支持 `X-Request-Id`，并在需要时支持 `Idempotency-Key`。
- 所有主响应需要 `schema_version` 或等价版本字段。
- 支付、权益、用量、训练 session、学习证据和账号删除的最终事实由服务端拥有。
- LLM/ASR/TTS/评分 provider 只能返回候选反馈或信号；planner/evidence/entitlement/usage 的最终裁决由 deterministic domain rules 完成。
- Breaking changes 必须记录 ADR 或 migration plan，并说明客户端兼容策略。
- 不得从 stage、roadmap 或 future boundary 直接生成实现级 endpoint。

## API Family Coverage / API 家族覆盖

| Family / 家族 | OpenAPI tag | Product object source / 产品对象来源 | Implementation status / 实现状态 |
| --- | --- | --- | --- |
| Auth / Identity<br>认证/身份 | `Auth`, `User` | Product Base FR-001, FR-010; P0 FR-COM-004, FR-COM-005, FR-COM-008 | In OpenAPI<br>已进入 OpenAPI |
| Onboarding<br>新手引导 | `Onboarding` | Product Base FR-002 | In OpenAPI, including assessment and route creation<br>已进入 OpenAPI，覆盖评估和路线创建 |
| Scenario / Content<br>场景/内容 | `Scenario`, `Home` | Product Base FR-003, FR-004, FR-005; P0.1 P01-FR-001, P01-FR-002 | In OpenAPI, including official content, user scenario state, and home summary<br>已进入 OpenAPI，覆盖官方内容、用户场景状态和首页摘要 |
| Product Base practice<br>Product Base 练习 | `Practice` | Product Base FR-007, FR-008, FR-009; `mvp-backend-practice-ai` MVP-SI-008/MVP-SI-009 | In OpenAPI, including start/resume/get/turn/complete, recoverable provider failure, and summary candidate input<br>已进入 OpenAPI，覆盖 start/resume/get/turn/complete、可恢复 provider failure 和 summary candidate input |
| P0.1 training planner<br>P0.1 训练 planner | `Training`, `Planner` | P0.1 P01-FR-001..P01-FR-017 | In OpenAPI; Product Base/production readiness blocked until backend Training implementation, tests and rollout gates close `P01-GAP-009` through `P01-GAP-014` or are explicitly marked blocked<br>已进入 OpenAPI；在 backend Training 实现、测试和 rollout gate 关闭 `P01-GAP-009` 到 `P01-GAP-014` 或明确标记 blocked 前，Product Base/production readiness 仍被阻断 |
| P0.2 goal autopilot<br>P0.2 目标 autopilot | `Goal Autopilot` | P0.2 P02-DIAG-FR-001..007, P02-PLAN-FR-001..008, P02-AUTO-FR-001..008, P02-FUB-FR-001..008 | In OpenAPI for deterministic local implementation, including Followup-B control/planner/memory hardening; high-cost AI/provider, commercial release and official-score claims remain governed by P02/P0 gates<br>已为确定性本地实现进入 OpenAPI，包含 Followup-B control/planner/memory 加固；高成本 AI/provider、商业发布和 official-score claims 仍受 P02/P0 gate 约束 |
| Learning / Review / Favorites<br>学习/复习/收藏 | `Learning`, `Review`, `Favorites` | Product Base FR-005, FR-006, FR-009; P0.1 P01-FR-009 | In OpenAPI<br>已进入 OpenAPI |
| Subscription / Entitlement<br>订阅/权益 | `Subscription`, `Entitlement` | P0 FR-COM-001..FR-COM-007, FR-COM-009 | In OpenAPI<br>已进入 OpenAPI |
| Usage / AI Gateway<br>用量/AI Gateway | `Usage`, `AI Gateway` | P0 FR-COM-010; Product Base FR-004, FR-008; P0.1 P01-FR-006, P01-FR-007; `mvp-backend-practice-ai` MVP-SI-006/MVP-SI-009 | In OpenAPI, including server-side ASR/TTS/pronunciation/coach adapters, no client provider secret field, and typed fallback results<br>已进入 OpenAPI，覆盖服务端 ASR/TTS/pronunciation/coach adapter、禁止客户端 provider secret 字段，以及 typed fallback result |
| Media / AI Provider Operations<br>媒体/AI Provider 运维 | `Media`, `AI Ops`, `AI Gateway` | P0 `commercial-ai-provider-hardening` FR-COM-AI-001..005 | In OpenAPI for media upload/signing, TTS cache metadata, provider evidence, cost metrics and retention jobs<br>已进入 OpenAPI，覆盖媒体上传/签名、TTS cache metadata、provider evidence、成本指标和 retention job |
| Admin / Ops<br>管理/运维 | `Admin` | P0 FR-COM-008, FR-COM-011, FR-COM-012 | In OpenAPI<br>已进入 OpenAPI |
| P0.2/P1/P2 future extensions<br>P0.2/P1/P2 未来扩展 | `Deferred` | Roadmap/stage/future V2 Capability boundaries only<br>仅来自 roadmap/stage/future V2 Capability 边界 | No implementation-level endpoints<br>不定义实现级 endpoint |

## Product Base Identity/Profile Contract Note / Product Base 身份与资料契约说明

Owning product object / 归属产品对象：`docs/product/base/` FR-010 / AC-011。

- `GET /user/me` returns the authenticated user's profile and account state, including the display-only `avatar_ref`.
- `PATCH /user/me` is the only Product Base profile update boundary for display name, profile preferences and the built-in avatar selection.
- `avatar_ref` is an in-app built-in avatar reference. The current implementation only accepts the existing shipped avatar asset paths under `assets/images/avatars/default_avatar_1.png` through `assets/images/avatars/default_avatar_6.png`.
- Flutter must call `PATCH /user/me` through the generated OpenAPI path boundary. It must not call or create `/user/me/avatar`, multipart avatar upload, or the audio media upload flow for the current built-in avatar picker.
- Future user-uploaded or remote avatars require a separately approved `media/image` contract with storage, ownership, content type, byte size, deletion, moderation and release evidence. They are out of scope for the current Product Base avatar fix.

- `GET /user/me` 返回认证用户的 profile 和账号状态，并包含只用于展示的 `avatar_ref`。
- `PATCH /user/me` 是 Product Base 中唯一允许更新 display name、profile preferences 和内置头像选择的 profile 边界。
- `avatar_ref` 是应用内置头像引用；当前实现只接受已经随包发布的 `assets/images/avatars/default_avatar_1.png` 到 `assets/images/avatars/default_avatar_6.png`。
- Flutter 必须通过 generated OpenAPI path 调用 `PATCH /user/me`，当前内置头像选择器不得调用或创建 `/user/me/avatar`、multipart avatar upload 或音频 media upload 流程。
- 用户上传头像或远程头像需要单独获批的 `media/image` 契约，覆盖 storage、ownership、content type、byte size、deletion、moderation 和 release evidence；这些不在当前 Product Base avatar 修复范围内。

## P0 Commercial Contract Gate / P0 商业契约门禁

Owning increment / 归属增量：`docs/product/increments/commercial-subscription-readiness/`。

| Work package / 工作包 | Contract decision / 契约决策 | Traceability / 追溯 |
| --- | --- | --- |
| P0-COM-API-001 | `GET /subscription/plans` is a public read endpoint for saleable plan display; purchase, restore, entitlement and usage endpoints remain authenticated. OpenAPI must use `security: []` for this path and must not imply unauthenticated entitlement access. | FR-COM-001, FR-COM-009; AC-COM-011 |
| P0-COM-API-001 | Apple and Google verification use authenticated `POST /subscriptions/apple/verify` and `POST /subscriptions/google/verify` with `Idempotency-Key`. Invalid receipt, product mismatch and idempotency conflict are explicit errors. | FR-COM-001, FR-COM-002, FR-COM-003; AC-COM-001, AC-COM-002 |
| P0-COM-API-001 | Restore purchase is an authenticated operation and empty restore is a successful typed state, not an entitlement grant. | FR-COM-002, FR-COM-003; AC-COM-003, AC-COM-004 |
| P0-COM-API-001 | Provider webhooks require `webhookSignature` and are processed idempotently through `PaymentProviderEvent`. | FR-COM-002, FR-COM-003, FR-COM-005; AC-COM-005 |
| P0-COM-API-001 | Entitlement refresh, usage summary, usage reserve/commit/release are server-owned boundaries; Flutter may cache display state but cannot mutate final entitlement or quota facts. | FR-COM-001, FR-COM-006, FR-COM-007, FR-COM-010; AC-COM-006, AC-COM-007, AC-COM-012 |
| P0-COM-API-001 | Account deletion remains authenticated and idempotent; admin retry and release health use `opsBearerAuth`. | FR-COM-004, FR-COM-008, FR-COM-011, FR-COM-012; AC-COM-008, AC-COM-010, AC-COM-014 |
| P0-COM-API-001 | `POST /admin/data-deletion/{job_id}/retry` is an OPS-only account-deletion recovery action requiring `Idempotency-Key`; only `failed` jobs execute a new retry, `completed` jobs return current state without re-execution, in-progress states return `DELETE_IN_PROGRESS`, and new retry executions are audited with redacted details. | FR-COM-008, FR-COM-011; AC-COM-010, AC-COM-013 |
| P0-COM-API-001 | `GET /admin/audit` is an `opsBearerAuth`-only, paginated and filterable audit event list. It exposes only `AuditLog` safe fields, omits `actor_id`, sanitizes `redacted_details`, and records each audit-read access as its own redacted audit event. | FR-COM-011, FR-COM-012; AC-COM-013, AC-COM-014 |

中文等价设计说明：

- P0-COM-API-001 / `GET /subscription/plans`：该 path 只用于公开展示可售 plan；购买、恢复、权益和用量仍必须认证，且 OpenAPI 要用 `security: []` 明确它不是匿名权益访问。
- P0-COM-API-001 / Apple and Google verification：Apple/Google 校验必须通过认证后的 verify path 和 `Idempotency-Key`；无效凭据、商品不匹配和幂等冲突都要成为明确错误。
- P0-COM-API-001 / Restore purchase：恢复购买是认证操作；空恢复是有类型的成功状态，不等价于授予权益。
- P0-COM-API-001 / Provider webhooks：支付 webhook 必须带 `webhookSignature`，并通过 `PaymentProviderEvent` 幂等处理。
- P0-COM-API-001 / Entitlement and usage：权益刷新、用量摘要和 reserve/commit/release 是服务端事实边界；Flutter 只能缓存展示状态，不能改写最终权益或额度事实。
- P0-COM-API-001 / Account deletion and ops：账号删除保持认证和幂等；admin retry 与 release health 使用 `opsBearerAuth`。
- P0-COM-API-001 / data deletion retry：`POST /admin/data-deletion/{job_id}/retry` 仅限 OPS 恢复失败删除任务；只有 `failed` job 会重新执行，已完成或进行中的 job 只返回当前状态，并记录脱敏审计。
- P0-COM-API-001 / admin audit：`GET /admin/audit` 仅允许 `opsBearerAuth`，返回分页/可过滤的安全审计字段；隐藏 `actor_id`、清洗 `redacted_details`，并把每次审计读取本身也写成脱敏审计事件。

P0-COM-API-001 gate result: API contract and OpenAPI source-of-truth cover the commercial subscription, entitlement, usage, account deletion and admin/release API families needed before implementation. Contract lint remains the validation gate before downstream code consumes these paths.

P0-COM-API-001 门禁结论：API contract 和 OpenAPI 事实源已经覆盖实现前所需的商业订阅、权益、用量、账号删除以及 admin/release API 家族；下游代码消费这些 path 前仍必须通过 contract lint。

## P0 Commercial AI Provider Hardening Contract Gate / P0 商业 AI Provider 加固契约门禁

Owning increment / 归属增量：`docs/product/increments/commercial-ai-provider-hardening/`。

| Work package / 工作包 | Contract decision / 契约决策 | Traceability / 追溯 |
| --- | --- | --- |
| P0-AI-ARCH-001 | `POST /media/audio/uploads` creates a backend-owned upload session with entitlement/usage precheck, accepted content type, byte size, duration, checksum and short-lived signed upload URL for an阿里云 OSS private bucket or equivalent storage adapter. Response returns `MediaAsset.audio_ref` as the only client-consumable ASR input ref; OSS AccessKey and provider read URL are never returned. | FR-COM-AI-001, AC-COM-AI-001, TC-COM-AI-001, TC-COM-AI-008 |
| P0-AI-ARCH-001 | `POST /media/audio/uploads/{media_id}/complete` validates object metadata, checksum, duration, owner and canonical `object_ref` before the asset can enter `/ai/transcribe`; local file paths, unsigned URLs, wrong-owner refs and client-forged object refs remain invalid. | FR-COM-AI-001, AC-COM-AI-001, TC-COM-AI-002, TC-COM-AI-008 |
| P0-AI-ARCH-001 | `/ai/tts` response adds optional `media_id`, `cache_status` and `cache_expires_at`; the cache key remains server-owned from normalized text hash, model, voice and language, and Flutter must not submit or see the raw cache key. | FR-COM-AI-002, AC-COM-AI-002, TC-COM-AI-003 |
| P0-AI-ARCH-001 | `GET /admin/ai/provider-evidence` exposes only reviewed provider evidence metadata and redacted evidence refs; provider keys, raw request payloads, raw audio and full transcripts must not appear in response bodies. | FR-COM-AI-003, AC-COM-AI-003, TC-COM-AI-004 |
| P0-AI-ARCH-001 | `GET /admin/ai/cost-metrics` exposes plan, user hash, provider family, model, capability, status, cache hit, call count, duration/token estimate, estimated cost, budget bucket and margin risk. | FR-COM-AI-004, AC-COM-AI-004, TC-COM-AI-005 |
| P0-AI-ARCH-001 | `POST /admin/ai/retention-jobs` and `GET /admin/ai/retention-jobs/{job_id}` expose retention execution status, aggregate deletion/redaction counts and redacted evidence refs only. | FR-COM-AI-005, AC-COM-AI-005, TC-COM-AI-006, TC-COM-AI-007 |

中文等价设计说明：

- P0-AI-ARCH-001 / media upload create：`POST /media/audio/uploads` 由后端创建上传会话，先做 entitlement/usage 预检，再限制内容类型、字节大小、时长、checksum 和短期签名上传 URL；客户端只能拿到 `MediaAsset.audio_ref` 作为 ASR 输入引用，不能拿到 OSS AccessKey 或 provider read URL。
- P0-AI-ARCH-001 / media upload complete：`POST /media/audio/uploads/{media_id}/complete` 必须校验对象元数据、checksum、时长、owner 和 canonical `object_ref` 后，音频才允许进入 `/ai/transcribe`；本地路径、未签名 URL、跨用户 ref 和客户端伪造 ref 都无效。
- P0-AI-ARCH-001 / `/ai/tts` cache metadata：`/ai/tts` 可以返回可选 `media_id`、`cache_status` 和 `cache_expires_at`；cache key 由后端根据归一化文本 hash、model、voice 和 language 管理，Flutter 不提交也看不到原始 cache key。
- P0-AI-ARCH-001 / provider evidence：`GET /admin/ai/provider-evidence` 只暴露已审阅的 provider evidence metadata 和脱敏 evidence ref；provider key、原始请求 payload、原始音频和完整 transcript 不得进入 response。
- P0-AI-ARCH-001 / cost metrics：`GET /admin/ai/cost-metrics` 暴露 plan、user hash、provider family、model、capability、status、cache hit、call count、duration/token estimate、estimated cost、budget bucket 和 margin risk，用于成本与毛利风险治理。
- P0-AI-ARCH-001 / retention jobs：`POST /admin/ai/retention-jobs` 和 `GET /admin/ai/retention-jobs/{job_id}` 只暴露 retention 执行状态、聚合删除/脱敏计数和脱敏 evidence ref。

P0-AI-ARCH-001 gate result: OpenAPI now contains implementation-level contracts for media upload/signing, persistent TTS cache metadata, provider evidence, cost metrics and AI retention jobs. Backend implementation may proceed only against these paths and must keep raw media, provider payloads, full signed URLs and provider secrets out of request/response DTOs and logs.

P0-AI-ARCH-001 门禁结论：OpenAPI 已包含媒体上传/签名、持久 TTS cache metadata、provider evidence、成本指标和 AI retention job 的实现级契约；后端只能按这些 path 实现，并且必须让 raw media、provider payload、完整签名 URL 和 provider secret 离开 request/response DTO 与日志。

## P0.1 Training Production-Hardening Contract Gate / P0.1 Training 生产加固契约门禁

Owning increment / 归属增量：`docs/product/increments/p0-1-expression-automation-training/`；remediation batch / 修复批次：2026-06-03。

| Work package / 工作包 | Contract decision / 契约决策 | Traceability / 追溯 |
| --- | --- | --- |
| P01-HARDEN-001 | `/training/sessions`, `/training/sessions/{session_id}`, `/training/sessions/{session_id}/turns` and `/training/sessions/{session_id}/complete` are the Product Base/production Training source-of-truth boundary. These endpoints must be authenticated, owner-scoped and backed by server persistence before P0.1 can be promoted from local route to stable product capability. | P01-FR-012, P01-SPEC-013, AC-P01-014, TC-P01-021, TC-P01-022, P01-TR-013 |
| P01-HARDEN-001 | Training turn replay requires `Idempotency-Key` plus `session_id`; duplicate keys with the same body return the prior turn result, while mismatched replay returns `IDEMPOTENCY_CONFLICT`. Flutter cannot create local draft attempts that count as accepted server turns. | P01-FR-012, AC-P01-014, TC-P01-022, TC-P01-029 |
| P01-HARDEN-002 | Learning evidence writes from training must preserve `source_turn_id`, `target_expression_id`, deterministic rule trace, schema version and acceptance/rejection status. Raw AI candidates or local recap text cannot directly become final mastery facts. | P01-FR-013, P01-SPEC-014, AC-P01-015, TC-P01-023, P01-TR-014 |
| P01-HARDEN-002 | Account deletion and retention jobs must cover server-backed TrainingSession, TrainingTurn, TrainingRecap, LearningEvidenceCandidate, media refs and redacted audit refs. | P01-FR-013, AC-P01-015, TC-P01-024 |
| P01-HARDEN-003 | Training responses must reference reviewed `scenario_version_id`, `action_chain_version`, `step_key` and target expression ids. Missing content mapping must produce explicit recoverable or blocked status, not generated unreviewed scenario content. | P01-FR-014, P01-SPEC-015, AC-P01-016, TC-P01-025, P01-TR-015 |
| P01-HARDEN-004 | Voice training must consume trusted backend media refs from the Media/AI Gateway contract, reuse usage reservation/commit/release, and return typed fallback for ASR/TTS/LLM/pronunciation failures. Paid AI voice remains blocked by `commercial-ai-provider-hardening` evidence until that gate passes. | P01-FR-015, P01-SPEC-016, AC-P01-017, TC-P01-026, P01-TR-016 |
| P01-HARDEN-005 | Planner endpoints and services must emit replayable `PlannerDecision` data with rule version, input snapshot refs, reason codes and AI candidate refs when applicable. Config changes must be versioned and testable against fixed fixtures. | P01-FR-016, P01-SPEC-017, AC-P01-018, TC-P01-027, P01-TR-017 |
| P01-HARDEN-006 | Training observability must expose redacted metrics for start, turn, fallback, completion, evidence write, provider status, latency and rollout gate health. Metrics cannot include provider secrets, raw audio, full transcript or raw provider payload. | P01-FR-017, P01-SPEC-018, AC-P01-019, TC-P01-028, P01-TR-018 |

中文等价设计说明：

- P01-HARDEN-001 / Training source of truth：`/training/sessions`、`/training/sessions/{session_id}`、`/training/sessions/{session_id}/turns` 和 `/training/sessions/{session_id}/complete` 是 Product Base/production Training 事实源边界；P0.1 从本地路线升级为稳定产品能力前，这些 endpoint 必须认证、按 owner 限定并由服务端持久化支撑。
- P01-HARDEN-001 / turn replay：Training turn replay 需要 `Idempotency-Key` 与 `session_id`；相同 body 的重复 key 返回原 turn 结果，不一致 replay 返回 `IDEMPOTENCY_CONFLICT`；Flutter 本地 draft attempt 不得计为已接受服务端 turn。
- P01-HARDEN-002 / learning evidence writes：Training 写入 learning evidence 时必须保留 `source_turn_id`、`target_expression_id`、deterministic rule trace、schema version 和接受/拒绝状态；raw AI candidate 或本地 recap text 不能直接成为最终 mastery fact。
- P01-HARDEN-002 / deletion and retention：账号删除和 retention job 必须覆盖服务端 TrainingSession、TrainingTurn、TrainingRecap、LearningEvidenceCandidate、media ref 和脱敏 audit ref。
- P01-HARDEN-003 / content mapping：Training response 必须引用已审阅的 `scenario_version_id`、`action_chain_version`、`step_key` 和 target expression id；缺少内容映射时必须返回明确 recoverable 或 blocked 状态，而不是生成未审阅场景内容。
- P01-HARDEN-004 / voice training：Voice training 必须消费 Media/AI Gateway 契约里的可信后端 media ref，复用 usage reservation/commit/release，并对 ASR/TTS/LLM/pronunciation 失败返回 typed fallback；付费 AI voice 仍要等 `commercial-ai-provider-hardening` evidence 通过。
- P01-HARDEN-005 / planner decisions：Planner endpoint 和 service 必须产出可 replay 的 `PlannerDecision`，包含 rule version、input snapshot ref、reason code，以及适用时的 AI candidate ref；配置变更必须版本化并可用固定 fixture 测试。
- P01-HARDEN-006 / observability：Training observability 只暴露 start、turn、fallback、completion、evidence write、provider status、latency 和 rollout gate health 的脱敏指标；不得包含 provider secret、raw audio、完整 transcript 或 raw provider payload。

P0.1 Training hardening gate result: the OpenAPI Training family is the Product Base/production source-of-truth boundary. The previous local-first Training route is retired；local-first 只是历史 local draft, not Product Base or production ready. Product Base merge, commercial production readiness or release checklist pass claims require `AC-P01-014` through `AC-P01-019` and `TC-P01-021` through `TC-P01-031` to pass, or the corresponding Product Base/release status must explicitly remain blocked.

P0.1 Training hardening 门禁结论：OpenAPI Training family 是 Product Base/production 的事实源边界；此前 local-first Training route 已退役，local-first 只代表历史本地草稿，不代表 Product Base 或 production ready。任何 Product Base merge、commercial production readiness 或 release checklist pass 结论，都必须等 `AC-P01-014` 到 `AC-P01-019` 与 `TC-P01-021` 到 `TC-P01-031` 通过，否则对应 Product Base/release 状态必须明确保持 blocked。

## P0.2 Goal Autopilot Contract Gate / P0.2 Goal Autopilot 契约门禁

Owning stage / 归属阶段：`docs/product/stages/p0-2-training-memory.md`。
Owning increments / 归属增量：`p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint`, `p0-2-followup-a-goal-intake-diagnostic-hardening`, `p0-2-followup-b-autopilot-control-planner-memory`, `p0-2-followup-c-checkpoint-forecast-surfaces`。

| Work package / 工作包 | Contract decision / 契约决策 | Traceability / 追溯 |
| --- | --- | --- |
| P02-API-001 | `POST /goal-autopilot/goals` is the authenticated goal intake boundary. It requires `Idempotency-Key`; missing required header may be rejected at the HTTP binding layer as `400`, replay with the same body returns the original goal summary, while mismatched replay returns `IDEMPOTENCY_CONFLICT`. It creates or revises the single server-owned `GoalProfile` chain for the user, evaluates `SupportedGoalMatrixDecision`, produces a deterministic diagnostic summary when local samples exist, and returns claim guards. Any submitted `diagnostic_samples.audio_ref` must be an authenticated-user-owned trusted `media://audio/...` reference from the Media upload create/complete flow; local paths, unsigned URLs, client-created refs, wrong-owner refs and unvalidated refs fail before goal/diagnostic fact persistence. Unsupported goals return typed unsupported state and cannot create a full plan. | P02-DIAG-FR-001, P02-DIAG-FR-002, P02-DIAG-FR-003, P02-DIAG-FR-004, P02-DIAG-FR-005, P02-DIAG-FR-006, P02-DIAG-FR-007, P02-FUA-FR-004, P02-FUA-FR-005, TC-P02-XCB-005-GOAL-IDEMPOTENCY |
| P02-API-001 | `GET /goal-autopilot/summary` returns the current P0.2 source-of-truth snapshot: active goal, diagnostic, daily plan, next action, forecast and latest checkpoint. Flutter must read this projection instead of computing goal progress locally. | P02-AUTO-FR-001, P02-AUTO-FR-002, P02-AUTO-FR-006 |
| P02-API-002 | `POST /goal-autopilot/plans/generate` creates or recalculates deterministic weekly/daily plans using only accepted upstream facts, memory policy, supported-goal status, user time budget and policy gates. LLM text may only be candidate explanation, never final plan facts. | P02-PLAN-FR-001, P02-PLAN-FR-002, P02-PLAN-FR-003, P02-PLAN-FR-004, P02-PLAN-FR-005, P02-PLAN-FR-006, P02-PLAN-FR-007, P02-PLAN-FR-008 |
| P02-API-002 | `GET /goal-autopilot/daily-plan`, `GET /goal-autopilot/actions/next`, and `POST /goal-autopilot/actions/{plan_item_id}/complete` expose no-choice execution, reason codes, plan item completion and defer/skip state without allowing Flutter to create final mastery, entitlement or official score facts. | P02-AUTO-FR-001, P02-AUTO-FR-002, P02-AUTO-FR-003 |
| P02-API-003 | `GET /goal-autopilot/forecast` returns the server-owned S001 hardened `ProgressForecast`: forecast state, source goal revision, gap summary, ETA range or unavailable reason, confidence band, risk level, risk reason code/text, next checkpoint date, deterministic explanation metadata, claim guard and updated timestamp. Partial, unsupported, low-confidence, stale, recovery-required, deleted or unavailable inputs must block high-precision ETA, goal-complete claims, official score equivalence and guaranteed outcome copy. Forecast AI explanation is candidate-only; when AI/provider use is unavailable or blocked, the response must expose deterministic fallback metadata without creating entitlement, quota, completion or official-score facts. | P02-AUTO-FR-004, P02-AUTO-FR-007, P02-FUC-FR-001, AC-P02-FUC-001, TC-P02-FUC-001..003 |
| P02-API-004 | `GET /goal-autopilot/checkpoints/task` returns the server-owned S002 checkpoint cadence and task-library decision: `CheckpointDue`, `CheckpointNotDue`, `CheckpointLimited` or `CheckpointUnavailable`, due/overdue/not-due status, weekly/biweekly cadence, goal-type task fields, required evidence, product-internal rubric boundary, support/content coverage and limitation reason. Partial, unsupported, entitlement-limited or cost/quota-limited goals must be downgraded server-side and must not create commercial entitlement facts or official-score certification claims. | P02-AUTO-FR-005, P02-FUC-FR-002, AC-P02-FUC-002, TC-P02-FUC-004..006 |
| P02-API-005 | `POST /goal-autopilot/checkpoints` records weekly/biweekly/business checkpoint results, updates forecast and emits a S003 checkpoint-to-plan signal when accepted-confidence evidence changes the plan. Request may include optional `result_status=recorded|failed|skipped`; omitted status is treated as recorded and low confidence is derived server-side from evidence quality. Any submitted `audio_ref` must use the existing trusted Media/AI Gateway `media://audio/...` boundary; local paths, unsigned URLs, client-created refs, wrong-owner refs and unvalidated refs fail before checkpoint persistence. `score_hint` is client evidence metadata only and cannot raise confidence, ETA precision, claim guard, mastery or goal completion. Response `OutcomeCheckpoint` returns result status, plan signal and reason code, while `PlanUpdateSignal` adds optional `source_checkpoint_id`, `rule_version`, `input_snapshot_hash` and `replay_audit_id` for replayable stale/replan evidence. Low-confidence, failed or skipped checkpoint results update risk/limitation state but do not mark goal complete or expose precise ETA. Unsupported/unavailable tasks and task types outside the server-owned task library are rejected with typed errors. Paused/control-blocked/recovery-required/stale state must not silently advance next action. | P02-AUTO-FR-005, P02-AUTO-FR-007, P02-AUTO-FR-008, P02-FUC-FR-002, P02-FUC-FR-003, AC-P02-FUC-003, TC-P02-FUC-007..009, TC-P02-XCB-005-CHECKPOINT-AUDIO |
| P02-API-006 | `GET /goal-autopilot/progress-projection` returns the S004 backend-owned safe goal-progress projection for Home, expression queue and personal Wiki. The response aggregates active goal support status, next action, forecast gap/ETA/risk, latest checkpoint conclusion, surface eligibility, downgrade reason and source refs. It must omit raw diagnostic transcript/audio, raw checkpoint payloads, sensitive target details and provider payloads. Surfaces may render only this projection or backend-owned fragments, and must not compute final goal state, goal completion, ETA precision or claim guards locally. | P02-FUC-FR-004, AC-P02-FUC-004, TC-P02-FUC-010..012 |
| P02-FUC-API-CLEANUP-001 | `ProgressForecast.eta_range` remains an optional nullable ETA range with unchanged payload semantics, but the OpenAPI 3.0.3 schema now uses `type: object`, `nullable: true` and `allOf` around `ProgressForecastEtaRange` instead of `$ref` plus nullable siblings. This removes the six repeated Redocly example warnings across forecast-bearing Goal Autopilot responses and syncs generated Dart OpenAPI hash `d8b492b07c98e948caf0b5912744f05fa6dcd4b76f97f0ece04dc9778df7da0f`. | P02-FUC-FR-001, P02-FUC-FR-007, AC-P02-FUC-007, TC-P02-FUC-022, `P02-FOLLOWUP-C-S007-OPENAPI-NULLABLE-CLEANUP-20260606` |
| P02-FUB-API-001 | `GET /goal-autopilot/control`, `PATCH /goal-autopilot/control`, `POST /goal-autopilot/control/pause` and `POST /goal-autopilot/control/resume` are the server-owned UserAutopilotControl boundary. Flutter may submit update intent, pause intent or resume intent, but the response is the only source of truth for active/paused/policy-blocked state, next-action impact, reminder eligibility impact, replan requirement and reason code. | P02-FUB-FR-001, P02-FUB-FR-002, AC-P02-FUB-001, AC-P02-FUB-002, TC-P02-FUB-001..004 |
| P02-FUB-API-002 | `POST /goal-autopilot/reminders/eligibility` evaluates control status, quiet hours, timezone, notification consent, platform permission, entitlement, quota, support status, active-plan ownership and plan freshness before any reminder schedule/send action. The endpoint validates `plan_item_id`, `reminder_slot`, `current_time` and `platform_permission`; missing or `unknown` platform permission fails closed with `permission_denied`, wrong-owner plan items return `404`, inactive-plan items return `409`, and malformed request fields return `422`. Blocked reminders return explicit reason code and optional `next_allowed_at`, write only low-sensitivity eligibility metrics, and must not be recorded as outbox, completion, refusal, failure or missed-day evidence. | P02-FUB-FR-003, P02-FUB-FR-004, AC-P02-FUB-003, AC-P02-FUB-004, TC-P02-FUB-005..006, TC-P02-FUB-018 |
| P02-FUB-API-003 | `GET /goal-autopilot/reminders/outbox` exposes the scheduler/outbox lifecycle projection for replay, troubleshooting and UI state. Outbox records use stable dedupe keys, lifecycle status, input snapshot hash, rule version and failure metadata; raw notification payloads and sensitive diagnostic details are not exposed. | P02-FUB-FR-004, AC-P02-FUB-004, TC-P02-FUB-007..008 |
| P02-FUB-API-004 | `POST /goal-autopilot/recovery/replan` creates a deterministic RecoveryPlanDecision for missed day, skip, defer, resume-after-pause gap, stale plan or expired item. The response must choose exactly one primary mode: `compress`, `defer` or `replace`; it must not stack all overdue work into the next daily plan. | P02-FUB-FR-005, AC-P02-FUB-005, TC-P02-FUB-009..010 |
| P02-FUB-API-005 | `POST /goal-autopilot/item-policy/decisions` exposes item-level policy decisions for expressions, scenarios, diagnostic weakness tags or plan items without using a future `/memory` path. It returns deterministic due decisions, overlearning-cap/interleaving reason codes and replay refs; AI output cannot persist final review schedule. | P02-FUB-FR-006, AC-P02-FUB-006, TC-P02-FUB-011..012; supporting replay TC-P02-FUB-015..017 |
| P02-FUB-API-006 | `GET /goal-autopilot/mastery-transitions` and `GET /goal-autopilot/replay-audits` expose read-only audit projections for accepted-evidence L0-L5 transitions and deterministic replay. They do not let clients write final mastery, official score equivalence, review schedule or goal completion facts. | P02-FUB-FR-007, P02-FUB-FR-008, AC-P02-FUB-007, AC-P02-FUB-008, TC-P02-FUB-013..017 |

中文等价设计说明：

- P02-API-001 / `POST /goal-autopilot/goals`：这是认证后的目标 intake 边界；必须使用 `Idempotency-Key`，相同请求 replay 返回原 goal summary，不一致 replay 返回 `IDEMPOTENCY_CONFLICT`。服务端创建或修订用户唯一的 `GoalProfile` 链，执行 `SupportedGoalMatrixDecision`，在有本地样本时产生确定性 diagnostic summary，并返回 claim guard。`diagnostic_samples.audio_ref` 必须是当前认证用户拥有、来自 Media upload create/complete 流程的可信 `media://audio/...` ref；本地路径、未签名 URL、客户端伪造 ref、跨用户 ref 和未验证 ref 都不能写入 goal/diagnostic fact。Unsupported goal 只能返回 typed unsupported state，不能生成完整 plan。
- P02-API-001 / `GET /goal-autopilot/summary`：返回当前 P0.2 事实源快照，包括 active goal、diagnostic、daily plan、next action、forecast 和 latest checkpoint；Flutter 必须读取这个 projection，而不是本地计算 goal progress。
- P02-API-002 / `POST /goal-autopilot/plans/generate`：只基于已接受上游事实、memory policy、supported-goal status、用户时间预算和 policy gate 生成或重算确定性的 weekly/daily plan；LLM text 只能作为候选解释，不能成为最终 plan fact。
- P02-API-002 / daily plan and action execution：`GET /goal-autopilot/daily-plan`、`GET /goal-autopilot/actions/next` 和 `POST /goal-autopilot/actions/{plan_item_id}/complete` 暴露 no-choice 执行、reason code、plan item completion 和 defer/skip 状态，但不允许 Flutter 写入最终 mastery、entitlement 或 official score fact。
- P02-API-003 / forecast：`GET /goal-autopilot/forecast` 返回服务端拥有的 S001 hardened `ProgressForecast`，包含 forecast state、source goal revision、gap summary、ETA range 或 unavailable reason、confidence band、risk level、risk reason、next checkpoint date、deterministic explanation metadata、claim guard 和 updated timestamp。partial、unsupported、low-confidence、stale、recovery-required、deleted 或 unavailable input 必须阻断高精度 ETA、goal-complete claim、official score equivalence 和 guaranteed outcome copy；Forecast AI explanation 只作候选，AI/provider 不可用或被阻断时必须返回 deterministic fallback metadata，不能创建 entitlement、quota、completion 或 official-score fact。
- P02-API-004 / checkpoint task：`GET /goal-autopilot/checkpoints/task` 返回服务端拥有的 S002 checkpoint cadence 和 task-library decision，包括 `CheckpointDue`、`CheckpointNotDue`、`CheckpointLimited` 或 `CheckpointUnavailable`、due/overdue/not-due 状态、weekly/biweekly cadence、goal-type task fields、required evidence、内部 rubric 边界、support/content coverage 和 limitation reason。partial、unsupported、entitlement-limited 或 cost/quota-limited goal 必须由服务端降级，不能产生商业权益事实或 official-score certification claim。
- P02-API-005 / checkpoint result：`POST /goal-autopilot/checkpoints` 记录 weekly/biweekly/business checkpoint 结果，更新 forecast，并在 accepted-confidence evidence 改变 plan 时发出 S003 checkpoint-to-plan signal。`result_status` 可选，缺省按 recorded 处理，低置信由服务端根据 evidence quality 判断。`audio_ref` 必须走既有可信 Media/AI Gateway `media://audio/...` 边界；本地路径、未签名 URL、客户端伪造 ref、跨用户 ref 和未验证 ref 在持久化前失败。`score_hint` 只是客户端 evidence metadata，不能提高 confidence、ETA precision、claim guard、mastery 或 goal completion。低置信、失败或 skipped checkpoint 只更新风险/限制状态，不标记 goal complete，也不暴露精确 ETA；不受支持任务、库外 task type 以及 paused/control-blocked/recovery-required/stale 状态都不能静默推进 next action。
- P02-API-006 / progress projection：`GET /goal-autopilot/progress-projection` 返回 S004 后端拥有的安全 goal-progress projection，供 Home、expression queue 和 personal Wiki 使用；响应聚合 active goal support status、next action、forecast gap/ETA/risk、latest checkpoint conclusion、surface eligibility、downgrade reason 和 source ref，并必须隐藏 raw diagnostic transcript/audio、raw checkpoint payload、敏感目标细节和 provider payload。各 surface 只能渲染该 projection 或后端片段，不得本地计算最终 goal state、goal completion、ETA precision 或 claim guard。
- P02-FUC-API-CLEANUP-001 / nullable cleanup：`ProgressForecast.eta_range` 的 payload 语义保持为可选 nullable ETA range，但 OpenAPI 3.0.3 schema 改为 `type: object`、`nullable: true` 和 `allOf` 包裹 `ProgressForecastEtaRange`，避免 `$ref` 与 nullable sibling 引起的六个 Redocly example 警告，并同步 generated Dart OpenAPI hash `d8b492b07c98e948caf0b5912744f05fa6dcd4b76f97f0ece04dc9778df7da0f`。
- P02-FUB-API-001 / autopilot control：`GET /goal-autopilot/control`、`PATCH /goal-autopilot/control`、`POST /goal-autopilot/control/pause` 和 `POST /goal-autopilot/control/resume` 是服务端拥有的 UserAutopilotControl 边界；Flutter 可提交 update/pause/resume intent，但 active/paused/policy-blocked 状态、next-action impact、reminder eligibility impact、replan requirement 和 reason code 以 response 为唯一事实源。
- P02-FUB-API-002 / reminder eligibility：`POST /goal-autopilot/reminders/eligibility` 在任何 reminder schedule/send 之前评估 control status、quiet hours、timezone、notification consent、platform permission、entitlement、quota、support status、active-plan ownership 和 plan freshness。endpoint 校验 `plan_item_id`、`reminder_slot`、`current_time` 和 `platform_permission`；缺失或 `unknown` 权限按 `permission_denied` fail closed，wrong-owner item 返回 `404`，inactive-plan item 返回 `409`，格式错误字段返回 `422`。被阻断 reminder 返回明确 reason code 和可选 `next_allowed_at`，只写低敏 eligibility metrics，不能被记录成 outbox、completion、refusal、failure 或 missed-day evidence。
- P02-FUB-API-003 / reminder outbox：`GET /goal-autopilot/reminders/outbox` 暴露 scheduler/outbox 生命周期 projection，用于 replay、排障和 UI 状态；outbox record 使用稳定 dedupe key、lifecycle status、input snapshot hash、rule version 和 failure metadata，不暴露 raw notification payload 或敏感 diagnostic details。
- P02-FUB-API-004 / recovery replan：`POST /goal-autopilot/recovery/replan` 为 missed day、skip、defer、resume-after-pause gap、stale plan 或 expired item 生成确定性 `RecoveryPlanDecision`；response 必须只选择一个 primary mode：`compress`、`defer` 或 `replace`，不能把所有逾期任务堆到下一个 daily plan。
- P02-FUB-API-005 / item policy：`POST /goal-autopilot/item-policy/decisions` 为 expressions、scenarios、diagnostic weakness tags 或 plan items 暴露 item-level policy decision，不使用未来 `/memory` path；返回确定性的 due decision、overlearning-cap/interleaving reason code 和 replay ref，AI output 不能持久化最终 review schedule。
- P02-FUB-API-006 / audit projections：`GET /goal-autopilot/mastery-transitions` 和 `GET /goal-autopilot/replay-audits` 只暴露 accepted-evidence L0-L5 transition 与 deterministic replay 的只读 audit projection；客户端不能写入 final mastery、official score equivalence、review schedule 或 goal completion fact。

P02-API-001 through P02-FUB-API-006 gate result: P0.2 implementation-level endpoints are allowed only inside the `Goal Autopilot` family and only for deterministic local source-of-truth behavior. Followup-B allows control, reminder eligibility/outbox, recovery, item-policy and audit contracts; paid AI depth, external scoring evidence, commercial release and official-score equivalence remain gated by P02-PG-001 through P02-PG-005 and P0 commercial gates.

P02-API-001 到 P02-FUB-API-006 门禁结论：P0.2 实现级 endpoint 只允许出现在 `Goal Autopilot` family 内，并且只覆盖确定性本地事实源行为。Followup-B 允许 control、reminder eligibility/outbox、recovery、item-policy 和 audit 契约；paid AI depth、external scoring evidence、commercial release 和 official-score equivalence 仍由 P02-PG-001 到 P02-PG-005 以及 P0 commercial gate 管控。

## Error Model / 错误模型

OpenAPI component / OpenAPI 组件：`ErrorResponse`。

| Code / 代码 | Meaning / 含义 | Typical status / 常见状态码 |
| --- | --- | --- |
| `UNAUTHENTICATED` | 未登录、token 缺失或 token 失效 | 401 |
| `FORBIDDEN` | 已登录但无权限、账号状态不允许或 admin 权限不足 | 403 |
| `ENTITLEMENT_REQUIRED` | 需要付费权益或当前 plan 不满足 | 402 / 403 |
| `USAGE_LIMIT_EXCEEDED` | AI/ASR/TTS/评分/训练额度耗尽 | 429 |
| `INVALID_RECEIPT` | Apple/Google 凭据无效 | 400 |
| `PRODUCT_MISMATCH` | 商店商品与后端 allowlist 或计划不匹配 | 409 |
| `SUBSCRIPTION_EXPIRED` | 订阅已过期、退款或撤销 | 403 |
| `IDEMPOTENCY_CONFLICT` | 幂等键重复但参数不一致 | 409 |
| `SCHEMA_VALIDATION_FAILED` | 请求或 AI/provider 输出 schema 无效 | 422 |
| `PROVIDER_UNAVAILABLE` | AI/ASR/TTS/评分/支付 provider 不可用 | 503 |
| `DELETE_IN_PROGRESS` | 账号删除任务处理中 | 409 |
| `RESOURCE_NOT_FOUND` | 指定资源不存在或不属于当前用户 | 404 |
| `CONFLICT` | 当前状态不允许该操作 | 409 |

## Versioning And Compatibility / 版本与兼容性

- Initial API path prefix: `/v1`.
- Response body uses `schema_version: 1`.
- Breaking path or DTO changes require ADR or migration notes.
- Additive optional fields are compatible only when clients can ignore unknown fields.
- Generated Dart client drift check is required before implementation merge.
- `lib/generated/api/` now contains the generated OpenAPI Dart boundary and `.openapi-sha256`; `npm run check:dart-client-drift` runs in `generated_client_drift` mode and also verifies documented handwritten-client exceptions.

- 初始 API path prefix 是 `/v1`。
- Response body 使用 `schema_version: 1`。
- Breaking path 或 DTO change 必须有 ADR 或 migration notes。
- 只有客户端能忽略未知字段时，新增 optional field 才视为兼容。
- 实现合并前必须通过 generated Dart client drift check。
- `lib/generated/api/` 当前承载 generated OpenAPI Dart boundary 和 `.openapi-sha256`；`npm run check:dart-client-drift` 以 `generated_client_drift` mode 运行，并校验已记录的 handwritten-client exception。

## Idempotency Rules / 幂等规则

| Flow / 流程 | Idempotency input / 幂等输入 | Rule / 规则 |
| --- | --- | --- |
| Apple/Google verify<br>Apple/Google 校验 | `Idempotency-Key` + provider transaction/token | Same key and same body returns the previous result<br>相同 key 和相同 body 返回上一次结果 |
| Restore purchase<br>恢复购买 | `Idempotency-Key` | Empty restore is a success response with empty result, not entitlement grant<br>空恢复是结果为空的成功响应，不授予权益 |
| Usage reserve/commit/release<br>用量 reserve/commit/release | `Idempotency-Key` or reservation id | Reserve cannot be double-counted; commit/release are terminal transitions<br>Reserve 不得重复计数；commit/release 是终态转换 |
| Account deletion<br>账号删除 | `Idempotency-Key` | Duplicate deletion request returns current deletion job<br>重复删除请求返回当前删除 job |
| Training/practice turn<br>训练/练习 turn | `Idempotency-Key` + session id | Replay cannot create duplicate turn/evidence<br>Replay 不得创建重复 turn/evidence |
| Media upload create<br>媒体上传创建 | `Idempotency-Key` + user + client_upload_id/checksum | Replay returns the same pending or validated media asset without creating duplicate provider-accessible refs<br>Replay 返回同一个 pending 或 validated media asset，不创建重复 provider-accessible ref |
| AI retention job<br>AI 保留任务 | `Idempotency-Key` + scope + reason + user_ref/deletion job ref | Replay returns the same retention job status and does not double-delete or double-count evidence<br>Replay 返回同一 retention job 状态，不重复删除或重复统计 evidence |
| Autopilot control update/pause/resume<br>Autopilot control 更新/暂停/恢复 | `Idempotency-Key` + user + active goal revision + requested control transition | Replay returns the same control result, deduped audit note and notification impact without duplicate cancellation or replan effects<br>Replay 返回相同 control result、去重后的 audit note 和 notification impact，不产生重复取消或 replan effect |
| Autopilot recovery replan<br>Autopilot recovery replan | `Idempotency-Key` + user + goal revision + source_event + rule_version | Replay returns the same RecoveryPlanDecision and does not create duplicate daily plan replacements<br>Replay 返回同一个 RecoveryPlanDecision，不创建重复 daily plan replacement |
| Reminder outbox scheduling<br>Reminder outbox 调度 | dedupe key from user + goal revision + plan item + reminder slot + rule_version | Duplicate schedule attempts resolve to the existing outbox record or blocked state<br>重复调度解析为既有 outbox record 或 blocked state |

## MVP Backend Practice/AI Contract Note / MVP 后端 Practice/AI 契约说明

Owning increment / 归属增量：`docs/product/increments/mvp-backend-practice-ai/`。

- `/practice/sessions` creates or resumes only Product Base official scenario practice sessions for the authenticated user.
- `/practice/sessions/{session_id}/turns` requires `Idempotency-Key`; replay with the same body returns the same turn, while a mismatched body returns `IDEMPOTENCY_CONFLICT`.
- `/practice/sessions/{session_id}/turns` may accept transcript-only input, but any submitted `audio_ref` must be an authenticated-user-owned trusted `media://audio/...` reference from the Media upload create/complete flow. Local file paths, `file://` refs, unsigned URLs, client-created refs, wrong-owner refs and unvalidated refs fail before turn persistence, coach feedback or provider calls.
- `/practice/sessions/{session_id}/complete` returns a `SessionSummary` plus candidate-only learning inputs; it must not write final mastery facts.
- `/ai/transcribe`, `/ai/tts`, `/ai/pronunciation`, `/ai/coach-turn`, and `/ai/feedback` are server-side provider gateway contracts. Request schemas use `additionalProperties: false`; clients must not submit provider secrets or raw provider credentials.
- Provider timeout, unavailable, media invalid, or invalid schema states must return either typed gateway status or `recoverable_error` feedback; invalid provider output must not become successful user-visible feedback.

- `/practice/sessions` 只为认证用户创建或恢复 Product Base 官方场景练习 session。
- `/practice/sessions/{session_id}/turns` 需要 `Idempotency-Key`；相同 body 的 replay 返回同一 turn，不一致 body 返回 `IDEMPOTENCY_CONFLICT`。
- `/practice/sessions/{session_id}/turns` 可以接受 transcript-only input；如果提交 `audio_ref`，则必须是当前认证用户拥有、来自 Media upload create/complete 流程的可信 `media://audio/...` ref。本地文件路径、`file://` ref、未签名 URL、客户端伪造 ref、跨用户 ref 和未验证 ref 在 turn persistence、coach feedback 或 provider call 前失败。
- `/practice/sessions/{session_id}/complete` 返回 `SessionSummary` 和 candidate-only learning input；不得写入最终 mastery fact。
- `/ai/transcribe`、`/ai/tts`、`/ai/pronunciation`、`/ai/coach-turn` 和 `/ai/feedback` 是服务端 provider gateway 契约。Request schema 使用 `additionalProperties: false`；客户端不得提交 provider secret 或 raw provider credential。
- Provider timeout、unavailable、media invalid 或 invalid schema 状态必须返回 typed gateway status 或 `recoverable_error` feedback；无效 provider output 不能变成用户可见的成功反馈。

## P0.1 DashScope Provider Adapter Contract Note / P0.1 DashScope Provider Adapter 契约说明

Owning increment / 归属增量：`docs/product/increments/p0-1-expression-automation-training/`；change request / 变更请求：`CR-20260601-001`。

- AI REST path 不新增：Flutter 继续调用 `/ai/transcribe`、`/ai/tts`、`/ai/pronunciation`、`/ai/coach-turn`、`/ai/feedback`。
- Provider implementation 可配置：`deterministic` 用于本地/CI；`dashscope` 用于当前后端真实 Qwen LLM、DashScope TTS、Paraformer ASR adapter。
- `TranscribeRequest.audio_ref` 必须是后端/provider 可访问且带后端签名媒体元数据的 media ref。DashScope ASR 不得信任客户端自填的 `duration_seconds`/`bytes` query；客户端本地文件路径、未签名 HTTP ref、空 ref、media invalid、provider no result 均不得转成伪成功 transcript。
- `TtsResponse.audio_ref` 是后端归一化媒体引用；DashScope TTS 首版必须至少支持 text/model/voice 稳定 cache key，持久对象存储 URL/proxy 是 release-hardening 项。
- `CoachTurnResponse.feedback` 只能来自 schema-valid provider output 或 deterministic fallback。无效 JSON、schema mismatch、timeout 或 provider unavailable 必须返回 `validation_status=fallback` 和 recoverable feedback。
- 所有 provider 调用必须复用现有 `AiGatewayService` usage reservation/commit/release 规则，不绕过 entitlement/usage boundary。
- Response 不得包含 provider secret、raw provider payload、raw audio 或完整敏感 transcript。日志/observability 仅记录 provider、model、status、latency、fallback reason、schema version、usage family、request id，以及适用时的 token estimate、audio duration 或 estimated cost bucket。
- Provider policy 必须由后端 entitlement/usage facts 决定，可按 free/pro/enterprise tier 限制模型、请求频率、文本长度和音频时长；客户端请求体不得直接选择商业 tier。
- Live DashScope E2E 属于外部服务证据；默认 automated tests 必须使用 mock HTTP/fixtures，不依赖真实 `DASHSCOPE_API_KEY`。

## MVP Backend Learning/Memory Contract Note / MVP 后端 Learning/Memory 契约说明

Owning increment / 归属增量：`docs/product/increments/mvp-backend-learning-memory/`。

- `/expressions/queue` returns stable target-expression practice tasks, priority, task type, due time, and explicit empty states.
- `/expressions/tasks/{queue_item_id}/complete` persists the task attempt and returns progress linked to accepted learning evidence.
- `/favorites/expressions` requires `target_expression_id` so duplicate favorites are resolved by stable expression identity; delete removes the favorite from the active list.
- `/learning/evidence` validates evidence before it can update final mastery; rejected evidence is visible in the write response but not in accepted evidence lists or mastery projections.
- `/learning/mastery`, `/review/items`, `/learning/wiki`, and `/learning/history` are server-backed projections of accepted learning evidence.
- `/learning/history/{history_entry_id}` deletes the history entry visibility without deleting the underlying saved expression/wiki projection.

- `/expressions/queue` 返回稳定的 target-expression practice task、priority、task type、due time 和显式 empty state。
- `/expressions/tasks/{queue_item_id}/complete` 持久化 task attempt，并返回与 accepted learning evidence 关联的 progress。
- `/favorites/expressions` 要求 `target_expression_id`，以 stable expression identity 去重收藏；delete 会把该 favorite 从 active list 移除。
- `/learning/evidence` 在 evidence 可更新最终 mastery 前先做校验；被拒绝的 evidence 会出现在写入响应中，但不会出现在 accepted evidence list 或 mastery projection 中。
- `/learning/mastery`、`/review/items`、`/learning/wiki` 和 `/learning/history` 是基于 accepted learning evidence 的服务端 projection。
- `/learning/history/{history_entry_id}` 只删除 history entry 的可见性，不删除底层 saved expression/wiki projection。

## MVP Backend Membership/Boundary Contract Note / MVP 后端 Membership/Boundary 契约说明

Owning increment / 归属增量：`docs/product/increments/mvp-backend-membership-boundary/`。

- `DELETE /user/me` requires authenticated user context and `Idempotency-Key`; it revokes active sessions, deletes user-owned Product Base learning/practice/profile rows, marks the account as deleted, returns the deletion job, and writes a redacted audit event.
- `GET /user/deletion-status` returns the latest deletion job for the authenticated user, including `failure_reason` for recoverable or manually inspectable failure states.
- `/membership/boundary` returns MVP membership state as an entry/boundary fact only; it must not claim production payment, full entitlement gating, or commercial launch readiness.
- `/membership/android/purchase` and `/membership/android/restore` return platform-limited responses because Android billing is not connected in this MVP backend increment.
- `/learning/report/summary`, `/offline-content/status`, and `/achievements/status` return explicit empty/placeholder responses rather than silently implying implemented report, offline content, or achievement systems.

- `DELETE /user/me` 要求认证用户上下文和 `Idempotency-Key`；它会撤销 active session，删除用户拥有的 Product Base learning/practice/profile row，将账号标记为 deleted，返回 deletion job，并写入脱敏 audit event。
- `GET /user/deletion-status` 返回认证用户最新 deletion job，并包含可恢复或需人工检查失败状态的 `failure_reason`。
- `/membership/boundary` 只返回 MVP membership state，作为入口/边界事实；不得宣称 production payment、完整 entitlement gating 或 commercial launch readiness。
- `/membership/android/purchase` 和 `/membership/android/restore` 返回平台受限响应，因为该 MVP backend increment 尚未接入 Android billing。
- `/learning/report/summary`、`/offline-content/status` 和 `/achievements/status` 返回明确 empty/placeholder response，不能静默暗示 report、offline content 或 achievement system 已实现。

## Deferred Boundaries / 延后边界

The following are intentionally excluded from implementation-level OpenAPI until Product Manager creates owning increment definitions and specs:

在 Product Manager 创建归属增量定义和 spec 前，以下范围有意排除在实现级 OpenAPI 之外：

- P1 notebook/vocabulary arbitrary phrase lookup and notes.
- P1 productized scoring card and scoring rubric.
- P1/P2 expanded scenario packages, CEFR mapping, CMS/content production workflow.
- P2 full A1-C2 content system.
- Public user-generated scenario/community workflows.

- P1 notebook/vocabulary 任意短语查询和笔记。
- P1 产品化 scoring card 和 scoring rubric。
- P1/P2 扩展 scenario package、CEFR mapping、CMS/content production workflow。
- P2 完整 A1-C2 content system。
- 公开用户生成 scenario/community workflow。

OpenAPI may reserve tags or extension metadata for these boundaries, but must not expose executable request/response schemas for them in this stage.

OpenAPI 可以为这些边界保留 tag 或 extension metadata，但当前阶段不得暴露可执行的 request/response schema。

## Contract Acceptance Gate / 契约验收门禁

Implementation may not start until:

实现不得开始，直到满足以下条件：

- `docs/architecture/openapi/speakeasy-api.yaml` exists and parses as OpenAPI.
- `npm run lint:openapi` passes against the OpenAPI source of truth.
- `npm run check:openapi-contract` passes for examples, traceability, 4XX responses, and deferred-boundary rules.
- `npm run check:dart-client-drift` passes for generated Dart client drift.
- `npm run check:api-contract` passes as the combined local gate.
- OpenAPI paths map to Product Base stable behavior, P0 approved increment, or P0.1 approved increment.
- Each implementation-level endpoint defines auth, request, response, errors, examples, and traceability metadata.
- Payment, usage, deletion and turn replay define idempotency behavior.
- P0.2 Goal Autopilot paths remain limited to the approved owning P0.2 increments, including Followup-B, and P02 policy gates; P1/P2 remain deferred unless a new Product Manager-approved increment is added.
- Product Object Governance Check returns pass after OpenAPI generation.

- `docs/architecture/openapi/speakeasy-api.yaml` 已存在，并且能按 OpenAPI 解析。
- `npm run lint:openapi` 针对 OpenAPI 事实源通过。
- `npm run check:openapi-contract` 针对 examples、traceability、4XX responses 和 deferred-boundary rules 通过。
- `npm run check:dart-client-drift` 针对 generated Dart client drift 通过。
- `npm run check:api-contract` 作为组合本地门禁通过。
- OpenAPI path 能映射到 Product Base stable behavior、P0 approved increment 或 P0.1 approved increment。
- 每个实现级 endpoint 都定义 auth、request、response、errors、examples 和 traceability metadata。
- Payment、usage、deletion 和 turn replay 都定义 idempotency behavior。
- P0.2 Goal Autopilot path 必须限定在已批准的 P0.2 归属增量（含 Followup-B）和 P02 policy gate 内；除非新增 Product Manager 批准的增量，否则 P1/P2 保持 deferred。
- OpenAPI 生成后，Product Object Governance Check 返回 pass。

## P0.2 Followup-E Speaking Diagnostic Production API Contract / P0.2 Followup-E 口语诊断生产 API 契约

Owning increment: `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。Phase 2 contract status: API family drafted in markdown for planning/contract evidence only. Machine-readable OpenAPI, generated Dart drift artifacts, backend implementation and diagnostic assessment submit/read paths remain planned until an approved implementation slice accepts executable evidence.

归属增量：`docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。Phase 2 契约状态：API family 仅以 markdown 起草，用作规划和契约证据。机器可读 OpenAPI、generated Dart drift artifact、后端实现以及 diagnostic assessment submit/read path 仍处于计划状态，直到获批 implementation slice 接受可执行证据。

### Contract Purpose / 契约目的
Provide a backend-owned diagnostic audio boundary for Goal Autopilot. Flutter can request upload sessions, upload local audio through the approved media path, submit trusted `audio_ref` samples for diagnostic assessment, read the diagnostic result, and request deletion. Flutter cannot create final diagnostic facts or synthesize `audio_ref`.

为 Goal Autopilot 提供后端拥有的 diagnostic audio 边界。Flutter 可以请求 upload session，通过已批准 media path 上传本地音频，提交可信 `audio_ref` 样本进行 diagnostic assessment，读取诊断结果并请求删除；Flutter 不能创建最终 diagnostic fact，也不能合成 `audio_ref`。

### Endpoint Family / Endpoint 家族
| Contract ID | Method / path | Purpose / 目的 | Auth / 认证 | Idempotency / 幂等 |
| --- | --- | --- | --- | --- |
| P02-FUE-API-001 | `POST /goal-autopilot/diagnostic-audio/uploads` | Create a diagnostic upload session for one sample.<br>为单个样本创建 diagnostic upload session。 | authenticated user<br>认证用户 | `Idempotency-Key` + `goal_profile_id` + `goal_revision` + `sample_ref` + `client_upload_id` |
| P02-FUE-API-002 | `POST /goal-autopilot/diagnostic-audio/uploads/{upload_session_id}/complete` | Mark upload complete and request backend validation/quality gate.<br>标记上传完成，并请求后端 validation/quality gate。 | owner only<br>仅 owner | `Idempotency-Key` + upload session |
| P02-FUE-API-003 | `POST /goal-autopilot/diagnostic-assessments` | Submit accepted audio refs and/or text fallback samples for assessment.<br>提交已接受 audio ref 和/或 text fallback sample 进行 assessment。 | owner only<br>仅 owner | `Idempotency-Key` + goal revision + sample refs |
| P02-FUE-API-004 | `GET /goal-autopilot/diagnostic-assessments/{diagnostic_id}` | Read accepted diagnostic state/result.<br>读取已接受 diagnostic state/result。 | owner only<br>仅 owner | read-only<br>只读 |
| P02-FUE-API-005 | `DELETE /goal-autopilot/diagnostic-audio/{audio_ref}` | Delete or redact one diagnostic audio sample and update privacy state.<br>删除或脱敏一个 diagnostic audio sample，并更新 privacy state。 | owner only<br>仅 owner | `Idempotency-Key` + `audio_ref` |

### Upload Create Request / 上传创建请求
Required fields / 必填字段：
- `goal_profile_id`
- `goal_revision`
- `sample_ref`
- `task_type`: `read_aloud`, `listen_repeat_or_retell`, `goal_context_free_answer`
- `client_upload_id`
- `content_type`
- `byte_size`
- `checksum_sha256`
- `estimated_duration_seconds`

Response fields / 响应字段：
- `upload_session_id`
- `sample_ref`
- `upload_status`: `created`, `replayed`, `blocked`
- `upload_target`: implementation-defined backend upload target; must not expose provider secret；后端实现定义的上传目标，不得暴露 provider secret。
- `expires_at`
- `max_bytes`
- `accepted_content_types`
- `schema_version`

### Upload Complete Response / 上传完成响应
Response fields / 响应字段：
- `upload_session_id`
- `sample_ref`
- `sample_id`
- `audio_ref` when validation succeeds；validation 成功时返回。
- `quality_status`: `accepted`, `too_short`, `silent`, `noisy`, `clipped`, `unsupported_format`, `provider_unavailable`, `policy_blocked`
- `quality_reason_code`
- `duration_seconds`
- `retention_state`
- `next_action`: `submit_diagnostic`, `retry_recording`, `use_text_fallback`

### Diagnostic Assessment Request / 诊断评估请求
Required fields / 必填字段：
- `goal_profile_id`
- `goal_revision`
- `samples[]`

Each sample may include / 每个 sample 可包含：
- `sample_ref`
- `task_type`
- `audio_ref` for backend-accepted audio sample；用于后端已接受的音频样本。
- `transcript` for text fallback or user-confirmed text only；仅用于文本兜底或用户确认文本。
- `transcript_source=user_text` when the client submits text fallback；客户端提交文本兜底时使用。
- `duration_seconds` as backend-confirmed value when audio-backed；音频支撑样本必须使用后端确认的时长值。

Validation rules / 校验规则：
- A sample with `audio_ref` must belong to the authenticated user and current goal revision or accepted recalibration path.
- A sample with `transcript_source=user_text` cannot create acoustic dimensions.
- `transcript_source=audio_asr` is backend-generated or backend-confirmed only; a client-supplied `audio_asr` transcript must fail validation or be ignored before accepted diagnostic facts are created.
- Request must fail or downgrade if a client sends local file path, unsigned URL, stale/expired ref, cross-user ref, unsupported task type or forbidden dimensions.

- 带 `audio_ref` 的 sample 必须属于认证用户，并且匹配当前 goal revision 或已接受 recalibration path。
- 带 `transcript_source=user_text` 的 sample 不得创建 acoustic dimension。
- `transcript_source=audio_asr` 只能由后端生成或确认；客户端提交的 `audio_asr` transcript 必须在 accepted diagnostic fact 创建前校验失败或被忽略。
- 如果客户端发送本地文件路径、未签名 URL、stale/expired ref、cross-user ref、不支持的 task type 或 forbidden dimension，请求必须失败或降级。

### Diagnostic Assessment Response / 诊断评估响应
Response fields / 响应字段：
- `diagnostic_id`
- `goal_profile_id`
- `goal_revision`
- `diagnostic_mode`: `audio_full`, `audio_partial`, `text_only`
- `status`: `accepted`, `low_confidence`, `degraded`, `recoverable_error`, `blocked`
- `confidence_band`: `high`, `medium`, `low`
- `sample_count`
- `accepted_audio_sample_count`
- `quality_flags[]`
- `top_weaknesses[]`
- `next_training_focus`
- `claim_guard`
- `recalibration_available`
- `safe_source_refs[]`
- `schema_version`

Forbidden response fields / 禁止响应字段：
- raw audio bytes
- full signed URLs
- provider secret
- raw provider payload
- unrestricted full transcript
- official IELTS/TOEFL equivalent score
- guaranteed outcome or goal completion flag
- entitlement, billing or release approval state

- 原始音频字节。
- 完整 signed URL。
- provider secret。
- raw provider payload。
- 不受限制的完整 transcript。
- official IELTS/TOEFL equivalent score。
- guaranteed outcome 或 goal completion flag。
- entitlement、billing 或 release approval state。

### Delete Response / 删除响应
Response fields / 响应字段：
- `audio_ref`
- `delete_status`: `deleted`, `redacted`, `already_deleted`, `not_found`
- `diagnostic_impact`: `diagnostic_degraded`, `diagnostic_unavailable`, `no_active_result_change`
- `retention_state`
- `safe_source_refs[]`

### Errors / 错误
| Code / 代码 | Status / 状态码 | Recovery / 恢复 |
| --- | --- | --- |
| `UNAUTHENTICATED` | 401 | Sign in again.<br>重新登录。 |
| `FORBIDDEN` | 403 | Do not expose existence of another user's audio.<br>不得暴露其他用户音频是否存在。 |
| `RESOURCE_NOT_FOUND` | 404 | Show deleted/unavailable state.<br>展示已删除或不可用状态。 |
| `INVALID_DIAGNOSTIC_AUDIO_REF` | 400 | Retry upload or use text fallback.<br>重试上传或使用文本兜底。 |
| `DIAGNOSTIC_AUDIO_QUALITY_LOW` | 422 | Re-record or continue low-confidence.<br>重新录制，或以低置信继续。 |
| `DIAGNOSTIC_TEXT_ONLY_LIMITED` | 200/202 | Continue with limited diagnosis and recalibration prompt.<br>以受限诊断继续，并提示后续 recalibration。 |
| `USAGE_LIMIT_EXCEEDED` | 429 | Downgrade to text/low-depth path.<br>降级到文本或低深度路径。 |
| `ENTITLEMENT_REQUIRED` | 402/403 | Show server-owned limit and available fallback.<br>展示服务端拥有的限制和可用 fallback。 |
| `PROVIDER_UNAVAILABLE` | 503 | Use deterministic fallback or retry later.<br>使用 deterministic fallback 或稍后重试。 |
| `IDEMPOTENCY_CONFLICT` | 409 | Retry with a new idempotency key or original payload.<br>使用新的 idempotency key 或原始 payload 重试。 |

### Compatibility And OpenAPI Gate / 兼容性与 OpenAPI 门禁
- This markdown contract is sufficient for Phase 2 planning and Phase 3 AC/TC mapping.
- Trusted diagnostic-audio create/complete/delete implementation can rely on `docs/architecture/openapi/speakeasy-api.yaml` and `lib/generated/api/` after `npm run check:api-contract` and `npm run check:dart-client-drift` pass.
- Diagnostic assessment submit/read implementation cannot start until those paths and result schemas are added to OpenAPI and generated Dart.
- Existing `POST /goal-autopilot/goals` remains compatible; it may accept existing text fallback samples until the new diagnostic assessment flow is implemented.
- No client may depend on these paths before OpenAPI/generated client drift gates pass.

- 该 markdown contract 足够支撑 Phase 2 planning 和 Phase 3 AC/TC mapping。
- Trusted diagnostic-audio create/complete/delete 实现可以在 `npm run check:api-contract` 和 `npm run check:dart-client-drift` 通过后依赖 `docs/architecture/openapi/speakeasy-api.yaml` 与 `lib/generated/api/`。
- Diagnostic assessment submit/read 实现必须等相关 path 和 result schema 加入 OpenAPI 并生成 Dart 后才能开始。
- 现有 `POST /goal-autopilot/goals` 保持兼容；在新的 diagnostic assessment flow 实现前，它可以继续接受现有 text fallback sample。
- OpenAPI/generated client drift gate 通过前，任何客户端都不得依赖这些 path。
