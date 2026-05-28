# MVP Backend Membership Boundary Traceability

## 状态
Validated - membership/boundary traceability matrix 已通过实现、测试和报告证据闭环。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 membership/boundary traceability rows。 |
| v1.0 | 2026-05-29 | Validated | 关闭账号删除、学习数据处理、MVP 会员/报告/占位边界 gaps，并补齐 AC-to-TC evidence。 |

## Traceability Chain
`docs/product/roadmap.md`
-> `docs/product/stages/mvp-backend-foundation.md`
-> `docs/product/increments/mvp-backend-membership-boundary/definition.md`
-> `requirements.md`
-> `spec.md`
-> `acceptance.md`
-> `traceability.md`

## Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| MVP-BE-TR-011 | MVP-SI-011 | `mvp-backend-membership-boundary` | MVP-BE-FR-011 account deletion and data processing | MVP-BE-SPEC-011 | AC-MVP-BE-011 | `docs/architecture/openapi/speakeasy-api.yaml` for `DELETE /user/me`, `GET /user/deletion-status`, `AccountDeletionJobResponse.failure_reason`, shared errors and idempotency headers | `backend/src/main/java/com/speakeasy/ops/AccountDeletionService.java`; `backend/src/main/java/com/speakeasy/api/AuthController.java`; `UserAccount.markDeleted`; deletion job/audit repository updates | TC-MVP-BE-033 script `backend/src/test/java/com/speakeasy/AccountDeletionControllerTest.java`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-034 script `backend/src/test/java/com/speakeasy/AccountDeletionSessionInvalidationTest.java`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-035 script `backend/src/test/java/com/speakeasy/AccountDeletionLearningDataTest.java`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-036 script `backend/src/test/java/com/speakeasy/AccountDeletionFailureAuditTest.java`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test`, result `passed`, evidence `docs/reports/test_report.md` | N/A for this non-release increment; release aggregation deferred to `mvp-backend-client-qa-release` | Done | MVP-BE-GAP-008 closed 2026-05-29 |
| MVP-BE-TR-012 | MVP-SI-012 | `mvp-backend-membership-boundary` | MVP-BE-FR-012 MVP membership/report boundary | MVP-BE-SPEC-012 | AC-MVP-BE-012 | `docs/architecture/openapi/speakeasy-api.yaml` for `/membership/boundary`, `/membership/android/purchase`, `/membership/android/restore`, `/learning/report/summary`, `/offline-content/status`, `/achievements/status` | `backend/src/main/java/com/speakeasy/api/MembershipBoundaryController.java`; entitlement read boundary remains existing foundation-only state | TC-MVP-BE-037 script `backend/src/test/java/com/speakeasy/MvpMembershipBoundaryControllerTest.java`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test`, result `passed`, evidence `docs/reports/test_report.md`; TC-MVP-BE-038 script `backend/src/test/java/com/speakeasy/MvpReportPlaceholderControllerTest.java`, command `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test`, result `passed`, evidence `docs/reports/test_report.md`; contract script `scripts/check_openapi_contract.py`, command `npm run check:api-contract`, result `passed`, OpenAPI hash `506282ac758a37269df95e12ca6752de9c201eb162fd4cc0e227b13c287ab082`, evidence `docs/reports/test_report.md` | N/A for this non-release increment; release aggregation deferred to `mvp-backend-client-qa-release` | Done | MVP-BE-GAP-009 closed 2026-05-29 |

## Gap Register
| Gap ID | Gap | Affected rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| MVP-BE-GAP-008 | 账号删除已有 foundation，但缺 Product Base 学习数据删除/匿名化完整执行和验收证据。 | MVP-BE-TR-011 | Backend + Security + QA | Closed 2026-05-29 |
| MVP-BE-GAP-009 | 会员/报告/占位页只需 MVP 边界事实，不应误升级为完整商业订阅；需防止与 P0 商业化 scope 混淆。 | MVP-BE-TR-012 | Product Manager + Backend + Frontend | Closed 2026-05-29 |

## Completion Rule
本 increment 只有在 MVP-BE-TR-011 和 MVP-BE-TR-012 的 code/test evidence 更新、gaps 关闭或明确例外记录后，才能标记为 Done。
