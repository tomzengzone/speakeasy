# MVP Backend Membership Boundary Test Cases

## 状态
Executed - `mvp-backend-membership-boundary` 的 AC-to-TC implementation gate 已通过。

## Owner
Test Case Development Agent

## Source
- `docs/product/increments/mvp-backend-membership-boundary/definition.md`
- `docs/product/increments/mvp-backend-membership-boundary/requirements.md`
- `docs/product/increments/mvp-backend-membership-boundary/spec.md`
- `docs/product/increments/mvp-backend-membership-boundary/acceptance.md`
- `docs/product/increments/mvp-backend-membership-boundary/traceability.md`

## Coverage Summary
| AC | Traceability Row | Test Case IDs | Gate status |
| --- | --- | --- | --- |
| AC-MVP-BE-011 | MVP-BE-TR-011 | TC-MVP-BE-033, TC-MVP-BE-034, TC-MVP-BE-035, TC-MVP-BE-036 | automated / passed |
| AC-MVP-BE-012 | MVP-BE-TR-012 | TC-MVP-BE-037, TC-MVP-BE-038 | automated / passed |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-033 | MVP-SI-011 | MVP-BE-FR-011 | MVP-BE-SPEC-011 | AC-MVP-BE-011 | MVP-BE-TR-011 | MVP-BE-GAP-008 | integration | automated | `backend/src/test/java/com/speakeasy/AccountDeletionControllerTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` | passed | `docs/reports/test_report.md` | Authenticated account deletion request fixture | 注销请求同步完成 deletion job，返回 `completed`、`completed_at` 和可理解状态。 |
| TC-MVP-BE-034 | MVP-SI-011 | MVP-BE-FR-011 | MVP-BE-SPEC-011 | AC-MVP-BE-011 | MVP-BE-TR-011 | MVP-BE-GAP-008 | integration | automated | `backend/src/test/java/com/speakeasy/AccountDeletionSessionInvalidationTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` | passed | `docs/reports/test_report.md` | Active token and deleted-user fixture | 注销完成后，同一用户 access token 和 refresh token 均失效。 |
| TC-MVP-BE-035 | MVP-SI-011 | MVP-BE-FR-011 | MVP-BE-SPEC-011 | AC-MVP-BE-011 | MVP-BE-TR-011 | MVP-BE-GAP-008 | integration | automated | `backend/src/test/java/com/speakeasy/AccountDeletionLearningDataTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` | passed | `docs/reports/test_report.md` | User with route, practice, learning evidence, favorites and history fixtures | Product Base 学习数据被清理，账号标记为 deleted，审计事件保留脱敏证据。 |
| TC-MVP-BE-036 | MVP-SI-011 | MVP-BE-FR-011 | MVP-BE-SPEC-011 | AC-MVP-BE-011 | MVP-BE-TR-011 | MVP-BE-GAP-008 | integration | automated | `backend/src/test/java/com/speakeasy/AccountDeletionFailureAuditTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` | passed | `docs/reports/test_report.md` | Recoverable deletion failure fixture | 删除过程失败状态可查询 `failure_reason`，并保留审计证据。 |
| TC-MVP-BE-037 | MVP-SI-012 | MVP-BE-FR-012 | MVP-BE-SPEC-012 | AC-MVP-BE-012 | MVP-BE-TR-012 | MVP-BE-GAP-009 | integration | automated | `backend/src/test/java/com/speakeasy/MvpMembershipBoundaryControllerTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` | passed | `docs/reports/test_report.md` | Membership state, Android subscription request and restore fixtures | 返回 MVP 边界状态，不伪造完整商业权益；Android 购买或恢复返回平台未接入限制状态。 |
| TC-MVP-BE-038 | MVP-SI-012 | MVP-BE-FR-012 | MVP-BE-SPEC-012 | AC-MVP-BE-012 | MVP-BE-TR-012 | MVP-BE-GAP-009 | integration | automated | `backend/src/test/java/com/speakeasy/MvpReportPlaceholderControllerTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=AccountDeletionControllerTest,AccountDeletionSessionInvalidationTest,AccountDeletionLearningDataTest,AccountDeletionFailureAuditTest,MvpMembershipBoundaryControllerTest,MvpReportPlaceholderControllerTest" test` | passed | `docs/reports/test_report.md` | Empty report, offline content and achievements placeholder fixtures | 学习报告、离线内容和成就返回 empty / placeholder；本 increment 不标记真实支付、权益 gating 或商业风控完成。 |

## Handoff Notes
- TC-MVP-BE-033 到 TC-MVP-BE-038 一经发布不得重排或复用。
- 本 increment 的 generated Dart client、完整商业订阅、支付校验、权益 gating 和 release readiness 仍归后续明确 increment；本测试库只证明 MVP membership/boundary scope。
