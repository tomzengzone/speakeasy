# Fallback Strategy

## Provider Failure
- Show a short retryable error.
- Keep learner input intact.
- Do not create correction, notebook item, or review item.
- Preserve the practice session and return `recoverable_error` when the turn cannot be evaluated.

## Invalid JSON
- Attempt one repair parse if safe.
- If repair fails, return typed fallback.
- Log raw failure only in safe server logs.
- Do not persist invalid provider output as successful `CoachFeedback`.

## Low-confidence Analysis
- Ask a clarifying follow-up.
- Do not advance action step.

## User Experience Rule
Fallbacks should preserve learner progress and avoid blaming the learner.

## MVP Practice/AI Mapping
- ASR unavailable: keep the turn/session recoverable and ask the user to retry or type the answer.
- TTS/playback unavailable: return typed `provider_unavailable` without changing session state.
- Coach invalid schema: return fallback feedback with no learning evidence candidate.
- Pronunciation unavailable: return a score signal with `status = unavailable`; do not block the session.

## P0.1 Training Fallback Mapping

Owning increment: `docs/product/increments/p0-1-expression-automation-training/`。

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

P0.1 fallback outputs are candidate-only. The deterministic planner decides whether to retry, raise hint, lower hint, enter pressure check, recap, or show fallback UI.

## DashScope Provider Adapter Fallback Mapping

Owning change request: `CR-20260601-001`。

| Provider area | Failure | Required normalized output |
| --- | --- | --- |
| Qwen LLM | timeout, unavailable, invalid JSON, schema mismatch, final mastery/billing fields | `CoachResult.feedbackType=recoverable_error`, `validationStatus=fallback`, provider status `timeout`, `provider_unavailable` or `invalid_schema`; no learning evidence candidate accepted |
| Paraformer ASR | blank/local-path `audio_ref`, unsigned HTTP media ref, no task id, failed task, empty transcript | `TranscribeResult.status=no_result`, schema/policy error, or `provider_unavailable`, transcript empty, usage reservation released |
| DashScope TTS | empty text, provider unavailable, missing audio URL | `TtsResult.status=provider_unavailable`, no session state mutation |
| Pronunciation | no selected real scoring provider | `ScoreResult.status=unavailable`, planner continues using completion/task signals |

Fallback logs must omit raw audio, provider keys and complete sensitive transcript. Observability may include provider, model, status, latency, fallback reason and schema version.

## P0.2 Followup-B AI Fallback Mapping

Owning increment: `docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/`。

Traceability: `AC-P02-FUB-007`, `AC-P02-FUB-008`, `TC-P02-FUB-014`。

Followup-B AI output is never a source of truth for L0-L5 transition, item-level review scheduling, notification scheduling, recovery planning, autopilot control, entitlement, quota or goal completion. It may only provide a candidate explanation after deterministic rules have already produced a `MasteryTransitionDecision`.

| Failure | Required behavior | Prohibited behavior |
| --- | --- | --- |
| LLM returns invalid JSON or markdown-wrapped JSON | Attempt one safe repair parse; if schema still fails, return deterministic explanation fallback with `recoverable_error.code=AI_SCHEMA_INVALID` | Persist raw provider output or mark transition explanation as successful |
| LLM includes `final_mastery_level`, `review_due_at`, `notification_schedule`, `control_status`, `recovery_mode`, `goal_completed`, `official_score`, `entitlement`, `quota_state`, billing, `release_approval`, `release_ready` or `product_base_merge_approved` fields | Reject or ignore the candidate for persistence; record fallback reason `FORBIDDEN_PERSISTENT_FIELD`; render deterministic explanation from `MasteryTransitionDecision.reason_code` only | Apply AI-proposed mastery, review schedule, notification schedule, recovery mode, control state, entitlement, quota, release approval or Product Base merge |
| LLM claims official score equivalence, certification, guaranteed outcome or goal completion | Reject candidate and use safe claim-guard fallback; preserve `official_score_equivalence=false` | Show official-score or guaranteed-outcome wording to the user |
| Evidence is low-confidence, partial, unsupported or fatigue-protected | Render conservative hold/demotion/block explanation from deterministic reason code | Force promotion or frame low-confidence evidence as mastery proof |
| LLM exposes raw transcript, raw audio, provider payload, provider name, provider secret or sensitive diagnostic details | Reject candidate and log only redacted fallback metadata | Send sensitive raw content to Flutter or audit projection |
| Provider timeout or unavailable during explanation generation | Return deterministic explanation fallback; keep `MasteryTransitionDecision` and replay audit unchanged | Block transition audit visibility or retry by creating duplicate transition records |
| Replay verification detects explanation candidate mismatch | Mark explanation candidate invalid for replay; compare deterministic decision/reason/rule version only | Treat prose mismatch as evidence that the deterministic transition changed |

