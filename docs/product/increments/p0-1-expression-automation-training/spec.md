# P0.1 Increment Spec：表达自动化训练 Agent

## 状态
Implementation-review ready - 作为 P0.1 acceptance criteria 的直接上游输入；2026-06-04 P0.1 Product Base/production-hardening local implementation review passed，local-first 与生产事实源之间的差距已由 backend Training source-of-truth、evidence governance、content versioning、media/AI pipeline、planner audit 和 rollout gates 本地关闭；PM Product Base merge approval and P0 commercial / paid AI external gates remain separate。

## 上游引用
- Increment definition: `docs/product/increments/p0-1-expression-automation-training/definition.md`
- Increment requirements: `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- Product Base: `docs/product/base/requirements.md`, `docs/product/base/spec.md`, `docs/product/base/acceptance.md`, `docs/product/base/traceability.md`
- Capability Registry classification: `docs/product/feature_registry.md`
- Change request: `docs/process/change_request.md`

## Product Object
- Active stage: P0.1 表达自动化训练闭环
- Primary Capability ID：`CAP-TRAIN`
- Primary Sub-capability ID：`CAP-TRAIN-03`
- Affected Capability IDs：`CAP-PRACTICE`、`CAP-CONTENT`、`CAP-MEMORY`、`CAP-COACH`
- Affected Sub-capability IDs：`CAP-TRAIN-02`、`CAP-TRAIN-04`、`CAP-TRAIN-05`、`CAP-TRAIN-06`、`CAP-PRACTICE-01`、`CAP-PRACTICE-02`、`CAP-PRACTICE-03`、`CAP-CONTENT-03`、`CAP-MEMORY-02`、`CAP-COACH-02`、`CAP-COACH-03`、`CAP-COACH-05`

## Spec Trace IDs
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| P01-SPEC-001 | P01-SI-001 | P01-FR-001 | Inputs, State Model `Loading` / `Ready`, official scene entry assumptions |
| P01-SPEC-002 | P01-SI-003 | P01-FR-002 | Inputs `actionChainStep`, State Model, Planner Rules |
| P01-SPEC-003 | P01-SI-004 | P01-FR-003 | Micro-action Contract |
| P01-SPEC-004 | P01-SI-002 | P01-FR-004 | Planner Rules, State Model transitions |
| P01-SPEC-005 | P01-SI-005 | P01-FR-005 | Planner Rules, hint level transitions |
| P01-SPEC-006 | P01-SI-007 | P01-FR-006 | Inputs `asrStatus`, Micro-action Contract fallback, Failure Handling |
| P01-SPEC-007 | P01-SI-008 | P01-FR-007 | Outputs, Planner Rules, Module Impact |
| P01-SPEC-008 | P01-SI-006 | P01-FR-008 | State Model `PressureCheck`, Planner Rules |
| P01-SPEC-009 | P01-SI-009 | P01-FR-009 | State Model `Recap`, Outputs, Failure Handling |
| P01-SPEC-010 | P01-SI-011 | P01-FR-010 | State Model `RecoverableError`, Failure Handling |
| P01-SPEC-011 | P01-SI-010 | P0.1 非目标边界 | Non-goals |
| P01-SPEC-012 | P01-SI-007, P01-SI-008, P01-SI-011 | P01-FR-011 | Backend AI Provider Gateway, media ref handling, provider fallback |
| P01-SPEC-013 | P01-SI-001, P01-SI-002, P01-SI-004, P01-SI-011 | P01-FR-012 | Backend Training API implementation and source-of-truth alignment |
| P01-SPEC-014 | P01-SI-009, P01-SI-011 | P01-FR-013 | Learning evidence write-back, rule trace and data governance |
| P01-SPEC-015 | P01-SI-001, P01-SI-003, P01-SI-004, P01-SI-010 | P01-FR-014 | Versioned training content and action-chain mapping |
| P01-SPEC-016 | P01-SI-007, P01-SI-008, P01-SI-011 | P01-FR-015 | Real voice/media/AI training-turn pipeline |
| P01-SPEC-017 | P01-SI-002, P01-SI-005, P01-SI-006, P01-SI-008, P01-SI-010 | P01-FR-016 | Planner service audit, replay and configuration |
| P01-SPEC-018 | P01-SI-007, P01-SI-008, P01-SI-009, P01-SI-011 | P01-FR-017 | Training observability, commercial boundaries and rollout gates |

## Baseline Spec Definitions

P01-SPEC-001 through P01-SPEC-012 是本 spec 的原始训练 Agent 设计定义。早期文档把这些 ID 只放在 trace table 中，并通过 `Inputs`、`State Model`、`Planner Rules`、`Micro-action Contract`、`Failure Handling` 和 `Backend AI Provider Gateway Contract` 等区域承载正文；2026-06-03 之后为避免查找歧义，以下小节作为可搜索的 canonical definition anchors。

### P01-SPEC-001 Official Scene Entry And Session Readiness
P0.1 session 只能从 `job_interview` 或 `onboarding_introduction` 进入。系统必须加载场景、等级、目标表达、历史 evidence 和当前 session draft，并在 `Loading -> Ready` 或 `Loading -> RecoverableError` 之间给出明确状态。

### P01-SPEC-002 Action Chain
每个 P0.1 session 按开场、说明目的、表达观点、回应追问、确认下一步、结束推进。`actionChainStep` 是 planner 输入，不得由 LLM 自由生成；Product Base/production 模式必须满足 `P01-SPEC-015` 的后端版本化内容映射，Flutter 不得再提供本地 action-chain fallback。

### P01-SPEC-003 Micro-action Flow
用户每次只面对一个主要 micro-action：`ListenOne`、`ChooseOne`、`SayOne`、`ShadowOne`、`FillOne` 或 `ContinueUnderPrompt`。UI 必须围绕当前 micro-action 呈现任务、输入、反馈和下一步，不得同时暴露多条训练主线。

### P01-SPEC-004 Session Planner
Planner 根据 scene、level、action chain step、target expression、attempt result、ASR status、score signal 和 learning evidence 选择 retry、hint、next micro-action、pressure check 或 recap。最终推进由 deterministic rules 决定，不能由 LLM 文本直接推进。

### P01-SPEC-005 Hint Ladder
连续失败时 hint level 按 none -> sentence frame -> options -> chunk shadowing -> model-then-retry 升级；连续通过时降低支架、升级 micro-action 或进入 pressure check。hint 阈值在 production 模式下还必须满足 `P01-SPEC-017` 的规则版本和 replay 要求。

### P01-SPEC-006 Voice Primary And Text Fallback
语音是默认训练输入路径；麦克风拒绝、ASR 失败或无结果时进入重录、文本兜底或可恢复错误。production 模式下语音输入还必须满足 `P01-SPEC-016` 的 trusted `audio_ref` 和 AI Gateway pipeline。

### P01-SPEC-007 Feedback And Pronunciation Boundary
即时反馈综合表达完成度、场景任务完成度、地道表达建议和可用评分信号。发音评分不可用或低置信度不能单独阻断；LLM/provider 输出只能作为候选反馈或候选 evidence 输入。

### P01-SPEC-008 In-session Pressure Check
连续通过后，planner 可以触发 session 内轻量追问或近场景复现。pressure check 不创建跨天计划、不进入完整 L0-L5，也不扩大到 P0.2/P1/P2。

### P01-SPEC-009 Recap And Learning Evidence Handoff
训练收尾必须展示 recap、下一步建议和 learning evidence handoff 状态。Product Base/production 模式必须满足 `P01-SPEC-014` 的服务端 rule trace 和数据治理；Flutter 不得再生成 `pending_local_write` 作为训练 evidence 状态。

### P01-SPEC-010 Recoverable Failure Handling
场景加载、音频、麦克风、ASR、LLM、评分或写回失败必须进入可恢复路径。失败不能让训练页空白，也不能把 provider failure 伪装为学习失败或成功 evidence。

### P01-SPEC-011 P0.1 Scope Boundary
P0.1 不新增第三个官方场景、不实现任意场景生成、跨天长期 planner、完整 L0-L5、任意词句笔记本、完整评分产品或商业权益事实源。商业权益和 paid AI release 仍由 P0 commercial gates 管理。

### P01-SPEC-012 Backend AI Provider Gateway
当前 Spring Boot `AiProviderGateway` 负责真实 LLM/TTS/ASR provider adapter、schema validation、fallback、usage reservation/commit/release、telemetry 和 secret isolation。该 spec 关闭本地 provider adapter 边界，但 full external provider/storage/cost/retention release evidence 仍由 `commercial-ai-provider-hardening` 管理。

## Goal
把现有语音场景模拟升级为训练型 Agent：系统在 session 内接管训练组织、节奏控制、难度拆解、重复推进、即时反馈和轻量场景施压，用户只完成可快速响应的小动作。

## Inputs
- `sceneId`: `job_interview` 或 `onboarding_introduction`
- `targetLevel`: 当前官方场景等级
- `actionChainStep`: 当前动作链位置
- `targetExpression`: 当前要自动化的表达或表达簇
- `microAction`: 当前用户小动作
- `hintLevel`: 当前提示等级
- `attemptResult`: 最近尝试结果
- `asrStatus`: 可用、失败、麦克风拒绝或无结果
- `scoreSignal`: 可用评分、低置信度评分或不可用
- `learningEvidence`: 既有掌握、薄弱、复习、个人素材或下一步建议

## Outputs
- 当前 micro-action 任务
- 目标表达和示范输入
- 提示、句框、选项、chunk shadowing 或 model-then-retry
- 即时反馈：表达完成度、场景任务完成度、地道表达建议、可用评分反馈
- Planner 决策：重试、降级、升级、轻量 pressure check、recap
- 本轮 learning evidence 写回结果

## State Model
| State | Meaning | Next states |
| --- | --- | --- |
| `Loading` | 加载场景、表达、历史证据或音频资源 | `Ready`, `RecoverableError` |
| `Ready` | 等待用户开始当前 micro-action | `Listening`, `Recording`, `Feedback` |
| `Listening` | 播放 TTS 或示范音频 | `Ready`, `RecoverableError` |
| `Recording` | 用户录音中 | `Transcribing`, `Ready`, `RecoverableError` |
| `Transcribing` | ASR/转写中 | `Evaluating`, `Retry`, `RecoverableError` |
| `Evaluating` | 评估表达、任务完成度和可用评分信号 | `Feedback`, `RecoverableError` |
| `Feedback` | 展示反馈、重试建议和地道表达提示 | `Retry`, `PressureCheck`, `Ready`, `Recap` |
| `Retry` | 按当前或更高 hint level 重试 | `Ready`, `Listening`, `Recording` |
| `PressureCheck` | 轻量追问或近场景复现 | `Recording`, `Feedback`, `Recap` |
| `Recap` | 展示总结并写回学习证据 | terminal |
| `RecoverableError` | 可恢复失败 | previous valid state, `Retry`, `Recap` |

## Planner Rules
- 连续失败时，hint level 必须按无提示 -> 句框 -> 选项 -> chunk shadowing -> model-then-retry 提升。
- 连续通过时，hint level 必须下降或进入 `PressureCheck`。
- ASR 失败不能直接判定表达失败；必须进入重录或文本兜底。
- 发音低分不能单独阻断通过；必须结合表达完成度和场景任务完成度。
- LLM 可以生成候选反馈和追问建议，但最终 planner 决策必须由应用层规则裁决。
- LLM 不得直接写入最终掌握状态。

## Micro-action Contract
| MicroAction | User action | Pass signal | Fallback |
| --- | --- | --- | --- |
| `ListenOne` | 听一句目标表达或场景提示 | 完成播放或确认继续 | TTS 失败时展示文本和可恢复错误 |
| `ChooseOne` | 从选项中选择合适表达 | 选择匹配目标意图或可接受变体 | 提供解释并进入重试 |
| `SayOne` | 说出一句目标表达 | 命中核心语义且任务完成度达标 | ASR 失败时重录或文本兜底 |
| `ShadowOne` | 跟一句或 chunk shadowing | 完整度和基础发音信号达标；不可用时以完成和转写为主 | model-then-retry |
| `FillOne` | 补一句或补 chunk | 补全核心槽位且语义匹配 | 句框或选项提示 |
| `ContinueUnderPrompt` | 在追问下继续说 | 在少提示或无提示下完成当前 action step | 降级到 SayOne 或 model-then-retry |

## Module Impact
| Area | Impact |
| --- | --- |
| Product | P0.1 increment，primary classification 为 `CAP-TRAIN` / `CAP-TRAIN-03` |
| Scenario content | 两个官方场景需要 action chain 映射 |
| Domain | 需要训练 session、action chain step、micro-action、hint level、pressure check、learning evidence 模型 |
| AI runtime | 需要结构化反馈、提示、重试、下一步建议和追问建议 schema |
| UX | 训练页需要呈现一个 micro-action、hint level、反馈、重试、pressure check 和 recap |
| Flutter module namespace | Training 生产 UI/adapter/contract 必须位于 `lib/features/training/`，测试位于 `test/features/training/`；`interview` 仅作为场景/练习内容命名空间，不得承载 Training bounded context |
| API | AI REST path 复用现有 `/ai/transcribe`、`/ai/tts`、`/ai/pronunciation`、`/ai/coach-turn`、`/ai/feedback`；Product Base/production training 必须实现 OpenAPI Training family 并满足 `P01-SPEC-013`；Flutter 不得保留 local draft adapter 作为可进入训练路径 |
| Backend AI Provider | 需要在当前 Spring Boot `AiProviderGateway` 后新增可配置 DashScope provider adapter，保留 deterministic provider 作为 test/dev 默认 |
| Tests | 需要 planner、hint ladder、micro-action、AI schema、widget 和回归测试 |

## Baseline Spec Applicability With Production Hardening

`State Model`、`Planner Rules` 和 `Micro-action Contract` 仍然适用，但它们现在是 P0.1 训练体验和领域行为的 baseline，不再足以单独证明 Product Base/production readiness。2026-06-03 新增的 `P01-SPEC-013` through `P01-SPEC-018` 是生产加固 overlay：
- state model 仍定义用户可见 session 流程；production 模式必须把 `TrainingSession`、`TrainingTurn`、`PlannerDecision`、`TrainingRecap` 和 evidence handoff 落到后端事实源。Flutter 只能渲染 `server_synced` 或后端可恢复失败状态，不得产生 `local_draft` training session。
- action chain 和 micro-action contract 仍定义训练组织方式；production 模式必须使用 reviewed `scenario_version_id` / `action_chain_version` / `step_key` / target expression mapping，不能只靠 Flutter 常量解释。
- planner rules 仍定义 deterministic 决策；production 模式必须增加 rule version、reason code、input snapshot refs 和 replay tests。
- voice/text/fallback rules 仍定义学习体验；production 模式必须走 trusted media ref、AI Gateway usage reservation、schema validation、typed fallback 和 redacted metrics。

## Commercial Software Remediation Design

本节把 2026-06-03 识别的 6 个商业软件风险和 7 个执行步骤落回本 P0.1 increment。它不新增 stage，也不把 P0 commercial release blockers 合并进 P0.1；它只定义 P0.1 作为可维护商业软件能力时必须具备的事实源、一致性、可审计和可运营边界。

### P01-SPEC-013 Backend Training API And Source Of Truth

Target architecture:
```text
Flutter Training UI
  -> OpenAPI generated client
  -> Spring Boot TrainingController
  -> TrainingSessionService / TrainingPlannerService
  -> AI Gateway and Media service when a turn needs ASR/TTS/LLM
  -> LearningEvidenceService for accepted evidence
  -> redacted audit / metrics
