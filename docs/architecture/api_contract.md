# API Contract

## 状态

Proposed - API Contract/OpenAPI source-of-truth 已建立。本文是人读的 API 契约总览；机器可校验的 OpenAPI source of truth 是 `docs/architecture/openapi/speakeasy-api.yaml`。

本文不替代领域模型、数据库 migration、AI prompt/schema、UX screen spec、QA test plan 或代码实现。Backend、Frontend、QA 在消费 OpenAPI 前，必须先完成 OpenAPI lint、契约追溯检查和 Product Object Governance Check。

## Source Of Truth

| Artifact | Path | Ownership |
| --- | --- | --- |
| API contract overview | `docs/architecture/api_contract.md` | API family、产品对象追溯、统一错误模型、版本策略、兼容性、deferred boundary |
| OpenAPI source of truth | `docs/architecture/openapi/speakeasy-api.yaml` | paths、components、request/response schema、examples、lint input |

`api_contract.md` 不复制完整 OpenAPI schema；OpenAPI YAML 不承载 roadmap priority 或未批准 future-stage endpoint。

## Upstream

| Source | Path | API use |
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

## Scope Classification

| Scope | OpenAPI treatment | Reason |
| --- | --- | --- |
| Product Base stable behavior | Implementation-level paths allowed | Accepted Product Base artifacts and traceability exist |
| P0 commercial subscription readiness | Implementation-level paths allowed | Approved increment artifacts exist |
| P0 commercial AI provider hardening | Implementation-level paths allowed for media upload/signing, provider evidence, cost metrics and retention operations | Approved increment artifacts exist and `P0-AI-ARCH-001` records the API/security contract gate |
| P0.1 expression automation training | Implementation-level paths allowed where server-backed behavior is required | Approved increment artifacts exist; local-only behavior must not be over-promoted |
| P0.2 goal-driven learning autopilot | Implementation-level paths allowed for goal intake, diagnostic summary, backplan, daily plan, next action, autopilot control, reminder eligibility/outbox, recovery replan, item-policy decision, mastery transition audit, progress forecast and checkpoint operations | Owning P0.2 increments, including Followup-B, have requirements/spec/AC/TC/traceability and P02 policy gates |
| P1 notebook/scoring/content expansion | Deferred boundary only | Roadmap/future feature boundary only |
| P2 A1-C2/CMS/content production | Deferred boundary only | Roadmap/future feature boundary only |

## Contract Rules

- API-first：跨端实现前必须先有 request/response/error schema。
- 所有响应使用 JSON；所有错误使用统一 `ErrorResponse` schema。
- OpenAPI schema 必须能生成或校验 Dart client；Flutter 手写 wrapper 不得重新定义 DTO 语义。
- 支付、用量、账号删除、训练 turn replay 必须支持 `X-Request-Id`，并在需要时支持 `Idempotency-Key`。
- 所有主响应需要 `schema_version` 或等价版本字段。
- 支付、权益、用量、训练 session、学习证据和账号删除的最终事实由服务端拥有。
- LLM/ASR/TTS/评分 provider 只能返回候选反馈或信号；planner/evidence/entitlement/usage 的最终裁决由 deterministic domain rules 完成。
- Breaking changes 必须记录 ADR 或 migration plan，并说明客户端兼容策略。
- 不得从 stage、roadmap 或 future boundary 直接生成实现级 endpoint。

## API Family Coverage

