# P0.2 Followup-C Traceability：周期复测、预测与多产品面加固

## 状态
S001 forecast hardening、S002 checkpoint task library、S003 checkpoint-to-plan and S004 backend projection locally implemented and tested / S005-S007 implementation gated - 本文件已把 Followup-C definition、requirements、spec、acceptance、test_cases 和 S000-S007 slice routing 接入 traceability。S000 文档链验证和独立审核已通过；S001 的 domain/API/OpenAPI/AI fallback contract、backend code 和 TC-P02-FUC-001..003 test evidence 已通过；S002 的 domain/API/OpenAPI/AI/UX contract、backend code 和 TC-P02-FUC-004..006 test evidence 已通过；S003 的 domain/API/OpenAPI/AI/UX contract、backend code、TC-P02-FUC-007..009 test evidence、coverage evidence 和独立审核已通过；S004 的 domain/API/OpenAPI/AI/UX contract、backend code、TC-P02-FUC-010..012 test evidence 和独立审核已通过；S005-S007 的 surface/downgrade/performance/release evidence 仍为 planned/not started。Followup-C is not release-ready；Product Base merge is not approved。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.6-p0.2-followup-c-s004-progress-projection |
| Last updated | 2026-06-06 |
| Owner | Product Manager Agent |
| Checker | Product Object Governance Check Agent / Documentation Governance / Independent Quality Review |
| Workflow state | S000 document chain validated；S001 forecast hardening locally implemented/tested；S002 checkpoint task library locally implemented/tested；S003 checkpoint-to-plan locally implemented/tested；S004 backend projection locally implemented/tested；S005-S007 implementation blocked |

## 上游链路
```text
docs/product/stages/p0-2-training-memory.md
  -> docs/product/increments/p0-2-autopilot-progress-checkpoint/
  -> docs/product/increments/p0-2-followup-b-autopilot-control-planner-memory/
  -> docs/reports/quality_report.md local implementation residual blockers
  -> docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/definition.md
  -> docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/requirements.md
  -> docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/spec.md
  -> docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/acceptance.md
  -> docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/test_cases.md
  -> docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces/traceability.md
```

## Implementation Slice Traceability
| Slice ID | WP | FR | Spec | AC | TC | Trace rows | Current status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUC-S000 | P02-FUC-WP-000 | P02-FUC-FR-000 | P02-FUC-SPEC-000 | AC-P02-FUC-000 | TC-P02-FUC-000 | P02-FUC-TR-000 | Documentation validation passed; no code |
| P02-FUC-S001 | P02-FUC-WP-001 | P02-FUC-FR-001 | P02-FUC-SPEC-001 | AC-P02-FUC-001 | TC-P02-FUC-001..003 | P02-FUC-TR-001 | Implemented locally / tests passed |
| P02-FUC-S002 | P02-FUC-WP-002 | P02-FUC-FR-002 | P02-FUC-SPEC-002 | AC-P02-FUC-002 | TC-P02-FUC-004..006 | P02-FUC-TR-002 | Implemented locally / tests passed |
| P02-FUC-S003 | P02-FUC-WP-003 | P02-FUC-FR-003 | P02-FUC-SPEC-003 | AC-P02-FUC-003 | TC-P02-FUC-007..009 | P02-FUC-TR-003 | Implemented locally / tests passed |
| P02-FUC-S004 | P02-FUC-WP-004 | P02-FUC-FR-004 | P02-FUC-SPEC-004 | AC-P02-FUC-004 | TC-P02-FUC-010..012 | P02-FUC-TR-004 | Implemented locally / tests passed |
| P02-FUC-S005 | P02-FUC-WP-005 | P02-FUC-FR-005 | P02-FUC-SPEC-005 | AC-P02-FUC-005 | TC-P02-FUC-013..016 | P02-FUC-TR-005 | Planned / not started |
| P02-FUC-S006 | P02-FUC-WP-006 | P02-FUC-FR-006 | P02-FUC-SPEC-006 | AC-P02-FUC-006 | TC-P02-FUC-017..019 | P02-FUC-TR-006 | Planned / not started |
| P02-FUC-S007 | P02-FUC-WP-007, P02-FUC-WP-008 | P02-FUC-FR-007 | P02-FUC-SPEC-007 | AC-P02-FUC-007 | TC-P02-FUC-020..022 | P02-FUC-TR-007 | Planned / not started |

