# Data Flow

## Current lineage

当前产品 lineage 由适用的 approved Story/VS/FR 解析；Engineering Artifact 之间的 direct/conditional inputs 和适用 Gate 继续仅由 Governance Contract 解析。手机号账号恢复与单一认证生命周期是本次新增的稳定跨组件流，依据已批准 `US-ACC-009` / `VS-ACC-009-1` 与 `FR-ACC-001..003`；它不改变用户、身份、会话/token 和审计的既有事实归属。文内旧 Product Base、Increment、Spec/AC、旧 TC/traceability 仅为 historical provenance。

## 状态
Proposed - whole-app architecture。本文描述跨模块数据流，不替代 API schema、domain schema 或 AI output schema。

SWC 级完整拓扑、稳定 `SWC-FLOW-*` 和局部变更参考基准在 `docs/architecture/software_component_architecture.md`。本文保留业务/跨边界数据流和事实源规则，供 SWC 架构基准引用。

## Shared Flow Rules
- 服务端是用户、权益、用量、训练 session、学习证据和审计的最终事实源。
- Flutter 本地状态只作为缓存、离线兜底或会话恢复草稿。
- Provider payload 不直接进入客户端；后端只返回经过 schema validation 和脱敏后的字段。
- 所有高成本 provider 调用先经过 entitlement/usage check。
- 学习证据写回必须保留 rule trace，不由 LLM 自由文本直接修改最终掌握状态。

## Authentication Lifecycle And Phone Account Recovery Flow

Authority boundary：账号恢复只承接已批准 `US-ACC-009`、`VS-ACC-009-1`、`FR-ACC-001`、`FR-ACC-002` 和 `FR-ACC-003`。启动/前台恢复、caller cancellation、TTS auth-error precedence 和认证观测是既有认证与复用边界的安全加固，不新增产品行为或公共 API。

```text
App cold start or foreground resume
  -> FE-BOOTSTRAP-ROUTING enters one explicit initializing/resume lifecycle
  -> FE-LOCAL-CACHE may provide display-only cached profile/credential material
  -> FE-API-CLIENT authenticated executor checks the caller cancellation signal
  -> the single shared RefreshCoordinator owns any near-expiry refresh
  -> concurrent startup/resume/feature waiters join that one refresh without owning it
  -> cancellation removes only that caller before send, after refresh wait, or before replay
  -> typed authenticated / unauthenticated / offline-degraded / terminal state returns to routing

Learner selects phone account recovery
  -> FE-AUTH-PROFILE requests a purpose-bound recovery code through the sole FE-API-CLIENT typed recovery wrapper
  -> the wrapper consumes generated path/schema/error/hash artifacts; this generator emits no callable recovery operation, recovery DTO or recovery client
  -> BE-API-CONTROLLERS validates the request
  -> BE-IDENTITY checks the default-off account-recovery capability before provider, identity or session effects
      -> missing, invalid or non-enabled release configuration fails closed with the existing typed 503 response and no side effects
      -> only explicit release configuration enables the remaining recovery flow
  -> BE-API-CONTROLLERS and BE-IDENTITY apply bounded rate limits
  -> BE-IDENTITY uses the existing phone verification provider boundary
  -> backend returns the same privacy-safe 202 accepted shape without exposing account/binding state
  -> learner submits phone number plus the one-time recovery code
  -> BE-IDENTITY verifies recovery purpose and resolves only an existing active AuthIdentity
  -> under the locked UserAccount, existing AccountSecurityService advances security epoch and revokes all sessions/token families in one DB transaction
  -> BE-OPS-AUDIT-DELETION records a redacted success event
  -> only an explicitly received 200 recovered/login_phone response establishes client-visible completion
      -> FE-AUTH-PROFILE clears local credentials and renders login-required state
      -> the learner may then perform ordinary phone login
  -> timeout, cancellation, connection loss, or another missing 200 produces result-unknown
      -> FE-AUTH-PROFILE remains in recovery, requests a new purpose-bound code, and repeats only-existing-identity recovery
      -> it must not invoke ordinary phone login or depend on a new recovery-status/no-create-login endpoint
```