| Family | OpenAPI tag | Product object source | Implementation status |
| --- | --- | --- | --- |
| Auth / Identity | `Auth`, `User` | Product Base FR-001, FR-010; P0 FR-COM-004, FR-COM-005, FR-COM-008 | In OpenAPI |
| Onboarding | `Onboarding` | Product Base FR-002 | In OpenAPI, including assessment and route creation |
| Scenario / Content | `Scenario`, `Home` | Product Base FR-003, FR-004, FR-005; P0.1 P01-FR-001, P01-FR-002 | In OpenAPI, including official content, user scenario state, and home summary |
| Product Base practice | `Practice` | Product Base FR-007, FR-008, FR-009; `mvp-backend-practice-ai` MVP-SI-008/MVP-SI-009 | In OpenAPI, including start/resume/get/turn/complete, recoverable provider failure, and summary candidate input |
| P0.1 training planner | `Training`, `Planner` | P0.1 P01-FR-001..P01-FR-017 | In OpenAPI; Product Base/production readiness blocked until backend Training implementation, tests and rollout gates close `P01-GAP-009` through `P01-GAP-014` or are explicitly marked blocked |
| P0.2 goal autopilot | `Goal Autopilot` | P0.2 P02-DIAG-FR-001..007, P02-PLAN-FR-001..008, P02-AUTO-FR-001..008, P02-FUB-FR-001..008 | In OpenAPI for deterministic local implementation, including Followup-B control/planner/memory hardening; high-cost AI/provider, commercial release and official-score claims remain governed by P02/P0 gates |
| Learning / Review / Favorites | `Learning`, `Review`, `Favorites` | Product Base FR-005, FR-006, FR-009; P0.1 P01-FR-009 | In OpenAPI |
| Subscription / Entitlement | `Subscription`, `Entitlement` | P0 FR-COM-001..FR-COM-007, FR-COM-009 | In OpenAPI |
| Usage / AI Gateway | `Usage`, `AI Gateway` | P0 FR-COM-010; Product Base FR-004, FR-008; P0.1 P01-FR-006, P01-FR-007; `mvp-backend-practice-ai` MVP-SI-006/MVP-SI-009 | In OpenAPI, including server-side ASR/TTS/pronunciation/coach adapters, no client provider secret field, and typed fallback results |
| Media / AI Provider Operations | `Media`, `AI Ops`, `AI Gateway` | P0 `commercial-ai-provider-hardening` FR-COM-AI-001..005 | In OpenAPI for media upload/signing, TTS cache metadata, provider evidence, cost metrics and retention jobs |
| Admin / Ops | `Admin` | P0 FR-COM-008, FR-COM-011, FR-COM-012 | In OpenAPI |
| P0.2/P1/P2 future extensions | `Deferred` | Roadmap/stage/future feature registry boundaries only | No implementation-level endpoints |

## P0 Commercial Contract Gate

Owning increment: `docs/product/increments/commercial-subscription-readiness/`.

| Work package | Contract decision | Traceability |
| --- | --- | --- |
| P0-COM-API-001 | `GET /subscription/plans` is a public read endpoint for saleable plan display; purchase, restore, entitlement and usage endpoints remain authenticated. OpenAPI must use `security: []` for this path and must not imply unauthenticated entitlement access. | FR-COM-001, FR-COM-009; AC-COM-011 |
| P0-COM-API-001 | Apple and Google verification use authenticated `POST /subscriptions/apple/verify` and `POST /subscriptions/google/verify` with `Idempotency-Key`. Invalid receipt, product mismatch and idempotency conflict are explicit errors. | FR-COM-001, FR-COM-002, FR-COM-003; AC-COM-001, AC-COM-002 |
| P0-COM-API-001 | Restore purchase is an authenticated operation and empty restore is a successful typed state, not an entitlement grant. | FR-COM-002, FR-COM-003; AC-COM-003, AC-COM-004 |
| P0-COM-API-001 | Provider webhooks require `webhookSignature` and are processed idempotently through `PaymentProviderEvent`. | FR-COM-002, FR-COM-003, FR-COM-005; AC-COM-005 |
| P0-COM-API-001 | Entitlement refresh, usage summary, usage reserve/commit/release are server-owned boundaries; Flutter may cache display state but cannot mutate final entitlement or quota facts. | FR-COM-001, FR-COM-006, FR-COM-007, FR-COM-010; AC-COM-006, AC-COM-007, AC-COM-012 |
| P0-COM-API-001 | Account deletion remains authenticated and idempotent; admin retry and release health use `opsBearerAuth`. | FR-COM-004, FR-COM-008, FR-COM-011, FR-COM-012; AC-COM-008, AC-COM-010, AC-COM-014 |

P0-COM-API-001 gate result: API contract and OpenAPI source-of-truth cover the commercial subscription, entitlement, usage, account deletion and admin/release API families needed before implementation. Contract lint remains the validation gate before downstream code consumes these paths.

