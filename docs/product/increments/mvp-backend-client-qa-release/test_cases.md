# MVP Backend Client QA Release Test Cases

## 状态
Executed - `mvp-backend-client-qa-release` 的 AC-to-TC、client drift、QA 和 release evidence gate 已通过。

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
| AC-MVP-BE-013 | MVP-BE-TR-013 | TC-MVP-BE-039, TC-MVP-BE-040, TC-MVP-BE-041, TC-MVP-BE-042 | automated / accepted exception / passed |
| AC-MVP-BE-014 | MVP-BE-TR-014 | TC-MVP-BE-043, TC-MVP-BE-044, TC-MVP-BE-045, TC-MVP-BE-046 | automated / passed |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-039 | MVP-SI-013 | MVP-BE-FR-013 | MVP-BE-SPEC-013 | AC-MVP-BE-013 | MVP-BE-TR-013 | MVP-BE-GAP-010 | contract | automated | `scripts/check_openapi_contract.py`; `docs/architecture/openapi/speakeasy-api.yaml` | `npm run check:api-contract` | passed | `docs/reports/test_report.md` | OpenAPI active endpoint and traceability fixtures | OpenAPI lint / contract gate 通过；缺少 traceability、schema 或 response contract 时 gate 会失败。 |
| TC-MVP-BE-040 | MVP-SI-013 | MVP-BE-FR-013 | MVP-BE-SPEC-013 | AC-MVP-BE-013 | MVP-BE-TR-013 | MVP-BE-GAP-010 | contract | automated | `scripts/check_openapi_dart_drift.py`; `docs/architecture/openapi/dart-client-drift-manifest.json`; `lib/generated/api/` | `npm run check:api-contract` | passed | `docs/reports/test_report.md` | Generated Dart OpenAPI boundary and handwritten exception manifest | generated Dart boundary 与 OpenAPI hash 对齐；手写 ApiClient 路径必须使用 generated constants 或列入明确例外。 |
| TC-MVP-BE-041 | MVP-SI-013 | MVP-BE-FR-013 | MVP-BE-SPEC-013 | AC-MVP-BE-013 | MVP-BE-TR-013 | MVP-BE-GAP-010 | widget | automated | `test/services/api_client_contract_test.dart`; `test/services/auth_service_test.dart`; `test/application/scene_voice_session_lifecycle_coordinator_test.dart`; `test/application/home_cards_coordinator_test.dart` | `flutter test test/services/api_client_contract_test.dart test/services/auth_service_test.dart test/application/scene_voice_session_lifecycle_coordinator_test.dart test/application/home_cards_coordinator_test.dart` | passed | `docs/reports/test_report.md` | Flutter active MVP backend flow fixtures | Flutter active auth/user/AI boundary 不继续使用已迁移的旧 endpoint 或旧字段；legacy endpoints 有 manifest 例外。 |
| TC-MVP-BE-042 | MVP-SI-013 | MVP-BE-FR-013 | MVP-BE-SPEC-013 | AC-MVP-BE-013 | MVP-BE-TR-013 | MVP-BE-GAP-010 | manual | accepted-exception | `docs/architecture/openapi/dart-client-drift-manifest.json`; `docs/reports/test_report.md` | `N/A - documented exception review` | accepted exception | `docs/reports/test_report.md` | Provider/platform-limited endpoint exception fixture | payment provider、legacy freeform scene、role memory、stats 等暂未接入 OpenAPI 的手写路径已逐项列入 manifest，并由 drift gate 检查未用或未登记例外。 |
| TC-MVP-BE-043 | MVP-SI-014 | MVP-BE-FR-014 | MVP-BE-SPEC-014 | AC-MVP-BE-014 | MVP-BE-TR-014 | MVP-BE-GAP-011 | release-check | automated | `docs/product/stages/mvp-backend-foundation.md`; `docs/product/increments/*/traceability.md` | `rg -n "MVP-SI-" docs/product/stages/mvp-backend-foundation.md docs/product/increments/mvp-backend-*` | passed | `docs/reports/test_report.md` | Stage and increment traceability files | MVP-SI-001 到 MVP-SI-014 每项都有 code evidence、test evidence、release evidence 或明确例外。 |
| TC-MVP-BE-044 | MVP-SI-014 | MVP-BE-FR-014 | MVP-BE-SPEC-014 | AC-MVP-BE-014 | MVP-BE-TR-014 | MVP-BE-GAP-011 | integration | automated | `backend/src/test/java/com/speakeasy/` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository test` | passed | `docs/reports/test_report.md` | Backend unit/integration suite | 全量后端回归通过，覆盖前五个 backend increments 的实现。 |
| TC-MVP-BE-045 | MVP-SI-014 | MVP-BE-FR-014 | MVP-BE-SPEC-014 | AC-MVP-BE-014 | MVP-BE-TR-014 | MVP-BE-GAP-011 | widget | automated | `test/` | `flutter test` | passed | `docs/reports/test_report.md` | Flutter active MVP flows | 全量 Flutter test 通过，包含 API client contract、auth、home、scene、practice、profile 等当前可自动化路径。 |
| TC-MVP-BE-046 | MVP-SI-014 | MVP-BE-FR-014 | MVP-BE-SPEC-014 | AC-MVP-BE-014 | MVP-BE-TR-014 | MVP-BE-GAP-011 | release-check | automated | `docs/release/release_checklist.md`; `docs/reports/quality_report.md`; `scripts/validate_governance_contracts.py` | `python3 scripts/validate_governance_contracts.py` | passed | `docs/reports/quality_report.md` | Release checklist and Product Object Governance Check evidence | release evidence 标记为 ready with documented exceptions；POGC 确认 stage/increment/FR/spec/AC/traceability row 不断链。 |

## Handoff Notes
- TC-MVP-BE-039 到 TC-MVP-BE-046 一经发布不得重排或复用。
- 本 increment 的 release status 是 `ready with documented exceptions`：完整商业支付、legacy freeform scene、role memory、stats migration、外部对象存储 retention 和真实 provider production readiness 仍按各自 owning increment / DevOps Security policy 管理。
