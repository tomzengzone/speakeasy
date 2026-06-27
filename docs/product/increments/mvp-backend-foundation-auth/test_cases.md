# MVP Backend Foundation Auth Test Cases

## 状态
Executed - TC-MVP-BE-001 到 TC-MVP-BE-006 均已自动化并于 2026-05-29 通过；TC-MVP-BE-004 于 2026-06-25 补齐并重新验证 Apple/WeChat test-substitute endpoint 证据；用于关闭 `mvp-backend-foundation-auth` 的 AC-to-TC implementation gate。

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
| AC-MVP-BE-001 | MVP-BE-TR-001 | TC-MVP-BE-001, TC-MVP-BE-002, TC-MVP-BE-003 | passed 2026-05-29 |
| AC-MVP-BE-002 | MVP-BE-TR-002 | TC-MVP-BE-004, TC-MVP-BE-005, TC-MVP-BE-006 | passed 2026-05-29; TC-MVP-BE-004 social endpoint evidence revalidated 2026-06-25 |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-001 | MVP-SI-001 | MVP-BE-FR-001 | MVP-BE-SPEC-001 | AC-MVP-BE-001 | MVP-BE-TR-001 | MVP-BE-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/FoundationMigrationTest.java`; `backend/src/test/java/com/speakeasy/PostgresFoundationMigrationTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test` | passed 2026-05-29 | `docs/reports/test_report.md` | H2 migration fixture; PostgreSQL-compatible local/Postgres fixture | Flyway 可重复执行，Product Base 与 MVP backend 基础表、索引、约束存在，重复启动不破坏 schema。 |
| TC-MVP-BE-002 | MVP-SI-001 | MVP-BE-FR-001 | MVP-BE-SPEC-001 | AC-MVP-BE-001 | MVP-BE-TR-001 | MVP-BE-GAP-001 | contract | automated | `backend/src/test/java/com/speakeasy/FoundationResponseContractTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test` | passed 2026-05-29 | `docs/reports/test_report.md` | Representative controller response fixture | Controller 不返回 raw persistence shape；成功响应使用 OpenAPI 对齐 DTO / response envelope。 |
| TC-MVP-BE-003 | MVP-SI-001 | MVP-BE-FR-001 | MVP-BE-SPEC-001 | AC-MVP-BE-001 | MVP-BE-TR-001 | MVP-BE-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/FoundationErrorContractTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test` | passed 2026-05-29 | `docs/reports/test_report.md` | validation、malformed JSON、unauthenticated request fixtures | 错误响应包含稳定错误码和可读消息，不暴露 stack trace；PostgreSQL-compatible 测试环境可验证。 |
| TC-MVP-BE-004 | MVP-SI-002 | MVP-BE-FR-002 | MVP-BE-SPEC-002 | AC-MVP-BE-002 | MVP-BE-TR-002 | MVP-BE-GAP-002 | integration | automated | `backend/src/test/java/com/speakeasy/AuthControllerTest.java`; `backend/src/test/java/com/speakeasy/AuthServiceTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AuthControllerTest,AuthServiceTest test` | passed 2026-06-25 | `docs/reports/test_report.md` | phone login fixture; Apple/WeChat test-substitute provider token fixtures; invalid social request fixtures | Phone login、Apple endpoint、WeChat endpoint 均创建或解析用户并返回 access token 与 refresh token；Apple/WeChat 使用同一 provider token 时按 provider namespace 隔离；同 provider 同 token 重复登录解析同一用户；current user/profile 返回用户 ID、profile 状态和 Product Base 门禁状态；invalid social schema/token/terms 返回 `SCHEMA_VALIDATION_FAILED`。 |
| TC-MVP-BE-005 | MVP-SI-002 | MVP-BE-FR-002 | MVP-BE-SPEC-002 | AC-MVP-BE-002 | MVP-BE-TR-002 | MVP-BE-GAP-002 | integration | automated | `backend/src/test/java/com/speakeasy/AuthSessionLifecycleTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository "-Dtest=FoundationMigrationTest,PostgresFoundationMigrationTest,FoundationResponseContractTest,FoundationErrorContractTest,AuthControllerTest,AuthServiceTest,AuthSessionLifecycleTest" test` | passed 2026-05-29 | `docs/reports/test_report.md` | valid、expired、revoked refresh/access token fixtures | refresh 返回新 token；无效或过期 refresh token 返回确定性错误；logout 后同一会话 token 不再通过受保护请求。 |
| TC-MVP-BE-006 | MVP-SI-002 | MVP-BE-FR-002 | MVP-BE-SPEC-002 | AC-MVP-BE-002 | MVP-BE-TR-002 | MVP-BE-GAP-002 | contract | automated | `scripts/check_openapi_dart_drift.py`; `test/services/auth_service_test.dart`; `docs/architecture/openapi/dart-client-drift-manifest.json` | `npm run check:api-contract`; `flutter test test/services/auth_service_test.dart` | passed 2026-05-29 | `docs/reports/test_report.md` | OpenAPI auth/current-user contract; Flutter auth service fixture | Flutter auth/current-user 调用不使用旧 endpoint 或旧字段；发现 drift 时 contract gate 或 Flutter service test 失败。 |

## Handoff Notes
- TC-MVP-BE-001 到 TC-MVP-BE-006 已在本 increment 执行并通过，执行证据写入 `docs/reports/test_report.md`，追溯证据写入 `traceability.md`。
- 2026-06-25 针对 TC-MVP-BE-004 补齐 Apple/WeChat test-substitute endpoint 与 `AuthService.loginSocial` 证据；该证据不代表真实 Apple identity token 或 WeChat code/openid/unionid 生产校验已实现。
- TC-MVP-BE-001 到 TC-MVP-BE-006 一经发布不得重排或复用。