## P0 Commercial AI Provider Hardening Contract Gate

Owning increment: `docs/product/increments/commercial-ai-provider-hardening/`.

| Work package | Contract decision | Traceability |
| --- | --- | --- |
| P0-AI-ARCH-001 | `POST /media/audio/uploads` creates a backend-owned upload session with entitlement/usage precheck, accepted content type, byte size, duration, checksum and short-lived signed upload URL for an阿里云 OSS private bucket or equivalent storage adapter. Response returns `MediaAsset.audio_ref` as the only client-consumable ASR input ref; OSS AccessKey and provider read URL are never returned. | FR-COM-AI-001, AC-COM-AI-001, TC-COM-AI-001, TC-COM-AI-008 |
| P0-AI-ARCH-001 | `POST /media/audio/uploads/{media_id}/complete` validates object metadata, checksum, duration, owner and canonical `object_ref` before the asset can enter `/ai/transcribe`; local file paths, unsigned URLs, wrong-owner refs and client-forged object refs remain invalid. | FR-COM-AI-001, AC-COM-AI-001, TC-COM-AI-002, TC-COM-AI-008 |
| P0-AI-ARCH-001 | `/ai/tts` response adds optional `media_id`, `cache_status` and `cache_expires_at`; the cache key remains server-owned from normalized text hash, model, voice and language, and Flutter must not submit or see the raw cache key. | FR-COM-AI-002, AC-COM-AI-002, TC-COM-AI-003 |
| P0-AI-ARCH-001 | `GET /admin/ai/provider-evidence` exposes only reviewed provider evidence metadata and redacted evidence refs; provider keys, raw request payloads, raw audio and full transcripts must not appear in response bodies. | FR-COM-AI-003, AC-COM-AI-003, TC-COM-AI-004 |
| P0-AI-ARCH-001 | `GET /admin/ai/cost-metrics` exposes plan, user hash, provider family, model, capability, status, cache hit, call count, duration/token estimate, estimated cost, budget bucket and margin risk. | FR-COM-AI-004, AC-COM-AI-004, TC-COM-AI-005 |
| P0-AI-ARCH-001 | `POST /admin/ai/retention-jobs` and `GET /admin/ai/retention-jobs/{job_id}` expose retention execution status, aggregate deletion/redaction counts and redacted evidence refs only. | FR-COM-AI-005, AC-COM-AI-005, TC-COM-AI-006, TC-COM-AI-007 |

P0-AI-ARCH-001 gate result: OpenAPI now contains implementation-level contracts for media upload/signing, persistent TTS cache metadata, provider evidence, cost metrics and AI retention jobs. Backend implementation may proceed only against these paths and must keep raw media, provider payloads, full signed URLs and provider secrets out of request/response DTOs and logs.