Security, reliability and rollback rules：
- Cached profile/user data never proves authentication. Startup and resume may not call refresh transport directly, and no second coordinator may compete with the shared refresh-token rotation owner.
- Cancelling a waiting or replaying caller aborts only that caller's transport/work; it never cancels the owner refresh needed by other callers. Cancellation is checked before initial send, after the refresh wait and before replay.
- Recovery verification codes are purpose-bound, single-use and provider-owned. The recovery service may resolve `AuthIdentity`, but it may not invoke login-or-create, create a session or issue tokens.
- Security epoch advance, all-session/family revocation and redacted success audit form the backend success boundary. If provider verification is consumed but the database transaction fails, no identity/session fact changes and the learner requests a new code.
- Client-visible recovery completion requires an explicitly received `200 recovered`; transport-level result-unknown remains inside the recovery flow and repeats it with a new purpose-bound code. Ordinary phone login is allowed only after explicit success because its login-or-create semantics cannot safely resolve an unknown recovery outcome. This rule does not authorize a status endpoint or no-create login variant.
- Failures intentionally collapse account-not-found, unbound/unavailable phone, account state and code failure into one public response; logs and metrics contain no raw phone/code/token or user/session/device identifier labels.
- Rollout is backend-first and additive. The backend capability switch is fail-closed and default-off; only explicit release configuration enables it, while the client feature flag controls entry visibility only. Rollback disables the backend capability and client entry without removing the additive OpenAPI method/path/schema/error surface, running a destructive migration or reactivating revoked sessions.
- The flow reuses `FE-BOOTSTRAP-ROUTING`, `FE-AUTH-PROFILE`, the sole `FE-API-CLIENT` typed wrapper plus generated path/schema/error/hash, `BE-API-CONTROLLERS`, `BE-IDENTITY`, `BE-OPS-AUDIT-DELETION`, `OPS-RELEASE-GATES` and existing identity/session persistence. A recovery-specific auth store, duplicate RefreshCoordinator, duplicate token revoker, feature-local recovery wrapper/DTO semantics or claim that a generated recovery DTO/client exists is forbidden.

## Approved Content Catalog And Version-Pinned Detail Flow

Authority boundary：本流只承接已批准的 `US-CONTENT-001`、`US-CONTENT-002` 及适用的 `FR-CONTENT-001`、`FR-CONTENT-002`。`US-CONTENT-003` 至 `US-CONTENT-012` 全部保持 draft，只作为未来兼容性 seam；本流不为它们定义 endpoint、payload 字段、UI/领域状态、表、provider 或验收。

```text
FE-CONTENT requests the authenticated catalog through FE-API-CLIENT
  -> BE-API-CONTROLLERS authenticates, validates and propagates request/trace identity
  -> BE-CONTENT-SCENARIO reads published theme and CourseVersion facts through DB-IDENTITY-CONTENT
  -> when visibility rules apply, BE-CONTENT-SCENARIO consumes an existing BE-COMMERCE-ENTITLEMENT decision without owning entitlement truth
  -> backend returns the complete visible theme set and Course summaries, preserving a published theme with zero visible Courses
  -> FE-CONTENT renders catalog, real-empty or typed failure; FE-LOCAL-CACHE may retain last-known display context only
  -> learner selects a stable Course identity and an exact CourseVersion identity
  -> BE-CONTENT-SCENARIO resolves that exact version and, after future contract approval, its CourseContentBinding to a matching ScenarioVersion + ScenarioLevel
  -> backend returns the exact published detail or a typed unavailable/failure result; it never substitutes latest
  -> FE-CONTENT renders the version-pinned detail and keys recovery cache by stable Course/CourseVersion identity
```