## Full Traceability Matrix
| Trace Row ID | Slice ID | WP ID | Stage Scope ID | Policy Gate | Existing upstream row | FR | Spec | AC | TC | Contract Evidence | Code Evidence | Test Evidence | Review Gate | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUC-TR-000 | P02-FUC-S000 | P02-FUC-WP-000 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-AUTO-TR-001..008, P02-FUB-TR-001..009 | P02-FUC-FR-000 | P02-FUC-SPEC-000 | AC-P02-FUC-000 | TC-P02-FUC-000 | S000 docs created: definition, requirements, spec, acceptance, test_cases and traceability | N/A - no code change | TC-P02-FUC-000 passed: `python3 scripts/project_agent_runner.py validate`; `git diff --check -- docs/product/increments/p0-2-followup-c-checkpoint-forecast-surfaces docs/reports/quality_report.md`; evidence `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s000-document-chain-independent-review` | Independent S000 review recorded in `docs/reports/quality_report.md` | S000 documentation validation passed |
| P02-FUC-TR-001 | P02-FUC-S001 | P02-FUC-WP-001 | P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-AUTO-TR-004 | P02-FUC-FR-001 | P02-FUC-SPEC-001 | AC-P02-FUC-001 | TC-P02-FUC-001, TC-P02-FUC-002, TC-P02-FUC-003 | Domain updated in `docs/domain/domain_schema.md`; API contract/OpenAPI updated in `docs/architecture/api_contract.md` and `docs/architecture/openapi/speakeasy-api.yaml`; Dart drift hash updated; AI deterministic N/A and candidate-only fallback documented in `docs/ai_runtime/`；UX N/A - no Flutter surface changed in S001 | Backend policy/entity/service/API/migration code in `ProgressForecastPolicy`, `ForecastExplanationCandidateValidator`, `GoalProgressForecast`, `GoalAutopilotService`, `GoalAutopilotController`, `V202606050004__p0_2_followup_c_forecast_hardening.sql`; generated API hash updated in `lib/generated/api/` | TC-P02-FUC-001 passed: `ProgressForecastPolicyTest`; TC-P02-FUC-002 passed: `GoalAutopilotControllerTest#tcP02Fuc001ForecastHardeningClaimGuard`; TC-P02-FUC-003 passed: `ForecastExplanationSchemaTest`; evidence `docs/reports/test_report.md#2026-06-05-p02-followup-c-s001-forecast-hardening` | Independent S001 review recorded in `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s001-forecast-hardening-independent-review` | S001 implemented locally / release gated |
| P02-FUC-TR-002 | P02-FUC-S002 | P02-FUC-WP-002 | P02-SI-013 | P02-PG-001, P02-PG-002, P02-PG-004 | P02-AUTO-TR-005 | P02-FUC-FR-002 | P02-FUC-SPEC-002 | AC-P02-FUC-002 | TC-P02-FUC-004, TC-P02-FUC-005, TC-P02-FUC-006 | Domain updated in `docs/domain/domain_schema.md`; API/OpenAPI updated in `docs/architecture/api_contract.md` and `docs/architecture/openapi/speakeasy-api.yaml`; generated Dart drift hash updated; AI deterministic N/A for task selection documented in `docs/ai_runtime/`; UX screen dependency updated in `docs/ux/screen_spec.md` | Backend policy/service/API code in `CheckpointCadencePolicy`, `GoalAutopilotService`, `GoalAutopilotController`; generated API hash updated in `lib/generated/api/` | TC-P02-FUC-004 passed: `CheckpointCadencePolicyTest`; TC-P02-FUC-005 passed: `GoalAutopilotControllerTest#tcP02Fuc002CheckpointTaskLibrary`; TC-P02-FUC-006 passed: `npm run check:api-contract`; evidence `docs/reports/test_report.md#2026-06-05-p02-followup-c-s002-checkpoint-task-library` | Independent S002 review recorded in `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s002-checkpoint-task-library-independent-review` | S002 implemented locally / release gated |
| P02-FUC-TR-003 | P02-FUC-S003 | P02-FUC-WP-003 | P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-003 | P02-AUTO-TR-004, P02-AUTO-TR-005, P02-FUB-TR-005 | P02-FUC-FR-003 | P02-FUC-SPEC-003 | AC-P02-FUC-003 | TC-P02-FUC-007, TC-P02-FUC-008, TC-P02-FUC-009 | Domain updated in `docs/domain/domain_schema.md`; API/OpenAPI updated in `docs/architecture/api_contract.md` and `docs/architecture/openapi/speakeasy-api.yaml`; generated Dart drift hash updated; AI checkpoint feedback candidate-only boundary documented in `docs/ai_runtime/`; UX screen dependency updated in `docs/ux/screen_spec.md` | Backend service/API code in `GoalAutopilotService` and `GoalAutopilotController`; generated API hash updated in `lib/generated/api/` | TC-P02-FUC-007 passed: `GoalAutopilotControllerTest#tcP02Fuc003CheckpointUpdatesForecastAndPlanSignal`; TC-P02-FUC-008 passed: `CheckpointReplayAuditTest`; TC-P02-FUC-009 passed: control/recovery/failed/skipped/blocked checkpoint branches; evidence `docs/reports/test_report.md#2026-06-05-p02-followup-c-s003-checkpoint-plan-update` | Independent S003 review recorded in `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s003-checkpoint-plan-update-independent-review` | S003 implemented locally / release gated |
| P02-FUC-TR-004 | P02-FUC-S004 | P02-FUC-WP-004 | P02-SI-006 | P02-PG-003, P02-PG-005 | P02-AUTO-TR-006, P02-FUB-TR-001 | P02-FUC-FR-004 | P02-FUC-SPEC-004 | AC-P02-FUC-004 | TC-P02-FUC-010, TC-P02-FUC-011, TC-P02-FUC-012 | Domain updated in `docs/domain/domain_schema.md`; API/OpenAPI updated in `docs/architecture/api_contract.md` and `docs/architecture/openapi/speakeasy-api.yaml`; generated Dart drift hash updated; AI deterministic N/A for projection selection documented in `docs/ai_runtime/`; UX screen dependency updated in `docs/ux/screen_spec.md` | Backend service/API code in `GoalAutopilotService` and `GoalAutopilotController`; generated API hash updated in `lib/generated/api/` | TC-P02-FUC-010 passed: `GoalProgressProjectionServiceTest`; TC-P02-FUC-011 passed: `GoalAutopilotControllerTest#tcP02Fuc004ProjectionIsBackendOwned`; TC-P02-FUC-012 passed: `npm run check:api-contract` and `npm run check:dart-client-drift`; evidence `docs/reports/test_report.md#2026-06-06-p02-followup-c-s004-progress-projection` | Independent S004 review recorded in `docs/reports/quality_report.md#2026-06-06-p02-followup-c-s004-progress-projection-independent-review` | S004 implemented locally / release gated |
| P02-FUC-TR-005 | P02-FUC-S005 | P02-FUC-WP-005 | P02-SI-006, P02-SI-010 | P02-PG-003, P02-PG-005 | P02-AUTO-TR-002, P02-AUTO-TR-006, P02-FUB-TR-002 | P02-FUC-FR-005 | P02-FUC-SPEC-005 | AC-P02-FUC-005 | TC-P02-FUC-013, TC-P02-FUC-014, TC-P02-FUC-015, TC-P02-FUC-016 | Planned Flutter adapter/surface and UX states | Not started | Planned - Home, Queue and Wiki widget/integration tests; one- or two-surface evidence remains partial | UX/source-of-truth and full-surface coverage review required | Planned |
| P02-FUC-TR-006 | P02-FUC-S006 | P02-FUC-WP-006 | P02-SI-006 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-AUTO-TR-006, P02-AUTO-TR-007 | P02-FUC-FR-006 | P02-FUC-SPEC-006 | AC-P02-FUC-006 | TC-P02-FUC-017, TC-P02-FUC-018, TC-P02-FUC-019 | Planned data governance, projection downgrade and UX downgrade contracts | Not started | Planned - deletion, unavailable, unsupported, partial, low-confidence and cache invalidation tests | Privacy review required | Planned |
| P02-FUC-TR-007 | P02-FUC-S007 | P02-FUC-WP-007, P02-FUC-WP-008 | P02-SI-006, P02-SI-010, P02-SI-012, P02-SI-013 | P02-PG-001..005 | P02-AUTO-TR-008, P02-FUB-TR-008, P02-FUB-TR-009 | P02-FUC-FR-007 | P02-FUC-SPEC-007 | AC-P02-FUC-007 | TC-P02-FUC-020, TC-P02-FUC-021, TC-P02-FUC-022 | Planned QA scripts, performance, coverage and report contracts | Not started | Planned - p95 budgets, coverage, traceability script and final review evidence | QA/performance/final independent review required | Planned |

