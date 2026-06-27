# P0.2 Followup-A Acceptance Criteria：目标录入与诊断加固

## 状态
FR-001..009 implemented locally / release-gated - AC-P02-FUA-009 已有本地 Flutter 测试证据；完整 P0.2 release 仍受 Followup-B/C/D 约束。

## 上游来源
- `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/requirements.md`
- `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/spec.md`
- `docs/architecture/openapi/speakeasy-api.yaml`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Policy Gate | WP ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- | --- | --- |
| P02-SI-007 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUA-WP-001 | P02-FUA-FR-001 | P02-FUA-SPEC-001 | AC-P02-FUA-001 |
| P02-SI-007 | P02-PG-001, P02-PG-002 | P02-FUA-WP-002 | P02-FUA-FR-002 | P02-FUA-SPEC-002 | AC-P02-FUA-002 |
| P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUA-WP-003 | P02-FUA-FR-003 | P02-FUA-SPEC-003 | AC-P02-FUA-003 |
| P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-FUA-WP-004 | P02-FUA-FR-004 | P02-FUA-SPEC-004 | AC-P02-FUA-004 |
| P02-SI-007, P02-SI-009 | P02-PG-003, P02-PG-005 | P02-FUA-WP-005 | P02-FUA-FR-005 | P02-FUA-SPEC-005 | AC-P02-FUA-005 |
| P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-004, P02-PG-005 | P02-FUA-WP-006 | P02-FUA-FR-006 | P02-FUA-SPEC-006 | AC-P02-FUA-006 |
| P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUA-WP-007 | P02-FUA-FR-007 | P02-FUA-SPEC-007 | AC-P02-FUA-007 |
| P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUA-WP-008 | P02-FUA-FR-008 | P02-FUA-SPEC-008 | AC-P02-FUA-008 |
| P02-SI-007 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-005 | P02-FUA-WP-009 | P02-FUA-FR-009 | P02-FUA-SPEC-009 | AC-P02-FUA-009 |

## AC-P02-FUA-001 Editable GoalProfile Intake
- Given the user selects `Set a goal` or edits an active goal, the panel must render editable goal type, target score, target ability, deadline, daily minutes, intensity preference and diagnostic sample inputs instead of fixed "IELTS speaking 8 · 30 min/day · 75 days" setup.
- Given the user submits valid custom values, the create-goal payload must contain those exact values and must not call the production default-goal-only path.
- Given goal type is empty, score and ability are both empty, deadline is not future, daily minutes is outside 5 through 240, or intensity is invalid, submit must be blocked before transport with user-visible validation.
- Given an active goal exists and the user selects edit, the same editable form must be available for revision rather than forcing a new default goal.

## AC-P02-FUA-002 SupportedGoalMatrix Pre-Plan Boundary
- Given a created goal returns `supported`, the summary must show support status, reason or limitation text, confidence and the normal plan-generation path.
- Given a created goal returns `partial`, the summary must show limitation copy and must not show high-certainty ETA, official score equivalence or goal-complete copy.
- Given a created goal returns `unsupported`, Generate plan, Checkpoint and Done actions must be disabled or absent, and the visible recovery action must be Edit goal.
- Given `goal_profile.support_status` and `support_decision.support_status` conflict, action gating must use the more restrictive status.

## AC-P02-FUA-003 Diagnostic Sample Capture
- Given the user fills one, two or three diagnostic transcript fields, only non-empty samples must be sent.
- Given all diagnostic transcript fields are empty, submit must be blocked before transport.
- Given the payload is sent, sample refs must be stable and ordered as `flutter_goal_sample_1`, `flutter_goal_sample_2`, `flutter_goal_sample_3` for the non-empty source fields.
- Given the response returns `diagnostic.sample_count` and `diagnostic.confidence_band`, summary must display both values so insufficient evidence is visible.

## AC-P02-FUA-004 Diagnostic Transport And Governance Boundary
- Given text fallback samples are submitted, the adapter must send candidate sample fields only: `sample_ref`, `transcript`, optional `audio_ref`, optional `duration_seconds`.
- Given no production audio capture is present, payload must not include fake `audio_ref`.
- Given the backend returns diagnostic facts, Flutter must parse and display summary-level accepted facts but must not locally create rubric, weakness or claim guard decisions.
- Given IELTS/TOEFL-like goals are displayed, copy must identify product-internal progress and must not imply official certification.

## AC-P02-FUA-005 Revision And Stale-Plan Visibility
- Given an active goal summary is loaded, UI/model must expose `goal_profile.revision` in a stable testable field.
- Given the user edits and submits the active goal, the request must use the create/revise endpoint and summary must refresh to the returned revision.
- Given the returned plan/action is missing, stale or blocked after revision, UI must not expose an old next action as executable.
- Given stale or missing plan state is visible, the recovery path must be Edit goal or Generate plan/Force replan only; no automatic notification, training execution or memory queue reorder is allowed in Followup-A.