Facts and seams：
- `Course` 是稳定的学习者可见内容单位，`CourseVersion` 是不可变发布身份；`Course != Scenario`，`ScenarioLevel` 保持既有 CEFR/场景轨道语义。
- 后续 `CourseContentBinding` 只提供稳定 authored-content 关联；本轮不定义其字段、基数、存储或 API schema。本架构不定义 Course inventory 的数量、标题或时长；真实库存必须来自 owning approved product/content source。001/002 只授权完整 published/visible collection 与 detail semantics，不授权具体库存，也不承诺 A1-C2 或 A1/C1/C2 覆盖。
- Practice、Training、Learning、AI、Media 继续分别拥有 session/turn/attempt、planner、progress/evidence、provider、recording/transcript/score/media lifecycle；Content 只产出或消费稳定 reference，不接收这些 runtime facts。
- 003-012 后续获批时，可消费 Course/CourseVersion、CourseContentBinding、ScenarioVersion/ScenarioLevel 和其他 owner 产出的稳定 reference；必须先通过 `software_component_architecture.md` 的逐行 impact check，并新增适用 Engineering Contract。

Failure, security and operations：
- empty 与 failure 必须区分；读取失败不得伪造空目录，版本不可用不得静默降级到 latest，缓存不得覆盖服务端 publication/visibility facts。
- 服务端执行认证、发布与可见性裁决；不可见资源不应通过错误差异、缓存键或日志泄漏。日志只记录 request/trace identity、结果类别和经脱敏的 Course/version reference，不记录 raw content 或用户 runtime payload。
- rollout 采用后续 additive contract/migration、backend-first compatibility 和 feature flag；rollback 关闭新 catalog/detail read path 与入口、保留 additive data，继续使用既有 Scenario/practice/training 流，不执行破坏性 down migration 或 ScenarioLevel reinterpretation。
- 本节是高层架构流，不是 API、Domain、migration、UX 或测试契约；具体重试、缓存期限、错误码和字段由后续相应 Engineering Contract 定义。

## P0 Subscription Purchase / Restore Flow
```text
Flutter membership/paywall
  -> platform purchase sheet
  -> client receives platform transaction token
  -> POST /subscriptions/apple|google/verify
  -> backend verifies with Apple/Google
  -> subscription state machine updates Purchase, Subscription, EntitlementSnapshot
  -> audit log writes payment event
  -> GET /entitlements refreshes client display cache
  -> UI unlocks or shows recoverable failure
```

Failure paths:
- invalid receipt -> `INVALID_RECEIPT` and no entitlement change;
- restored purchase empty -> typed empty restore state;
- refund/revocation/expiration webhook -> entitlement downgraded on server, client refresh shows downgraded state;
- network failure after platform purchase -> client retries verify with idempotency key.

失败路径：
- invalid receipt 返回 `INVALID_RECEIPT`，且不改变 entitlement；
- restored purchase empty 返回类型化的空恢复状态；
- refund/revocation/expiration webhook 由服务端降级 entitlement，客户端刷新后展示降级状态；
- platform purchase 后遇到 network failure 时，客户端使用 idempotency key 重试 verify。

## P0 Commercial Usage Flow
```text
Flutter requests AI/ASR/TTS/scoring
  -> backend checks auth
  -> backend checks entitlement
  -> backend reserves usage quota
  -> backend calls provider through AI Gateway
  -> backend validates provider/AI schema
  -> backend commits or releases usage reservation
  -> backend returns typed result or fallback
```

Rules:
- Quota cannot be decremented only on the client.
- Provider timeout must release or mark usage according to an auditable rule.
- Abuse detection consumes request metadata, not raw sensitive audio payloads.

规则：
- Quota 不能只在客户端扣减。
- Provider timeout 必须按可审计规则 release 或 mark usage。
- Abuse detection 使用 request metadata，不使用 raw sensitive audio payloads。

## P0.1 Micro-Action Training Turn Flow
```text
Flutter training screen
  -> current TrainingSession loaded
  -> learner completes micro-action
  -> audio/transcript submitted to /training/sessions/{id}/turns
  -> Training Planner evaluates deterministic state
  -> AI Gateway requests structured feedback if needed
  -> schema validation filters AI output
  -> planner decides retry / hint / next micro-action / pressure check / complete
  -> learning evidence candidates are generated
  -> deterministic evidence rule writes accepted evidence
  -> Flutter renders one next action
```

State boundaries:
- Action chain and micro-action state are domain objects.
- LLM may suggest feedback and follow-up prompt.
- Planner decides whether a step is satisfied.
- Mastery/evidence updates include source turn, rule trace, schema version, and timestamp.