```

Rules:
- The OpenAPI Training family is not optional once Product Base merge is requested. `/training/sessions`, `/{session_id}`, `/turns`, `/planner/next`, `/hints`, `/pressure-check` and `/complete` must either have Spring Boot implementation and tests, or release/Product Base merge remains blocked.
- `POST /training/sessions` must validate `scenario_id` against the backend official available scenario catalog, published `scenario_version_id`, supported level and reviewed training content mapping. Unsupported, non-official or unmapped scenes fail closed and cannot be converted into generated or user-defined training content. Current P0.1 seed/acceptance fixtures include `job_interview` and `onboarding_introduction`, but production code must not hard-code those two ids as the API boundary.
- `POST /training/sessions/{session_id}/turns` must use `Idempotency-Key`; duplicate keys return the previous accepted turn result or `409` conflict without double decision, double evidence or double usage.
- Session ownership is resolved from authenticated backend user. Request body user ids, Flutter nickname or client display ids are display/cache data only.
- Flutter Training route requires a backend adapter. If backend training is disabled or unavailable, the entry must be closed or render a service-unavailable state; it must not instantiate a frontend planner, local session, local recap or synthetic feedback fallback.

### P01-SPEC-014 Learning Evidence And Data Governance

Design:
- `LearningEvidenceCandidate` remains candidate-only until a deterministic evidence rule accepts, rejects or merges it.
- Accepted evidence must store `source_turn_id`, `source_feedback_id` or AI result ref, `planner_decision_id` when applicable, `rule_name`, `rule_input_hash`, `decision`, `reason_code`, `schema_version`, `created_at`, `accepted_at` and deletion/retention policy version.
- Training recap is user-visible and may survive temporary evidence write failure, but the session status must expose `evidence_write_status=retryable` until backend write succeeds or is explicitly abandoned.
- Account deletion, data export, retention jobs and security logs must cover training sessions, turns, planner decisions, media refs, recap text, evidence candidates and accepted evidence refs according to the security retention policy; audit rows keep only redacted proof fields.

### P01-SPEC-015 Versioned Training Content

Design:
- Production training uses `scenario_version_id` and reviewed mapping for action chain, micro-action prompt, target expression ids and fallback text.
- For current P0.1 seed evidence, reviewed content exists for `job_interview` and `onboarding_introduction`; adding a third seed fixture is still out of scope for this increment. The production mapping mechanism itself is scenario-version based and must support any future official scenario that has reviewed content.
- If mapping is missing, the system may use a reviewed bundled fallback with `fallback_reason=missing_content_mapping`, or return recoverable error. LLM-generated unreviewed content cannot create official training steps.
- Existing sessions continue using the version they started with; content version changes must not rewrite historical planner decisions or evidence meaning.

### P01-SPEC-016 Real Voice / Media / AI Training Turn Pipeline

Design:
```text
record audio
  -> create media upload / trusted audio_ref
  -> submit training turn with media ref or text fallback
  -> backend usage reservation
  -> ASR/TTS/LLM through AiProviderGateway
  -> schema validation and typed fallback
  -> planner decision
  -> usage commit/release
  -> response renders next micro-action
