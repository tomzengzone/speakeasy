# P0.2 Acceptance Criteria：目标画像与诊断基础

## 状态
Design-ready / AC-to-TC mapping required - 基于 increment spec 生成；尚未进入实现。

## 上游来源
- `docs/product/increments/p0-2-goal-diagnostic-foundation/requirements.md`
- `docs/product/increments/p0-2-goal-diagnostic-foundation/spec.md`

## Stage Scope Acceptance Coverage
| Stage Scope ID | Requirement ID | Spec ID | Acceptance Criteria |
| --- | --- | --- | --- |
| P02-SI-007 | P02-DIAG-FR-001 | P02-DIAG-SPEC-001 | AC-P02-DIAG-001 |
| P02-SI-007 | P02-DIAG-FR-002 | P02-DIAG-SPEC-002 | AC-P02-DIAG-002 |
| P02-SI-008 | P02-DIAG-FR-003 | P02-DIAG-SPEC-003 | AC-P02-DIAG-003 |
| P02-SI-008 | P02-DIAG-FR-004 | P02-DIAG-SPEC-004 | AC-P02-DIAG-004 |
| P02-SI-008 | P02-DIAG-FR-005 | P02-DIAG-SPEC-005 | AC-P02-DIAG-005 |
| P02-SI-003 | P02-DIAG-FR-006 | P02-DIAG-SPEC-006 | AC-P02-DIAG-006 |
| P02 policy gates | P02-DIAG-FR-007 | P02-DIAG-SPEC-007 | AC-P02-DIAG-007 |

## AC-P02-DIAG-001 GoalProfile 事实源
- Given an authenticated user submits target type, target score/ability, deadline, daily minutes and intensity preference, the system must persist a versioned GoalProfile.
- Given the user edits any target fact, the system must create a new revision or mark downstream plan/forecast inputs stale.
- Given downstream planner or forecast reads goal input, it must reference the active GoalProfile revision and not a UI-local draft.

## AC-P02-DIAG-002 SupportedGoalMatrix
- Given a goal has enough rubric, content and scoring support, the system must mark it `supported` and allow diagnostic flow.
- Given a goal has partial content or rubric support, the system must mark it `partial`, show limitation copy and block full ETA/achievement claims.
- Given a goal is unsupported, the system must mark it `unsupported` and must not generate full plan, ETA, checkpoint forecast or goal-complete status.

## AC-P02-DIAG-003 Initial Diagnostic Flow
- Given a supported or partial goal, the system must collect the minimum diagnostic sample set before producing normal-confidence diagnostic facts.
- Given ASR/scoring/LLM candidate evaluation fails or returns invalid schema, the system must return recoverable or low-confidence state, not a fake score.
- Given diagnostic sample count or audio quality is insufficient, the system must require more diagnostic evidence or downgrade confidence.

## AC-P02-DIAG-004 Rubric, Confidence And Claim Guard
- Given diagnostic completes, the result must include product-internal rubric scores and confidence band.
- Given confidence is low, the system must prevent high-precision ETA and goal-complete claims.
- Given a TOEFL/IELTS-like target, the system must not claim official certification or official score equivalence.

## AC-P02-DIAG-005 Weakness Decomposition
- Given diagnostic completes, the system must output structured weakness tags with evidence refs, severity and target-rubric dimension.
- Given a weakness is candidate-only from AI output, app rules must accept/reject/downgrade before persistence.
- Given backplan consumes diagnostic output, weakness tags must be machine-readable and not display-only prose.

## AC-P02-DIAG-006 Initial L0-L5 Mastery
- Given diagnostic has accepted evidence, the system must initialize applicable L0-L5 starting states.
- Given an initial mastery state is created, it must be marked as diagnostic-derived and cannot be treated as final mastery.
- Given AI output includes final mastery or goal completion, the system must reject those fields as final persistent state.

## AC-P02-DIAG-007 Commercial, Data, Performance And Coverage Gates
- Given diagnostic uses AI or paid-depth assessment, entitlement and quota must be checked server-side; quota failure must downgrade or block with user-visible reason.
- Given goal or diagnostic data is stored, consent, retention, deletion/export and audit behavior must be defined before implementation completion.
- Given implementation is submitted, changed backend/domain/API/Flutter code for this increment must have automated line and branch coverage >=80%.
- Given implementation performance tests run, goal support decision p95 must be <=500 ms, deterministic diagnostic result retrieval p95 <=800 ms and diagnostic candidate evaluation request accepted/queued p95 <=2 s.

## AC-to-TC Requirement
Every AC-P02-DIAG-001 through AC-P02-DIAG-007 must map to at least one stable TC-P02-DIAG ID before implementation routing.