状态边界：
- Action chain 和 micro-action state 是 domain objects。
- LLM 可以建议 feedback 和 follow-up prompt。
- Planner 决定 step 是否满足完成条件。
- Mastery/evidence updates 必须包含 source turn、rule trace、schema version 和 timestamp。

## Historical P0.1 Local-First Draft Flow - Superseded

历史 P0.1 本地优先草稿流程 - 已被替代。

```text
official scene entry
  -> local TrainingSession draft created or resumed
  -> Training Planner selects current ActionChainStep + MicroAction + HintState
  -> Training screen renders one action
  -> audio/text input collected
  -> ASR/scoring/AI candidate feedback adapter returns schema-valid signals or fallback
  -> Training Planner applies deterministic decision
  -> accepted evidence adapter writes local recap/wiki/home/queue input
  -> traceable tests verify the same state transition
```

Boundary notes:
- This flow is retained only as historical context for the first local draft slice.
- It is superseded for Product Base merge, production training, commercial production mode and release readiness.
- Flutter local-first Training source-of-truth is removed from the product Training entry. Current Product Base/production design requires the production-hardened Training flow below, or an explicit blocked status/service-unavailable entry gate.
- Local-first demos, fixtures or experiments must remain isolated from the product Training entry and cannot be used as accepted TrainingSession, TrainingTurn, PlannerDecision, TrainingRecap or learning evidence facts.

边界说明：
- 此 flow 仅作为第一版本地 draft slice 的历史上下文保留。
- 对于 Product Base merge、production training、commercial production mode 和 release readiness，本 flow 已被取代。
- Flutter local-first Training source-of-truth 已从产品 Training 入口移除。当前 Product Base/production design 必须使用下方 production-hardened Training flow，或显式展示 blocked status/service-unavailable entry gate。
- Local-first demos、fixtures 或 experiments 必须与产品 Training 入口隔离，不能作为已接受的 TrainingSession、TrainingTurn、PlannerDecision、TrainingRecap 或 learning evidence facts。

## P0.1 Production-Hardened Training Flow
```text
Flutter training screen
  -> OpenAPI generated Training client
  -> POST /training/sessions creates/resumes authenticated server session
  -> media upload flow returns trusted audio_ref when voice input is used
  -> POST /training/sessions/{id}/turns with Idempotency-Key
  -> backend TrainingSessionService verifies owner/content version/session state
  -> TrainingPlannerService replays deterministic planner rules with versioned config
  -> AI Gateway provides schema-valid candidate feedback or typed fallback
  -> LearningEvidenceService writes accepted evidence with deterministic rule trace
  -> TrainingMetricEvent emits redacted start/turn/fallback/completion/evidence metrics
  -> Flutter renders server next action, recoverable state or recap
```

Production-hardening rules:
- Server owns accepted `TrainingSession`, `TrainingTurn`, `PlannerDecision`, `TrainingRecap` and learning evidence handoff facts.
- Turn replay must be idempotent and cannot duplicate provider calls, evidence writes, usage charges or metrics.
- Training content must be tied to reviewed `scenario_version_id`, `action_chain_version`, `step_key` and stable target expression ids.
- Raw AI output, client-generated recap text, client-generated turns and full transcript/audio payloads cannot directly become final mastery facts.
- Paid AI voice remains blocked until media/object-storage/provider/cost/retention evidence passes in `commercial-ai-provider-hardening`.
- Rollout metrics and kill switch status must distinguish local pass, Product Base merge readiness and commercial release readiness.

生产加固规则：
- 服务端拥有已接受的 `TrainingSession`、`TrainingTurn`、`PlannerDecision`、`TrainingRecap` 和 learning evidence handoff facts。
- Turn replay 必须幂等，不能重复触发 provider calls、evidence writes、usage charges 或 metrics。
- Training content 必须绑定已审核的 `scenario_version_id`、`action_chain_version`、`step_key` 和稳定 target expression ids。
- Raw AI output、client-generated recap text、client-generated turns 以及 full transcript/audio payloads 不能直接成为 final mastery facts。
- Paid AI voice 在 `commercial-ai-provider-hardening` 的 media/object-storage/provider/cost/retention evidence 通过前保持 blocked。
- Rollout metrics 和 kill switch status 必须区分 local pass、Product Base merge readiness 和 commercial release readiness。

