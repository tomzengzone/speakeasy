# Fallback Strategy

## Provider Failure
- Show a short retryable error.
- Keep learner input intact.
- Do not create correction, notebook item, or review item.
- Preserve the practice session and return `recoverable_error` when the turn cannot be evaluated.

- 展示简短、可重试的错误提示。
- 保留 learner input，不做改写或丢弃。
- 不创建 correction、notebook item 或 review item。
- 当本轮无法评估时，保留 practice session，并返回 `recoverable_error`。

## Invalid JSON
- Attempt one repair parse if safe.
- If repair fails, return typed fallback.
- Log raw failure only in safe server logs.
- Do not persist invalid provider output as successful `CoachFeedback`.

- 在安全时只尝试一次 repair parse。
- 如果修复失败，返回 typed fallback。
- raw failure 只能写入安全的 server logs。
- 不得把 invalid provider output 作为成功的 `CoachFeedback` 持久化。

## Low-confidence Analysis
- Ask a clarifying follow-up.
- Do not advance action step.

- 先发起澄清性的 follow-up。
- 不推进 action step。

## User Experience Rule
Fallbacks should preserve learner progress and avoid blaming the learner.

Fallback 应保留 learner progress，并避免把 provider、schema 或输入质量问题归咎于 learner。

## MVP Practice/AI Mapping
- ASR unavailable: keep the turn/session recoverable and ask the user to retry or type the answer.
- TTS/playback unavailable: return typed `provider_unavailable` without changing session state.
- Coach invalid schema: return fallback feedback with no learning evidence candidate.
- Pronunciation unavailable: return a score signal with `status = unavailable`; do not block the session.

- ASR unavailable：保持 turn/session 可恢复，并请用户重试或改为输入答案。
- TTS/playback unavailable：返回 typed `provider_unavailable`，不改变 session state。
- Coach invalid schema：返回 fallback feedback，不生成 learning evidence candidate。
- Pronunciation unavailable：返回 `status = unavailable` 的 score signal，不阻断 session。

