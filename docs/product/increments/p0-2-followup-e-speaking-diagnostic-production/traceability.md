# P0.2 Followup-E Traceability：生产级音频优先口语诊断

## 状态
Phase 3 traceability passed independent review / implementation planning only - 本文件建立 Followup-E Stage Scope -> WP -> FR -> Spec -> AC -> TC -> Contract Evidence -> Code Evidence -> Test Evidence -> Review Gate 链路。当前链路仅记录规划/合同证据；所有 Code Evidence 和 executable Test Evidence 均为 implementation pending。Followup-E 不代表 backend、Flutter、OpenAPI/generated client、AI runtime、native mic/audio bytes upload、release-ready、paid AI external evidence passed 或 Product Base merge approved。

## 上游来源
- `docs/process/change_request.md#cr-20260607-001-p02-sheng-chan-ji-yin-pin-you-xian-kou-yu-zhen-duan`
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/definition.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/requirements.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/spec.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/acceptance.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/test_cases.md`
- `docs/domain/domain_schema.md`
- `docs/architecture/api_contract.md`
- `docs/architecture/data_flow.md`
- `docs/ai_runtime/prompt_contract.md`
- `docs/ai_runtime/llm_output_schema.md`
- `docs/ai_runtime/fallback_strategy.md`
- `docs/ai_runtime/ai_eval_cases.md`
- `docs/ux/screen_spec.md`

## Source Chain
```text
P02-SI-007 / P02-SI-008 / P02-SI-009 / P02-SI-012 / P02-SI-013
  -> CR-20260607-001
  -> definition.md
  -> requirements.md
  -> spec.md
  -> domain/API/data/AI/UX contracts
  -> acceptance.md
  -> test_cases.md
  -> traceability.md
  -> implementation/tests/reports later
