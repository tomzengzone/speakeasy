# MVP Backend Membership Boundary Test Cases

## 状态
Draft - 实现前测试用例库；用于关闭 `mvp-backend-membership-boundary` 的 AC-to-TC implementation gate，不代表测试脚本已实现或已通过。

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
| AC-MVP-BE-011 | MVP-BE-TR-011 | TC-MVP-BE-033, TC-MVP-BE-034, TC-MVP-BE-035, TC-MVP-BE-036 | planned |
| AC-MVP-BE-012 | MVP-BE-TR-012 | TC-MVP-BE-037, TC-MVP-BE-038 | planned |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-033 | MVP-SI-011 | MVP-BE-FR-011 | MVP-BE-SPEC-011 | AC-MVP-BE-011 | MVP-BE-TR-011 | MVP-BE-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/AccountDeletionControllerTest.java` | `mvn.cmd -q "-Dtest=AccountDeletionControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Authenticated account deletion request fixture | 注销请求创建 deletion job 或完成同步删除，并返回可理解状态。 |
| TC-MVP-BE-034 | MVP-SI-011 | MVP-BE-FR-011 | MVP-BE-SPEC-011 | AC-MVP-BE-011 | MVP-BE-TR-011 | MVP-BE-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/AccountDeletionSessionInvalidationTest.java` | `mvn.cmd -q "-Dtest=AccountDeletionSessionInvalidationTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Active token and deleted-user fixture | 注销完成后，同一用户 session/token 请求受保护资源失败。 |
| TC-MVP-BE-035 | MVP-SI-011 | MVP-BE-FR-011 | MVP-BE-SPEC-011 | AC-MVP-BE-011 | MVP-BE-TR-011 | MVP-BE-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/AccountDeletionLearningDataTest.java` | `mvn.cmd -q "-Dtest=AccountDeletionLearningDataTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | User with route, practice, learning evidence, favorites and history fixtures | Product Base 学习数据被删除或匿名化；任何不能覆盖的数据必须由 traceability 记录明确例外。 |
| TC-MVP-BE-036 | MVP-SI-011 | MVP-BE-FR-011 | MVP-BE-SPEC-011 | AC-MVP-BE-011 | MVP-BE-TR-011 | MVP-BE-GAP-008 | integration | planned | `backend/src/test/java/com/speakeasy/AccountDeletionFailureAuditTest.java` | `mvn.cmd -q "-Dtest=AccountDeletionFailureAuditTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Recoverable deletion failure fixture | 删除过程失败时返回可恢复或可解释错误，并保留审计证据。 |
| TC-MVP-BE-037 | MVP-SI-012 | MVP-BE-FR-012 | MVP-BE-SPEC-012 | AC-MVP-BE-012 | MVP-BE-TR-012 | MVP-BE-GAP-009 | integration | planned | `backend/src/test/java/com/speakeasy/MvpMembershipBoundaryControllerTest.java` | `mvn.cmd -q "-Dtest=MvpMembershipBoundaryControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Membership state, Android subscription request and restore fixtures | 返回 MVP 边界状态，不伪造完整商业权益；Android 购买或恢复返回平台未接入限制状态。 |
| TC-MVP-BE-038 | MVP-SI-012 | MVP-BE-FR-012 | MVP-BE-SPEC-012 | AC-MVP-BE-012 | MVP-BE-TR-012 | MVP-BE-GAP-009 | integration | planned | `backend/src/test/java/com/speakeasy/MvpReportPlaceholderControllerTest.java` | `mvn.cmd -q "-Dtest=MvpReportPlaceholderControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Empty report, offline content and achievements placeholder fixtures | 学习报告、离线内容或成就未实现时返回 empty / placeholder；本 increment 不标记真实支付、权益 gating 或商业风控完成。 |

## Handoff Notes
- 本库只建立测试设计和 AC-to-TC 映射；Backend / Security / Frontend / QA 仍需在后续执行中实现脚本并更新执行证据。
- TC-MVP-BE-033 到 TC-MVP-BE-038 一经发布不得重排或复用。
