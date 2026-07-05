# MVP System E2E Validation Test Cases

## 状态
Validated for full local MVP system E2E gate - TC-MVP-E2E-001 到 TC-MVP-E2E-010 已有脚本、命令、执行结果和报告证据；TC-MVP-E2E-010 的真实支付 provider 保留 manual/external gate。

## Owner
Test Case Development Agent

## Source
- `docs/product/base/acceptance.md`
- `docs/product/increments/mvp-system-e2e-validation/definition.md`
- `docs/product/increments/mvp-system-e2e-validation/requirements.md`
- `docs/product/increments/mvp-system-e2e-validation/spec.md`
- `docs/product/increments/mvp-system-e2e-validation/acceptance.md`
- `docs/product/increments/mvp-system-e2e-validation/traceability.md`

## Coverage Summary
| AC | Traceability Row | Test Case IDs | Gate status |
| --- | --- | --- | --- |
| AC-MVP-E2E-001 | MVP-E2E-TR-001 | TC-MVP-E2E-001 | automated passed |
| AC-MVP-E2E-002 | MVP-E2E-TR-002 | TC-MVP-E2E-002, TC-MVP-E2E-003 | automated passed |
| AC-MVP-E2E-003 | MVP-E2E-TR-003 | TC-MVP-E2E-004 | automated passed |
| AC-MVP-E2E-004 | MVP-E2E-TR-004 | TC-MVP-E2E-005 | automated passed |