## P0.1 Training Production-Hardening Contract Gate

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`；remediation batch 2026-06-03。

| Work package | Contract decision | Traceability |
| --- | --- | --- |
| P01-HARDEN-001 | `/training/sessions`, `/training/sessions/{session_id}`, `/training/sessions/{session_id}/turns` and `/training/sessions/{session_id}/complete` are the Product Base/production Training source-of-truth boundary. These endpoints must be authenticated, owner-scoped and backed by server persistence before P0.1 can be promoted from local route to stable product capability. | P01-FR-012, P01-SPEC-013, AC-P01-014, TC-P01-021, TC-P01-022, P01-TR-013 |
| P01-HARDEN-001 | Training turn replay requires `Idempotency-Key` plus `session_id`; duplicate keys with the same body return the prior turn result, while mismatched replay returns `IDEMPOTENCY_CONFLICT`. Flutter cannot create local draft attempts that count as accepted server turns. | P01-FR-012, AC-P01-014, TC-P01-022, TC-P01-029 |
| P01-HARDEN-002 | Learning evidence writes from training must preserve `source_turn_id`, `target_expression_id`, deterministic rule trace, schema version and acceptance/rejection status. Raw AI candidates or local recap text cannot directly become final mastery facts. | P01-FR-013, P01-SPEC-014, AC-P01-015, TC-P01-023, P01-TR-014 |
| P01-HARDEN-002 | Account deletion and retention jobs must cover server-backed TrainingSession, TrainingTurn, TrainingRecap, LearningEvidenceCandidate, media refs and redacted audit refs. | P01-FR-013, AC-P01-015, TC-P01-024 |
| P01-HARDEN-003 | Training responses must reference reviewed `scenario_version_id`, `action_chain_version`, `step_key` and target expression ids. Missing content mapping must produce explicit recoverable or blocked status, not generated unreviewed scenario content. | P01-FR-014, P01-SPEC-015, AC-P01-016, TC-P01-025, P01-TR-015 |
| P01-HARDEN-004 | Voice training must consume trusted backend media refs from the Media/AI Gateway contract, reuse usage reservation/commit/release, and return typed fallback for ASR/TTS/LLM/pronunciation failures. Paid AI voice remains blocked by `commercial-ai-provider-hardening` evidence until that gate passes. | P01-FR-015, P01-SPEC-016, AC-P01-017, TC-P01-026, P01-TR-016 |
| P01-HARDEN-005 | Planner endpoints and services must emit replayable `PlannerDecision` data with rule version, input snapshot refs, reason codes and AI candidate refs when applicable. Config changes must be versioned and testable against fixed fixtures. | P01-FR-016, P01-SPEC-017, AC-P01-018, TC-P01-027, P01-TR-017 |
| P01-HARDEN-006 | Training observability must expose redacted metrics for start, turn, fallback, completion, evidence write, provider status, latency and rollout gate health. Metrics cannot include provider secrets, raw audio, full transcript or raw provider payload. | P01-FR-017, P01-SPEC-018, AC-P01-019, TC-P01-028, P01-TR-018 |

P0.1 Training hardening gate result: the OpenAPI Training family is the Product Base/production source-of-truth boundary. The previous local-first Training route is retired；local-first 只是历史 local draft, not Product Base or production ready. Product Base merge, commercial production readiness or release checklist pass claims require `AC-P01-014` through `AC-P01-019` and `TC-P01-021` through `TC-P01-031` to pass, or the corresponding Product Base/release status must explicitly remain blocked.

## P0.2 Goal Autopilot Contract Gate

Owning stage: `docs/product/stages/p0-2-training-memory.md`。
Owning increments: `p0-2-goal-diagnostic-foundation`, `p0-2-goal-backplan-memory-policy`, `p0-2-autopilot-progress-checkpoint`, `p0-2-followup-b-autopilot-control-planner-memory`, `p0-2-followup-c-checkpoint-forecast-surfaces`。

| Work package | Contract decision | Traceability |
| --- | --- | --- |
| P02-API-001 | `POST /goal-autopilot/goals` is the authenticated goal intake boundary. It creates or revises the active `GoalProfile`, evaluates `SupportedGoalMatrixDecision`, produces a deterministic diagnostic summary when local samples exist, and returns claim guards. Unsupported goals return typed unsupported state and cannot create a full plan. | P02-DIAG-FR-001, P02-DIAG-FR-002, P02-DIAG-FR-003, P02-DIAG-FR-004, P02-DIAG-FR-005, P02-DIAG-FR-006, P02-DIAG-FR-007 |
| P02-API-001 | `GET /goal-autopilot/summary` returns the current P0.2 source-of-truth snapshot: active goal, diagnostic, daily plan, next action, forecast and latest checkpoint. Flutter must read this projection instead of computing goal progress locally. | P02-AUTO-FR-001, P02-AUTO-FR-002, P02-AUTO-FR-006 |
| P02-API-002 | `POST /goal-autopilot/plans/generate` creates or recalculates deterministic weekly/daily plans using only accepted upstream facts, memory policy, supported-goal status, user time budget and policy gates. LLM text may only be candidate explanation, never final plan facts. | P02-PLAN-FR-001, P02-PLAN-FR-002, P02-PLAN-FR-003, P02-PLAN-FR-004, P02-PLAN-FR-005, P02-PLAN-FR-006, P02-PLAN-FR-007, P02-PLAN-FR-008 |
| P02-API-002 | `GET /goal-autopilot/daily-plan`, `GET /goal-autopilot/actions/next`, and `POST /goal-autopilot/actions/{plan_item_id}/complete` expose no-choice execution, reason codes, plan item completion and defer/skip state without allowing Flutter to create final mastery, entitlement or official score facts. | P02-AUTO-FR-001, P02-AUTO-FR-002, P02-AUTO-FR-003 |
| P02-API-003 | `GET /goal-autopilot/forecast` returns the server-owned S001 hardened `ProgressForecast`: forecast state, source goal revision, gap summary, ETA range or unavailable reason, confidence band, risk level, risk reason code/text, next checkpoint date, deterministic explanation metadata, claim guard and updated timestamp. Partial, unsupported, low-confidence, stale, recovery-required, deleted or unavailable inputs must block high-precision ETA, goal-complete claims, official score equivalence and guaranteed outcome copy. Forecast AI explanation is candidate-only; when AI/provider use is unavailable or blocked, the response must expose deterministic fallback metadata without creating entitlement, quota, completion or official-score facts. | P02-AUTO-FR-004, P02-AUTO-FR-007, P02-FUC-FR-001, AC-P02-FUC-001, TC-P02-FUC-001..003 |
| P02-API-003 | `POST /goal-autopilot/checkpoints` records weekly/biweekly checkpoint results, updates forecast and emits a plan update signal. It must not claim official IELTS/TOEFL certification or guaranteed score. | P02-AUTO-FR-005, P02-AUTO-FR-007, P02-AUTO-FR-008 |
| P02-FUB-API-001 | `GET /goal-autopilot/control`, `PATCH /goal-autopilot/control`, `POST /goal-autopilot/control/pause` and `POST /goal-autopilot/control/resume` are the server-owned UserAutopilotControl boundary. Flutter may submit update intent, pause intent or resume intent, but the response is the only source of truth for active/paused/policy-blocked state, next-action impact, reminder eligibility impact, replan requirement and reason code. | P02-FUB-FR-001, P02-FUB-FR-002, AC-P02-FUB-001, AC-P02-FUB-002, TC-P02-FUB-001..004 |
| P02-FUB-API-002 | `POST /goal-autopilot/reminders/eligibility` evaluates control status, quiet hours, timezone, notification consent, platform permission, entitlement, quota, support status and plan freshness before any reminder schedule/send action. Blocked reminders return explicit reason code and optional `next_allowed_at`, and must not be recorded as completion, refusal, failure or missed-day evidence. | P02-FUB-FR-003, AC-P02-FUB-003, TC-P02-FUB-005..006 |
| P02-FUB-API-003 | `GET /goal-autopilot/reminders/outbox` exposes the scheduler/outbox lifecycle projection for replay, troubleshooting and UI state. Outbox records use stable dedupe keys, lifecycle status, input snapshot hash, rule version and failure metadata; raw notification payloads and sensitive diagnostic details are not exposed. | P02-FUB-FR-004, AC-P02-FUB-004, TC-P02-FUB-007..008 |
| P02-FUB-API-004 | `POST /goal-autopilot/recovery/replan` creates a deterministic RecoveryPlanDecision for missed day, skip, defer, resume-after-pause gap, stale plan or expired item. The response must choose exactly one primary mode: `compress`, `defer` or `replace`; it must not stack all overdue work into the next daily plan. | P02-FUB-FR-005, AC-P02-FUB-005, TC-P02-FUB-009..010 |
| P02-FUB-API-005 | `POST /goal-autopilot/item-policy/decisions` exposes item-level policy decisions for expressions, scenarios, diagnostic weakness tags or plan items without using a future `/memory` path. It returns deterministic due decisions, overlearning-cap/interleaving reason codes and replay refs; AI output cannot persist final review schedule. | P02-FUB-FR-006, AC-P02-FUB-006, TC-P02-FUB-011..012; supporting replay TC-P02-FUB-015..017 |
| P02-FUB-API-006 | `GET /goal-autopilot/mastery-transitions` and `GET /goal-autopilot/replay-audits` expose read-only audit projections for accepted-evidence L0-L5 transitions and deterministic replay. They do not let clients write final mastery, official score equivalence, review schedule or goal completion facts. | P02-FUB-FR-007, P02-FUB-FR-008, AC-P02-FUB-007, AC-P02-FUB-008, TC-P02-FUB-013..017 |

P02-API-001 through P02-FUB-API-006 gate result: P0.2 implementation-level endpoints are allowed only inside the `Goal Autopilot` family and only for deterministic local source-of-truth behavior. Followup-B allows control, reminder eligibility/outbox, recovery, item-policy and audit contracts; paid AI depth, external scoring evidence, commercial release and official-score equivalence remain gated by P02-PG-001 through P02-PG-005 and P0 commercial gates.

## Error Model

OpenAPI component: `ErrorResponse`.

| Code | Meaning | Typical status |
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

## Versioning And Compatibility

- Initial API path prefix: `/v1`.
- Response body uses `schema_version: 1`.
- Breaking path or DTO changes require ADR or migration notes.
- Additive optional fields are compatible only when clients can ignore unknown fields.
- Generated Dart client drift check is required before implementation merge.
- `lib/generated/api/` now contains the generated OpenAPI Dart boundary and `.openapi-sha256`; `npm run check:dart-client-drift` runs in `generated_client_drift` mode and also verifies documented handwritten-client exceptions.

## Idempotency Rules

| Flow | Idempotency input | Rule |
| --- | --- | --- |
| Apple/Google verify | `Idempotency-Key` + provider transaction/token | Same key and same body returns the previous result |
| Restore purchase | `Idempotency-Key` | Empty restore is a success response with empty result, not entitlement grant |
| Usage reserve/commit/release | `Idempotency-Key` or reservation id | Reserve cannot be double-counted; commit/release are terminal transitions |
| Account deletion | `Idempotency-Key` | Duplicate deletion request returns current deletion job |
| Training/practice turn | `Idempotency-Key` + session id | Replay cannot create duplicate turn/evidence |
| Media upload create | `Idempotency-Key` + user + client_upload_id/checksum | Replay returns the same pending or validated media asset without creating duplicate provider-accessible refs |
| AI retention job | `Idempotency-Key` + scope + reason + user_ref/deletion job ref | Replay returns the same retention job status and does not double-delete or double-count evidence |
| Autopilot control update/pause/resume | `Idempotency-Key` + user + active goal revision + requested control transition | Replay returns the same control result, deduped audit note and notification impact without duplicate cancellation or replan effects |
| Autopilot recovery replan | `Idempotency-Key` + user + goal revision + source_event + rule_version | Replay returns the same RecoveryPlanDecision and does not create duplicate daily plan replacements |
| Reminder outbox scheduling | dedupe key from user + goal revision + plan item + reminder slot + rule_version | Duplicate schedule attempts resolve to the existing outbox record or blocked state |

## MVP Backend Practice/AI Contract Note

Owning increment: `docs/product/increments/mvp-backend-practice-ai/`.

- `/practice/sessions` creates or resumes only Product Base official scenario practice sessions for the authenticated user.
- `/practice/sessions/{session_id}/turns` requires `Idempotency-Key`; replay with the same body returns the same turn, while a mismatched body returns `IDEMPOTENCY_CONFLICT`.
- `/practice/sessions/{session_id}/complete` returns a `SessionSummary` plus candidate-only learning inputs; it must not write final mastery facts.
- `/ai/transcribe`, `/ai/tts`, `/ai/pronunciation`, `/ai/coach-turn`, and `/ai/feedback` are server-side provider gateway contracts. Request schemas use `additionalProperties: false`; clients must not submit provider secrets or raw provider credentials.
- Provider timeout, unavailable, media invalid, or invalid schema states must return either typed gateway status or `recoverable_error` feedback; invalid provider output must not become successful user-visible feedback.

## P0.1 DashScope Provider Adapter Contract Note

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`；change request `CR-20260601-001`。

