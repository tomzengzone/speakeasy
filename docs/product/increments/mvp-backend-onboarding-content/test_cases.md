# MVP Backend Onboarding Content Test Cases

## 状态
Draft - 实现前测试用例库；用于关闭 `mvp-backend-onboarding-content` 的 AC-to-TC implementation gate，不代表测试脚本已实现或已通过。

## Owner
Test Case Development Agent

## Source
- `docs/product/increments/mvp-backend-onboarding-content/definition.md`
- `docs/product/increments/mvp-backend-onboarding-content/requirements.md`
- `docs/product/increments/mvp-backend-onboarding-content/spec.md`
- `docs/product/increments/mvp-backend-onboarding-content/acceptance.md`
- `docs/product/increments/mvp-backend-onboarding-content/traceability.md`

## Coverage Summary
| AC | Traceability Row | Test Case IDs | Gate status |
| --- | --- | --- | --- |
| AC-MVP-BE-003 | MVP-BE-TR-003 | TC-MVP-BE-007, TC-MVP-BE-008, TC-MVP-BE-009 | planned |
| AC-MVP-BE-004 | MVP-BE-TR-004 | TC-MVP-BE-010, TC-MVP-BE-011, TC-MVP-BE-012 | planned |
| AC-MVP-BE-005 | MVP-BE-TR-005 | TC-MVP-BE-013, TC-MVP-BE-014, TC-MVP-BE-015 | planned |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-007 | MVP-SI-003 | MVP-BE-FR-003 | MVP-BE-SPEC-003 | AC-MVP-BE-003 | MVP-BE-TR-003 | MVP-BE-GAP-003 | integration | planned | `backend/src/test/java/com/speakeasy/OnboardingAssessmentControllerTest.java` | `mvn.cmd -q "-Dtest=OnboardingAssessmentControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Missing goal、expression blocker、output-level assessment fixtures | 缺少目标方向、表达卡点或输出水平时，后端拒绝完成首评并返回 validation error。 |
| TC-MVP-BE-008 | MVP-SI-003 | MVP-BE-FR-003 | MVP-BE-SPEC-003 | AC-MVP-BE-003 | MVP-BE-TR-003 | MVP-BE-GAP-003 | integration | planned | `backend/src/test/java/com/speakeasy/LearningRouteMappingTest.java` | `mvn.cmd -q "-Dtest=LearningRouteMappingTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | English interview、onboarding/work communication、daily service direction fixtures | 英语面试映射到 `job_interview`；入职介绍或工作沟通映射到 `onboarding_introduction`；日常服务不创建可练官方场景。 |
| TC-MVP-BE-009 | MVP-SI-003 | MVP-BE-FR-003 | MVP-BE-SPEC-003 | AC-MVP-BE-003 | MVP-BE-TR-003 | MVP-BE-GAP-003 | contract | planned | `backend/src/test/java/com/speakeasy/OnboardingRouteResponseContractTest.java` | `mvn.cmd -q "-Dtest=OnboardingRouteResponseContractTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Completed assessment and route response fixtures | 完成首评后，后端返回 assessment、learning route 和当前 scenario state，字段与 OpenAPI contract 一致。 |
| TC-MVP-BE-010 | MVP-SI-004 | MVP-BE-FR-004 | MVP-BE-SPEC-004 | AC-MVP-BE-004 | MVP-BE-TR-004 | MVP-BE-GAP-003, MVP-BE-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/ScenarioCatalogControllerTest.java` | `mvn.cmd -q "-Dtest=ScenarioCatalogControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Published scenario catalog seed with `job_interview` and `onboarding_introduction` | scenario list 只返回两个 Product Base 官方场景，不返回任意场景、draft 场景或 Product Base 外场景。 |
| TC-MVP-BE-011 | MVP-SI-004 | MVP-BE-FR-004 | MVP-BE-SPEC-004 | AC-MVP-BE-004 | MVP-BE-TR-004 | MVP-BE-GAP-003, MVP-BE-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/ScenarioContentControllerTest.java` | `mvn.cmd -q "-Dtest=ScenarioContentControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Scenario detail and L1/L2/L3 level content fixtures | detail 返回标题、简介、标签、目标等级、表达数量和版本；有效等级返回内容，无效等级返回确定性错误。 |
| TC-MVP-BE-012 | MVP-SI-004 | MVP-BE-FR-004 | MVP-BE-SPEC-004 | AC-MVP-BE-004 | MVP-BE-TR-004 | MVP-BE-GAP-003, MVP-BE-GAP-004 | contract | planned | `backend/src/test/java/com/speakeasy/ScenarioSeedVersioningTest.java` | `mvn.cmd -q "-Dtest=ScenarioSeedVersioningTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Content seed/version fixture | seed 或版本变更后内容可读取，且不会误新增 Product Base 外场景。 |
| TC-MVP-BE-013 | MVP-SI-005 | MVP-BE-FR-005 | MVP-BE-SPEC-005 | AC-MVP-BE-005 | MVP-BE-TR-005 | MVP-BE-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/UserScenarioStateControllerTest.java` | `mvn.cmd -q "-Dtest=UserScenarioStateControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Join、remove、set-current、change-level request fixtures | 加入场景后 home summary 反映已加入；移除后不得继续作为 current scene；切换当前场景或等级后后续 summary 使用新状态。 |
| TC-MVP-BE-014 | MVP-SI-005 | MVP-BE-FR-005 | MVP-BE-SPEC-005 | AC-MVP-BE-005 | MVP-BE-TR-005 | MVP-BE-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/HomeSummaryControllerTest.java` | `mvn.cmd -q "-Dtest=HomeSummaryControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | User with no joined scenario; user with missing review/weakness/session data | 未加入场景时返回可理解空状态；复习、薄弱或未完成会话数据未实现时返回明确缺省状态，不伪造完成数据。 |
| TC-MVP-BE-015 | MVP-SI-005 | MVP-BE-FR-005 | MVP-BE-SPEC-005 | AC-MVP-BE-005 | MVP-BE-TR-005 | MVP-BE-GAP-004 | widget | planned | `test/application/home_cards_coordinator_test.dart`; `test/application/scene_setup_coordinator_test.dart` | `flutter test test/application/home_cards_coordinator_test.dart test/application/scene_setup_coordinator_test.dart` | planned | `docs/reports/test_report.md`（执行后更新） | Flutter home/scene coordinator fixture backed by service response | Flutter 练习入口和 home cards 使用服务端新状态；旧本地状态不会覆盖服务端 current scene / level。 |

## Handoff Notes
- 本库只建立测试设计和 AC-to-TC 映射；Backend / Frontend / QA 仍需在后续执行中实现脚本并更新执行证据。
- TC-MVP-BE-007 到 TC-MVP-BE-015 一经发布不得重排或复用。
