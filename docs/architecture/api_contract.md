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
| P0 commercial increment | `docs/product/increments/commercial-subscription-readiness/` | 订阅、权益、用量、账号删除、审计和 release gate API |
| P0.1 training increment | `docs/product/increments/p0-1-expression-automation-training/` | training session、turn、planner、hint、pressure、evidence API |
| Domain schema | `docs/domain/domain_schema.md` | 实体、状态机、事实源、API boundary recommendations |
| Entity relationship | `docs/domain/entity_relationship.md` | ownership、cardinality、cross-domain references |
| Foundation contract | `docs/architecture/backend_db_foundation_contract.md` | OpenAPI source-of-truth、generated Dart client、server fact boundary |
| Path governance and traceability findings | `docs/reports/quality_report.md` | OpenAPI path decision and Product Base/P0/P0.1 eligibility |

## Scope Classification

| Scope | OpenAPI treatment | Reason |
| --- | --- | --- |
| Product Base stable behavior | Implementation-level paths allowed | Accepted Product Base artifacts and traceability exist |
| P0 commercial readiness | Implementation-level paths allowed | Approved increment artifacts exist |
| P0.1 expression automation training | Implementation-level paths allowed where server-backed behavior is required | Approved increment artifacts exist; local-only behavior must not be over-promoted |
| P0.2 training memory | Deferred boundary only | Stage exists, but no increment definition/spec yet |
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
| P0.1 training planner | `Training`, `Planner` | P0.1 P01-FR-001..P01-FR-010 | In OpenAPI |
| Learning / Review / Favorites | `Learning`, `Review`, `Favorites` | Product Base FR-005, FR-006, FR-009; P0.1 P01-FR-009 | In OpenAPI |
| Subscription / Entitlement | `Subscription`, `Entitlement` | P0 FR-COM-001..FR-COM-007, FR-COM-009 | In OpenAPI |
| Usage / AI Gateway | `Usage`, `AI Gateway` | P0 FR-COM-010; Product Base FR-004, FR-008; P0.1 P01-FR-006, P01-FR-007; `mvp-backend-practice-ai` MVP-SI-006/MVP-SI-009 | In OpenAPI, including server-side ASR/TTS/pronunciation/coach adapters, no client provider secret field, and typed fallback results |
| Admin / Ops | `Admin` | P0 FR-COM-008, FR-COM-011, FR-COM-012 | In OpenAPI |
| P0.2/P1/P2 future extensions | `Deferred` | Roadmap/stage/future feature registry boundaries only | No implementation-level endpoints |

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

## MVP Backend Practice/AI Contract Note

Owning increment: `docs/product/increments/mvp-backend-practice-ai/`.

- `/practice/sessions` creates or resumes only Product Base official scenario practice sessions for the authenticated user.
- `/practice/sessions/{session_id}/turns` requires `Idempotency-Key`; replay with the same body returns the same turn, while a mismatched body returns `IDEMPOTENCY_CONFLICT`.
- `/practice/sessions/{session_id}/complete` returns a `SessionSummary` plus candidate-only learning inputs; it must not write final mastery facts.
- `/ai/transcribe`, `/ai/tts`, `/ai/pronunciation`, `/ai/coach-turn`, and `/ai/feedback` are server-side provider gateway contracts. Request schemas use `additionalProperties: false`; clients must not submit provider secrets or raw provider credentials.
- Provider timeout, unavailable, media invalid, or invalid schema states must return either typed gateway status or `recoverable_error` feedback; invalid provider output must not become successful user-visible feedback.

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

- P0.2 Daily training planner, cross-session pressure ladder, long-term session planner, complete L0-L5 mastery ladder.
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
- P0.2/P1/P2 remain deferred unless a new Product Manager-approved increment is added.
- Product Object Governance Check returns pass after OpenAPI generation.