- AI REST path 不新增：Flutter 继续调用 `/ai/transcribe`、`/ai/tts`、`/ai/pronunciation`、`/ai/coach-turn`、`/ai/feedback`。
- Provider implementation 可配置：`deterministic` 用于本地/CI；`dashscope` 用于当前后端真实 Qwen LLM、DashScope TTS、Paraformer ASR adapter。
- `TranscribeRequest.audio_ref` 必须是后端/provider 可访问且带后端签名媒体元数据的 media ref。DashScope ASR 不得信任客户端自填的 `duration_seconds`/`bytes` query；客户端本地文件路径、未签名 HTTP ref、空 ref、media invalid、provider no result 均不得转成伪成功 transcript。
- `TtsResponse.audio_ref` 是后端归一化媒体引用；DashScope TTS 首版必须至少支持 text/model/voice 稳定 cache key，持久对象存储 URL/proxy 是 release-hardening 项。
- `CoachTurnResponse.feedback` 只能来自 schema-valid provider output 或 deterministic fallback。无效 JSON、schema mismatch、timeout 或 provider unavailable 必须返回 `validation_status=fallback` 和 recoverable feedback。
- 所有 provider 调用必须复用现有 `AiGatewayService` usage reservation/commit/release 规则，不绕过 entitlement/usage boundary。
- Response 不得包含 provider secret、raw provider payload、raw audio 或完整敏感 transcript。日志/observability 仅记录 provider、model、status、latency、fallback reason、schema version、usage family、request id，以及适用时的 token estimate、audio duration 或 estimated cost bucket。
- Provider policy 必须由后端 entitlement/usage facts 决定，可按 free/pro/enterprise tier 限制模型、请求频率、文本长度和音频时长；客户端请求体不得直接选择商业 tier。
- Live DashScope E2E 属于外部服务证据；默认 automated tests 必须使用 mock HTTP/fixtures，不依赖真实 `DASHSCOPE_API_KEY`。