## Product Base Practice Turn Flow
```text
Scenario selection
  -> PracticeSession start/resume
  -> learner voice turn
  -> ASR or fallback transcript
  -> AI coach feedback
  -> correction / saved expression candidate
  -> summary
  -> local and eventually backend learning evidence
  -> home / queue / wiki refresh
```

This flow remains supported as Product Base behavior while P0.1 introduces stricter planner boundaries.

在 P0.1 引入更严格 planner boundaries 的同时，此 flow 仍作为 Product Base behavior 继续支持。

## Frontend Scenario Practice Runtime Migration Flow
```text
FE-SCENARIO-PRACTICE or FE-LEGACY-SCENARIO-SANDBOX
  -> FE-PRACTICE-RUNTIME session/voice/message/hint/feedback/history adapters
  -> FE-AUDIO-PLATFORM for local recording/playback
  -> FE-LOCAL-CACHE for recoverable display/session/practice-history cache
  -> FE-API-CLIENT for OpenAPI practice/media/AI/learning calls, with legacy /user/stats* only behind stats adapter
  -> owning backend SWCs: BE-PRACTICE / BE-MEDIA-STORAGE / BE-AI-GATEWAY / BE-LEARNING when OpenAPI calls apply
  -> typed response/fallback
  -> FE-PRACTICE-RUNTIME normalized runtime state
  -> owning feature UI/domain adapter renders or merges result
```

迁移规则：
- `lib/features/interview/` 是当前 main-flow path，但稳定 SWC 是 `FE-SCENARIO-PRACTICE`；新工作不得分配给 deprecated alias `FE-SCENARIO-INTERVIEW`。
- `lib/features/scenario/` 是 `FE-LEGACY-SCENARIO-SANDBOX`；它是 legacy / non-main-flow，不得承接新的 product expansion。
- `FE-PRACTICE-RUNTIME` 只能拥有 reusable mechanics：session recovery、voice capture shell、message lifecycle、TTS/playback coordination、hint request shell、feedback recorder、practice history recorder、runtime retry/fallback state 和 telemetry adapters。
- Interview/onboarding expression graph、mastery、wiki、daily queue、reviewed content、listening/shadowing 和 domain-specific review rules 在单独 domain migration 获批前仍归 `FE-SCENARIO-PRACTICE`。
- Practice history 必须复用现有 `AppSession -> SessionStatsCoordinator -> StatsService -> FE-API-CLIENT` 路径；禁止第二套 practice history/statistics store。当前 `/user/stats*` 调用是 legacy non-OpenAPI client path，在单独 API Contract / OpenAPI increment 批准前不能视为稳定 cross-end contract。
- 远程调用必须保持现有 OpenAPI 和 backend source-of-truth 边界。此 flow 不授权 backend、DB、provider、entitlement、usage、media trust 或 learning evidence ownership 变更。
- Voice/ASR/TTS 业务/播放失败必须映射到 recoverable runtime state 和 text/audio fallback；typed auth/session 失败必须原样越过 `FE-AUDIO-PLATFORM` 交给统一 session-security 路由，其优先级高于普通 TTS/播放文案，不得被吞掉或映射为 `false`。Flutter 不得创建 trusted `media://audio/...`、provider-readable signed URL、provider credential、final mastery 或 accepted server evidence。

## AI Provider Fallback Flow
```text
Provider request
  -> timeout/error/invalid JSON
  -> typed fallback from AI Gateway
  -> no mastery mutation
  -> UI shows recoverable state
  -> observability event with request_id and provider label
```

Fallback output may provide a safe next action, but cannot complete a session or write final learning evidence unless deterministic rules confirm the required state.

Fallback output 可以提供安全的下一步动作，但除非 deterministic rules 确认满足所需状态，否则不能完成 session 或写入 final learning evidence。

