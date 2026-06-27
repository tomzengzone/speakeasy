# Increment Definition：P0.2 Followup-E 生产级音频优先口语诊断

## 状态
S000 phase-0 planning passed / S001 phase-1 requirements-spec passed / S002 phase-2 contracts passed after correction / S003 phase-3 AC-TC-traceability passed / implementation planning only - change request accepted, increment definition created, requirements/spec independently reviewed, domain/API/AI/UX/data contracts independently re-reviewed after correction, and acceptance/test_cases/traceability independently reviewed. Followup-E currently provides planning and contract evidence only; backend, Flutter, OpenAPI/generated client, native mic/audio bytes upload, AI runtime diagnostic result, retention/export/account deletion, entitlement/provider downgrade, release readiness, paid AI external evidence and Product Base merge remain unapproved and unimplemented for this docs-only state.

## Increment ID
`p0-2-followup-e-speaking-diagnostic-production`

## Active Stage
`docs/product/stages/p0-2-training-memory.md`

## Product Classification
- Request type: P0.2 diagnostic experience and production evidence hardening follow-up
- Product object mode: `feature-increment`
- Change request: `CR-20260607-001`
- Source mode: accepted scope-change after Followup-A/B/C/D upstream-downstream review

## Primary Feature
`goal-driven-learning-autopilot`

## Affected Features
- `scoring-feedback`
- `ai-provider-operations`
- `learning-memory-review`
- `access-onboarding`
- `commercial-subscription`

## Upstream Decision Source
- P0.2 stage scope: `docs/product/stages/p0-2-training-memory.md`
- Followup-A local implementation: `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/`
- Followup-D data governance, entitlement, cost and release gate hardening: `docs/product/increments/p0-2-followup-d-release-gate-hardening/`
- Change request: `docs/process/change_request.md#cr-20260607-001-p02-sheng-chan-ji-yin-pin-you-xian-kou-yu-zhen-duan`
- User-approved product direction: audio-first Speaking Check, text fallback, confidence downgrade and no fake `audio_ref`.

## Problem Statement
Followup-A currently allows text fallback diagnostic samples and explicitly forbids fake `audio_ref`. This is safe and locally accepted, but it is weaker than a production spoken-language diagnostic because it cannot measure pronunciation, intonation, speech rate, pauses, fluency or real speaking confidence. P0.2's goal-driven learning coach needs a real speaking baseline before it can credibly personalize backplans, memory focus and checkpoints.

## Scope
- Add a 2-3 minute audio-first Speaking Check after GoalProfile intake.
- Capture three diagnostic sample types: read-aloud calibration, listen/repeat or short retell, and goal-context free answer.
- Support recording, playback, re-recording, skip, cancel and text fallback.
- Generate `audio_ref` only through backend-confirmed trusted upload and validation.
- Add audio quality gate results for silence, too-short, noisy, clipped, duplicate and provider-unavailable states.
- Distinguish audio-derived transcript from user-entered text.
- Return `diagnostic_mode`, `confidence_band`, sample count, quality issues, claim guard, top weaknesses and next training focus.
- Preserve text-only low-confidence fallback when microphone, privacy, accessibility, network, provider, quota or cost constraints block audio.
- Add privacy/data-governance boundaries for audio retention, deletion, export and third-party processing disclosure.
- Keep GoalBackplan and downstream training behavior conservative when diagnostic evidence is limited.

