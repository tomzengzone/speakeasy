# MVP System E2E Validation Traceability

## 状态
Validated for full local MVP system E2E gate - TC-MVP-E2E-001 到 TC-MVP-E2E-010 已有脚本、命令、执行结果和报告证据；真实支付 provider 继续以 external/manual gate 追踪。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-29 | Draft | 建立本地系统 E2E 验证追踪矩阵。 |
| v1.0 | 2026-05-29 | Validated | 实现并通过本地 PostgreSQL + Spring Boot + Flutter macOS smoke gate；覆盖审计脚本通过。 |
| v1.1 | 2026-05-29 | Validated | 实现并通过 TC-MVP-E2E-006 到 TC-MVP-E2E-010 深度系统回归；支付 provider 保留 external/manual gate。 |

## Owner
Document Traceability Check Skill

## Traceability Chain
`docs/product/roadmap.md`
-> `docs/product/stages/mvp-backend-foundation.md`
-> `docs/product/base/acceptance.md`
-> `docs/product/increments/mvp-system-e2e-validation/definition.md`
-> `requirements.md`
-> `spec.md`
-> `acceptance.md`
-> `test_cases.md`
-> `traceability.md`

## Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Product Base Coverage | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-E2E-TR-001 | MVP-SI-014 | `mvp-system-e2e-validation` | MVP-E2E-FR-001 Local real-stack orchestration | MVP-E2E-SPEC-001 | AC-MVP-E2E-001 | Supports AC-001, AC-002, AC-003 by proving the real stack is executable | `docs/product/increments/mvp-system-e2e-validation/spec.md`; `docs/product/increments/mvp-system-e2e-validation/test_cases.md` | `scripts/run_mvp_system_e2e.sh`; `macos/Runner/DebugProfile.entitlements`; macOS deployment target 11.0 | TC-MVP-E2E-001, script `scripts/run_mvp_system_e2e.sh`, command `scripts/run_mvp_system_e2e.sh`, result `passed 2026-05-29`, evidence `docs/reports/test_report.md` | `docs/reports/test_report.md`; `docs/reports/implementation_report.md`; `docs/reports/quality_report.md` | Validated | MVP-E2E-GAP-001 closed: script implemented and passed with local PostgreSQL 15.18. |
| MVP-E2E-TR-002 | MVP-SI-014 | `mvp-system-e2e-validation` | MVP-E2E-FR-002 Flutter-driven critical user journey | MVP-E2E-SPEC-002 | AC-MVP-E2E-002 | Covers AC-001, AC-002, AC-003, AC-004, AC-005 smoke path | `docs/product/base/acceptance.md`; `docs/product/increments/mvp-system-e2e-validation/test_cases.md` | `integration_test/mvp_system_smoke_test.dart`; `scripts/run_mvp_system_e2e.sh`; UI test keys in `login_page.dart` and `onboarding_page.dart`; E2E Hive isolation in bootstrap/storage services | TC-MVP-E2E-002 and TC-MVP-E2E-003, script `integration_test/mvp_system_smoke_test.dart`, command `scripts/run_mvp_system_e2e.sh`, result `passed 2026-05-29`, evidence `docs/reports/test_report.md` | `docs/reports/test_report.md`; `docs/reports/implementation_report.md`; `docs/reports/quality_report.md` | Validated | MVP-E2E-GAP-002 closed for smoke path: Flutter UI ran against real backend/PostgreSQL. |
| MVP-E2E-TR-003 | MVP-SI-014 | `mvp-system-e2e-validation` | MVP-E2E-FR-003 Product Base AC system coverage matrix | MVP-E2E-SPEC-003 | AC-MVP-E2E-003 | Maps AC-001 through AC-013 to TC-MVP-E2E-002 through TC-MVP-E2E-010 or explicit exception | `docs/product/base/acceptance.md`; `docs/product/base/traceability.md`; `docs/product/increments/mvp-system-e2e-validation/test_cases.md` | `scripts/check_mvp_system_e2e_coverage.py`; `integration_test/mvp_system_scene_catalog_test.dart`; `integration_test/mvp_system_learning_memory_test.dart`; `integration_test/mvp_system_practice_feedback_test.dart`; `integration_test/mvp_system_profile_settings_test.dart`; `integration_test/mvp_system_membership_boundary_test.dart` | TC-MVP-E2E-004 and TC-MVP-E2E-006..010, commands `python3 scripts/check_mvp_system_e2e_coverage.py`, `scripts/run_mvp_system_e2e.sh --suite scene-catalog`, `--suite learning-memory`, `--suite practice-feedback`, `--suite profile-settings`, `--suite membership-boundary`, result `passed 2026-05-29`, evidence `docs/reports/test_report.md` | `docs/reports/test_report.md`; `docs/reports/implementation_report.md`; `docs/reports/quality_report.md` | Validated | MVP-E2E-GAP-003, GAP-005, GAP-006 and GAP-007 closed; GAP-008 remains accepted external payment exception only. |
| MVP-E2E-TR-004 | MVP-SI-014 | `mvp-system-e2e-validation` | MVP-E2E-FR-004 Evidence, diagnostics and rerun protocol | MVP-E2E-SPEC-004 | AC-MVP-E2E-004 | Applies to all Product Base AC rows via required TC metadata/evidence fields | `docs/product/increments/mvp-system-e2e-validation/test_cases.md` | `scripts/check_mvp_system_e2e_coverage.py`; `scripts/run_mvp_system_e2e.sh` | TC-MVP-E2E-005, script `scripts/check_mvp_system_e2e_coverage.py`, command `python3 scripts/check_mvp_system_e2e_coverage.py`, result `passed 2026-05-29`, evidence `docs/reports/test_report.md` | `docs/reports/test_report.md`; `docs/reports/implementation_report.md`; `docs/reports/quality_report.md` | Validated | MVP-E2E-GAP-004 closed: execution evidence and known residual diagnostics are recorded. |