## MVP Backend Learning/Memory Contract Note

Owning increment: `docs/product/increments/mvp-backend-learning-memory/`.

- `/expressions/queue` returns stable target-expression practice tasks, priority, task type, due time, and explicit empty states.
- `/expressions/tasks/{queue_item_id}/complete` persists the task attempt and returns progress linked to accepted learning evidence.
- `/favorites/expressions` requires `target_expression_id` so duplicate favorites are resolved by stable expression identity; delete removes the favorite from the active list.
- `/learning/evidence` validates evidence before it can update final mastery; rejected evidence is visible in the write response but not in accepted evidence lists or mastery projections.
- `/learning/mastery`, `/review/items`, `/learning/wiki`, and `/learning/history` are server-backed projections of accepted learning evidence.
- `/learning/history/{history_entry_id}` deletes the history entry visibility without deleting the underlying saved expression/wiki projection.

## MVP Backend Membership/Boundary Contract Note

Owning increment: `docs/product/increments/mvp-backend-membership-boundary/`.

- `DELETE /user/me` requires authenticated user context and `Idempotency-Key`; it revokes active sessions, deletes user-owned Product Base learning/practice/profile rows, marks the account as deleted, returns the deletion job, and writes a redacted audit event.
- `GET /user/deletion-status` returns the latest deletion job for the authenticated user, including `failure_reason` for recoverable or manually inspectable failure states.
- `/membership/boundary` returns MVP membership state as an entry/boundary fact only; it must not claim production payment, full entitlement gating, or commercial launch readiness.
- `/membership/android/purchase` and `/membership/android/restore` return platform-limited responses because Android billing is not connected in this MVP backend increment.
- `/learning/report/summary`, `/offline-content/status`, and `/achievements/status` return explicit empty/placeholder responses rather than silently implying implemented report, offline content, or achievement systems.

## Deferred Boundaries

The following are intentionally excluded from implementation-level OpenAPI until Product Manager creates owning increment definitions and specs:

- P1 notebook/vocabulary arbitrary phrase lookup and notes.
- P1 productized scoring card and scoring rubric.
- P1/P2 expanded scenario packages, CEFR mapping, CMS/content production workflow.
- P2 full A1-C2 content system.
- Public user-generated scenario/community workflows.

OpenAPI may reserve tags or extension metadata for these boundaries, but must not expose executable request/response schemas for them in this stage.

## Contract Acceptance Gate

Implementation may not start until:

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