## P0.1 Training Fallback Mapping

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`。

所属增量：`docs/product/increments/p0-1-expression-automation-training/`。

| Failure | Required behavior | Prohibited behavior |
| --- | --- | --- |
| ASR failed or transcript empty | Return `recoverable_error.code=ASR_UNAVAILABLE`, preserve audio/input refs, recommend `retry` or `text_fallback` | Mark learner answer as failed or write weak evidence |
| Microphone denied | Recommend `text_fallback` and permission recovery | Treat text fallback as default primary path |
| TTS/model audio failed | Show text prompt and typed recoverable error | Block session start if text prompt is available |
| LLM invalid JSON | Attempt safe repair once; otherwise return deterministic fallback candidate with no learning evidence candidate | Persist invalid output as successful feedback |
| LLM off-scope next action | Reject the next action and ask deterministic planner for allowed retry/fallback | Apply a next action outside planner-supplied options |
| Score unavailable | Set pronunciation signal `status=unavailable` and continue expression/task feedback | Fail the user solely because pronunciation score is absent |
| Evidence write failed | Preserve `TrainingRecap`, mark evidence write retryable | Clear recap or mark session completed without visible result |
| Provider timeout during pressure check | Return to prior valid state or retry with higher hint | Advance to cross-day schedule or L0-L5 state |

中文等价说明：
- ASR failed 或 transcript empty：返回 `recoverable_error.code=ASR_UNAVAILABLE`，保留 audio/input refs，推荐 `retry` 或 `text_fallback`；不得把 learner answer 标记为失败，也不得写入 weak evidence。
- Microphone denied：推荐 `text_fallback` 和权限恢复；不得把 text fallback 当成默认主路径。
- TTS/model audio failed：展示 text prompt 和 typed recoverable error；如果 text prompt 可用，不得阻断 session start。
- LLM invalid JSON：安全地尝试一次修复；仍失败时返回无 learning evidence candidate 的 deterministic fallback candidate；不得把 invalid output 持久化为成功反馈。
- LLM off-scope next action：拒绝该 next action，并让 deterministic planner 选择允许的 retry/fallback；不得应用 planner-supplied options 之外的 next action。
- Score unavailable：设置 pronunciation signal `status=unavailable`，并继续 expression/task feedback；不得仅因 pronunciation score 缺失就判定用户失败。
- Evidence write failed：保留 `TrainingRecap`，并把 evidence write 标记为 retryable；不得清空 recap 或在没有可见结果时标记 session completed。
- Provider timeout during pressure check：回到前一个有效状态，或用更高 hint 重试；不得推进到 cross-day schedule 或 L0-L5 state。

P0.1 fallback outputs are candidate-only. The deterministic planner decides whether to retry, raise hint, lower hint, enter pressure check, recap, or show fallback UI.

P0.1 fallback output 只能作为 candidate。是否 retry、raise hint、lower hint、进入 pressure check、recap 或展示 fallback UI，均由 deterministic planner 决定。

## DashScope Provider Adapter Fallback Mapping

Owning change request: `CR-20260601-001`。

所属变更请求：`CR-20260601-001`。

| Provider area | Failure | Required normalized output |
| --- | --- | --- |
| Qwen LLM | timeout, unavailable, invalid JSON, schema mismatch, final mastery/billing fields | `CoachResult.feedbackType=recoverable_error`, `validationStatus=fallback`, provider status `timeout`, `provider_unavailable` or `invalid_schema`; no learning evidence candidate accepted |
| Paraformer ASR | blank/local-path `audio_ref`, unsigned HTTP media ref, no task id, failed task, empty transcript | `TranscribeResult.status=no_result`, schema/policy error, or `provider_unavailable`, transcript empty, usage reservation released |
| DashScope TTS | empty text, provider unavailable, missing audio URL | `TtsResult.status=provider_unavailable`, no session state mutation |
| Pronunciation | no selected real scoring provider | `ScoreResult.status=unavailable`, planner continues using completion/task signals |

中文等价说明：
- Qwen LLM 出现 timeout、unavailable、invalid JSON、schema mismatch 或 final mastery/billing fields 时，标准化为 `CoachResult.feedbackType=recoverable_error`、`validationStatus=fallback`，provider status 使用 `timeout`、`provider_unavailable` 或 `invalid_schema`；不接受 learning evidence candidate。
- Paraformer ASR 遇到空白或本地路径 `audio_ref`、未签名 HTTP media ref、无 task id、task failed 或 empty transcript 时，返回 `TranscribeResult.status=no_result`、schema/policy error 或 `provider_unavailable`，transcript 为空，并释放 usage reservation。
- DashScope TTS 遇到 empty text、provider unavailable 或缺少 audio URL 时，返回 `TtsResult.status=provider_unavailable`，不修改 session state。
- Pronunciation 没有选定真实 scoring provider 时，返回 `ScoreResult.status=unavailable`，planner 继续使用 completion/task signals。

Fallback logs must omit raw audio, provider keys and complete sensitive transcript. Observability may include provider, model, status, latency, fallback reason and schema version.

Fallback logs 必须省略 raw audio、provider keys 和完整敏感 transcript。Observability 可以包含 provider、model、status、latency、fallback reason 和 schema version。

## P0.2 Followup-B AI Fallback Mapping

Owning increment: `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