## Product Base Coverage Audit
| Product Base AC | Coverage disposition | Owning TC IDs | Residual risk |
| --- | --- | --- | --- |
| AC-001 | smoke automated passed | TC-MVP-E2E-002 | Startup/login gate passed in local system smoke. |
| AC-002 | smoke automated passed | TC-MVP-E2E-002 | Apple/WeChat/SMS production providers remain external; test phone path covers local backend session. |
| AC-003 | smoke automated passed | TC-MVP-E2E-003 | Deep validation of all onboarding branches remains future expansion. |
| AC-004 | automated passed | TC-MVP-E2E-003, TC-MVP-E2E-006 | Catalog/detail/join/listening path passed locally. |
| AC-005 | automated passed | TC-MVP-E2E-003, TC-MVP-E2E-007, TC-MVP-E2E-009 | Learning route, favorite memory and relogin persistence passed locally. |
| AC-006 | automated passed | TC-MVP-E2E-006 | Real speaker/mic behavior may still require platform/manual evidence. |
| AC-007 | automated passed | TC-MVP-E2E-007 | Expression queue and favorite persistence passed locally. |
| AC-008 | automated passed | TC-MVP-E2E-008 | Practice UI and deterministic backend provider path passed; real voice capture remains external/manual if needed. |
| AC-009 | automated passed | TC-MVP-E2E-008 | Deterministic coach feedback and provider status passed. |
| AC-010 | automated passed | TC-MVP-E2E-007, TC-MVP-E2E-008 | Favorites memory, evidence candidates and recap fields passed. |
| AC-011 | automated passed | TC-MVP-E2E-009 | Profile/settings/session persistence passed. |
| AC-012 | automated UI passed plus manual-external payment exception | TC-MVP-E2E-010 | Local membership boundary UI passed; real payment provider remains external/manual. |
| AC-013 | automated UI passed plus accepted payment exception | TC-MVP-E2E-010 | Boundary UI passed; real purchase completion remains out of local MVP gate. |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-E2E-GAP-001 | 本地真实 PostgreSQL + backend + Flutter orchestration script 尚未落地。 | MVP-E2E-TR-001 | QA + Codex Root | Closed 2026-05-29 |
| MVP-E2E-GAP-002 | Flutter integration smoke 尚未实现，无法证明 UI 到后端/DB 的核心路径已经自动化通过。 | MVP-E2E-TR-002 | Frontend + QA | Closed 2026-05-29 |
| MVP-E2E-GAP-003 | Product Base AC 系统覆盖矩阵尚未有机器审核脚本。 | MVP-E2E-TR-003 | QA | Closed 2026-05-29 |
| MVP-E2E-GAP-004 | 系统 E2E 执行证据和失败分类尚未写入报告。 | MVP-E2E-TR-004 | QA | Closed 2026-05-29 |
| MVP-E2E-GAP-005 | 场景目录、听力热身、推荐表达、收藏和学习记忆曾缺少深度系统测试执行证据。 | MVP-E2E-TR-003 | Frontend + Backend + QA | Closed 2026-05-29 |
| MVP-E2E-GAP-006 | 语音模拟、教练反馈和学习证据需要 deterministic provider 系统测试。 | MVP-E2E-TR-003 | Backend + AI Runtime + QA | Closed 2026-05-29 |
| MVP-E2E-GAP-007 | Profile/settings/session persistence 系统测试尚未自动化。 | MVP-E2E-TR-003 | Frontend + QA | Closed 2026-05-29 |
| MVP-E2E-GAP-008 | 真实支付 provider 不纳入本地系统必过 gate，需保持 manual-external 例外。 | MVP-E2E-TR-003 | Product + QA + Release | Accepted external exception |

## Completion Rule
本 increment 不允许仅凭文档进入 Validated。TC-MVP-E2E-001 到 TC-MVP-E2E-010 均已有脚本、命令、执行结果和报告证据；TC-MVP-E2E-010 对真实支付 provider 保留 Product Base AC 的明确 external/manual 例外关系。