## P0.1 DashScope Provider Adapter Flow
```text
Flutter records or requests AI help
  -> Flutter calls current Spring Boot AI REST
  -> backend auth + usage reservation
  -> AiGatewayService routes to configured AiProviderGateway
  -> deterministic provider for local/CI OR DashScope provider for real LLM/TTS/ASR
  -> provider response is normalized to TranscribeResult / TtsResult / CoachResult / ScoreResult
  -> invalid schema, no result, timeout or unavailable becomes typed fallback
  -> usage reservation commits only on available/success, otherwise releases
  -> Flutter receives status/fallback without provider secrets or raw payload
```

Provider-specific rules:
- LLM: Qwen OpenAI-compatible response must produce strict JSON or recoverable fallback; no final mastery, entitlement, billing or review schedule fields can pass.
- ASR: Paraformer requires a backend/provider-accessible `audio_ref` with backend-signed media metadata; local device file paths are rejected or returned as no result, and unsigned HTTP refs are rejected before provider calls.
- TTS: DashScope TTS uses a text/model/voice/language cache key before calling provider; P0 paid AI voice requires persistent cache metadata and media object storage, while process-local cache is dev-only.
- Observability records provider/model/status/latency/fallback reason, not raw audio or full sensitive transcript.

Provider 专项规则：
- LLM：Qwen OpenAI-compatible response 必须产出 strict JSON 或 recoverable fallback；final mastery、entitlement、billing 或 review schedule 字段不能通过。
- ASR：Paraformer 需要带 backend-signed media metadata、且 backend/provider-accessible 的 `audio_ref`；local device file paths 会被拒绝或返回 no result，unsigned HTTP refs 在 provider calls 前被拒绝。
- TTS：DashScope TTS 在调用 provider 前使用 text/model/voice/language cache key；P0 paid AI voice 需要 persistent cache metadata 和 media object storage，process-local cache 仅限 dev 使用。
- Observability 记录 provider/model/status/latency/fallback reason，不记录 raw audio 或 full sensitive transcript。

## P0 Commercial AI Provider Hardening Flow
```text
Flutter records audio
  -> POST /media/audio/uploads creates backend-owned media upload session
  -> Flutter uploads audio to backend-signed阿里云 OSS private bucket URL or equivalent storage adapter URL
  -> POST /media/audio/uploads/{media_id}/complete validates metadata/checksum
  -> backend validates mime, duration, size, entitlement and retention policy
  -> backend writes MediaAsset metadata, canonical object_ref and returns trusted audio_ref/media id
  -> /ai/transcribe consumes trusted audio_ref only and backend signs provider read URL just-in-time
  -> DashScope ASR/LLM/TTS provider calls emit sanitized metrics
  -> TTS results are stored in persistent cache/object storage by text hash/model/voice/language
  -> GET /admin/ai/cost-metrics aggregates plan/user/provider/model/status/cache metrics
  -> POST /admin/ai/retention-jobs deletes or anonymizes audio, transcripts, provider payload refs and cache refs
```

Release-hardening rules:
- Paid AI voice cannot rely on local device paths, unsigned URLs, fake transport or process-local TTS cache.
- Provider evidence must include DashScope LLM、Paraformer ASR、TTS latency、error、cost、format compatibility and fallback results.
- Audit and metrics may store media hash/ref, user hash, plan, model, status, cache hit and cost bucket, but not full signed URLs, raw audio, full transcript, raw provider payload or provider secrets.

发布加固规则：
- Paid AI voice 不能依赖 local device paths、unsigned URLs、fake transport 或 process-local TTS cache。
- Provider evidence 必须包含 DashScope LLM、Paraformer ASR、TTS latency、error、cost、format compatibility 和 fallback results。
- Audit 和 metrics 可以保存 media hash/ref、user hash、plan、model、status、cache hit 和 cost bucket，但不能保存 full signed URLs、raw audio、full transcript、raw provider payload 或 provider secrets。