## Product Base System Coverage Matrix
| Product Base AC | System coverage | Test Case IDs | Status | Notes |
| --- | --- | --- | --- | --- |
| AC-001 | App startup and login gate | TC-MVP-E2E-002 | smoke automated passed | Flutter app starts against real backend config and shows unauthenticated gate in the smoke path. |
| AC-002 | Phone login and authenticated session | TC-MVP-E2E-002 | smoke automated passed | Uses test phone path only under `ENABLE_TEST_PHONE_LOGIN=true`; backend issues token and user. |
| AC-003 | Onboarding / first assessment | TC-MVP-E2E-003 | smoke automated passed | UI choices persist onboarding completion and learning route. |
| AC-004 | Home and official scenes | TC-MVP-E2E-003, TC-MVP-E2E-006 | automated passed | Smoke asserts home modules; TC-006 opens catalog scene detail, joins a scene, and reaches listening warmup. |
| AC-005 | Home learning state | TC-MVP-E2E-003, TC-MVP-E2E-007, TC-MVP-E2E-009 | automated passed | First route, favorite memory, and relogin persistence are now system-tested. |
| AC-006 | Listening warmup | TC-MVP-E2E-006 | automated passed | Local UI path reaches listening warmup and mode toggle; real speaker output remains platform/manual if needed. |
| AC-007 | Recommendations and favorites | TC-MVP-E2E-007 | automated passed | Expression queue card, favorite action and profile/favorites persistence are asserted. |
| AC-008 | Scene simulation | TC-MVP-E2E-008 | automated passed | Practice UI is reached; backend practice session/turn uses deterministic feedback provider. |
| AC-009 | Coach feedback and message assistance | TC-MVP-E2E-008 | automated passed | Deterministic coach summary, validation status and provider status are asserted. |
| AC-010 | Recap and learning evidence | TC-MVP-E2E-008, TC-MVP-E2E-007 | automated passed | Practice completion returns recap fields and evidence candidates; favorites memory persists. |
| AC-011 | Profile and settings | TC-MVP-E2E-009 | automated passed | Profile update, settings toggle, logout/relogin and backend session persistence are asserted. |
| AC-012 | Membership and commercial placeholders | TC-MVP-E2E-010 | automated passed plus manual-external payment gate | Local membership UI/plans/restore/subscribe boundary is tested; real payment provider is external. |
| AC-013 | MVP boundary | TC-MVP-E2E-010 | automated passed plus accepted payment exception | Boundary UI is explicit; real purchase completion remains outside local gate. |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-E2E-001 | MVP-SI-014 | MVP-E2E-FR-001 | MVP-E2E-SPEC-001 | AC-MVP-E2E-001 | MVP-E2E-TR-001 | MVP-E2E-GAP-001 | system-e2e | automated | `scripts/run_mvp_system_e2e.sh` | `scripts/run_mvp_system_e2e.sh` | passed 2026-05-29 | `docs/reports/test_report.md` | Local PostgreSQL binaries, Java 17, Maven, Flutter, isolated temp DB | PostgreSQL boots, backend migrations complete, backend public readiness endpoint responds, and teardown runs. |
| TC-MVP-E2E-002 | MVP-SI-014 | MVP-E2E-FR-002 | MVP-E2E-SPEC-002 | AC-MVP-E2E-002 | MVP-E2E-TR-002 | MVP-E2E-GAP-002 | system-e2e | automated | `integration_test/mvp_system_smoke_test.dart`; `scripts/run_mvp_system_e2e.sh` | `scripts/run_mvp_system_e2e.sh` | passed 2026-05-29 | `docs/reports/test_report.md` | Test phone `13800139999`; `ENABLE_TEST_PHONE_LOGIN=true`; backend `/auth/login/phone` | App shows login gate, accepts agreement, opens phone login, submits test phone login and reaches onboarding without mocked API responses. |
| TC-MVP-E2E-003 | MVP-SI-014 | MVP-E2E-FR-002 | MVP-E2E-SPEC-002 | AC-MVP-E2E-002 | MVP-E2E-TR-002 | MVP-E2E-GAP-002 | system-e2e | automated | `integration_test/mvp_system_smoke_test.dart`; `scripts/run_mvp_system_e2e.sh` | `scripts/run_mvp_system_e2e.sh` | passed 2026-05-29 | `docs/reports/test_report.md` | Onboarding choices: 英语面试, 不会表达, 只能蹦关键词, 15 分钟 | App completes onboarding, saves learning route and renders home learning/scene content. |
| TC-MVP-E2E-004 | MVP-SI-014 | MVP-E2E-FR-003 | MVP-E2E-SPEC-003 | AC-MVP-E2E-003 | MVP-E2E-TR-003 | MVP-E2E-GAP-003 | traceability-audit | automated | `scripts/check_mvp_system_e2e_coverage.py`; `docs/product/increments/mvp-system-e2e-validation/test_cases.md` | `python3 scripts/check_mvp_system_e2e_coverage.py` | passed 2026-05-29 | `docs/reports/test_report.md` | Product Base AC-001..AC-013 coverage matrix | Audit fails if any Product Base AC is missing or any TC lacks required traceability/evidence fields. |
| TC-MVP-E2E-005 | MVP-SI-014 | MVP-E2E-FR-004 | MVP-E2E-SPEC-004 | AC-MVP-E2E-004 | MVP-E2E-TR-004 | MVP-E2E-GAP-004 | evidence-audit | automated | `scripts/check_mvp_system_e2e_coverage.py`; `docs/reports/test_report.md` | `python3 scripts/check_mvp_system_e2e_coverage.py` | passed 2026-05-29 | `docs/reports/test_report.md` | TC rows, commands, result statuses and evidence paths | Audit fails if script path, command, result status or evidence report is blank. |
| TC-MVP-E2E-006 | MVP-SI-014 | MVP-E2E-FR-003 | MVP-E2E-SPEC-003 | AC-MVP-E2E-003 | MVP-E2E-TR-003 | MVP-E2E-GAP-005 | system-e2e | automated | `integration_test/mvp_system_scene_catalog_test.dart`; `scripts/run_mvp_system_e2e.sh` | `scripts/run_mvp_system_e2e.sh --suite scene-catalog` | passed 2026-05-29 | `docs/reports/test_report.md` | Official scene catalog and target expression fixtures | Home scene catalog opens, selected scene can be joined, listening warmup UI path is reachable. |
| TC-MVP-E2E-007 | MVP-SI-014 | MVP-E2E-FR-003 | MVP-E2E-SPEC-003 | AC-MVP-E2E-003 | MVP-E2E-TR-003 | MVP-E2E-GAP-005 | system-e2e | automated | `integration_test/mvp_system_learning_memory_test.dart`; `scripts/run_mvp_system_e2e.sh` | `scripts/run_mvp_system_e2e.sh --suite learning-memory` | passed 2026-05-29 | `docs/reports/test_report.md` | Expression queue, favorites and local learning route fixture | Recommendation card appears, favorite persists to storage/profile/favorites page. |
| TC-MVP-E2E-008 | MVP-SI-014 | MVP-E2E-FR-003 | MVP-E2E-SPEC-003 | AC-MVP-E2E-003 | MVP-E2E-TR-003 | MVP-E2E-GAP-006 | system-e2e | automated | `integration_test/mvp_system_practice_feedback_test.dart`; `scripts/run_mvp_system_e2e.sh` | `scripts/run_mvp_system_e2e.sh --suite practice-feedback` | passed 2026-05-29 | `docs/reports/test_report.md` | Deterministic practice/feedback provider fixture | Practice UI opens; backend practice turn returns deterministic coach feedback, evidence candidates and recap fields. |
| TC-MVP-E2E-009 | MVP-SI-014 | MVP-E2E-FR-003 | MVP-E2E-SPEC-003 | AC-MVP-E2E-003 | MVP-E2E-TR-003 | MVP-E2E-GAP-007 | system-e2e | automated | `integration_test/mvp_system_profile_settings_test.dart`; `scripts/run_mvp_system_e2e.sh` | `scripts/run_mvp_system_e2e.sh --suite profile-settings` | passed 2026-05-29 | `docs/reports/test_report.md` | Authenticated user profile/session fixture | Profile/settings changes persist, logout clears session, relogin bypasses onboarding and keeps nickname. |
| TC-MVP-E2E-010 | MVP-SI-014 | MVP-E2E-FR-003 | MVP-E2E-SPEC-003 | AC-MVP-E2E-003 | MVP-E2E-TR-003 | MVP-E2E-GAP-008 | system-e2e/manual-external | automated / accepted-exception | `integration_test/mvp_system_membership_boundary_test.dart`; `docs/release/release_checklist.md` | `scripts/run_mvp_system_e2e.sh --suite membership-boundary`; `N/A - provider payment manual gate` | passed 2026-05-29 / accepted-exception | `docs/reports/test_report.md`; `docs/release/release_checklist.md` | Subscription plans, placeholder screens, payment provider exception | Local plans/restore/subscribe boundary UI is tested; real payment provider remains external/manual. |

## Depth Rules
- A system E2E TC must cross at least Flutter UI + HTTP API + PostgreSQL, unless it is explicitly a traceability/evidence audit or accepted external exception.
- Backend-only, widget-only and contract-only tests can support evidence but cannot replace TC-MVP-E2E-001 to TC-MVP-E2E-003.
- Any planned TC promoted to automated must keep the same TC ID and update only automation/result/evidence fields.
- 100% coverage in this file means Product Base AC coverage mapping is complete and current local-system TCs have execution evidence; it does not mean code line coverage is 100% or that the product has no defects.

## Handoff Notes
- TC-MVP-E2E-001 to TC-MVP-E2E-010 are stable and must not be reused for different behavior.
- TC-MVP-E2E-001 to TC-MVP-E2E-010 are the current required local MVP system E2E gate and passed on 2026-05-29, with TC-MVP-E2E-010 retaining the real payment provider external/manual exception.