## Bidirectional Coverage Index
| Direction | Coverage |
| --- | --- |
| Stage scope -> Slice | P02-SI-006 maps to S000, S004, S005, S006, S007；P02-SI-010 maps to S000, S005, S007；P02-SI-012 maps to S000, S001, S003, S007；P02-SI-013 maps to S000, S002, S003, S007 |
| Slice -> FR | S000..S007 each map to exactly one primary FR |
| FR -> Spec -> AC -> TC | P02-FUC-FR-000..007 each has one primary P02-FUC-SPEC, AC-P02-FUC and at least one TC-P02-FUC |
| TC -> AC | TC-P02-FUC-000..022 all reference at least one AC; AC-P02-FUC-000..007 all have primary TC coverage |
| Contract -> Code | S001, S002, S003 and S004 contract impacts are implemented and tested；S005-S007 contract impacts remain planned |
| Code -> Test | S001 code maps to TC-P02-FUC-001..003 passed evidence；S002 code maps to TC-P02-FUC-004..006 passed evidence；S003 code maps to TC-P02-FUC-007..009 passed evidence；S004 code maps to TC-P02-FUC-010..012 passed evidence；S005-S007 TC rows remain planned until routed execution |

## Gap Register
| Gap ID | Gap | Trace Row | Current handling |
| --- | --- | --- | --- |
| P02-FUC-GAP-000 | Followup-C lacked requirements/spec/acceptance/test_cases and S000-S007 slice routing. | P02-FUC-TR-000 | Closed for S000 documentation chain: required docs, S000-S007 routing, FR/Spec/AC/TC mapping, validation commands and independent review exist. |
| P02-FUC-GAP-001 | ProgressForecast is deterministic/local but not fully explainable or claim-guarded for all downgrade states. | P02-FUC-TR-001 | Closed for S001 local forecast hardening: policy/API expose forecast state, source goal revision, ETA range/unavailable reason, risk reason code, deterministic explanation metadata, claim guard and deterministic AI-provider N/A fallback. |
| P02-FUC-GAP-002 | Checkpoint cadence and goal-type task library are not robust. | P02-FUC-TR-002 | Closed for S002 local checkpoint task library: weekly/biweekly cadence, due-now/overdue/not-due, supported goal task matching, partial/unsupported limitation and cost fallback are covered by TC-P02-FUC-004..006. |
| P02-FUC-GAP-003 | Checkpoint result does not yet provide full replayable checkpoint-to-plan update semantics. | P02-FUC-TR-003 | Closed for S003 local checkpoint-to-plan update: checkpoint result status/reason, forecast update, replayable plan signal, no false completion, paused rejection and recovery/control-blocked compatibility are covered by TC-P02-FUC-007..009. |
| P02-FUC-GAP-004 | Backend-owned goal-progress projection for surfaces does not exist as a complete source-of-truth boundary. | P02-FUC-TR-004 | Closed for S004 local backend projection: `GET /goal-autopilot/progress-projection` aggregates safe goal/next-action/forecast/checkpoint/surface fragments, source refs and downgrade reason while redacting raw transcript/audio, sensitive target details and provider payloads; covered by TC-P02-FUC-010..012. |
| P02-FUC-GAP-005 | Queue/Wiki propagation remains open and Home is the only current product surface evidence. | P02-FUC-TR-005 | Planned for S005; Home, Queue and Wiki are all required for full S005 and P02-SI-006 closure. One- or two-surface evidence can only close a partial milestone. |
| P02-FUC-GAP-006 | Surface deletion/unavailable/unsupported/low-confidence downgrade is not implemented across surfaces. | P02-FUC-TR-006 | Planned for S006. |
| P02-FUC-GAP-007 | Followup-C p95 performance budgets are not implemented. | P02-FUC-TR-007 | Planned for S007. |
| P02-FUC-GAP-008 | Followup-C dedicated traceability/coverage gate does not exist yet. | P02-FUC-TR-007 | Planned for S007; `scripts/check_p0_2_followup_c_traceability.py` is not yet implemented. |
| P02-FUC-GAP-009 | Followup-C final independent implementation review is not available because S005-S007 and final release-check evidence are not complete. | P02-FUC-TR-007 | Planned for S007 after surface/downgrade/performance/code/test/report evidence exists. |

