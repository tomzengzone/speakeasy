# P0.2 Increment Spec：目标画像与诊断基础

## 状态
Design-ready / acceptance-input ready - 本 spec 是 `p0-2-goal-diagnostic-foundation` acceptance criteria 的直接上游输入；尚未进入实现。

## 上游引用
- Increment definition: `docs/product/increments/p0-2-goal-diagnostic-foundation/definition.md`
- Increment requirements: `docs/product/increments/p0-2-goal-diagnostic-foundation/requirements.md`
- Active stage: `docs/product/stages/p0-2-training-memory.md`

## Spec Trace IDs
| Spec ID | Stage Scope ID | Policy Gate | Requirement ID | Spec area |
| --- | --- | --- | --- | --- |
| P02-DIAG-SPEC-001 | P02-SI-007 | P02-PG-001, P02-PG-005 | P02-DIAG-FR-001 | GoalProfile lifecycle |
| P02-DIAG-SPEC-002 | P02-SI-007 | P02-PG-002 | P02-DIAG-FR-002 | SupportedGoalMatrix |
| P02-DIAG-SPEC-003 | P02-SI-008 | P02-PG-001, P02-PG-005 | P02-DIAG-FR-003 | Diagnostic flow |
| P02-DIAG-SPEC-004 | P02-SI-008 | P02-PG-001 | P02-DIAG-FR-004 | Rubric and confidence |
| P02-DIAG-SPEC-005 | P02-SI-008 | P02-PG-005 | P02-DIAG-FR-005 | Weakness decomposition |
| P02-DIAG-SPEC-006 | P02-SI-003 | P02-PG-001 | P02-DIAG-FR-006 | Initial mastery state |
| P02-DIAG-SPEC-007 | P02-SI-007, P02-SI-008 | P02-PG-004, P02-PG-005 | P02-DIAG-FR-007 | Commercial, data, performance and coverage gates |

## Inputs
- authenticated user id
- target type, target score/ability, deadline, daily minutes, intensity preference
- official scenario/content/rubric availability
- oral sample audio refs or text fallback where allowed
- ASR/scoring/LLM candidate results
- entitlement, quota and paid AI availability

## Outputs
- `GoalProfile` with status `supported`, `partial`, `unsupported`, `needs_more_diagnostic` or `active`
- `DiagnosticAssessment` with rubric scores, weakness tags, confidence band and evidence refs
- `SupportedGoalMatrixDecision`
- initial L0-L5 mastery starting state
- audit records for goal intake, diagnosis, candidate acceptance and policy downgrade

## State Model
| State | Meaning | Next states |
| --- | --- | --- |
| `GoalDraft` | User is entering target facts | `GoalSupportCheck`, `Cancelled` |
| `GoalSupportCheck` | System checks SupportedGoalMatrix | `DiagnosticReady`, `PartialSupported`, `Unsupported` |
| `DiagnosticReady` | Enough support exists to collect diagnostic samples | `CollectingSample`, `RecoverableError` |
| `CollectingSample` | User records required diagnostic answers | `EvaluatingDiagnostic`, `RecoverableError` |
| `EvaluatingDiagnostic` | ASR/scoring/LLM candidate evaluation runs | `DiagnosticComplete`, `LowConfidence`, `RecoverableError` |
| `DiagnosticComplete` | Trusted diagnostic facts are available | terminal |
| `LowConfidence` | Diagnostic is usable only with conservative plan or reassessment | terminal |
| `PartialSupported` | Goal can be partially supported with visible limits | terminal |
| `Unsupported` | Goal cannot enter full P0.2 plan | terminal |
| `RecoverableError` | Input/provider/policy failure | previous valid state, `PartialSupported`, `Unsupported` |

## P02-DIAG-SPEC-001 GoalProfile Lifecycle
GoalProfile is versioned. Target edits create a new revision and mark dependent plans/forecasts as stale. Downstream increments must reference profile id and revision.

## P02-DIAG-SPEC-002 SupportedGoalMatrix
The support decision checks goal type, score/ability range, deadline feasibility, daily minutes, rubric availability, scenario/task/content coverage and scoring signal availability. Unsupported goals fail closed.

## P02-DIAG-SPEC-003 Diagnostic Flow
Diagnostics require a minimum sample set defined by target type. Provider output is candidate-only; app rules accept, reject or downgrade based on sample count, audio quality, schema validity and confidence.

## P02-DIAG-SPEC-004 Rubric And Confidence
Rubric scores are product-internal. Each diagnostic result includes confidence band, reason codes and a claim guard that blocks official score equivalence and high-precision ETA from low-confidence input.

## P02-DIAG-SPEC-005 Weakness Decomposition
Weakness tags include evidence refs, severity, trainability, target-rubric dimension and recommended training direction. Tags must be structured enough for plan generation.

## P02-DIAG-SPEC-006 Initial Mastery State
Initial L0-L5 state is derived from diagnostic evidence and marked `initial_from_diagnostic`; it cannot be final mastery or goal achievement evidence.

## P02-DIAG-SPEC-007 Commercial, Data, Performance And Coverage Gates
Diagnostic depth and AI calls obey server-owned entitlement and quota. Sensitive goal/diagnostic data requires consent and retention/deletion/export rules. Implementation must include automated coverage >=80% for changed code and performance budgets: goal support decision p95 <= 500 ms, deterministic diagnostic result retrieval p95 <= 800 ms, diagnostic candidate evaluation request accepted/queued p95 <= 2 s in local deterministic tests.

## Required Downstream Contracts
- Domain model: GoalProfile, SupportedGoalMatrixDecision, DiagnosticAssessment, RubricScore, ConfidenceBand, WeaknessTag, MasteryInitialState.
- API/OpenAPI: goal intake, support decision, diagnostic sample submit, diagnostic result retrieval.
- AI runtime: diagnostic candidate schema, invalid-output rejection, claim guard examples.
- UX: goal setup, unsupported/partial state, diagnostic flow, low-confidence explanation.

## Non-goals
- Full official exam scoring certification.
- Backplan generation, daily planner, autopilot, checkpoint loop.
- Commercial release approval or paid AI provider external evidence closure.
