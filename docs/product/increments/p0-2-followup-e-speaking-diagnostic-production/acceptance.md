# P0.2 Followup-E Acceptance Criteria：生产级音频优先口语诊断

## 状态
Phase 3 acceptance passed independent review / implementation planning only - 本文件基于 Followup-E requirements、spec、domain/API/AI/UX/data contracts 生成验收标准。AC-to-TC mapping 已在 `test_cases.md` 和 `traceability.md` 中通过独立审核；当前所有 TC-P02-FUE-000..026 均保持 planned，不记录 trusted diagnostic-audio backend slice、Flutter Speaking Check UI slice、OpenAPI/generated client 或测试通过证据。本文不代表 backend diagnostic assessment、native mic/audio bytes upload、AI runtime、release readiness、paid AI external evidence 或 Product Base merge 已完成。

## 上游来源
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/definition.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/requirements.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/spec.md`
- `docs/domain/domain_schema.md`
- `docs/architecture/api_contract.md`
- `docs/architecture/data_flow.md`
- `docs/ai_runtime/prompt_contract.md`
- `docs/ai_runtime/llm_output_schema.md`
- `docs/ai_runtime/fallback_strategy.md`
- `docs/ai_runtime/ai_eval_cases.md`
- `docs/ux/screen_spec.md`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Policy Gate | Slice ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- |
| P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-FUE-S000 | P02-FUE-FR-000 | P02-FUE-SPEC-000 | AC-P02-FUE-000 |
| P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-S001 | P02-FUE-FR-001 | P02-FUE-SPEC-001 | AC-P02-FUE-001 |
| P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-S001 | P02-FUE-FR-002 | P02-FUE-SPEC-002 | AC-P02-FUE-002 |
| P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUE-S001 | P02-FUE-FR-003 | P02-FUE-SPEC-003 | AC-P02-FUE-003 |
| P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-S002 | P02-FUE-FR-004 | P02-FUE-SPEC-004 | AC-P02-FUE-004 |
| P02-SI-008, P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUE-S003 | P02-FUE-FR-005 | P02-FUE-SPEC-005 | AC-P02-FUE-005 |
| P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-FUE-S004 | P02-FUE-FR-006 | P02-FUE-SPEC-006 | AC-P02-FUE-006 |
| P02-SI-008, P02-SI-009, P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-002 | P02-FUE-S004 | P02-FUE-FR-007 | P02-FUE-SPEC-007 | AC-P02-FUE-007 |
| P02-SI-008 | P02-PG-005 | P02-FUE-S005 | P02-FUE-FR-008 | P02-FUE-SPEC-008 | AC-P02-FUE-008 |
| P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUE-S006 | P02-FUE-FR-009 | P02-FUE-SPEC-009 | AC-P02-FUE-009 |
| P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-FUE-S007 | P02-FUE-FR-010 | P02-FUE-SPEC-010 | AC-P02-FUE-010 |

## Implementation Slice Acceptance Routing
| Slice ID | Scope | Acceptance | Test cases | Required evidence before local completion |
| --- | --- | --- | --- | --- |
| P02-FUE-S000 | Document chain and phase gate | AC-P02-FUE-000 | TC-P02-FUE-000 | Docs, workflow validation, no-code diff check and independent review |
| P02-FUE-S001 | Speaking Check entry, sample set and recording UX | AC-P02-FUE-001..003 | TC-P02-FUE-001..006 | Flutter/widget tests, no-goal guard and reviewed sample metadata checks |
| P02-FUE-S002 | Trusted upload and backend-owned `audio_ref` | AC-P02-FUE-004 | TC-P02-FUE-007..009 | Backend/API contract, idempotency, security and deletion tests |
| P02-FUE-S003 | Quality gate and diagnostic mode | AC-P02-FUE-005 | TC-P02-FUE-010..012 | Backend quality policy and Flutter downgrade tests |
| P02-FUE-S004 | ASR/scoring/AI candidate and accepted result | AC-P02-FUE-006..007 | TC-P02-FUE-013..016 | AI schema/eval, backend validation and downstream handoff tests |
| P02-FUE-S005 | Privacy, retention, export and deletion | AC-P02-FUE-008 | TC-P02-FUE-017..019 | Data governance, deletion/export and account deletion cleanup tests |
| P02-FUE-S006 | Entitlement, quota, cost and provider downgrade | AC-P02-FUE-009 | TC-P02-FUE-020..022 | Usage reservation, quota/cost/provider fallback and UI downgrade tests |
| P02-FUE-S007 | Traceability, coverage, drift and review gates | AC-P02-FUE-010 | TC-P02-FUE-023..026 | AC-to-TC gate, OpenAPI/generated drift, reports and independent review |

## AC-P02-FUE-000 Document Chain And Gate
- Given Followup-E advances by implementation slices, `definition.md`, `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and `traceability.md` must exist under the same increment id and cite the same active P0.2 stage.
- Given Phase 0-3 documents are reviewed, every slice P02-FUE-S000..S007 must map to FR, Spec, AC and stable TC IDs or an explicit allowed exception.
- Given an individual TC has not been implemented or executed, Code Evidence and executed Test Evidence must remain `Not started`, `planned` or `N/A - no code`, not `passed`.
- Given an independent review runs, it must find no blocker in phase routing, upstream coverage, AC-to-TC mapping, status wording, release/Product Base boundary or no-fake-`audio_ref` boundary.
- Given any backend, Flutter, OpenAPI/generated client, AI runtime or test code changes are requested, implementation for that slice must remain blocked until this AC-to-TC gate has passed.