Deterministic fallback text must be generated from safe fields only: `transition_direction`, `previous_level`, `accepted_level`, `reason_code`, `confidence_band`, `rule_version` and redacted evidence counts. Fallback must not create or modify `PlannerReplayAudit`; replay audit belongs to deterministic planner rules.

## P0.2 Followup-C Forecast Explanation Fallback Mapping

Owning increment: `docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/`。
Traceability: `AC-P02-FUC-001`, `TC-P02-FUC-003`。

S001 forecast explanation is deterministic by default. Provider/LLM output may only be a future candidate explanation after deterministic `ProgressForecast` has already decided forecast state, ETA range/unavailable reason, risk reason code, next checkpoint, claim guard and source goal revision.

| Failure or blocked condition | Required behavior | Prohibited behavior |
| --- | --- | --- |
| Provider path not configured for S001 | Return deterministic forecast explanation metadata with `explanation_source=deterministic_policy` and `ai_explanation_unavailable_reason=deterministic_no_provider_path` | Claim an AI explanation was generated or create entitlement/quota facts |
| Entitlement, quota, cost or policy blocks AI explanation | Keep deterministic forecast facts, set fallback reason such as `cost_quota_limited` or `ai_explanation_unavailable`, and preserve claim guard | Infer paid entitlement, quota state, completion or official-score status from the block |
| Candidate output includes `goal_completed`, official score/certification, guaranteed ETA, entitlement, quota, billing, plan state, checkpoint status, release approval, Product Base merge approval or persistent forecast fields | Reject candidate and render deterministic explanation from `risk_reason_code` and `explanation_key` | Persist candidate fields or mutate `ProgressForecast`, `GoalProfile`, `OutcomeCheckpoint`, plan state, billing, release or Product Base facts |
| Candidate output exposes raw transcript, raw audio, provider payload or sensitive diagnostic detail | Reject candidate, log only redacted fallback metadata and return safe deterministic explanation | Send sensitive raw content to Flutter or reports |
| Low-confidence, partial, unsupported, stale, deleted or unavailable forecast | Return limited/unavailable forecast state, suppress precise ETA and goal-complete copy, and show deterministic limitation reason | Rephrase limitation as high-confidence progress or guaranteed achievement |

Deterministic fallback text must be generated from safe fields only: `forecast_state`, `gap_summary`, `risk_reason_code`, `eta_unavailable_reason`, `confidence_band`, `next_checkpoint_date`, `rule_version` and `source_goal_revision`.

## P0.2 Followup-E Speaking Diagnostic Fallback Mapping

Owning increment: `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/`。
Traceability: planned `AC-P02-FUE-004` through `AC-P02-FUE-010`, `TC-P02-FUE-007` through `TC-P02-FUE-026`。

Followup-E provider output is never a source of truth for trusted `audio_ref`, accepted diagnostic facts, downstream plan/forecast/checkpoint state, entitlement, quota, billing, release readiness or Product Base merge approval. Backend deterministic validation must preserve a usable learner path when real audio capture or provider analysis fails.

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

Deterministic fallback text must be generated from safe fields only: `diagnostic_mode`, `confidence_band`, accepted sample counts, quality flags, transcript source summary, claim guard, allowed weakness categories, allowed next training focus categories, retention/deletion state and rule version. Text-only fallback must explicitly state that pronunciation, intonation, speech-rate, pause timing and acoustic fluency were not measured.