```

## Implementation Slice Traceability
| Slice ID | WP | FR | Spec | AC | TC | Trace rows | Current status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUE-S000 | P02-FUE-WP-000 | P02-FUE-FR-000 | P02-FUE-SPEC-000 | AC-P02-FUE-000 | TC-P02-FUE-000 | P02-FUE-TR-000 | Phase 3 planning gate passed; no code |
| P02-FUE-S001 | P02-FUE-WP-001, P02-FUE-WP-006 | P02-FUE-FR-001..003 | P02-FUE-SPEC-001..003 | AC-P02-FUE-001..003 | TC-P02-FUE-001..006 | P02-FUE-TR-001..003 | Planned - reuse existing MVP/P0.1 recording service; implement Speaking Check orchestration/upload bridge later |
| P02-FUE-S002 | P02-FUE-WP-002 | P02-FUE-FR-004 | P02-FUE-SPEC-004 | AC-P02-FUE-004 | TC-P02-FUE-007..009 | P02-FUE-TR-004 | Planned |
| P02-FUE-S003 | P02-FUE-WP-003 | P02-FUE-FR-005 | P02-FUE-SPEC-005 | AC-P02-FUE-005 | TC-P02-FUE-010..012 | P02-FUE-TR-005 | Planned |
| P02-FUE-S004 | P02-FUE-WP-004 | P02-FUE-FR-006..007 | P02-FUE-SPEC-006..007 | AC-P02-FUE-006..007 | TC-P02-FUE-013..016 | P02-FUE-TR-006..007 | Planned |
| P02-FUE-S005 | P02-FUE-WP-005 | P02-FUE-FR-008 | P02-FUE-SPEC-008 | AC-P02-FUE-008 | TC-P02-FUE-017..019 | P02-FUE-TR-008 | Planned |
| P02-FUE-S006 | P02-FUE-WP-007 | P02-FUE-FR-009 | P02-FUE-SPEC-009 | AC-P02-FUE-009 | TC-P02-FUE-020..022 | P02-FUE-TR-009 | Planned |
| P02-FUE-S007 | P02-FUE-WP-008, P02-FUE-WP-009 | P02-FUE-FR-010 | P02-FUE-SPEC-010 | AC-P02-FUE-010 | TC-P02-FUE-023..026 | P02-FUE-TR-010 | Planned |

## Full Traceability Matrix
| Trace Row ID | Slice ID | WP ID | Stage Scope ID | Policy Gate | Existing upstream row | FR | Spec | AC | TC | Contract Evidence | Code Evidence | Test Evidence | Review Gate | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| P02-FUE-TR-000 | P02-FUE-S000 | P02-FUE-WP-000 | P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-AUTO-TR-001; P02-FUA document chain; P02-FUD release/data gates | P02-FUE-FR-000 | P02-FUE-SPEC-000 | AC-P02-FUE-000 | TC-P02-FUE-000 | `definition.md`, `requirements.md`, `spec.md`, `acceptance.md`, `test_cases.md`, `traceability.md`; stage/status docs | N/A - no code change in Phase 0-3 | TC-P02-FUE-000 planned: docs validation and `git diff --check`; no execution evidence yet | Phase 3 independent review passed | Planning gate passed / implementation blocked |
| P02-FUE-TR-001 | P02-FUE-S001 | P02-FUE-WP-001, P02-FUE-WP-006 | P02-SI-007, P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUA diagnostic intake boundary; P02-FUD privacy UX boundary | P02-FUE-FR-001 | P02-FUE-SPEC-001 | AC-P02-FUE-001 | TC-P02-FUE-001, TC-P02-FUE-002 | UX contract in `docs/ux/screen_spec.md`; data/privacy boundary in `docs/architecture/data_flow.md` | Not started - implementation pending; must reuse existing MVP/P0.1 audio capture boundary where practical | TC-P02-FUE-001/002 planned widget tests; no execution evidence | Phase 3 independent review passed | Planned |
| P02-FUE-TR-002 | P02-FUE-S001 | P02-FUE-WP-001, P02-FUE-WP-006 | P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUA diagnostic sample scaffold | P02-FUE-FR-002 | P02-FUE-SPEC-002 | AC-P02-FUE-002 | TC-P02-FUE-003, TC-P02-FUE-004 | Domain task/sample model in `docs/domain/domain_schema.md`; UX sample states in `docs/ux/screen_spec.md` | Not started - implementation pending | TC-P02-FUE-003/004 planned widget/backend policy tests; no execution evidence | Phase 3 independent review passed | Planned |
| P02-FUE-TR-003 | P02-FUE-S001 | P02-FUE-WP-001, P02-FUE-WP-006 | P02-SI-008 | P02-PG-001, P02-PG-005 | P02-FUA fallback UX; P02-FUD consent/privacy UX | P02-FUE-FR-003 | P02-FUE-SPEC-003 | AC-P02-FUE-003 | TC-P02-FUE-005, TC-P02-FUE-006 | UX recording states in `docs/ux/screen_spec.md`; fallback rules in `docs/ai_runtime/fallback_strategy.md` | Not started - implementation pending; no duplicate mic subsystem approved | TC-P02-FUE-005/006 planned widget tests; no execution evidence | Phase 3 independent review passed | Planned |
| P02-FUE-TR-004 | P02-FUE-S002 | P02-FUE-WP-002 | P02-SI-008 | P02-PG-004, P02-PG-005 | Commercial AI provider hardening media flow; P02-FUD cost/data gates | P02-FUE-FR-004 | P02-FUE-SPEC-004 | AC-P02-FUE-004 | TC-P02-FUE-007, TC-P02-FUE-008, TC-P02-FUE-009 | API contract in `docs/architecture/api_contract.md`; data flow in `docs/architecture/data_flow.md`; domain upload/session model in `docs/domain/domain_schema.md` | Not started - backend/API implementation pending; machine-readable OpenAPI/generated-client evidence not accepted in this docs-only state | TC-P02-FUE-007/008/009 planned backend tests; no execution evidence | Phase 3 independent review passed | Planned |
| P02-FUE-TR-005 | P02-FUE-S003 | P02-FUE-WP-003 | P02-SI-008, P02-SI-012 | P02-PG-001, P02-PG-002, P02-PG-005 | P02-AUTO forecast confidence; P02-FUC forecast downgrade | P02-FUE-FR-005 | P02-FUE-SPEC-005 | AC-P02-FUE-005 | TC-P02-FUE-010, TC-P02-FUE-011, TC-P02-FUE-012 | Domain diagnostic mode rules in `docs/domain/domain_schema.md`; UX downgrade states in `docs/ux/screen_spec.md`; API response fields in `docs/architecture/api_contract.md` | Not started - quality/mode implementation pending | TC-P02-FUE-010/011/012 planned unit/integration/widget tests; no execution evidence | Phase 3 independent review passed | Planned |
| P02-FUE-TR-006 | P02-FUE-S004 | P02-FUE-WP-004 | P02-SI-008 | P02-PG-001, P02-PG-004, P02-PG-005 | P02-FUB/P02-FUC AI candidate-only boundaries; P02-FUD AI fallback/cost gates | P02-FUE-FR-006 | P02-FUE-SPEC-006 | AC-P02-FUE-006 | TC-P02-FUE-013, TC-P02-FUE-014, TC-P02-FUE-015 | AI prompt/schema/fallback/eval in `docs/ai_runtime/`; API transcript rules in `docs/architecture/api_contract.md` | Not started - backend AI validation implementation pending | TC-P02-FUE-013/014/015 planned contract/AI eval tests; no execution evidence | Phase 3 independent review passed | Planned |
| P02-FUE-TR-007 | P02-FUE-S004 | P02-FUE-WP-004 | P02-SI-008, P02-SI-009, P02-SI-012, P02-SI-013 | P02-PG-001, P02-PG-002 | P02-AUTO backplan/forecast/checkpoint inputs; P02-FUC forecast/checkpoint downgrade | P02-FUE-FR-007 | P02-FUE-SPEC-007 | AC-P02-FUE-007 | TC-P02-FUE-016 | Domain result model in `docs/domain/domain_schema.md`; API result fields in `docs/architecture/api_contract.md`; AI schema boundary in `docs/ai_runtime/llm_output_schema.md` | Not started - backend diagnostic/handoff implementation pending | TC-P02-FUE-016 planned integration test; no execution evidence | Phase 3 independent review passed | Planned |
| P02-FUE-TR-008 | P02-FUE-S005 | P02-FUE-WP-005 | P02-SI-008 | P02-PG-005 | P02-FUD data governance/export/retention; account deletion flow | P02-FUE-FR-008 | P02-FUE-SPEC-008 | AC-P02-FUE-008 | TC-P02-FUE-017, TC-P02-FUE-018, TC-P02-FUE-019 | Data flow in `docs/architecture/data_flow.md`; domain privacy state in `docs/domain/domain_schema.md`; UX privacy states in `docs/ux/screen_spec.md` | Not started - privacy UI/data governance/account deletion implementation pending | TC-P02-FUE-017/018/019 planned widget/integration tests; no execution evidence | Phase 3 independent review passed | Planned |
| P02-FUE-TR-009 | P02-FUE-S006 | P02-FUE-WP-007 | P02-SI-008 | P02-PG-004, P02-PG-005 | P02-FUD entitlement/quota/cost/usage gates | P02-FUE-FR-009 | P02-FUE-SPEC-009 | AC-P02-FUE-009 | TC-P02-FUE-020, TC-P02-FUE-021, TC-P02-FUE-022 | API errors in `docs/architecture/api_contract.md`; fallback strategy in `docs/ai_runtime/fallback_strategy.md`; data flow usage boundary in `docs/architecture/data_flow.md` | Not started - entitlement/quota/provider downgrade implementation pending | TC-P02-FUE-020/021/022 planned integration/widget tests; no execution evidence | Phase 3 independent review passed | Planned |
| P02-FUE-TR-010 | P02-FUE-S007 | P02-FUE-WP-008, P02-FUE-WP-009 | P02-SI-007, P02-SI-008 | P02-PG-001..005 | P02-FUB/FUC/FUD quality gate patterns | P02-FUE-FR-010 | P02-FUE-SPEC-010 | AC-P02-FUE-010 | TC-P02-FUE-023, TC-P02-FUE-024, TC-P02-FUE-025, TC-P02-FUE-026 | This traceability file; planned checker; planned OpenAPI/generated drift gate; reports `docs/reports/test_report.md`, `docs/reports/implementation_report.md`, `docs/reports/quality_report.md` | Not started - checker/OpenAPI/generated/report implementation evidence pending | TC-P02-FUE-023/024/025/026 planned release-check/review gates; no execution evidence | Phase 3 independent review passed | Planned |

## Bidirectional Coverage Index
| Direction | Coverage |
| --- | --- |
| Stage scope -> Slice | P02-SI-007 maps to S000, S001, S007；P02-SI-008 maps to S000..S007；P02-SI-009 maps to S004；P02-SI-012 maps to S003 and S004；P02-SI-013 maps to S004 |
| Policy gate -> Slice | P02-PG-001 maps to S000, S001, S003, S004, S007；P02-PG-002 maps to S000, S003, S004, S007；P02-PG-003 maps to S000/S007 as no-autostart boundary；P02-PG-004 maps to S002, S004, S006, S007；P02-PG-005 maps to every slice with audio/privacy implications |
| Slice -> FR | S000 maps to FR-000；S001 maps to FR-001..003；S002 maps to FR-004；S003 maps to FR-005；S004 maps to FR-006..007；S005 maps to FR-008；S006 maps to FR-009；S007 maps to FR-010 |
| FR -> Spec -> AC -> TC | P02-FUE-FR-000..010 each has one primary Spec and AC; every AC has at least one stable TC-P02-FUE ID |
| Contract -> AC | Domain/API/data/AI/UX contracts feed AC-P02-FUE-001..010, with explicit no-fake-`audio_ref`, no client `audio_asr`, three-sample `audio_full`, text-only low-confidence and release boundary checks |
| TC -> AC | TC-P02-FUE-000..026 all reference an owning AC; AC-P02-FUE-000..010 all have planned TC coverage |

## Gap Register
| Gap ID | Gap | Trace Row | Current handling |
| --- | --- | --- | --- |
| P02-FUE-GAP-000 | Followup-E lacked complete phase 0-3 document chain and gate status. | P02-FUE-TR-000 | Phase 0-3 document/contract/planning gate has independent review pass; implementation remains blocked until executable code, tests, reports and release/Product Base gates are completed. |
| P02-FUE-GAP-001 | Followup-A text fallback did not provide production real-speaking baseline. | P02-FUE-TR-001 | AC/TC require audio-first Speaking Check after GoalProfile, with skip/text fallback as downgraded path; implementation remains planned. |
| P02-FUE-GAP-002 | Diagnostic sample set was not defined strongly enough for real speaking evidence. | P02-FUE-TR-002 | AC/TC require three sample types; `audio_full` requires all three accepted and quality-passed; implementation remains planned. |
| P02-FUE-GAP-003 | Recording UX could be high-friction or permission-hostile. | P02-FUE-TR-003 | AC/TC require permission only on record, playback/re-record/cancel/skip/text fallback and no local fact on cancel; implementation must reuse existing recording service where practical. |
| P02-FUE-GAP-004 | Fake or client-created `audio_ref` risk. | P02-FUE-TR-004 | AC/TC/API contract require backend-owned trusted upload and rejection of local paths, unsigned URLs, stale/cross-user refs and duplicate conflicts; implementation remains planned. |
| P02-FUE-GAP-005 | Quality and diagnostic mode could overclaim full audio diagnosis. | P02-FUE-TR-005 | AC/TC require quality states, `audio_full` all-three rule, `audio_partial` downgrade and `text_only` acoustic omission; implementation remains planned. |
| P02-FUE-GAP-006 | ASR/scoring/LLM output could become persistent source of truth. | P02-FUE-TR-006 | AC/TC/AI contracts require candidate-only output, forbidden-field rejection and no client-supplied `audio_asr`; implementation remains planned. |
| P02-FUE-GAP-007 | Diagnostic could stop at a score instead of training handoff. | P02-FUE-TR-007 | AC/TC require top weaknesses, next training focus and conservative downstream handoff; implementation remains planned. |
| P02-FUE-GAP-008 | Audio privacy, retention, export and deletion boundaries were not productized. | P02-FUE-TR-008 | AC/TC/data contracts require consent copy, retention states, export minimization, deletion cleanup and account deletion handling; implementation remains planned. |
| P02-FUE-GAP-009 | Provider/cost/quota failures could block setup or create fake success. | P02-FUE-TR-009 | AC/TC require entitlement/usage reservation/cost policy, stable downgrade reasons and no full diagnostic success under fallback; implementation remains planned. |
| P02-FUE-GAP-010 | AC-to-TC, drift, coverage, reports and independent review gates were missing. | P02-FUE-TR-010 | Planning gate is defined; checker, drift, coverage, report and independent review evidence must be produced only after executable implementation exists. |

## Required Next Documents And Evidence
After this docs-only planning gate, required next executable evidence is:
- Implementation plan approval for the selected next slice.
- OpenAPI source-of-truth and generated Dart drift evidence only if that slice explicitly updates machine-readable API contracts.
- Backend tests for upload create/complete/delete, idempotency, owner isolation/delete security, quality rejection, diagnostic mode, AI validation, data governance and entitlement/quota/cost paths as applicable.
- Flutter tests for Speaking Check entry, no-goal guard, deterministic tasks, recording controls, permission/text fallback, downgrade copy, privacy copy, native upload bridge and deleted/unavailable states as applicable.
- AI eval tests for valid candidates, forbidden fields, text-only acoustic claim rejection and sensitive payload rejection.
- Reports that cite TC IDs, script paths, commands, result status and residual blockers before any slice-level local completion claim.

## Scaffold Review Checklist
- `audio_full` requires all three required diagnostic sample types accepted and quality-passed.
- Client-supplied `audio_asr` is invalid or ignored; only backend-generated/backend-confirmed ASR can become an accepted transcript source.
- Text fallback is allowed but low confidence and cannot produce acoustic dimensions.
- Flutter never creates, edits or infers `audio_ref`.
- Followup-E reuses existing MVP/P0.1 recording capability where practical and does not duplicate mic functionality without a separate architectural decision.
- AI/provider output is candidate-only and cannot mutate persistent diagnostic, plan, forecast, checkpoint, entitlement, billing, release or Product Base facts.
- Privacy/export/delete states do not leak raw audio, signed URLs, provider payloads, provider secrets or unrestricted sensitive transcript.
- Phase 3 docs do not claim implementation, release readiness, paid AI external evidence or Product Base merge.

## Traceability Independent Review
Result: pass for planning gate. Independent Phase 2-3 review confirmed AC-to-TC completeness, Stage Scope coverage, contract evidence coverage, planned code/test evidence status and release/Product Base boundary. All executable TC statuses remain `planned`; implementation, OpenAPI/generated client sync, executable tests, paid AI external evidence, release readiness and Product Base merge remain explicitly gated.