## AC-P02-FUE-001 Audio-First Speaking Check Entry
- Given a valid GoalProfile has been accepted by the backend, the default diagnostic path must offer a 2-3 minute Speaking Check before relying on text-only diagnostic samples.
- Given the Speaking Check intro is shown, it must explain product-internal learning use, recording value, skip/text fallback, deletion/retention summary and no official score/certification/guaranteed outcome boundary.
- Given the user has not tapped a record action, the UI must not request microphone permission.
- Given the user chooses skip, later recording or text fallback, GoalProfile creation must remain available and the diagnostic confidence must be downgraded as applicable.
- Given the user is in no-goal Explore Mode, sample browsing or practice must not create GoalProfile, DiagnosticAssessment, diagnostic audio or downstream plan facts.

## AC-P02-FUE-002 Diagnostic Sample Task Set
- Given Speaking Check starts, the flow must include exactly three required sample types for `audio_full`: `read_aloud`, `listen_repeat_or_retell` and `goal_context_free_answer`.
- Given each sample is displayed, it must include sample ref, task type, reviewed prompt or deterministic prompt ref, order index, min duration and max duration.
- Given prompt content is loaded, it must come from reviewed assets or deterministic templates and must not be live free-form LLM generation.
- Given any required audio sample is skipped, rejected or missing, the accepted diagnostic mode must be `audio_partial` or `text_only`, never `audio_full`.
- Given all three required samples are accepted, only then may `audio_full` be considered, subject to quality gates and claim guard.

## AC-P02-FUE-003 Recording Interaction And Fallback UX
- Given a sample prompt is ready, the learner must be able to start recording, stop recording, play back, re-record, accept, skip, cancel and enter text fallback.
- Given microphone permission is denied, device capture fails, the environment is unusable or privacy concern is selected, the UI must offer retry, text fallback and later recalibration without shaming the learner.
- Given recording is cancelled before accepted upload, local temporary audio must be discarded and no diagnostic sample, `audio_ref` or accepted diagnostic fact may be created.
- Given a sample is re-recorded before upload, the prior local temporary capture must not remain as an accepted sample.
- Given upload or analysis fails recoverably, learner input options must be preserved and the user must not be forced to restart GoalProfile setup.