## Work Packages
| WP ID | Work package | Primary outcome |
| --- | --- | --- |
| P02-FUE-WP-000 | Followup-E document chain setup | Change request, increment definition and phase routing exist before requirements/spec work. |
| P02-FUE-WP-001 | Speaking Check user flow | Audio-first diagnostic flow is specified with text fallback and low-friction learner experience. |
| P02-FUE-WP-002 | Trusted diagnostic audio transport | Backend-owned upload, `audio_ref`, idempotency and deletion boundaries are contract-ready. |
| P02-FUE-WP-003 | Audio quality and diagnostic mode policy | Quality gates and `audio_full` / `audio_partial` / `text_only` confidence behavior are defined. |
| P02-FUE-WP-004 | Speaking diagnostic scoring boundary | ASR/scoring/LLM outputs are candidate-only and accepted facts remain backend-owned. |
| P02-FUE-WP-005 | Privacy, retention and export boundary | Audio/transcript retention, deletion, export and third-party disclosure rules are defined. |
| P02-FUE-WP-006 | UX and learner trust surface | UI states support recording, failure, privacy concern, low confidence and next training focus. |
| P02-FUE-WP-007 | Cost, entitlement and provider downgrade | Provider, quota and cost failures degrade safely without blocking goal setup. |
| P02-FUE-WP-008 | AC-to-TC and traceability gate | Every AC maps to stable TC IDs before implementation can start. |
| P02-FUE-WP-009 | Independent review and reports | Each phase has independent checker findings and residual risks recorded. |

## Implementation Slice Routing
| Slice ID | Work package | Requirement | Spec | Acceptance | Test cases | Primary outcome | Current state |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUE-S000 | P02-FUE-WP-000 | P02-FUE-FR-000 | P02-FUE-SPEC-000 | AC-P02-FUE-000 | TC-P02-FUE-000 | Phase 0 planning and governance routing | Phase 0 passed / no code |
| P02-FUE-S001 | P02-FUE-WP-001, P02-FUE-WP-006 | P02-FUE-FR-001, P02-FUE-FR-002, P02-FUE-FR-003 | P02-FUE-SPEC-001..003 | AC-P02-FUE-001..003 | TC-P02-FUE-001..006 | Speaking Check user flow and Flutter-facing states | Planned - must reuse existing MVP/P0.1 recording service rather than rebuild mic capability |
| P02-FUE-S002 | P02-FUE-WP-002 | P02-FUE-FR-004 | P02-FUE-SPEC-004 | AC-P02-FUE-004 | TC-P02-FUE-007..009 | Trusted upload and backend-owned `audio_ref` | Planned - backend/API implementation evidence pending |
| P02-FUE-S003 | P02-FUE-WP-003 | P02-FUE-FR-005 | P02-FUE-SPEC-005 | AC-P02-FUE-005 | TC-P02-FUE-010..012 | Audio quality gate and diagnostic mode downgrade | Planned - quality/mode implementation evidence pending |
| P02-FUE-S004 | P02-FUE-WP-004 | P02-FUE-FR-006, P02-FUE-FR-007 | P02-FUE-SPEC-006..007 | AC-P02-FUE-006..007 | TC-P02-FUE-013..016 | ASR/scoring candidate validation and accepted diagnostic output | Phase 2 contract passed / no code |
| P02-FUE-S005 | P02-FUE-WP-005 | P02-FUE-FR-008 | P02-FUE-SPEC-008 | AC-P02-FUE-008 | TC-P02-FUE-017..019 | Audio privacy, retention, export and deletion | Planned - privacy/retention/export/account-deletion evidence pending |
| P02-FUE-S006 | P02-FUE-WP-007 | P02-FUE-FR-009 | P02-FUE-SPEC-009 | AC-P02-FUE-009 | TC-P02-FUE-020..022 | Entitlement, quota, provider and cost downgrade | Phase 2 contract passed / no code |
| P02-FUE-S007 | P02-FUE-WP-008, P02-FUE-WP-009 | P02-FUE-FR-010 | P02-FUE-SPEC-010 | AC-P02-FUE-010 | TC-P02-FUE-023..026 | Traceability, coverage, reports and independent review | Planned - executable evidence, reports and implementation review pending |

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P02-SI-007 | GoalProfile setup is extended with audio-first diagnostic entry after explicit goal setup. |
| P02-SI-008 | DiagnosticAssessment is strengthened with trusted audio evidence, diagnostic mode and quality/confidence gates. |
| P02-SI-009 | Backplan freshness must consider revised diagnostic confidence when audio evidence later recalibrates a goal. |
| P02-SI-012 | Forecast and ETA confidence must remain conservative when Speaking Check evidence is partial or text-only. |
| P02-SI-013 | Checkpoint and later retest behavior must not treat initial low-confidence text-only diagnosis as final speaking baseline. |