## AC-P02-FUA-006 Downgrade And Prohibited Claims
- Given `diagnostic.confidence_band=low`, `diagnostic.status=low_confidence`, `support_status=partial`, or `support_status=unsupported`, UI must display a downgrade/limitation reason.
- Given diagnostic or forecast claim guard has `official_score_equivalence=false`, UI must not display official-score-equivalent copy.
- Given diagnostic or forecast claim guard has `goal_completion_claim_allowed=false`, UI must not display guaranteed outcome or completed-goal copy.
- Given ETA is missing, guarded, partial or low-confidence, UI must omit or qualify ETA instead of showing a precise target-achieved date.

## AC-P02-FUA-007 Test, Performance And Coverage Gate
- Given Followup-A implementation is submitted, Flutter widget/adapter tests must cover form validation, payload, sample filtering, support states, claim guard, revision/stale visibility and recovery controls.
- Given backend/API/domain code is modified, backend unit/integration tests must cover the modified branches and the existing P0.2 backend regression suite must pass.
- Given coverage checks run, Flutter feature line coverage must be >=80%; backend changed-code line and branch coverage must be >=80% when backend code changes.
- Given backend performance-sensitive code changes, P0.2 local budgets must remain at support decision p95 <=500 ms and diagnostic retrieval p95 <=800 ms.

## AC-P02-FUA-008 Independent Review And Traceability
- Given requirements, spec, acceptance and test cases are generated, each artifact must contain an independent review section with pass/fail result and residual risk.
- Given traceability is updated, every Followup-A row must include Stage Scope ID, Policy Gate, WP, FR, Spec, AC, TC, contract evidence, code evidence, test evidence and status.
- Given code work is ready for Followup-A closeout, `docs/reports/quality_report.md` must cite the review result, test commands and residual risk for Followup-A.
- Given any AC lacks executable test coverage, the exception must be explicit, justified and independently reviewed; silent gaps are not allowed.

## AC-P02-FUA-009 No-goal Explore Mode
- Given no active goal exists and the user has not selected `Set a goal`, the panel must render a `No active goal` empty state with primary CTA `Set a goal` and secondary `Explore practice` or `Try a sample drill`, and must not render the GoalProfile form by default.
- Given the user taps `Set a goal`, the editable intake form must open without calling create-goal transport or creating GoalProfile, DiagnosticAssessment, forecast, plan, autopilot or memory records before valid submit.
- Given the user taps `Explore practice` or `Try a sample drill`, no goal-autopilot create, generate-plan, complete-action, checkpoint, forecast or memory-schedule API may be called.
- Given Explore Mode produces practice feedback, that evidence must be ordinary practice/session evidence only and must not appear as goal-autopilot evidence, target gap, ETA, forecast, achieved-goal, guaranteed outcome, official score equivalence or next autopilot/memory item.
- Given `createDefaultGoal()` remains in code as a compatibility helper, no production no-goal browsing path may call it.

## AC-to-TC Requirement
Every AC-P02-FUA-001 through AC-P02-FUA-009 must map to at least one stable TC-P02-FUA ID before implementation routing. Code work remains blocked until this mapping is complete.

## 2026-06-11 XCB-005 Regression Addendum
- AC-P02-FUA-004 additionally requires backend rejection of untrusted `diagnostic_samples.audio_ref` values such as local paths, naked URLs, wrong-owner refs or unvalidated refs before any GoalProfile/DiagnosticAssessment fact persists.
- AC-P02-FUA-004 allows diagnostic audio only when the ref is an authenticated-user-owned validated `media://audio/...` produced by the existing Media upload create/complete flow and checked through AI Gateway.
- AC-P02-FUA-005 additionally requires `POST /goal-autopilot/goals` to be idempotent by `Idempotency-Key`; Flutter production transport must send that header, same-key/same-body replay must return the same summary, same-key/different-body must return `IDEMPOTENCY_CONFLICT`, and the data layer must preserve the single server-owned active goal revision chain.
- AC-P02-FUA-005 additionally requires the `goal_profiles.user_id` uniqueness migration to be upgrade-safe for legacy duplicate rows by pruning to the service-canonical active/latest profile before adding the unique constraint.
- AC-P02-FUA-008 additionally requires goal intake replay metadata, raw diagnostic audio refs and response JSON to follow XCB-006 export/deletion/redaction rules.

## Acceptance Independent Review
Result: pass after implementation evidence update. AC-P02-FUA-009 has executed TC-P02-FUA-014..016 coverage for no active goal empty state, explicit Set-a-goal transition, Explore Mode API isolation, evidence isolation, prohibited goal claims and `createDefaultGoal()` production-path exclusion.
