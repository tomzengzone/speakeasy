# MVP Backend Practice AI Test Cases

## 状态
Draft - 实现前测试用例库；用于关闭 `mvp-backend-practice-ai` 的 AC-to-TC implementation gate，不代表测试脚本已实现或已通过。

## Owner
Test Case Development Agent

## Source
- `docs/product/increments/mvp-backend-practice-ai/definition.md`
- `docs/product/increments/mvp-backend-practice-ai/requirements.md`
- `docs/product/increments/mvp-backend-practice-ai/spec.md`
- `docs/product/increments/mvp-backend-practice-ai/acceptance.md`
- `docs/product/increments/mvp-backend-practice-ai/traceability.md`

## Coverage Summary
| AC | Traceability Row | Test Case IDs | Gate status |
| --- | --- | --- | --- |
| AC-MVP-BE-006 | MVP-BE-TR-006 | TC-MVP-BE-016, TC-MVP-BE-017, TC-MVP-BE-018, TC-MVP-BE-019 | planned |
| AC-MVP-BE-008 | MVP-BE-TR-008 | TC-MVP-BE-020, TC-MVP-BE-021, TC-MVP-BE-022, TC-MVP-BE-023 | planned |
| AC-MVP-BE-009 | MVP-BE-TR-009 | TC-MVP-BE-024, TC-MVP-BE-025 | planned |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-MVP-BE-016 | MVP-SI-006 | MVP-BE-FR-006 | MVP-BE-SPEC-006 | AC-MVP-BE-006 | MVP-BE-TR-006 | MVP-BE-GAP-005 | contract | planned | `backend/src/test/java/com/speakeasy/ProviderGatewaySecurityContractTest.java` | `mvn.cmd -q "-Dtest=ProviderGatewaySecurityContractTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Authenticated client request without provider secret fixture | 客户端不需要也不能提交 provider secret；后端通过 server-side adapter 处理 ASR/TTS/pronunciation/LLM 请求。 |
| TC-MVP-BE-017 | MVP-SI-006 | MVP-BE-FR-006 | MVP-BE-SPEC-006 | AC-MVP-BE-006 | MVP-BE-TR-006 | MVP-BE-GAP-005 | integration | planned | `backend/src/test/java/com/speakeasy/ProviderGatewayControllerTest.java` | `mvn.cmd -q "-Dtest=ProviderGatewayControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Mock ASR/TTS/pronunciation/LLM success fixtures | provider 成功时后端返回符合 OpenAPI / AI schema 的规范化结果。 |
| TC-MVP-BE-018 | MVP-SI-006 | MVP-BE-FR-006 | MVP-BE-SPEC-006 | AC-MVP-BE-006 | MVP-BE-TR-006 | MVP-BE-GAP-005 | integration | planned | `backend/src/test/java/com/speakeasy/ProviderGatewayFailureTest.java` | `mvn.cmd -q "-Dtest=ProviderGatewayFailureTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Mock timeout、unavailable、invalid-schema provider fixtures | timeout、不可用或 schema invalid 返回可恢复错误或明确失败，不写入伪成功反馈。 |
| TC-MVP-BE-019 | MVP-SI-006 | MVP-BE-FR-006 | MVP-BE-SPEC-006 | AC-MVP-BE-006 | MVP-BE-TR-006 | MVP-BE-GAP-005 | integration | planned | `backend/src/test/java/com/speakeasy/ProviderGatewayAuthorizationTest.java` | `mvn.cmd -q "-Dtest=ProviderGatewayAuthorizationTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Unauthenticated request and session mismatch fixtures | 未认证或 session 不匹配时后端拒绝 provider 调用；mock provider invocation count 保持为 0。 |
| TC-MVP-BE-020 | MVP-SI-008 | MVP-BE-FR-008 | MVP-BE-SPEC-008 | AC-MVP-BE-008 | MVP-BE-TR-008 | MVP-BE-GAP-005, MVP-BE-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/PracticeSessionLifecycleTest.java` | `mvn.cmd -q "-Dtest=PracticeSessionLifecycleTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | User, official scenario and level fixtures | 用户从官方场景和等级开始练习时，后端创建 active session；同一用户/场景/等级已有未完成 session 时返回可恢复 session。 |
| TC-MVP-BE-021 | MVP-SI-008 | MVP-BE-FR-008 | MVP-BE-SPEC-008 | AC-MVP-BE-008 | MVP-BE-TR-008 | MVP-BE-GAP-005, MVP-BE-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/PracticeTurnControllerTest.java` | `mvn.cmd -q "-Dtest=PracticeTurnControllerTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Valid text/audio/transcript turn fixtures | 有效 turn 被持久化并推进 session 状态；后续 fetch session 返回最新 turn 和状态。 |
| TC-MVP-BE-022 | MVP-SI-008 | MVP-BE-FR-008 | MVP-BE-SPEC-008 | AC-MVP-BE-008 | MVP-BE-TR-008 | MVP-BE-GAP-005, MVP-BE-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/PracticeSessionCompletionTest.java` | `mvn.cmd -q "-Dtest=PracticeSessionCompletionTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Completed session with turn and feedback fixtures | session 完成后返回 summary payload 或 learning-memory increment 可写入的 evidence candidate。 |
| TC-MVP-BE-023 | MVP-SI-008 | MVP-BE-FR-008 | MVP-BE-SPEC-008 | AC-MVP-BE-008 | MVP-BE-TR-008 | MVP-BE-GAP-005, MVP-BE-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/PracticeSessionRecoveryTest.java` | `mvn.cmd -q "-Dtest=PracticeSessionRecoveryTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Completed and active session fixtures | 已完成 session 不再作为 active recovery session；中断未完成 session 可恢复。 |
| TC-MVP-BE-024 | MVP-SI-009 | MVP-BE-FR-009 | MVP-BE-SPEC-009 | AC-MVP-BE-009 | MVP-BE-TR-009 | MVP-BE-GAP-005, MVP-BE-GAP-007 | ai-eval | planned | `backend/src/test/java/com/speakeasy/CoachFeedbackContractTest.java`; `docs/ai_runtime/ai_eval_cases.md` | `mvn.cmd -q "-Dtest=CoachFeedbackContractTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Valid answer and feedback variant fixtures | 有效回答返回 coach feedback、retry suggestion、expression suggestion、next question、score signal 或 recoverable error 至少一种；评分标记来源和可用性。 |
| TC-MVP-BE-025 | MVP-SI-009 | MVP-BE-FR-009 | MVP-BE-SPEC-009 | AC-MVP-BE-009 | MVP-BE-TR-009 | MVP-BE-GAP-005, MVP-BE-GAP-007 | integration | planned | `backend/src/test/java/com/speakeasy/FeedbackFailureHandlingTest.java` | `mvn.cmd -q "-Dtest=FeedbackFailureHandlingTest" test` | planned | `docs/reports/test_report.md`（执行后更新） | Playback/translation failure and invalid provider output fixtures | playback/translation failure 能表达失败且不丢 session；invalid provider output 不成为用户可见反馈。 |

## Handoff Notes
- 本库只建立测试设计和 AC-to-TC 映射；Backend / AI Runtime / QA 仍需在后续执行中实现脚本并更新执行证据。
- TC-MVP-BE-016 到 TC-MVP-BE-025 一经发布不得重排或复用。