## P0.2 Followup-E Speaking Diagnostic Audio Flow
```text
Flutter Goal Autopilot
  -> GoalProfile is accepted by backend
  -> Speaking Check intro shows purpose, privacy, no-official-score boundary and text fallback
  -> learner records and reviews each required diagnostic sample type after explicit record action
  -> POST /goal-autopilot/diagnostic-audio/uploads creates backend-owned upload session
  -> Flutter uploads bytes through approved backend/object-storage transport
  -> POST /goal-autopilot/diagnostic-audio/uploads/{upload_session_id}/complete validates ownership, checksum, MIME, size, duration and safety
  -> backend creates opaque trusted audio_ref only after validation
  -> backend quality gate checks speech, silence, noise, clipping, duplicate and policy/provider availability
  -> POST /goal-autopilot/diagnostic-assessments submits accepted audio refs and/or text fallback samples with Idempotency-Key
  -> backend ASR/scoring/LLM adapters produce candidate transcript, acoustic signal and explanation
  -> backend schema/claim/privacy validators accept, downgrade or reject candidates
  -> SpeakingDiagnosticAssessment stores diagnostic_mode, confidence, sample counts, quality flags, safe weaknesses and next training focus
  -> GoalBackplan/forecast/checkpoint receive conservative accepted diagnostic facts, not raw provider output
  -> Flutter renders result, recalibration and deletion/export-safe states
```

Flow boundaries:
- `audio_ref` is backend-generated, opaque and resolved to provider-readable media only server-side.
- Flutter can upload local bytes/stream and metadata hints, but cannot persist local file paths, signed URLs or generated refs as accepted diagnostic facts.
- ASR transcript source must distinguish `audio_asr` from `user_text`; text fallback never creates acoustic dimensions.
- Provider payloads, full signed URLs, raw audio and provider secrets are not sent to Flutter, reports or exports.
- Idempotency covers upload create/complete and diagnostic assessment submission so retries do not duplicate media assets, provider calls, usage charges or diagnostic facts.
- Usage reservation, quota, entitlement and cost policy wrap high-cost ASR/scoring/LLM operations. Provider/cost failure downgrades safely and must not block GoalProfile creation.

Flow 边界：
- `audio_ref` 由后端生成，保持 opaque，只在服务端解析为 provider-readable media。
- Flutter 可以上传 local bytes/stream 和 metadata hints，但不能把 local file paths、signed URLs 或 generated refs 持久化为 accepted diagnostic facts。
- ASR transcript source 必须区分 `audio_asr` 和 `user_text`；text fallback 不产生 acoustic dimensions。
- Provider payloads、full signed URLs、raw audio 和 provider secrets 不发送给 Flutter、reports 或 exports。
- Idempotency 覆盖 upload create/complete 和 diagnostic assessment submission，确保 retries 不重复创建 media assets、provider calls、usage charges 或 diagnostic facts。
- Usage reservation、quota、entitlement 和 cost policy 包裹高成本 ASR/scoring/LLM operations。Provider/cost failure 必须安全降级，且不能阻断 GoalProfile creation。

Retention and deletion:
- Raw audio is short-lived by default and tied to `DiagnosticPrivacyState`.
- Accepted diagnostic facts may persist as product-internal learning evidence only with redacted source refs and rule/version metadata.
- Full sensitive transcript and raw provider payload are not long-term product facts; if retained for debugging, they require a separate redacted/limited retention policy and cannot appear in user export by default.
- Delete requests must remove or mark unavailable raw audio, transcript refs and provider payload refs according to data governance policy, then cause UI/downstream surfaces to stop presenting deleted audio as current high-confidence evidence.
- Export may include diagnostic mode, confidence band, sample counts, quality flags, safe weakness summaries, next training focus, retention state and redacted source refs. Export must omit raw audio, signed URLs, provider secrets, raw provider payload and unrestricted sensitive transcript.

保留和删除：
- Raw audio 默认短期保留，并绑定 `DiagnosticPrivacyState`。
- Accepted diagnostic facts 只有在包含 redacted source refs 和 rule/version metadata 时，才能作为产品内部 learning evidence 保留。
- Full sensitive transcript 和 raw provider payload 不是长期 product facts；如需为 debugging 保留，必须走单独的 redacted/limited retention policy，且默认不能出现在 user export 中。
- Delete requests 必须按 data governance policy 删除或标记 raw audio、transcript refs 和 provider payload refs 不可用，并让 UI/downstream surfaces 停止把已删除音频展示为当前高置信 evidence。
- Export 可以包含 diagnostic mode、confidence band、sample counts、quality flags、safe weakness summaries、next training focus、retention state 和 redacted source refs。Export 必须省略 raw audio、signed URLs、provider secrets、raw provider payload 和 unrestricted sensitive transcript。