## Required Next Documents And Evidence
Before any S005-S007 code change:
- Confirm routed slice ownership and whether domain/API/OpenAPI/AI/UX contracts need updates.
- Keep `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md` and this traceability file synchronized.
- If API shape changes, update `docs/architecture/openapi/speakeasy-api.yaml` and generated Dart drift manifest before implementation completion.
- If surface UI changes, update UX screen spec or record a scoped N/A decision.
- If forecast or checkpoint AI explanation schema changes, update AI runtime schema/eval docs before implementation completion and include entitlement/quota/cost fallback or deterministic N/A evidence.

After implementation begins:
- Test Evidence must cite TC ID, script path, execution command, result status and evidence report.
- Code Evidence must cite concrete backend/domain/API/Flutter files or explicit N/A reason.
- Quality Report must state whether the routed slice is locally closed and must preserve release/Product Base non-approval unless Followup-D explicitly closes it.

## Scaffold Review Checklist
- Queue/Wiki/Home progress displays are treated as backend-owned projections.
- Home, Queue and Wiki must all be covered by AC and widget/integration tests before full S005, P02-SI-006 or Followup-C local completion.
- Forecast AI explanation must prove entitlement/quota/cost fallback or document deterministic N/A before S001 can close.
- Forecast and checkpoint copy cannot claim official score certification or guaranteed outcome.
- Code evidence is explicit: S001 is implemented locally; S002-S007 remain `Not started` rather than blank.
- Followup-C does not claim release approval or completed implementation.

## Traceability Independent Review
S000 independent review passed on 2026-06-05 and is recorded in `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s000-document-chain-independent-review`. S001 independent review passed on 2026-06-05 and is recorded in `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s001-forecast-hardening-independent-review`. S002 independent review passed on 2026-06-05 and is recorded in `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s002-checkpoint-task-library-independent-review`. S003 independent review passed on 2026-06-05 and is recorded in `docs/reports/quality_report.md#2026-06-05-p02-followup-c-s003-checkpoint-plan-update-independent-review`. S004 independent review passed on 2026-06-06 and is recorded in `docs/reports/quality_report.md#2026-06-06-p02-followup-c-s004-progress-projection-independent-review`. The reviews preserve S000-S007 slice routing, FR/Spec/AC/TC mapping, gap register, evidence entry points and release/Product Base boundaries. S005-S007 remain implementation blocked until their routed contract/code/test gates are approved.
