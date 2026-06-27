# 场景练习 Runtime 迁移测试用例

## 状态
已规划。这些测试用例用于后续迁移实现；本次 documentation-only 增量没有运行测试。

## 测试用例
| TC ID | FR | AC | Type | Automation target | Expected evidence |
| --- | --- | --- | --- | --- | --- |
| MIG-TC-001 | MIG-FR-001 | MIG-AC-002 | static architecture | SWC catalog / module-boundary check | `FE-SCENARIO-PRACTICE` maps to `lib/features/interview/` as current main flow with legacy-compatible path note. |
| MIG-TC-002 | MIG-FR-002 | MIG-AC-003 | static architecture | SWC catalog / path guard | `lib/features/scenario/` is marked `FE-LEGACY-SCENARIO-SANDBOX`; new feature expansion fails review. |
| MIG-TC-003 | MIG-FR-003 | MIG-AC-004, MIG-AC-009 | unit | Future `test/application/practice_runtime/*` | Runtime voice/message/TTS/recovery interfaces are reusable without importing interview or legacy sandbox widgets. |
| MIG-TC-004 | MIG-FR-004 | MIG-AC-008 | unit/static | `test/features/interview/*` plus import-boundary guard | Expression graph, mastery, wiki, queue, and content logic are not moved into generic runtime. |
| MIG-TC-005 | MIG-FR-005 | MIG-AC-001 | contract/static | OpenAPI drift check and backend diff review | No OpenAPI/backend/DB/provider diff appears in frontend-only migration. |
| MIG-TC-006 | MIG-FR-006 | MIG-AC-005 | review checklist | `spec.md` inventory table | Every old practice-related file has current responsibility and target SWC. |
| MIG-TC-007 | MIG-FR-007 | MIG-AC-006 | review checklist | `swc_allocation.md` allocation matrix | Each preserved behavior maps to FE SWC, BE SWC/API where applicable, domain entity, DB ownership, provider boundary, and test. |
| MIG-TC-008 | MIG-FR-008 | MIG-AC-007 | unit/integration | Interview practice page/runtime tests | Start/resume, voice, ASR fallback, text submit, message loop, TTS, hint, feedback/review, wiki, exit/recovery all pass. |
| MIG-TC-009 | MIG-FR-009 | MIG-AC-009 | static/import test | duplicate-runtime guard | No duplicate voice service, API DTO, local store, TTS wrapper, provider call, or final-mastery writer. |
| MIG-TC-010 | MIG-FR-010 | MIG-AC-010 | governance | Software Architecture Governance Check | Independent checker records pass in `docs/reports/quality_report.md`. |
| MIG-TC-011 | MIG-FR-011 | MIG-AC-011 | unit/integration | `test/application/session_stats_coordinator_test.dart` plus future runtime history adapter test | Completed-session and feedback-history updates reuse AppSession/session stats path or are explicitly blocked as non-goal. |

## 后续建议命令
后续实现切片应从以下命令中选择最小相关集合：
- `flutter test test/application/scene_setup_coordinator_test.dart test/application/scene_conversation_coordinator_test.dart`
- `flutter test test/application/practice_runtime/`
- `flutter test test/features/interview/`
- 如果触碰 legacy sandbox，运行 `flutter test test/features/scenario/`
- `flutter test test/application/session_stats_coordinator_test.dart`
- 触碰任何 API client 代码时，运行 OpenAPI/generated drift check
- 针对 forbidden imports 和 duplicate runtime creation 运行 static architecture guard