Release-hardening rules:
- Followup-E does not satisfy paid AI external evidence, native/store privacy evidence, commercial release approval or Product Base merge approval.
- OpenAPI, backend media storage, provider credentials, retention jobs, deletion jobs, usage telemetry and cost telemetry must be implemented and tested before any production audio diagnostic claim.
- Deterministic no-provider or text-only fallback evidence may support local development, but cannot be represented as full production spoken-diagnostic evidence.

发布加固规则：
- Followup-E 不满足 paid AI external evidence、native/store privacy evidence、commercial release approval 或 Product Base merge approval。
- OpenAPI、backend media storage、provider credentials、retention jobs、deletion jobs、usage telemetry 和 cost telemetry 必须在任何 production audio diagnostic claim 前完成实现和测试。
- Deterministic no-provider 或 text-only fallback evidence 可以支持 local development，但不能被表述为完整 production spoken-diagnostic evidence。

## Account Deletion And Data Retention Flow
```text
Flutter account deletion confirmation
  -> DELETE /user/me
  -> backend creates deletion job
  -> token/session revoked
  -> local session data cleared
  -> backend deletes or anonymizes user profile, learning data, audio refs, transcripts, entitlement links
  -> audit log records deletion without sensitive payload
  -> user sees completion or in-progress state
```

Deletion must define:
- which data is hard-deleted;
- which data is anonymized for legal/accounting/audit reasons;
- retention duration for audio/transcripts/provider payloads;
- retry and manual ops path for failed deletion jobs.

删除必须定义：
- 哪些 data 会被 hard-deleted；
- 哪些 data 因 legal/accounting/audit reasons 被 anonymized；
- audio/transcripts/provider payloads 的 retention duration；
- failed deletion jobs 的 retry 和 manual ops path。

## Observability Flow
```text
Flutter request
  -> request_id / trace context
  -> backend structured logs
  -> OpenTelemetry trace and metrics
  -> Sentry client crash/performance signal
  -> release dashboard and incident triage
```

Minimum attributes:
- bounded app-version major/minor-or-release bucket, platform allowlist, server-owned API-family allowlist, feature area, request_id;
- provider label, not raw provider secret or raw audio;
- entitlement status class, not full payment credential;
- schema version and validation result.

Metric dimensions must be finite and server-normalized. Raw path, query, token, phone number, verification code, user/session/device id, free-form app version and other unbounded request values are forbidden as metric labels. `request_id` remains trace/log correlation context and must not become a metric label. Valid authenticated requests may obtain normalized platform/app-version buckets from existing session metadata; unauthenticated requests use bounded request metadata or `unknown`, never caller-controlled arbitrary labels.

最小 attributes：
- 有限集合的 app-version major/minor-or-release bucket、platform allowlist、服务端 API-family allowlist、feature area、request_id；
- provider label，而不是 raw provider secret 或 raw audio；
- entitlement status class，而不是 full payment credential；
- schema version 和 validation result。

Metric dimension 必须有限且由服务端标准化。raw path/query/token/phone/verification code/user/session/device id、自由格式 app version 及其他无界请求值禁止作为 metric label；`request_id` 只用于 trace/log 关联，不是 metric label。有效认证请求可从既有 session metadata 取标准化 platform/app-version bucket；未认证请求只能使用有界请求 metadata 或 `unknown`。

## Release Flow
```text
PR / release candidate
  -> document traceability gate
  -> contract/schema/test gate
  -> commercial boundary test matrix
  -> release secrets/config gate
  -> store metadata and privacy declaration check
  -> staged rollout
  -> monitor Sentry/OpenTelemetry/payment webhooks
  -> rollback or feature flag disable if needed
```

P0 paid release must not proceed while entitlement, usage, account deletion, commercial copy, or rollback evidence is missing.

当 entitlement、usage、account deletion、commercial copy 或 rollback evidence 缺失时，P0 paid release 不得继续推进。