## AC-P02-FUE-004 Trusted Audio Transport And `audio_ref`
- Given Flutter captures audio, Flutter may upload bytes/stream and metadata hints only; it must not generate, concatenate, persist or infer `audio_ref`.
- Given upload create/complete succeeds, `audio_ref` must be generated only by the backend after ownership, goal revision, format, size, checksum, duration, safety and basic quality validation.
- Given the client submits a local file path, unsigned URL, stale/expired ref, cross-user ref, duplicate idempotency conflict, unsupported task type or unsupported format, the backend must reject or safely downgrade before creating accepted diagnostic facts.
- Given network retry or duplicate submission occurs, idempotency must prevent duplicate media assets, provider calls, usage charges and DiagnosticAssessment facts.
- Given a response returns audio evidence, it must expose only opaque safe refs and must not expose full signed URLs, provider secrets or raw provider payloads.

## AC-P02-FUE-005 Audio Quality Gate And Diagnostic Mode
- Given a backend quality gate runs, it must produce one of the allowed quality states: `accepted`, `too_short`, `silent`, `noisy`, `clipped`, `unsupported_format`, `provider_unavailable` or `policy_blocked`.
- Given all three required sample types are accepted and quality gates pass, the diagnostic may be `audio_full`; any lower threshold requires a future approved scope change.
- Given at least one trusted audio sample exists but a required sample is skipped, missing, rejected or limited, the diagnostic must be `audio_partial` with conservative confidence.
- Given no trusted audio sample exists, the diagnostic must be `text_only` with low confidence.
- Given `text_only` is returned, result and UI must omit measured pronunciation, intonation, speech-rate, pause timing, clipping, noise and acoustic fluency conclusions.
- Given quality or provider constraints downgrade confidence, the user must see the limitation and a later audio recalibration path.

## AC-P02-FUE-006 ASR, Scoring And AI Candidate Boundary
- Given an audio-backed transcript exists, `transcript_source=audio_asr` must be backend-generated or backend-confirmed only; client-supplied `audio_asr` must fail validation or be ignored before accepted facts are created.
- Given user text fallback is submitted, `transcript_source=user_text` must not create acoustic dimensions.
- Given ASR, pronunciation/scoring or LLM output is produced, it must be candidate-only until backend deterministic validation accepts, rejects or downgrades it.
- Given provider output contains invalid JSON, unknown fields, forbidden persistent fields, raw payload, provider secrets, official score/certification, guaranteed ETA, goal completion, entitlement, quota, billing, release or Product Base claims, backend validation must reject it and use deterministic fallback.
- Given AI/provider output is rejected, it must not mutate DiagnosticAssessment, DiagnosticAudioSample, GoalProfile, GoalBackplan, ProgressForecast, OutcomeCheckpoint, entitlement, billing, release or Product Base facts.

## AC-P02-FUE-007 Accepted Diagnostic Result And Training Handoff
- Given diagnostic assessment succeeds or downgrades, the result must include diagnostic id, goal profile id/revision, diagnostic mode, confidence band, sample count, accepted audio sample count, transcript source summary, quality flags, claim guard, 1-3 top weaknesses, next training focus, recalibration availability and rule version.
- Given top weaknesses are shown, they must be learner-actionable and compatible with the diagnostic mode and evidence source.
- Given next training focus is returned, it must map to allowed training categories and feed conservative downstream GoalBackplan inputs instead of being a standalone score-only result.
- Given the result is `audio_partial`, `text_only` or low confidence, GoalBackplan, ProgressForecast and checkpoint initialization must downgrade precision and show the audio recalibration path.
- Given any result or handoff mentions target outcome, it must not claim official exam equivalence, certification, guaranteed achievement, goal completion or precise ETA.