## Applicable Policy Gates
| Policy Gate ID | Coverage requirement |
| --- | --- |
| P02-PG-001 | Claim guards must block official score equivalence, guaranteed outcomes and over-precise speaking scores. |
| P02-PG-002 | Supported/partial/unsupported goal behavior must remain visible before plan generation and after diagnostic downgrade. |
| P02-PG-003 | Followup-E must not auto-start training, reminders or memory queues; it only supplies accepted diagnostic facts. |
| P02-PG-004 | Provider use, ASR/scoring depth, quota and cost limits must be server-owned and fail closed or downgrade safely. |
| P02-PG-005 | Audio, transcript and diagnostic facts require consent, minimization, deletion, export and retention boundaries. |

## Excluded Stage Scope Items
- P02-SI-001..006: Followup-E does not redesign backplan, memory curve, review scheduling or mastery algorithms.
- P02-SI-010..011: Followup-E does not implement pause/resume, notification scheduler, missed-day recovery or item-level memory.
- P1/P2 content, notebook, full scoring productization, A1-C2 content system and arbitrary scenario generation remain deferred.

## Required Downstream Artifacts
- `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and `traceability.md` under this increment before implementation.
- Domain updates in `docs/domain/domain_schema.md`.
- API contract updates in `docs/architecture/api_contract.md`; OpenAPI source-of-truth update is required before code implementation, after Phase 2 contract review.
- AI runtime updates in `docs/ai_runtime/prompt_contract.md`, `docs/ai_runtime/llm_output_schema.md`, `docs/ai_runtime/fallback_strategy.md` and `docs/ai_runtime/ai_eval_cases.md` where applicable.
- UX updates in `docs/ux/screen_spec.md`, with optional user flow and usability checklist notes.
- Data governance/privacy/release notes in the appropriate architecture, release and report files before release claims.
- Independent checker finding after every phase.

## Non-goals
- Does not mark Followup-A incomplete or overwrite existing Followup-A local evidence.
- Does not implement official IELTS/TOEFL/CEFR certification or guaranteed score prediction.
- Does not require recording before a learner can start; text fallback remains available with low confidence.
- Does not expose provider secrets, raw provider payloads or full sensitive transcripts to Flutter or reports.
- Does not close commercial release, paid AI external evidence, native/store privacy evidence or Product Base merge approval.

## Completion Gate
Followup-E cannot enter code implementation until Phase 0-3 artifacts pass independent review and every approved AC maps to stable TC IDs or explicit exceptions. Followup-E cannot be marked locally complete until implementation, tests, API/generated drift, coverage, traceability, reports and independent quality review pass with release/Product Base blockers preserved.

## Phase 2 Independent Review
Result: pass after correction. Initial independent review found no blocking issue and listed wording risks; a follow-up independent review then blocked on stale `spec.md` wording that still allowed a minimum audio threshold for `audio_full`. The stale wording was corrected, and the final independent re-review passed: `audio_full` requires all three required sample types, client-supplied `audio_asr` is not accepted as a fact, and the data flow describes each required reviewed diagnostic sample type. This pass does not approve implementation, OpenAPI/generated client updates, release readiness or Product Base merge.

## Phase 3 Independent Review
Result: pass. Independent review confirmed AC-P02-FUE-000..010, TC-P02-FUE-000..026 and P02-FUE-TR-000..010 are present, all TC result statuses remain `planned`, no test pass is fabricated, implementation remains blocked, OpenAPI/generated client update remains gated and release/Product Base/paid AI external evidence blockers are preserved. This pass allows Followup-E to proceed to the next implementation planning step; it is not implementation approval, release approval, paid AI external evidence approval or Product Base approval.