所属增量：`docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

Traceability: `AC-P02-FUB-007`, `AC-P02-FUB-008`, `TC-P02-FUB-014`。

可追溯项：`AC-P02-FUB-007`, `AC-P02-FUB-008`, `TC-P02-FUB-014`。

Followup-B AI output is never a source of truth for L0-L5 transition, item-level review scheduling, notification scheduling, recovery planning, autopilot control, entitlement, quota or goal completion. It may only provide a candidate explanation after deterministic rules have already produced a `MasteryTransitionDecision`.

Followup-B AI output 绝不是 L0-L5 transition、item-level review scheduling、notification scheduling、recovery planning、autopilot control、entitlement、quota 或 goal completion 的事实来源。它只能在 deterministic rules 已经生成 `MasteryTransitionDecision` 后，提供 candidate explanation。

| Failure | Required behavior | Prohibited behavior |
| --- | --- | --- |
| LLM returns invalid JSON or markdown-wrapped JSON | Attempt one safe repair parse; if schema still fails, return deterministic explanation fallback with `recoverable_error.code=AI_SCHEMA_INVALID` | Persist raw provider output or mark transition explanation as successful |
| LLM includes `final_mastery_level`, `review_due_at`, `notification_schedule`, `control_status`, `recovery_mode`, `goal_completed`, `official_score`, `entitlement`, `quota_state`, billing, `release_approval`, `release_ready` or `product_base_merge_approved` fields | Reject or ignore the candidate for persistence; record fallback reason `FORBIDDEN_PERSISTENT_FIELD`; render deterministic explanation from `MasteryTransitionDecision.reason_code` only | Apply AI-proposed mastery, review schedule, notification schedule, recovery mode, control state, entitlement, quota, release approval or Product Base merge |
| LLM claims official score equivalence, certification, guaranteed outcome or goal completion | Reject candidate and use safe claim-guard fallback; preserve `official_score_equivalence=false` | Show official-score or guaranteed-outcome wording to the user |
| Evidence is low-confidence, partial, unsupported or fatigue-protected | Render conservative hold/demotion/block explanation from deterministic reason code | Force promotion or frame low-confidence evidence as mastery proof |
| LLM exposes raw transcript, raw audio, provider payload, provider name, provider secret or sensitive diagnostic details | Reject candidate and log only redacted fallback metadata | Send sensitive raw content to Flutter or audit projection |
| Provider timeout or unavailable during explanation generation | Return deterministic explanation fallback; keep `MasteryTransitionDecision` and replay audit unchanged | Block transition audit visibility or retry by creating duplicate transition records |
| Replay verification detects explanation candidate mismatch | Mark explanation candidate invalid for replay; compare deterministic decision/reason/rule version only | Treat prose mismatch as evidence that the deterministic transition changed |

中文等价说明：
- LLM 返回 invalid JSON 或 markdown-wrapped JSON：安全地尝试一次 repair parse；schema 仍失败时，返回带 `recoverable_error.code=AI_SCHEMA_INVALID` 的 deterministic explanation fallback；不得持久化 raw provider output 或把 transition explanation 标记为成功。
- LLM 包含 `final_mastery_level`、`review_due_at`、`notification_schedule`、`control_status`、`recovery_mode`、`goal_completed`、`official_score`、`entitlement`、`quota_state`、billing、`release_approval`、`release_ready` 或 `product_base_merge_approved` fields：拒绝或忽略该 candidate 的持久化，记录 fallback reason `FORBIDDEN_PERSISTENT_FIELD`，并只从 `MasteryTransitionDecision.reason_code` 渲染 deterministic explanation；不得应用 AI 提议的 mastery、review schedule、notification schedule、recovery mode、control state、entitlement、quota、release approval 或 Product Base merge。
- LLM 声称 official score equivalence、certification、guaranteed outcome 或 goal completion：拒绝 candidate，使用安全的 claim-guard fallback，并保持 `official_score_equivalence=false`；不得向用户展示 official-score 或 guaranteed-outcome 表述。
- Evidence low-confidence、partial、unsupported 或 fatigue-protected：从 deterministic reason code 渲染保守的 hold/demotion/block explanation；不得强制 promotion，也不得把 low-confidence evidence 表述为 mastery proof。
- LLM 暴露 raw transcript、raw audio、provider payload、provider name、provider secret 或敏感 diagnostic details：拒绝 candidate，只记录 redacted fallback metadata；不得把敏感原始内容发送到 Flutter 或 audit projection。
- Provider timeout 或 unavailable：返回 deterministic explanation fallback，并保持 `MasteryTransitionDecision` 与 replay audit 不变；不得阻断 transition audit visibility，也不得通过创建重复 transition record 来重试。
- Replay verification 发现 explanation candidate mismatch：将 explanation candidate 标记为 replay 无效，只比较 deterministic decision/reason/rule version；不得把文案不一致视为 deterministic transition 改变的证据。

Deterministic fallback text must be generated from safe fields only: `transition_direction`, `previous_level`, `accepted_level`, `reason_code`, `confidence_band`, `rule_version` and redacted evidence counts. Fallback must not create or modify `PlannerReplayAudit`; replay audit belongs to deterministic planner rules.

Deterministic fallback text 只能由安全字段生成：`transition_direction`、`previous_level`、`accepted_level`、`reason_code`、`confidence_band`、`rule_version` 和 redacted evidence counts。Fallback 不得创建或修改 `PlannerReplayAudit`；replay audit 归 deterministic planner rules 所有。

## P0.2 Followup-C Forecast Explanation Fallback Mapping

Owning increment: `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`。
Traceability: `AC-P02-FUC-001`, `TC-P02-FUC-003`。

所属增量：`docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`。
可追溯项：`AC-P02-FUC-001`, `TC-P02-FUC-003`。

S001 forecast explanation is deterministic by default. Provider/LLM output may only be a future candidate explanation after deterministic `ProgressForecast` has already decided forecast state, ETA range/unavailable reason, risk reason code, next checkpoint, claim guard and source goal revision.

S001 forecast explanation 默认由 deterministic policy 生成。Provider/LLM output 只能作为未来的 candidate explanation，并且必须发生在 deterministic `ProgressForecast` 已经决定 forecast state、ETA range/unavailable reason、risk reason code、next checkpoint、claim guard 和 source goal revision 之后。

| Failure or blocked condition | Required behavior | Prohibited behavior |
| --- | --- | --- |
| Provider path not configured for S001 | Return deterministic forecast explanation metadata with `explanation_source=deterministic_policy` and `ai_explanation_unavailable_reason=deterministic_no_provider_path` | Claim an AI explanation was generated or create entitlement/quota facts |
| Entitlement, quota, cost or policy blocks AI explanation | Keep deterministic forecast facts, set fallback reason such as `cost_quota_limited` or `ai_explanation_unavailable`, and preserve claim guard | Infer paid entitlement, quota state, completion or official-score status from the block |
| Candidate output includes `goal_completed`, official score/certification, guaranteed ETA, entitlement, quota, billing, plan state, checkpoint status, release approval, Product Base merge approval or persistent forecast fields | Reject candidate and render deterministic explanation from `risk_reason_code` and `explanation_key` | Persist candidate fields or mutate `ProgressForecast`, `GoalProfile`, `OutcomeCheckpoint`, plan state, billing, release or Product Base facts |
| Candidate output exposes raw transcript, raw audio, provider payload or sensitive diagnostic detail | Reject candidate, log only redacted fallback metadata and return safe deterministic explanation | Send sensitive raw content to Flutter or reports |
| Low-confidence, partial, unsupported, stale, deleted or unavailable forecast | Return limited/unavailable forecast state, suppress precise ETA and goal-complete copy, and show deterministic limitation reason | Rephrase limitation as high-confidence progress or guaranteed achievement |

中文等价说明：
- S001 未配置 provider path：返回带 `explanation_source=deterministic_policy` 和 `ai_explanation_unavailable_reason=deterministic_no_provider_path` 的 deterministic forecast explanation metadata；不得声称已生成 AI explanation，也不得创建 entitlement/quota facts。
- Entitlement、quota、cost 或 policy 阻断 AI explanation：保留 deterministic forecast facts，设置 `cost_quota_limited` 或 `ai_explanation_unavailable` 等 fallback reason，并保持 claim guard；不得从阻断状态推断 paid entitlement、quota state、completion 或 official-score status。
- Candidate output 包含 `goal_completed`、official score/certification、guaranteed ETA、entitlement、quota、billing、plan state、checkpoint status、release approval、Product Base merge approval 或 persistent forecast fields：拒绝 candidate，并从 `risk_reason_code` 和 `explanation_key` 渲染 deterministic explanation；不得持久化 candidate fields 或修改 `ProgressForecast`、`GoalProfile`、`OutcomeCheckpoint`、plan state、billing、release 或 Product Base facts。
- Candidate output 暴露 raw transcript、raw audio、provider payload 或 sensitive diagnostic detail：拒绝 candidate，只记录 redacted fallback metadata，并返回安全的 deterministic explanation；不得把敏感原始内容发送到 Flutter 或 reports。
- Forecast low-confidence、partial、unsupported、stale、deleted 或 unavailable：返回 limited/unavailable forecast state，压制 precise ETA 和 goal-complete copy，并展示 deterministic limitation reason；不得把限制重写成 high-confidence progress 或 guaranteed achievement。

Deterministic fallback text must be generated from safe fields only: `forecast_state`, `gap_summary`, `risk_reason_code`, `eta_unavailable_reason`, `confidence_band`, `next_checkpoint_date`, `rule_version` and `source_goal_revision`.

Deterministic fallback text 只能由安全字段生成：`forecast_state`、`gap_summary`、`risk_reason_code`、`eta_unavailable_reason`、`confidence_band`、`next_checkpoint_date`、`rule_version` 和 `source_goal_revision`。

## P0.2 Followup-E Speaking Diagnostic Fallback Mapping

Owning increment: `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。
Traceability: planned `AC-P02-FUE-004` through `AC-P02-FUE-010`, `TC-P02-FUE-007` through `TC-P02-FUE-026`。

