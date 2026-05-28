# MVP Backend Foundation Auth Test Cases

## 状态
Draft - 实现前测试用例库；用于关闭 `mvp-backend-foundation-auth` 的 AC-to-TC implementation gate，不代表测试脚本已实现或已通过。

## Owner
Test Case Development Agent

## Source
- `docs/product/increments/mvp-backend-foundation-auth/definition.md`
- `docs/product/increments/mvp-backend-foundation-auth/requirements.md`
- `docs/product/increments/mvp-backend-foundation-auth/spec.md`
- `docs/product/increments/mvp-backend-foundation-auth/acceptance.md`
- `docs/product/increments/mvp-backend-foundation-auth/traceability.md`

## Coverage Summary
| AC | Traceability Row | Test Case IDs | Gate status |
| --- | --- | --- | --- |
| AC-MVP-BE-001 | MVP-BE-TR-001 | TC-MVP-BE-001, TC-MVP-BE-002, TC-MVP-BE-003 | planned |
| AC-MVP-BE-002 | MVP-BE-TR-002 | TC-MVP-BE-004, TC-MVP-BE-005, TC-MVP-BE-006 | planned |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-001 | MVP-SI-001 | MVP-BE-FR-001 | MVP-BE-SPEC-001 | AC-MVP-BE-001 | MVP-BE-TR-001 | MVP-BE-GAP-001 | integration | planned | `backend/src/test/java/com/speakeasy/FoundationMigrationTest.java`; `backend/src/test/java/com/speakeasy/PostgresFoundationMigrationTest.java` | `mvn.cmd -q "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | H2 migration fixture; PostgreSQL Testcontainers fixture | Flyway 可重复执行，Product Base 与 MVP backend 基础表、索引、约束存在，重复启动不破坏 schema。 |
| TC-MVP-BE-002 | MVP-SI-001 | MVP-BE-FR-001 | MVP-BE-SPEC-001 | AC-MVP-BE-001 | MVP-BE-TR-001 | MVP-BE-GAP-001 | contract | planned | `backend/src/test/java/com/speakeasy/FoundationResponseContractTest.java` | `mvn.cmd -q "-Dtest=FoundationResponseContractTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Representative controller response fixture | Controller 不返回 raw persistence shape；成功响应使用 OpenAPI 对齐 DTO / response envelope。 |
| TC-MVP-BE-003 | MVP-SI-001 | MVP-BE-FR-001 | MVP-BE-SPEC-001 | AC-MVP-BE-001 | MVP-BE-TR-001 | MVP-BE-GAP-001 | integration | planned | `backend/src/test/java/com/speakeasy/FoundationErrorContractTest.java` | `mvn.cmd -q "-Dtest=FoundationErrorContractTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | validation、unauthenticated、forbidden、internal-error request fixtures | 错误响应包含稳定错误码和可读消息，不暴露 stack trace；PostgreSQL-compatible 测试环境可验证。 |
| TC-MVP-BE-004 | MVP-SI-002 | MVP-BE-FR-002 | MVP-BE-SPEC-002 | AC-MVP-BE-002 | MVP-BE-TR-002 | MVP-BE-GAP-002 | integration | planned | `backend/src/test/java/com/speakeasy/AuthControllerTest.java`; `backend/src/test/java/com/speakeasy/AuthServiceTest.java` | `mvn.cmd -q "-Dtest=AuthControllerTest,AuthServiceTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | phone / Apple / WeChat test-substitute login fixtures | 有效登录创建或解析用户并返回 access token 与 refresh token；current user/profile 返回用户 ID、profile 状态和 Product Base 门禁状态。 |
| TC-MVP-BE-005 | MVP-SI-002 | MVP-BE-FR-002 | MVP-BE-SPEC-002 | AC-MVP-BE-002 | MVP-BE-TR-002 | MVP-BE-GAP-002 | integration | planned | `backend/src/test/java/com/speakeasy/AuthSessionLifecycleTest.java` | `mvn.cmd -q "-Dtest=AuthSessionLifecycleTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | valid、expired、revoked refresh/access token fixtures | refresh 返回新 token；无效或过期 refresh token 返回确定性错误；logout 后同一会话 token 不再通过受保护请求。 |
| TC-MVP-BE-006 | MVP-SI-002 | MVP-BE-FR-002 | MVP-BE-SPEC-002 | AC-MVP-BE-002 | MVP-BE-TR-002 | MVP-BE-GAP-002 | contract | planned | `scripts/check_openapi_dart_drift.py`; `test/services/auth_service_test.dart` | `npm.cmd run check:api-contract`; `flutter test test/services/auth_service_test.dart` | planned | `docs/reports/test_report.md`（执行后更新） | OpenAPI auth/current-user contract; Flutter auth service fixture | Flutter auth/current-user 调用不使用旧 endpoint 或旧字段；发现 drift 时 contract gate 或 Flutter service test 失败。 |

## Handoff Notes
- 本库只建立测试设计和 AC-to-TC 映射；Backend / Frontend / QA 仍需在后续执行中实现脚本并更新执行证据。
- TC-MVP-BE-001 到 TC-MVP-BE-006 一经发布不得重排或复用。
