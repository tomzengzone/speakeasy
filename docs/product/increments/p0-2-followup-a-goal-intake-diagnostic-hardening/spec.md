# P0.2 Followup-A Spec：目标录入与诊断加固

## 状态
FR-001..009 implemented locally / release-gated - 本 spec 的 no-goal Explore Mode 已进入本地 Flutter 实现和测试证据；完整 P0.2 release 仍受 Followup-B/C/D 约束。

## 上游引用
- Increment definition: `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/definition.md`
- Increment requirements: `docs/product/increments/p0-2-followup-a-goal-intake-diagnostic-hardening/requirements.md`
- Existing foundation increment: `docs/product/increments/p0-2-goal-diagnostic-foundation/`
- Active stage: `docs/product/stages/p0-2-training-memory.md`
- API contract: `docs/architecture/openapi/speakeasy-api.yaml`

## Spec Trace IDs
| Spec ID | Stage Scope ID | Policy Gate | WP ID | Requirement ID | Spec area |
| --- | --- | --- | --- | --- | --- |
| P02-FUA-SPEC-001 | P02-SI-007 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-FUA-WP-001 | P02-FUA-FR-001 | Editable GoalProfile intake |
| P02-FUA-SPEC-002 | P02-SI-007 | P02-PG-001, P02-PG-002 | P02-FUA-WP-002 | P02-FUA-FR-002 | SupportedGoalMatrix pre-plan boundary |
| P02-FUA-SPEC-003 | P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUA-WP-003 | P02-FUA-FR-003 | Diagnostic sample capture |
| P02-FUA-SPEC-004 | P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-FUA-WP-004 | P02-FUA-FR-004 | Diagnostic transport and governance |
| P02-FUA-SPEC-005 | P02-SI-007, P02-SI-009 | P02-PG-003, P02-PG-005 | P02-FUA-WP-005 | P02-FUA-FR-005 | Revision and stale-plan visibility |
| P02-FUA-SPEC-006 | P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-004, P02-PG-005 | P02-FUA-WP-006 | P02-FUA-FR-006 | Downgrade and prohibited claims |
| P02-FUA-SPEC-007 | P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUA-WP-007 | P02-FUA-FR-007 | Test, performance and coverage gates |
| P02-FUA-SPEC-008 | P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-004, P02-PG-005 | P02-FUA-WP-008 | P02-FUA-FR-008 | Review and traceability evidence |
| P02-FUA-SPEC-009 | P02-SI-007 | P02-PG-001, P02-PG-002, P02-PG-003, P02-PG-005 | P02-FUA-WP-009 | P02-FUA-FR-009 | No-goal Explore Mode |

## Contract Decision
Followup-A can use the existing P0.2 OpenAPI contract without adding backend fields if Flutter sends and parses the current fields fully:
- Request: `GoalAutopilotGoalRequest.goal_type`, `target_score`, `target_ability`, `deadline`, `daily_minutes`, `intensity_preference`, `diagnostic_samples`, `autopilot_control`.
- Response: `goal_profile`, `support_decision`, `diagnostic`, `forecast`, optional `weekly_backplan`, optional `daily_plan`, optional `next_action`.
- If implementation discovers a missing API field, code must stop at contract update first; tests cannot rely on undocumented response fields.

## Inputs
- Authenticated learner session.
- No-active-goal summary or recoverable "no active goal" state.
- User-entered GoalProfile: goal type, target score or ability, deadline, daily minutes, intensity preference.
- User-entered diagnostic sample drafts: up to three visible transcript fields and optional future `audio_ref` boundary.
- User action: `Set a goal`, `Explore practice` or `Try a sample drill`.
- Existing backend support matrix and diagnostic response.

## Outputs
- No active goal empty state that does not persist a GoalProfile.
- Goal creation or revision payload derived from user input, not from a fixed default goal.
- Parsed `GoalAutopilotSummary` model with goal, support, diagnostic, claim guard, forecast and plan visibility fields.
- User-visible state for supported, partial, unsupported, low-confidence and stale-plan cases.
- Ordinary practice/session feedback when the user explores without setting a goal, explicitly outside goal-autopilot evidence.
- Automated test evidence mapped to Followup-A AC and TC IDs.

