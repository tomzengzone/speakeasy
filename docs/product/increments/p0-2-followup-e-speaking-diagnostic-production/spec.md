# P0.2 Followup-E Spec：生产级音频优先口语诊断

## 状态
Phase 1 spec passed / Phase 2 contracts passed after correction / Phase 3 AC-TC-traceability passed / implementation planning only - 本规格把 Followup-E requirements 转换为 domain/API/AI/UX/data contract 和实现可用的行为契约。Phase 2 contracts 已在独立复核 block 后完成修正并通过复核；acceptance、test_cases 和 traceability 已通过独立审核。当前 Followup-E 不记录 backend、Flutter、OpenAPI/generated client 或测试通过证据；native mic/audio bytes upload、AI runtime diagnostic result、retention/export/account deletion、entitlement/provider downgrade 和 release/Product Base gates 均仍未完成。

## 上游来源
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/definition.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/requirements.md`
- `docs/product/stages/p0-2-training-memory.md`
- `docs/process/change_request.md#cr-20260607-001-p02-sheng-chan-ji-yin-pin-you-xian-kou-yu-zhen-duan`

## Covered Stage Scope Items
| Stage Scope ID | Spec coverage |
| --- | --- |
| P02-SI-007 | Speaking Check begins after explicit GoalProfile setup and never creates a default goal. |
| P02-SI-008 | DiagnosticAssessment gains audio-first evidence, diagnostic mode, quality gate and confidence semantics. |
| P02-SI-009 | Backplan receives accepted diagnostic facts and must treat low-confidence inputs conservatively. |
| P02-SI-012 | Forecast precision is constrained by diagnostic mode and confidence. |
| P02-SI-013 | Initial checkpoint/retest planning must distinguish real audio baseline from text-only start. |

## Spec Overview
Followup-E introduces a production-ready Speaking Check flow inside Goal Autopilot. The system prefers short real speaking samples, validates them through backend-owned media and diagnostic policies, and produces accepted diagnostic facts that downstream planner/forecast/checkpoint surfaces can trust. Text fallback remains available but is explicitly lower confidence and cannot create audio-derived dimensions.

## State Model
| State | Description | Allowed next states |
| --- | --- | --- |
| `goal_ready_for_diagnostic` | Valid GoalProfile exists and user has chosen to start diagnostic. | `speaking_check_intro`, `text_fallback_entry` |
| `speaking_check_intro` | Shows purpose, privacy, non-official-score boundary and skip/fallback options before permission request. | `recording_ready`, `text_fallback_entry`, `diagnostic_cancelled` |
| `recording_ready` | A sample prompt is visible; microphone permission may be requested only after record action. | `recording_active`, `permission_blocked`, `text_fallback_entry` |
| `recording_active` | Audio is being captured for one sample. | `recording_review`, `recording_failed` |
| `recording_review` | User can play, re-record, accept or skip the captured sample. | `upload_pending`, `recording_ready`, `sample_skipped` |
| `upload_pending` | Backend upload/create/complete is in progress. | `quality_checking`, `upload_failed` |
| `quality_checking` | Backend validates ownership, format, size, safety and basic audio quality. | `sample_accepted`, `quality_rejected`, `diagnostic_degraded` |
| `sample_accepted` | A trusted sample exists with backend-generated `audio_ref`. | `recording_ready`, `diagnostic_submitting` |
| `sample_skipped` | User skipped the sample. | `recording_ready`, `diagnostic_degraded` |
| `text_fallback_entry` | User enters text samples because audio is unavailable or intentionally skipped. | `diagnostic_submitting`, `diagnostic_cancelled` |
| `diagnostic_submitting` | Backend assembles audio/text samples and runs deterministic/provider candidate validation. | `diagnostic_result_ready`, `diagnostic_degraded`, `diagnostic_failed_recoverable` |
| `diagnostic_result_ready` | Accepted diagnostic facts are ready for summary and training handoff. | `first_training_focus_ready`, `goal_recalibration_available` |
| `diagnostic_degraded` | Partial/text-only/provider-blocked result exists with low or medium confidence. | `first_training_focus_ready`, `recording_ready`, `text_fallback_entry` |
| `diagnostic_failed_recoverable` | No acceptable diagnostic could be created, but goal setup remains valid. | `recording_ready`, `text_fallback_entry`, `diagnostic_cancelled` |
| `first_training_focus_ready` | UI can show top weaknesses and today's first training focus. | downstream GoalBackplan generation |
| `goal_recalibration_available` | User can later complete audio diagnostic to revise confidence and stale downstream plan. | `recording_ready`, downstream stale/replan |
| `diagnostic_cancelled` | No diagnostic fact should be persisted from cancelled local samples. | `goal_ready_for_diagnostic`, no-goal/explore path |