```

Rules:
- Local file paths, unsigned URLs or client-generated provider refs fail before provider calls.
- Pronunciation status can be `available`, `low_confidence` or `unavailable`; unavailable cannot block expression/task feedback.
- Training UI cannot synthesize production feedback from hardcoded local strings. Deterministic behavior is allowed only behind the backend deterministic provider/test fixture boundary, not inside Flutter Training state management.

### P01-SPEC-017 Planner Service Audit And Replay

Design:
- Planner logic is a deterministic domain service, not page event glue.
- Every applied decision records: `planner_decision_id`, `training_session_id`, `source_turn_id`, `decision_type`, `next_micro_action_type`, `hint_level`, `reason_code`, `schema_version`, `rule_version`, `applied_at`.
- Rule thresholds such as consecutive-success pressure trigger and hint escalation order are versioned configuration.
- Replay test input is the session state, source turn, score/AI candidate and existing evidence; replay must produce the same decision for the same rule version.
- LLM recommended next actions are candidate-only. If a candidate is outside the planner allowed-action set for the current session state, the planner must reject it, keep the session in a valid deterministic state and record the rejection `reason_code`.

### P01-SPEC-018 Observability, Commercial Boundary And Rollout

Metrics:
- funnel：start/resume、turn submit、feedback ready、recap shown、finish。
- training quality：hint escalation/lowering、pressure enter/pass/fail、retry count、text fallback count、unsupported scene rejection。
- evidence：candidate generated、accepted、rejected、merged_duplicate、write_failed。
- provider/cost：provider family/model/status、latency bucket、fallback reason、token/audio duration estimate、usage reservation result。
- identity and privacy：metrics use user hash, session id, request id and redacted metadata only; metrics must not include raw audio, complete sensitive transcript, provider key or raw provider payload.

Rollout rules:
- P0.1 must have feature flag, kill switch and provider rollback.
- Paid AI voice exposure is blocked until `commercial-ai-provider-hardening` strict evidence passes.
- If P0.1 becomes part of paid entitlement, entitlement/usage decisions remain owned by P0 commercial modules; P0.1 cannot create its own billing truth.

## Backend AI Provider Gateway Contract

Traceability: P01-SPEC-012 -> P01-FR-011 -> P01-SI-007/P01-SI-008/P01-SI-011。

| Capability | Required behavior | Failure behavior |
| --- | --- | --- |
| Provider selection | `speakeasy.ai.provider=deterministic` keeps local deterministic behavior；`speakeasy.ai.provider=dashscope` routes through DashScope adapter | 未配置真实 provider key 时不得暴露 secret；provider call returns typed unavailable/fallback |
| ASR | `/ai/transcribe` passes a backend/provider-accessible `audio_ref` with backend-signed media metadata to Paraformer ASR and returns transcript/confidence/status | local file path, unsigned HTTP ref, blank ref, provider timeout or no transcript returns schema/policy error, `no_result` or `provider_unavailable`; no pseudo success |
| TTS | `/ai/tts` calls DashScope TTS, returns normalized `audio_ref`, and caches same text/model/voice within the backend process | provider failure returns `provider_unavailable`; session remains recoverable |
| LLM coach | `/ai/coach-turn` / `/ai/feedback` call Qwen compatible chat completion and map strict JSON to `CoachResult` | invalid JSON/schema returns recoverable fallback with `validation_status=fallback` and no evidence candidate |
| Pronunciation | Until a real pronunciation provider is selected, DashScope adapter returns `status=unavailable` so planner can continue on expression/task signals | unavailable score must not block training |
| Usage/cost policy | Provider calls attach server-side metadata for usage family, provider, model, status, latency and fallback reason; token estimate, audio duration or estimated cost bucket is recorded when applicable | metadata is auditable but not a live billing invoice |
| Entitlement tier policy | Provider policy is selected from backend facts such as free/pro/enterprise tier; policy may cap model, request frequency, text length and audio duration | Flutter cannot select premium provider policy by request body |

Provider adapter must not:
- expose `DASHSCOPE_API_KEY` or provider credentials to Flutter;
- copy old Node/FastAPI routes into this backend;
- mark final mastery, entitlement, billing state, or cross-day schedule from LLM output;
- treat a client local file path as successful ASR provider input.

## Failure Handling
- 场景或表达加载失败：展示可恢复错误，不进入空白训练页。
- 音频播放失败：展示文本备选和错误提示。
- 麦克风拒绝：提示授权或进入文本兜底。
- ASR 无结果：提示重录或进入文本兜底。
- LLM 失败：允许重试或给出 deterministic fallback。
- 评分失败：继续表达完成度和任务完成度反馈，不阻断。
- 本地写回失败：提示可恢复错误，并不得丢失当前 session recap。

## Required Downstream Artifacts
- Acceptance: `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- Traceability: `docs/product/increments/p0-1-expression-automation-training/traceability.md`
- API contract and OpenAPI Training family: `docs/architecture/api_contract.md`, `docs/architecture/openapi/speakeasy-api.yaml`
- Architecture/data/module boundaries: `docs/architecture/module_boundary.md`, `docs/architecture/data_flow.md`
- Domain model update under `docs/domain/`
- AI runtime prompt/schema update under `docs/ai_runtime/`
- UX screen spec update under `docs/ux/`
- Test plan or test cases under `test/` and/or `docs/reports/test_report.md`

## Non-goals
- 不新增第三个官方场景。
- 不实现任意场景生成。
- 不实现跨 session/跨天长期调度。
- 不实现完整 L0-L5 掌握阶梯。
- 不产品化任意词句笔记本。
- 不把完整评分体系或商业权益 gating 作为 P0.1 阻塞项。

## Acceptance Readiness
本 spec 已满足 P0.1 acceptance generation 的上游要求：目标、范围、非目标、状态、输入、输出、失败路径、模块影响和测试期望均已明确。
