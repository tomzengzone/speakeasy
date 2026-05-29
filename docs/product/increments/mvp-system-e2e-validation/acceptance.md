# MVP System E2E Validation Acceptance

## 状态
Validated for local MVP system E2E gate - system E2E acceptance criteria。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-29 | Draft | 建立系统 E2E acceptance criteria。 |
| v1.0 | 2026-05-29 | Validated | AC-MVP-E2E-001 到 AC-MVP-E2E-004 已由 TC-MVP-E2E-001 到 TC-MVP-E2E-005 验证通过。 |
| v1.1 | 2026-05-29 | Validated | Product Base AC-001 到 AC-013 已由 TC-MVP-E2E-001 到 TC-MVP-E2E-010 覆盖；真实支付 provider 保留外部门禁。 |

## Owner
Acceptance Criteria Generate Skill

## Acceptance Criteria
| AC ID | Requirement ID | Spec ID | Acceptance Criterion | Verification |
| --- | --- | --- | --- | --- |
| AC-MVP-E2E-001 | MVP-E2E-FR-001 | MVP-E2E-SPEC-001 | Given a developer machine with PostgreSQL binaries, Java 17, Maven and Flutter, when `scripts/run_mvp_system_e2e.sh` runs, then it starts isolated PostgreSQL and backend processes, points the app at `/v1`, and exits non-zero on boot or migration failure. | `TC-MVP-E2E-001` |
| AC-MVP-E2E-002 | MVP-E2E-FR-002 | MVP-E2E-SPEC-002 | Given the app starts without a stored session, when the system smoke test runs, then Flutter UI reaches login, uses the test phone login path, completes onboarding and reaches home without mocked backend responses. | `TC-MVP-E2E-002`, `TC-MVP-E2E-003` |
| AC-MVP-E2E-003 | MVP-E2E-FR-003 | MVP-E2E-SPEC-003 | Given the Product Base AC list, when the coverage audit runs, then AC-001 through AC-013 each map to an executed automated system TC or an accepted/manual external exception. | `TC-MVP-E2E-004`, `TC-MVP-E2E-006`..`TC-MVP-E2E-010` |
| AC-MVP-E2E-004 | MVP-E2E-FR-004 | MVP-E2E-SPEC-004 | Given a system test execution, when QA reviews evidence, then every TC has script path, command, result, evidence report and failure category if not passed. | `TC-MVP-E2E-005` |

## Product Base Coverage Rule
Coverage is complete only when all Product Base acceptance criteria are represented:

- AC-001 to AC-005 must have at least one executable local system TC because they are core onboarding/home behavior.
- AC-006 to AC-010 must have executable system TC coverage for listening, recommendation, practice and learning evidence because they are high defect-discovery paths.
- AC-011 must have executable system TC coverage for profile/session state.
- AC-012 and AC-013 may use accepted exceptions only for true external/platform restrictions; placeholder UI and boundary copy remain testable.

## Rejection Criteria
- Any TC row missing script path, command, result or evidence field.
- Any Product Base AC omitted from the system coverage matrix.
- Any backend-only or widget-only test represented as full system E2E without a real backend and real PostgreSQL.
- Any local system script requiring Docker as the only path.