## P02-FUE-SPEC-000 Document Chain And Gate
- Phase 0 creates accepted change request, increment definition and stage/status routing.
- Phase 1 creates this requirements/spec pair.
- Phase 2 must create domain/API/AI/UX/data contracts before AC/TC can be treated as implementation-ready.
- Phase 3 must create acceptance, stable test cases and traceability with AC-to-TC mapping.
- Code routing is blocked until Phase 0-3 independent checker findings are pass.

## P02-FUE-SPEC-001 Speaking Check Entry
- Entry point: Goal Autopilot panel after valid GoalProfile submit or explicit diagnostic recalibration action.
- The intro must communicate: product-internal diagnosis, no official score, why recording helps, skip/text fallback, deletion/retention summary.
- The UI must not request microphone permission until a user action starts recording.
- The flow must preserve no-goal Explore Mode: browsing or sample drill must not create GoalProfile, DiagnosticAssessment or diagnostic audio facts.

## P02-FUE-SPEC-002 Sample Task Set
- Sample task type `read_aloud`: fixed reviewed calibration sentence or short paragraph, 15-30 seconds target.
- Sample task type `listen_repeat_or_retell`: user hears/reads a short prompt and repeats or retells, 15-30 seconds target.
- Sample task type `goal_context_free_answer`: goal-specific prompt, 20-45 seconds target, such as interview answer, IELTS-like speaking response or business meeting update.
- Each task must carry `sample_ref`, `task_type`, `prompt_ref`, `display_prompt`, `min_duration_seconds`, `max_duration_seconds`, `order_index` and `optional_skip_reason`.
- Prompt content must come from reviewed assets or deterministic task templates, not live free-form LLM generation in Phase 1.

## P02-FUE-SPEC-003 Recording Interaction
- UI components: task prompt, record button, stop button, timer, level/noise indicator when available, playback control, re-record action, accept action, skip action and text fallback action.
- `permission_blocked` state must explain how to continue with text fallback or retry permission; it must not shame the learner or block goal setup.
- `recording_failed` and `upload_failed` must preserve local retry/fallback options and avoid creating diagnostic facts.
- On cancel, local temporary recordings are discarded and no diagnostic sample is submitted.

## P02-FUE-SPEC-004 Trusted Audio Transport
- The backend owns upload session creation, media ownership, allowed MIME types, max size, duration envelope, checksum and generated `audio_ref`.
- The client may submit only local file bytes/stream through approved upload protocol plus client-side metadata such as local duration estimate and checksum; these are hints, not facts.
- Upload complete returns a server-owned audio sample state. Only `sample_accepted` or compatible pending state can be used in diagnostic submission.
- Idempotency: `client_upload_id` plus user, goal id/revision, sample_ref and checksum must not create duplicate media assets.
- `audio_ref` must be opaque and provider-accessible only through backend-controlled resolution; full signed URLs must not be persisted in Flutter-visible diagnostic facts.

## P02-FUE-SPEC-005 Quality Gate And Diagnostic Mode
- Quality inputs: validated duration, speech detected, clipping, ambient noise, supported codec, duplicate hash, sample task match, provider policy availability.
- Diagnostic mode rules:
  - `audio_full`: all three required diagnostic sample types are accepted and quality gates pass. Any lower threshold requires a future approved scope change.
  - `audio_partial`: at least one accepted audio sample exists but required task set is incomplete or quality is limited.
  - `text_only`: no accepted audio samples; diagnostic uses user text only.
- Confidence rules:
  - `high` requires `audio_full`, all required sample durations/quality gates passing and no claim guard block.
  - `medium` allows audio_partial or minor quality issues.
  - `low` applies to text_only, severe quality limits, provider fallback or insufficient sample count.
- Text-only results must omit acoustic dimensions and show a recalibration prompt.