## UI State Model
| State | Entry condition | Allowed user actions | Exit condition |
| --- | --- | --- | --- |
| `NoActiveGoal` | Summary load fails because no active goal exists, or no summary data is available | `Set a goal`; `Explore practice`; `Try a sample drill` | User enters `GoalIntakeForm` or `ExplorePractice`; no goal-autopilot fact is created by this state |
| `GoalIntakeForm` | User explicitly chooses `Set a goal` or starts editing an active goal | Fill GoalProfile and diagnostic samples; submit; cancel | Valid submit creates or revises goal; cancel returns to prior state without creating facts |
| `ExplorePractice` | User chooses `Explore practice` or `Try a sample drill` before setting a goal | Ordinary practice actions and feedback only | User exits practice or later chooses `Set a goal`; no GoalProfile, DiagnosticAssessment, Forecast, Plan, AutopilotAction or MemoryCurve schedule is created |
| `EditingGoal` | User chooses to edit the active goal | Edit current fields; submit revision; cancel back to summary | Valid submit creates new profile revision |
| `SubmittingGoal` | Intake submit is in flight | No duplicate submit | Summary reloads or recoverable error appears |
| `SupportedReady` | `support_status=supported` and diagnostic is not unsupported | Generate plan if no current action; complete action if action exists | Plan/action/checkpoint updates |
| `PartialOrLowConfidence` | `support_status=partial` or diagnostic/forecast confidence is `low` | Generate conservative plan; edit goal; add better sample if exposed | Plan is partial or goal is revised |
| `Unsupported` | `support_status=unsupported` or diagnostic status is `unsupported` | Edit goal only | Revised goal becomes supported or partial |
| `StalePlanVisible` | Goal revision changes and summary has no valid plan/action, or plan status is `stale` if returned | Force replan or edit goal; no stale next action completion | Fresh plan/action is generated |

## P02-FUA-SPEC-001 Editable GoalProfile Intake
- Replace the fixed default setup panel with a form in `GoalAutopilotPanel`.
- The form appears only after the user explicitly chooses `Set a goal` or edits an active goal; no-active-goal browsing must render the empty state defined in P02-FUA-SPEC-009.
- Form fields:
  - goal type options: `ielts_speaking`, `toefl_speaking`, `business_meeting`, `job_interview`, `onboarding_introduction`.
  - target score numeric field, optional only when target ability is present.
  - target ability text field, optional only when target score is present.
  - deadline date field or picker; submitted value must be a future calendar date.
  - daily minutes numeric field; valid range 5 through 240.
  - intensity preference options: `gentle`, `standard`, `intensive`.
- Client validation must block empty goal type, missing score/ability pair, non-future deadline, out-of-range minutes and invalid intensity before transport.
- The start button must call `GoalAutopilotAdapter.createGoal(...)` with user-entered values and must not call `createDefaultGoal()` from the production setup path.
- `createDefaultGoal()` may remain only as a compatibility/test helper if production UI no longer uses it.

## P02-FUA-SPEC-002 SupportedGoalMatrix Pre-Plan Boundary
- `GoalAutopilotSummary` must parse `support_decision.support_status`, `reason_code`, `limitation_message`, `rubric_available` and `content_coverage`.
- Summary UI must show support status and limitation message before plan generation.
- For `unsupported`, Generate plan, Checkpoint and Done actions must be unavailable; the visible recovery action is Edit goal.
- For `partial`, UI must show the limitation and avoid high-certainty ETA or complete-goal wording.
- If `support_decision.support_status` and `goal_profile.support_status` disagree, UI must choose the more restrictive status for action gating.

## P02-FUA-SPEC-003 Diagnostic Sample Capture
- Intake form must render three diagnostic transcript fields.
- At least one non-empty diagnostic transcript is required for submission; one or two samples are allowed but must be visible as low-confidence or conservative diagnostic risk after response parsing.
- Empty sample fields must be filtered out of the payload.
- Submitted samples must have stable `sample_ref` values in the form `flutter_goal_sample_1`, `flutter_goal_sample_2`, `flutter_goal_sample_3`.
- UI must show the resulting `diagnostic.sample_count` and `diagnostic.confidence_band` in summary.
- Flutter adapter implementation must expose a typed sample input boundary such as `GoalDiagnosticSampleInput` so UI text fields cannot be silently replaced by hard-coded transcripts.

## P02-FUA-SPEC-004 Diagnostic Transport And Governance Boundary
- Adapter must send diagnostic samples as candidate evidence only: `sample_ref`, `transcript`, optional `audio_ref`, optional `duration_seconds`.
- Followup-A must not synthesize or hard-code diagnostic transcripts when the user provides samples.
- If no production audio capture exists, Followup-A must not send fake `audio_ref`; text fallback is the only allowed local sample path.
- Flutter must parse backend accepted facts but must not locally write final rubric scores, weakness tags or claim guard decisions.
- Production UI copy must preserve that IELTS/TOEFL-like goals use product-internal progress and are not official certification.

## P02-FUA-SPEC-005 Revision And Stale-Plan Visibility
- `GoalAutopilotSummary` must parse `goal_profile.revision`, `goal_profile.status`, `daily_plan.status` and `next_action.status`.
- Summary UI must expose revision in a stable text/testable node.
- Editing and submitting an existing goal must create a new goal revision through the same create/revise endpoint.
- After a revision, if no fresh plan/action is present or if returned plan/action status is stale/blocked, UI must not render old next action as executable.
- The only Followup-A recovery controls are Edit goal and Generate plan/Force replan. Automatic execution, notification scheduling and memory queue reorder remain blocked for Followup-B.

