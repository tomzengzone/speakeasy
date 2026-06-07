# P0.2 Followup-E Implementation Plan：Speaking Diagnostic Production

## 状态
Implementation plan drafted / planning gate only - 本计划承接已通过的 Followup-E Phase 0-3 文档门禁。当前只记录规划/合同证据；不记录 backend、Flutter、OpenAPI/generated Dart、AI runtime、native mic/audio bytes upload、测试通过、release、Product Base merge 或 paid AI external evidence。任何代码实现都必须另起可审核 slice，并在执行后再补测试、报告和独立 review 证据。

## 上游来源
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/definition.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/requirements.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/spec.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/acceptance.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/test_cases.md`
- `docs/product/increments/p0-2-followup-e-speaking-diagnostic-production/traceability.md`
- `docs/architecture/api_contract.md`
- `docs/domain/domain_schema.md`
- `docs/ux/screen_spec.md`

## Implementation Batch Plan
| Batch ID | Scope | Primary AC | Primary TC | Status |
| --- | --- | --- | --- | --- |
| P02-FUE-IMP-000 | Implementation plan and routing | AC-P02-FUE-010 | TC-P02-FUE-023, TC-P02-FUE-026 | Planned / docs-only |
| P02-FUE-IMP-001 | OpenAPI source-of-truth and generated Dart drift for diagnostic audio endpoints | AC-P02-FUE-004, AC-P02-FUE-010 | TC-P02-FUE-007, TC-P02-FUE-024 | Planned |
| P02-FUE-IMP-002 | Backend diagnostic upload/session/audio sample persistence and service policy | AC-P02-FUE-004, AC-P02-FUE-005 | TC-P02-FUE-007, TC-P02-FUE-008, TC-P02-FUE-010, TC-P02-FUE-011 | Planned |
| P02-FUE-IMP-003 | Backend controller endpoints for create/complete/delete and owner/idempotency/security tests | AC-P02-FUE-004, AC-P02-FUE-005 | TC-P02-FUE-007, TC-P02-FUE-008, TC-P02-FUE-009 | Planned |
| P02-FUE-IMP-004 | Reports, traceability checker and independent quality review for backend upload slice | AC-P02-FUE-010 | TC-P02-FUE-023, TC-P02-FUE-024, TC-P02-FUE-025, TC-P02-FUE-026 | Planned |
| P02-FUE-IMP-005 | Flutter Speaking Check implementation routing with explicit reuse of existing MVP/P0.1 mic/recording service | AC-P02-FUE-001, AC-P02-FUE-002, AC-P02-FUE-003, AC-P02-FUE-010 | TC-P02-FUE-001..006, TC-P02-FUE-012, TC-P02-FUE-017, TC-P02-FUE-023, TC-P02-FUE-025, TC-P02-FUE-026 | Planned |
| P02-FUE-IMP-006 | Flutter adapter/upload bridge using backend-owned diagnostic upload API; no client-created `audio_ref` | AC-P02-FUE-004, AC-P02-FUE-010 | TC-P02-FUE-007, TC-P02-FUE-009, TC-P02-FUE-024 | Planned |
| P02-FUE-IMP-007 | Goal setup transition to Speaking Check intro, deterministic sample task policy and no-goal guard | AC-P02-FUE-001, AC-P02-FUE-002 | TC-P02-FUE-001, TC-P02-FUE-002, TC-P02-FUE-003, TC-P02-FUE-004 | Planned |
| P02-FUE-IMP-008 | Recording-control UI wired to existing recording boundary, permission-blocked path, text fallback and no local accepted facts on cancel/rerecord | AC-P02-FUE-003, AC-P02-FUE-005 | TC-P02-FUE-005, TC-P02-FUE-006, TC-P02-FUE-012 | Planned |
| P02-FUE-IMP-009 | Privacy/retention copy and conservative diagnostic submission from accepted text fallback or backend-returned refs only | AC-P02-FUE-001, AC-P02-FUE-004, AC-P02-FUE-008 | TC-P02-FUE-001, TC-P02-FUE-006, TC-P02-FUE-017 | Planned |
| P02-FUE-IMP-010 | Flutter/backend tests, reports, traceability checker update and independent review for Speaking Check slice | AC-P02-FUE-010 | TC-P02-FUE-001..006, TC-P02-FUE-012, TC-P02-FUE-017, TC-P02-FUE-023, TC-P02-FUE-025, TC-P02-FUE-026 | Planned |

## Next Executable Batch Proposal
The next implementation owner should choose one narrow batch and produce evidence only for that batch. The recommended first executable batch is backend trusted diagnostic upload, because Flutter must not synthesize `audio_ref` and diagnostic assessment must later consume only backend-owned refs.

Included for the first backend batch:
- Add or confirm machine-readable OpenAPI paths and schemas for diagnostic audio create, complete and delete only after implementation approval.
- Regenerate/update `lib/generated/api/` drift artifacts only as part of that approved batch.
- Implement backend-owned diagnostic upload session and sample state using existing media upload/storage primitives where appropriate.
- Ensure `audio_ref` is backend-generated and tied to authenticated user, goal revision, sample ref and accepted media state.
- Reject local file paths, unsigned URLs, stale/expired refs, cross-user refs, unsupported format and duplicate idempotency conflicts.
- Add backend tests for trusted upload, idempotency/ownership/security and basic quality-mode boundary.
- Update reports/traceability after executable evidence exists.

Excluded from the first backend batch:
- Flutter Speaking Check UI or native recording integration.
- ASR, pronunciation/scoring, LLM diagnostic generation or full diagnostic assessment result.
- Full retention/export/account-deletion cleanup.
- Entitlement/provider quota/cost downgrade.
- Release readiness, paid AI external evidence and Product Base merge approval.

## Flutter Batch Boundary
Flutter work should start only after the backend-owned `audio_ref` boundary is accepted or an approved mock contract is explicitly documented. The Flutter batch must reuse the existing MVP/P0.1 recording capability where practical. Its scope is Speaking Check orchestration, UI state, permission timing, local playback/re-record UX and upload bridge; it is not a duplicate mic subsystem.

Included for the Flutter batch:
- Replace or extend the GoalProfile diagnostic entry with a two-step flow: first create/update the backend GoalProfile without client-created audio evidence, then enter Speaking Check using accepted goal metadata.
- Render three deterministic sample tasks: `read_aloud`, `listen_repeat_or_retell` and `goal_context_free_answer`.
- Provide recording controls and UI states for start, stop, playback, re-record, accept, skip, cancel, permission blocked and text fallback.
- Bridge accepted local recordings to backend upload create/complete only through the approved API; `audio_ref` is consumed only from backend responses.
- Submit text fallback as low-confidence transcript-only evidence, with no acoustic claims.
- Add widget/adapter tests and report evidence only after implementation exists.

Excluded from the Flutter batch until separately approved:
- Replacing the existing local mic/recording service.
- Real provider ASR/scoring/LLM result generation.
- Full data governance/account deletion cleanup.
- Release, paid AI external evidence and Product Base merge approval.

## Ordering Rationale
1. Backend trusted upload before Flutter upload bridging because Flutter must never create `audio_ref`.
2. Flutter Speaking Check must reuse existing mic/recording capability to avoid duplicating MVP work.
3. Diagnostic assessment, ASR/scoring and downstream handoff should wait until trusted audio/text evidence is available.
4. Reports and independent review happen after each executable slice to avoid marking planned work as complete.

## Planned Verification Commands
| Gate | Command |
| --- | --- |
| Project agent validation | `python3 scripts/project_agent_runner.py validate` |
| OpenAPI/API drift | `npm run check:api-contract`; `npm run check:dart-client-drift` |
| Backend targeted tests | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DiagnosticAudioUploadContractTest,DiagnosticAudioUploadIdempotencyTest,DiagnosticAudioSecurityAndDeleteTest,SpeakingDiagnosticQualityGateTest,SpeakingDiagnosticModePolicyTest test` |
| Flutter focused widget tests | `flutter test test/features/goal_autopilot/speaking_check_entry_widget_test.dart test/features/goal_autopilot/speaking_check_no_goal_guard_test.dart test/features/goal_autopilot/speaking_check_sample_tasks_widget_test.dart test/features/goal_autopilot/speaking_check_recording_controls_test.dart test/features/goal_autopilot/speaking_check_permission_fallback_test.dart test/features/goal_autopilot/speaking_diagnostic_mode_downgrade_test.dart test/features/goal_autopilot/speaking_check_privacy_copy_test.dart` |
| Followup-E traceability checker | `python3 scripts/check_p0_2_followup_e_traceability.py` |
| Goal Autopilot coverage guard | `python3 scripts/check_p0_2_goal_autopilot_coverage.py` |
| Diff hygiene | `git diff --check -- <changed files>` |

## Independent Review Requirements
- Review each implementation slice before it is called locally complete.
- Verify TC IDs, script paths, command results, report IDs and residual blockers are recorded after execution.
- Verify Followup-E does not claim release readiness, paid AI external evidence, native/store privacy evidence or Product Base merge approval.
- Verify Flutter does not create, infer or persist `audio_ref`, and does not duplicate existing mic/recording service without explicit architecture approval.

## Exit Criteria Before Any Local Completion Claim
- The selected implementation slice has code/tests/reports that map to stable TC-P02-FUE IDs.
- Planned tests have been executed and results recorded with commands and evidence locations.
- OpenAPI/generated drift evidence is present only if that slice changed machine-readable API contracts.
- Independent review finds no blocker for the slice.
- Full Followup-E blockers remain explicit unless every downstream slice is complete: native mic/audio upload bridge, ASR/scoring/result, full data governance, entitlement/provider downgrade, paid AI external evidence, release readiness and Product Base merge.

## Current Evidence Boundary
No 2026-06-07 backend or Flutter Followup-E implementation evidence is accepted in this docs-only state. Any local code currently present in the working tree must be treated as unreviewed/unaccepted until the user explicitly approves a code implementation path or asks to restore those changes as executable evidence.