## P02-FUE-SPEC-006 ASR, Scoring And AI Candidate Validation
- ASR produces candidate transcript with source `audio_asr`, provider status, confidence bucket and redacted processing refs.
- Pronunciation/scoring candidate may include internal scores or buckets only after audio quality passes. Candidate fields must not be treated as official exam scores.
- LLM explanation candidate may summarize weaknesses and next training focus from accepted deterministic facts only.
- Backend validation rejects candidates with raw provider payload, provider secret, official score equivalence, guaranteed outcome, entitlement/billing facts, unknown schema fields or persistent state mutations.
- Invalid provider output returns deterministic fallback with stable reason code.

## P02-FUE-SPEC-007 Accepted Diagnostic Result And Handoff
- Accepted result fields: `diagnostic_id`, `goal_profile_id`, `goal_revision`, `diagnostic_mode`, `confidence_band`, `sample_count`, `accepted_audio_sample_count`, `transcript_source_summary`, `quality_flags`, `top_weaknesses`, `next_training_focus`, `claim_guard`, `recalibration_available`, `rule_version`.
- Top weaknesses must be limited to 1-3 learner-actionable items.
- Next training focus must map to existing or planned GoalBackplan categories such as short answer structure, sentence completeness, pause reduction, pronunciation clarity or vocabulary range.
- Downstream planner/forecast/checkpoint must receive confidence and mode; low confidence blocks precise ETA and high-certainty plan claims.

## P02-FUE-SPEC-008 Privacy, Retention, Export And Deletion
- Audio consent copy must appear before recording and must explain data use in product-internal training plan generation.
- Retention state must distinguish raw audio, transcript, accepted diagnostic facts, redacted audit refs and provider invocation metrics.
- Delete action must remove or mark deleted raw audio and diagnostic refs according to data governance policy; UI must clear stale audio-backed facts when backend reports deletion/unavailable.
- Export response must be redacted and omit raw audio, full signed URLs, provider payloads, provider secrets and unbounded transcript content.
- Store/privacy/release disclosure remains a release blocker until external evidence is recorded.

## P02-FUE-SPEC-009 Entitlement, Cost And Provider Downgrade
- Server policy decides which diagnostic depth is available by entitlement, quota, provider availability and cost budget.
- Free/limited depth can allow one accepted audio sample, deterministic quality gate and low-depth feedback; paid/full depth may allow all samples and richer scoring only when entitlement and cost gates allow.
- Provider unavailable, quota exhausted or budget blocked returns stable downgrade reason and preserves a text or low-depth path.
- Usage reservation/commit/release must surround high-cost operations during implementation, following Followup-D policy.

## P02-FUE-SPEC-010 Test, Traceability And Review Gate
- Acceptance generation must cover success, permission failure, audio quality failure, provider failure, text fallback, privacy deletion, claim guard and cost/quota downgrade.
- Test case generation must include widget, adapter, backend unit/integration, API contract, AI eval, release-check and traceability gates.
- Traceability must map Stage Scope ID -> WP -> FR -> Spec -> AC -> TC -> Contract Evidence -> Code Evidence -> Test Evidence -> Review Gate -> Status.
- Reports must preserve release/Product Base blockers.

## API Impact Summary
- Phase 2 must define goal-autopilot diagnostic audio API family in `docs/architecture/api_contract.md`.
- OpenAPI source-of-truth update is required before implementation but may be deferred until the implementation slice that owns machine-readable schema generation.
- Planned endpoint families: upload create/complete, diagnostic submit/status/result, diagnostic audio delete.

## Domain Impact Summary
- Phase 2 must add domain facts for diagnostic upload session, audio sample, quality gate, diagnostic mode, accepted result, privacy/retention state and safe source refs.
- Database migrations are not part of Phase 1.

## AI Runtime Impact Summary
- Phase 2 must define scoring/explanation candidate schema, forbidden fields, deterministic fallback and eval cases.
- AI runtime must not own persistent decision state.

## UX Impact Summary
- Phase 2 must add screen states for Speaking Check intro, recording, playback/re-record, fallback, result and deletion/recalibration.
- UX must keep the flow short, low-pressure and action-oriented.

## Release And Data Governance Impact Summary
- Phase 2 must define data minimization, retention, deletion/export and release disclosure requirements.
- Release-ready and Product Base approval remain blocked until explicit external/native/store/provider evidence exists.

## Spec Independent Review
Result: pass for Phase 1 independent review. The checker found the state model, data semantics, downgrade handling and downstream contract needs sufficient for Phase 2 domain/API/AI/UX/data contract generation. This pass does not approve Phase 2 contracts, Phase 3 AC/TC/traceability, implementation, release readiness or Product Base merge.
