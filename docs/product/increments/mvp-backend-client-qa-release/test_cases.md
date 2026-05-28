# MVP Backend Client QA Release Test Cases

## 状态
Draft - 实现前测试用例库；用于关闭 `mvp-backend-client-qa-release` 的 AC-to-TC implementation gate，不代表测试脚本已实现或已通过。

## Owner
Test Case Development Agent

## Source
- `docs/product/increments/mvp-backend-client-qa-release/definition.md`
- `docs/product/increments/mvp-backend-client-qa-release/requirements.md`
- `docs/product/increments/mvp-backend-client-qa-release/spec.md`
- `docs/product/increments/mvp-backend-client-qa-release/acceptance.md`
- `docs/product/increments/mvp-backend-client-qa-release/traceability.md`

## Coverage Summary
| AC | Traceability Row | Test Case IDs | Gate status |
| --- | --- | --- | --- |
| AC-MVP-BE-013 | MVP-BE-TR-013 | TC-MVP-BE-039, TC-MVP-BE-040, TC-MVP-BE-041, TC-MVP-BE-042 | planned |
| AC-MVP-BE-014 | MVP-BE-TR-014 | TC-MVP-BE-043, TC-MVP-BE-044, TC-MVP-BE-045, TC-MVP-BE-046 | planned |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-039 | MVP-SI-013 | MVP-BE-FR-013 | MVP-BE-SPEC-013 | AC-MVP-BE-013 | MVP-BE-TR-013 | MVP-BE-GAP-010 | contract | planned | `scripts/check_openapi_contract.py`; `docs/architecture/openapi/speakeasy-api.yaml` | `npm.cmd run check:api-contract` | planned | `docs/reports/test_report.md`（执行后更新） | OpenAPI active endpoint and traceability fixtures | OpenAPI lint / contract gate 在缺少 traceability、schema 或 response contract 时失败。 |
| TC-MVP-BE-040 | MVP-SI-013 | MVP-BE-FR-013 | MVP-BE-SPEC-013 | AC-MVP-BE-013 | MVP-BE-TR-013 | MVP-BE-GAP-010 | contract | planned | `scripts/check_openapi_dart_drift.py`; `docs/architecture/openapi/dart-client-drift-manifest.json` | `npm.cmd run check:api-contract` | planned | `docs/reports/test_report.md`（执行后更新） | Generated or typed Dart client drift manifest | generated Dart client 或等效 typed client 与 OpenAPI 对齐；存在 drift 时 gate 失败或记录明确例外。 |
| TC-MVP-BE-041 | MVP-SI-013 | MVP-BE-FR-013 | MVP-BE-SPEC-013 | AC-MVP-BE-013 | MVP-BE-TR-013 | MVP-BE-GAP-010 | widget | planned | `test/services/auth_service_test.dart`; `test/application/scene_voice_session_lifecycle_coordinator_test.dart`; `test/application/home_cards_coordinator_test.dart` | `flutter test test/services/auth_service_test.dart test/application/scene_voice_session_lifecycle_coordinator_test.dart test/application/home_cards_coordinator_test.dart` | planned | `docs/reports/test_report.md`（执行后更新） | Flutter active MVP backend flow fixtures | Flutter active flows 不继续使用与 OpenAPI 不一致的旧 endpoint 或旧字段。 |
| TC-MVP-BE-042 | MVP-SI-013 | MVP-BE-FR-013 | MVP-BE-SPEC-013 | AC-MVP-BE-013 | MVP-BE-TR-013 | MVP-BE-GAP-010 | manual | manual-verification | `docs/reports/test_report.md` | `N/A - 外部服务或平台限制场景由 QA 手工记录` | planned | `docs/reports/test_report.md`（执行后更新） | Provider/platform-limited endpoint exception fixture | 无法自动验证的 endpoint 必须记录例外、原因、owner 和人工验收方式，不允许静默通过。 |
| TC-MVP-BE-043 | MVP-SI-014 | MVP-BE-FR-014 | MVP-BE-SPEC-014 | AC-MVP-BE-014 | MVP-BE-TR-014 | MVP-BE-GAP-011 | release-check | planned | `docs/product/stages/mvp-backend-foundation.md`; `docs/product/increments/*/traceability.md` | `rg -n "MVP-SI-" docs/product/stages/mvp-backend-foundation.md docs/product/increments/mvp-backend-*` | planned | `docs/reports/test_report.md`（执行后更新） | Stage and increment traceability files | MVP-SI-001 到 MVP-SI-014 每项都有 code evidence、test evidence、release evidence 或明确例外。 |
| TC-MVP-BE-044 | MVP-SI-014 | MVP-BE-FR-014 | MVP-BE-SPEC-014 | AC-MVP-BE-014 | MVP-BE-TR-014 | MVP-BE-GAP-011 | integration | planned | `backend/src/test/java/com/speakeasy/` | `mvn.cmd test` | planned | `docs/reports/test_report.md`（执行后更新） | Backend unit/integration suite | 后端实现完成后运行并记录 backend tests 和 OpenAPI contract gate 结果。 |
| TC-MVP-BE-045 | MVP-SI-014 | MVP-BE-FR-014 | MVP-BE-SPEC-014 | AC-MVP-BE-014 | MVP-BE-TR-014 | MVP-BE-GAP-011 | widget | planned | `test/` | `flutter test` | planned | `docs/reports/test_report.md`（执行后更新） | Flutter active MVP flows | Flutter 集成完成后运行并记录相关 Flutter tests 或人工验收结果。 |
| TC-MVP-BE-046 | MVP-SI-014 | MVP-BE-FR-014 | MVP-BE-SPEC-014 | AC-MVP-BE-014 | MVP-BE-TR-014 | MVP-BE-GAP-011 | release-check | planned | `docs/release/release_checklist.md`; `docs/reports/quality_report.md` | `python scripts\\project_agent_runner.py validate` | planned | `docs/reports/quality_report.md`（审查后更新） | Release checklist and Product Object Governance Check packet | 未关闭 gap 时 release evidence 标记为 blocked、conditional 或 accepted exception；Product Object Governance Check 确认 stage/increment/FR/spec/AC/traceability row 不断链。 |

## Handoff Notes
- 本库只建立测试设计和 AC-to-TC 映射；QA / DevOps / Product Object Governance Check 仍需在后续执行中更新真实执行证据。
- TC-MVP-BE-039 到 TC-MVP-BE-046 一经发布不得重排或复用。