## P02-FUA-SPEC-006 Downgrade And Prohibited Claims
- `GoalAutopilotSummary` must parse `diagnostic.status`, `diagnostic.sample_count`, `diagnostic.claim_guard.official_score_equivalence`, `diagnostic.claim_guard.goal_completion_claim_allowed`, `diagnostic.claim_guard.allowed_claim`, `forecast.eta_date`, `forecast.eta_window`, `forecast.risk_reason` and `forecast.claim_guard`.
- If official score equivalence is false in diagnostic or forecast claim guard, UI must not display official-score-equivalent language.
- If goal completion claim is false, UI must not display "goal achieved", "guaranteed", "official score", or equivalent claim text.
- Low-confidence and partial states may show product-internal progress, gap summary, risk level and next checkpoint date, but ETA must be conservative or omitted if claim guard disallows it.

## P02-FUA-SPEC-007 Test, Performance And Coverage Gates
- Required Flutter tests:
  - form validation and user-entered payload;
  - diagnostic sample filtering and stable sample refs;
  - supported, partial and unsupported rendering/action gating;
  - claim guard copy blocking official/guaranteed claims;
  - revision/stale-plan rendering and force replan recovery;
  - adapter model parsing for newly consumed fields.
- Required backend tests only if backend/API/domain code changes. Existing P0.2 backend foundation tests remain reusable for unchanged backend behavior.
- Coverage gate: Flutter feature line coverage >=80%; backend changed-code line and branch coverage >=80% when backend code changes.
- Performance gate: unchanged backend budgets from diagnostic foundation must remain valid if backend is touched: support decision p95 <=500 ms and deterministic diagnostic retrieval p95 <=800 ms.

## P02-FUA-SPEC-008 Review And Traceability Evidence
- `acceptance.md` must map each spec row to at least one AC.
- `test_cases.md` must map each AC to at least one TC unless an explicit non-executable review exception is documented.
- `traceability.md` must contain Stage Scope ID, Policy Gate, WP, FR, Spec, AC, TC, contract evidence, code evidence, test evidence and status.
- `docs/reports/quality_report.md` must include independent review entries for requirements, spec, acceptance, test cases, traceability and implementation once code exists.

## P02-FUA-SPEC-009 No-goal Explore Mode
- When no active goal exists and the user has not selected `Set a goal`, `GoalAutopilotPanel` must render a `No active goal` empty state instead of an editable GoalProfile form.
- Empty state controls must include primary CTA `Set a goal` and at least one secondary entry: `Explore practice` or `Try a sample drill`.
- Selecting `Set a goal` opens `GoalIntakeForm` and must not create a goal, diagnostic, forecast, plan or memory schedule until the user submits valid values.
- Selecting `Explore practice` or `Try a sample drill` routes to ordinary practice/session behavior and must not call `createGoal`, `generatePlan`, `completeAction`, `submitCheckpoint` or any goal-autopilot persistence endpoint.
- Explore Mode must not persist `GoalProfile`, `DiagnosticAssessment`, `ProgressForecast`, `GoalBackplan`, `GoalDailyPlan`, `AutopilotAction` or MemoryCurve schedule records.
- Explore Mode evidence, if any, must be stored as ordinary practice/session evidence and must not feed goal-autopilot gap, ETA, forecast, achievement, plan or checkpoint calculations until the user explicitly creates a goal and accepted diagnostic facts exist.
- Explore Mode UI may show ordinary practice feedback only. It must not show goal gap, estimated achievement date, goal achieved copy, guaranteed outcome copy, official exam-score equivalence or next autopilot/memory item.
- `createDefaultGoal()` is not a production browse fallback. It may remain only as a test fixture or explicit compatibility helper and must not be called from no-goal browsing paths.

## Non-goals
- Do not implement Followup-B pause/resume endpoints, notification scheduler, missed-day recovery or item-level memory queue reorder.
- Do not implement Followup-C Queue/Wiki surface projection or checkpoint forecast hardening.
- Do not implement Followup-D release flags, commercial entitlement telemetry, export/retention UI or Product Base merge approval.
- Do not implement a complete Explore Practice content library or recommender in Followup-A; this spec only defines the no-goal boundary and testable entry behavior.

## Spec Independent Review
Result: pass after implementation evidence update. P02-FUA-SPEC-009 is implemented locally by `GoalAutopilotPanel` no-active-goal empty state, `GoalIntakeForm` transition and ordinary `ExplorePractice` sample drill; TC-P02-FUA-014..016 verify no goal-autopilot fact creation or prohibited claims.