所属增量：`docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。
可追溯项：计划覆盖 `AC-P02-FUE-004` 至 `AC-P02-FUE-010`，以及 `TC-P02-FUE-007` 至 `TC-P02-FUE-026`。

Followup-E provider output is never a source of truth for trusted `audio_ref`, accepted diagnostic facts, downstream plan/forecast/checkpoint state, entitlement, quota, billing, release readiness or Product Base merge approval. Backend deterministic validation must preserve a usable learner path when real audio capture or provider analysis fails.

Followup-E provider output 绝不是 trusted `audio_ref`、accepted diagnostic facts、downstream plan/forecast/checkpoint state、entitlement、quota、billing、release readiness 或 Product Base merge approval 的事实来源。当真实音频采集或 provider analysis 失败时，backend deterministic validation 必须保留可用的 learner path。

| Failure or blocked condition | Required behavior | Prohibited behavior |
| --- | --- | --- |
| Microphone denied, device unavailable or learner chooses privacy skip | Offer text fallback and later Speaking Check recalibration; mark `diagnostic_mode=text_only`, `confidence_band=low` when no accepted audio exists | Block GoalProfile creation or imply full audio diagnostic completion |
| Local recording failed before upload complete | Keep retry, re-record, skip and text fallback options; discard local temporary sample on cancel | Persist a diagnostic sample or generate an `audio_ref` from client state |
| Upload create/complete fails, checksum mismatch, unsupported format, expired ref, cross-user ref or duplicate conflict | Return typed upload/validation error; allow retry or re-record; preserve idempotency outcome | Accept local file paths, unsigned URLs, stale refs or Flutter-generated `audio_ref` |
| Quality gate returns `too_short`, `silent`, `noisy`, `clipped`, `unsupported_format`, `provider_unavailable` or `policy_blocked` | Ask for re-record when useful, downgrade to `audio_partial` or `text_only`, record quality flags and suppress high confidence | Treat failed quality gate as accepted speech evidence or hide the quality limitation |
| ASR returns empty transcript, low confidence, invalid media result or provider unavailable | Keep accepted audio quality fact if available, mark transcript unavailable/low confidence, use deterministic fallback or text prompt as needed | Convert ASR failure into user failure, final mastery or official score claim |
| Pronunciation/scoring provider unavailable or quota/cost blocked | Return lower-depth diagnostic result, omit unavailable acoustic dimensions and expose safe downgrade reason | Fabricate pronunciation, intonation, speech-rate or pause timing from text |
| LLM returns invalid JSON, unknown top-level fields or markdown-wrapped JSON | Attempt one safe repair parse; otherwise return deterministic diagnostic explanation fallback | Render raw provider text or persist invalid candidate as successful diagnosis |
| Candidate includes `audio_ref`, official score/certification, guaranteed ETA, goal completion, entitlement, quota, billing, release approval, Product Base merge approval or persistent plan/checkpoint/mastery fields | Reject candidate, keep backend deterministic diagnostic facts, render safe fallback from accepted facts and claim guard | Mutate `DiagnosticAssessment`, `GoalProfile`, `GoalBackplan`, forecast, checkpoint, entitlement, billing, release or Product Base facts |
| Candidate exposes raw audio, local file path, signed URL, raw provider payload, provider secret or unrestricted transcript | Reject candidate and log only redacted fallback metadata | Send sensitive raw payload to Flutter, reports, exports or audit projections |
| Diagnostic deletion or retention job removes audio/transcript refs | Return deleted/unavailable state and clear audio-backed high-confidence UI facts | Continue showing deleted audio as current accepted evidence |

中文等价说明：
- Microphone denied、device unavailable 或 learner 选择 privacy skip：提供 text fallback 和稍后 Speaking Check recalibration；没有 accepted audio 时标记 `diagnostic_mode=text_only`、`confidence_band=low`；不得阻断 GoalProfile creation 或暗示 full audio diagnostic completion。
- Local recording 在 upload complete 前失败：保留 retry、re-record、skip 和 text fallback 选项；取消时丢弃 local temporary sample；不得持久化 diagnostic sample 或从 client state 生成 `audio_ref`。
- Upload create/complete 失败、checksum mismatch、unsupported format、expired ref、cross-user ref 或 duplicate conflict：返回 typed upload/validation error，允许 retry 或 re-record，并保留 idempotency outcome；不得接受 local file paths、unsigned URLs、stale refs 或 Flutter 生成的 `audio_ref`。
- Quality gate 返回 `too_short`、`silent`、`noisy`、`clipped`、`unsupported_format`、`provider_unavailable` 或 `policy_blocked`：必要时请求 re-record，降级为 `audio_partial` 或 `text_only`，记录 quality flags 并压制 high confidence；不得把 failed quality gate 当作 accepted speech evidence，也不得隐藏质量限制。
- ASR 返回 empty transcript、low confidence、invalid media result 或 provider unavailable：如果可用，保留 accepted audio quality fact，标记 transcript unavailable/low confidence，并按需使用 deterministic fallback 或 text prompt；不得把 ASR failure 转成 user failure、final mastery 或 official score claim。
- Pronunciation/scoring provider unavailable 或 quota/cost blocked：返回较低深度的 diagnostic result，省略 unavailable acoustic dimensions，并暴露安全的 downgrade reason；不得从文本伪造 pronunciation、intonation、speech-rate 或 pause timing。
- LLM 返回 invalid JSON、unknown top-level fields 或 markdown-wrapped JSON：安全地尝试一次 repair parse；否则返回 deterministic diagnostic explanation fallback；不得渲染 raw provider text 或把 invalid candidate 持久化为 successful diagnosis。
- Candidate 包含 `audio_ref`、official score/certification、guaranteed ETA、goal completion、entitlement、quota、billing、release approval、Product Base merge approval 或 persistent plan/checkpoint/mastery fields：拒绝 candidate，保留 backend deterministic diagnostic facts，并从 accepted facts 和 claim guard 渲染安全 fallback；不得修改 `DiagnosticAssessment`、`GoalProfile`、`GoalBackplan`、forecast、checkpoint、entitlement、billing、release 或 Product Base facts。
- Candidate 暴露 raw audio、local file path、signed URL、raw provider payload、provider secret 或 unrestricted transcript：拒绝 candidate，只记录 redacted fallback metadata；不得把 sensitive raw payload 发送到 Flutter、reports、exports 或 audit projections。
- Diagnostic deletion 或 retention job 移除 audio/transcript refs：返回 deleted/unavailable state，并清除 audio-backed high-confidence UI facts；不得继续把 deleted audio 展示为当前 accepted evidence。

Deterministic fallback text must be generated from safe fields only: `diagnostic_mode`, `confidence_band`, accepted sample counts, quality flags, transcript source summary, claim guard, allowed weakness categories, allowed next training focus categories, retention/deletion state and rule version. Text-only fallback must explicitly state that pronunciation, intonation, speech-rate, pause timing and acoustic fluency were not measured.

Deterministic fallback text 只能由安全字段生成：`diagnostic_mode`、`confidence_band`、accepted sample counts、quality flags、transcript source summary、claim guard、allowed weakness categories、allowed next training focus categories、retention/deletion state 和 rule version。Text-only fallback 必须明确说明 pronunciation、intonation、speech-rate、pause timing 和 acoustic fluency 未被测量。