## AC-P02-FUE-008 Privacy, Retention, Export And Deletion
- Given recording starts, the user must first see product-internal purpose, sensitive data boundary, third-party provider processing note, retention summary and deletion path.
- Given raw audio, transcript, accepted diagnostic facts, redacted audit refs or provider metrics are stored, their retention states must be explicit and auditable.
- Given the user deletes diagnostic audio or diagnostic records, backend state and UI must stop presenting deleted audio as current high-confidence evidence.
- Given export is requested, export may include diagnostic mode, confidence band, sample counts, quality flags, safe weakness summaries, next training focus, retention state and redacted source refs only.
- Given export, reports, logs or Flutter surfaces render diagnostic data, they must omit raw audio, signed URLs, provider secrets, raw provider payload and unrestricted sensitive transcript.
- Given account deletion cleanup runs, diagnostic audio refs, transcript refs, provider payload refs and user-linked diagnostic facts must be deleted or redacted according to data governance policy.

## AC-P02-FUE-009 Entitlement, Cost, Quota And Provider Downgrade
- Given high-cost ASR, pronunciation/scoring, LLM explanation or multi-sample analysis is requested, backend entitlement, usage reservation, quota and cost policy must decide allowed depth before provider calls.
- Given free, limited, expired, refunded, revoked, quota exhausted, cost budget limited or provider unavailable state applies, the backend must return a stable downgrade reason and safe lower-depth/text path.
- Given a provider, quota or cost failure occurs, GoalProfile creation must not be blocked and no fake full audio diagnostic success may be created.
- Given a usage reservation is needed, retry and failure behavior must not double-charge, double-commit or leak provider facts to the client.
- Given UI renders paid/limited depth, it must not imply unlimited AI, full diagnostic completion, commercial entitlement creation, release approval or Product Base approval.

## AC-P02-FUE-010 Test, Traceability, Review And Release Boundary
- Given Phase 3 closes, every AC-P02-FUE-000..010 must map to at least one stable TC-P02-FUE ID or an explicit allowed exception in `test_cases.md`.
- Given traceability is reviewed, every Stage Scope ID and Policy Gate listed in requirements must map through WP, FR, Spec, AC, TC, contract evidence, code evidence, test evidence and review status.
- Given implementation starts later, changed backend/domain/API/Flutter/AI runtime code must have planned and executed tests, coverage gate evidence and drift checks before local completion.
- Given OpenAPI or generated client changes are required, machine-readable OpenAPI source and generated Dart drift checks must be implemented in the owning implementation slice; Phase 3 docs alone must not claim that drift is closed.
- Given reports or status documents are updated, they must preserve release/Product Base/paid AI external evidence blockers and must not mark Followup-E locally complete until implementation and tests pass.

## Negative And Edge Coverage Requirements
- Text fallback must remain available but must be visibly low confidence.
- Any skipped required audio sample blocks `audio_full`.
- Client-provided `audio_asr`, local file paths, unsigned URLs and fake `audio_ref` are forbidden.
- Low-quality, low-confidence, provider-unavailable and quota/cost-blocked paths must downgrade safely.
- Deleted or unavailable audio must not continue powering high-confidence UI or downstream plan facts.
- AI/provider output must be rejected when it contains official-score, guaranteed outcome, persistent state, entitlement, release or Product Base claims.
- No stage document may close commercial release, paid AI external evidence, native/store privacy evidence or Product Base merge.

## AC-to-TC Requirement
Every AC-P02-FUE-000 through AC-P02-FUE-010 maps to at least one stable TC-P02-FUE ID in `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/test_cases.md` before any implementation routing.

## 下游交接边界
- `test_cases.md` and `traceability.md` may consume this file as the AC source of truth but must not renumber or redefine AC-P02-FUE-000 through AC-P02-FUE-010 without a versioned Followup-E change.
- Contract docs remain source-of-truth for domain/API/AI/UX/data behavior until implementation creates machine-readable OpenAPI and executable tests.
- Phase 3 pass does not approve backend, Flutter, OpenAPI/generated client, AI runtime implementation, release readiness, paid AI external evidence or Product Base merge.
