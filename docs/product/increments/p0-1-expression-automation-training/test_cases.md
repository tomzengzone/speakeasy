# P0.1 Test Cases：表达自动化训练 Agent

## 状态
Draft - AC-to-TC gate ready；P0.1 training Agent core tests executed for TC-P01-001 through TC-P01-012；backend provider adapter tests executed for TC-P01-015 through TC-P01-020；TC-P01-013 integration loop and TC-P01-014 document-level AI eval remain planned。

## 上游来源
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`
- `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- `docs/product/increments/p0-1-expression-automation-training/traceability.md`
- `docs/domain/training_model.md`
- `docs/ai_runtime/prompt_contract.md`
- `docs/ai_runtime/llm_output_schema.md`
- `docs/ai_runtime/fallback_strategy.md`
- `docs/ux/screen_spec.md`
- `docs/architecture/module_boundary.md`

## AC-to-TC Gate Result
| 字段 | 值 |
| --- | --- |
| Gate | P0.1 pre-implementation AC-to-TC mapping |
| Result | Passed for implementation routing |
| Date | 2026-06-01 |
| Scope | P0.1 官方场景 `job_interview`、`onboarding_introduction` 的训练型 Agent 行为；当前后端 AI Provider Gateway |
| Boundary | 不覆盖第三官方场景、任意场景生成、跨天调度、完整 L0-L5、完整商业 release gating；仅覆盖当前 AI Gateway provider policy 和 usage boundary |
| Execution status | TC-P01-001 through TC-P01-012 passed on 2026-06-01；TC-P01-015 through TC-P01-020 passed on 2026-06-01；TC-P01-013 and TC-P01-014 remain planned |
| Evidence report | `docs/reports/test_report.md` |

## Test Case Library
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-P01-001 | P01-SI-001 | P01-FR-001 | P01-SPEC-001 | AC-P01-001 | P01-TR-001 | P01-GAP-006 | widget | automated | `test/features/interview/interview_training_entry_test.dart` | `flutter test test/features/interview/interview_training_entry_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-002 | P01-SI-003 | P01-FR-002 | P01-SPEC-002 | AC-P01-002 | P01-TR-003 | P01-GAP-006 | unit | automated | `test/features/interview/interview_training_planner_test.dart` | `flutter test test/features/interview/interview_training_planner_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-003 | P01-SI-004 | P01-FR-003 | P01-SPEC-003 | AC-P01-003 | P01-TR-004 | P01-GAP-006 | unit | automated | `test/features/interview/interview_training_planner_test.dart` | `flutter test test/features/interview/interview_training_planner_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-004 | P01-SI-002 | P01-FR-004 | P01-SPEC-004 | AC-P01-004 | P01-TR-002 | P01-GAP-006 | unit | automated | `test/features/interview/interview_training_planner_test.dart` | `flutter test test/features/interview/interview_training_planner_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-005 | P01-SI-005 | P01-FR-005 | P01-SPEC-005 | AC-P01-005 | P01-TR-005 | P01-GAP-006 | unit | automated | `test/features/interview/interview_training_hint_ladder_test.dart` | `flutter test test/features/interview/interview_training_hint_ladder_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-006 | P01-SI-007 | P01-FR-006 | P01-SPEC-006 | AC-P01-006 | P01-TR-007 | P01-GAP-006 | widget | automated | `test/features/interview/interview_training_voice_flow_test.dart` | `flutter test test/features/interview/interview_training_voice_flow_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-007 | P01-SI-007 | P01-FR-006 | P01-SPEC-006 | AC-P01-007 | P01-TR-007 | P01-GAP-006 | widget | automated | `test/features/interview/interview_training_text_fallback_test.dart` | `flutter test test/features/interview/interview_training_text_fallback_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-008 | P01-SI-008 | P01-FR-007 | P01-SPEC-007 | AC-P01-008 | P01-TR-008 | P01-GAP-006 | contract | automated | `test/features/interview/interview_training_feedback_schema_test.dart` | `flutter test test/features/interview/interview_training_feedback_schema_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-009 | P01-SI-006 | P01-FR-008 | P01-SPEC-008 | AC-P01-009 | P01-TR-006 | P01-GAP-006 | unit | automated | `test/features/interview/interview_training_pressure_check_test.dart` | `flutter test test/features/interview/interview_training_pressure_check_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-010 | P01-SI-009 | P01-FR-009 | P01-SPEC-009 | AC-P01-010 | P01-TR-009 | P01-GAP-006 | unit | automated | `test/features/interview/interview_training_evidence_test.dart` | `flutter test test/features/interview/interview_training_evidence_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-011 | P01-SI-011 | P01-FR-010 | P01-SPEC-010 | AC-P01-011 | P01-TR-011 | P01-GAP-006 | unit | automated | `test/features/interview/interview_training_recoverable_failure_test.dart` | `flutter test test/features/interview/interview_training_recoverable_failure_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-012 | P01-SI-010 | P0.1 非目标边界 | P01-SPEC-011 | AC-P01-012 | P01-TR-010 | P01-GAP-007 | release-check | automated | `test/features/interview/interview_training_scope_boundary_test.dart` | `flutter test test/features/interview/interview_training_scope_boundary_test.dart` | passed | `docs/reports/test_report.md` |
| TC-P01-013 | P01-SI-001, P01-SI-002, P01-SI-004, P01-SI-008, P01-SI-009, P01-SI-010 | P01-FR-001, P01-FR-004, P01-FR-003, P01-FR-007, P01-FR-009, P0.1 非目标边界 | P01-SPEC-001, P01-SPEC-004, P01-SPEC-003, P01-SPEC-007, P01-SPEC-009, P01-SPEC-011 | AC-P01-001, AC-P01-003, AC-P01-004, AC-P01-008, AC-P01-010, AC-P01-012 | P01-TR-001, P01-TR-002, P01-TR-004, P01-TR-008, P01-TR-009, P01-TR-010 | P01-GAP-006 | integration | planned | `integration_test/p0_1_training_loop_test.dart` | `flutter test integration_test/p0_1_training_loop_test.dart` | planned | `docs/product/increments/p0-1-expression-automation-training/test_cases.md`; execution report pending |
| TC-P01-014 | P01-SI-008, P01-SI-011 | P01-FR-007, P01-FR-010 | P01-SPEC-007, P01-SPEC-010 | AC-P01-008, AC-P01-011 | P01-TR-008, P01-TR-011 | P01-GAP-006 | ai-eval | planned | `docs/ai_runtime/ai_eval_cases.md` | `N/A - document-level AI eval cases until schema validator implementation is available` | planned | `docs/product/increments/p0-1-expression-automation-training/test_cases.md`; execution report pending |
| TC-P01-015 | P01-SI-007, P01-SI-008, P01-SI-011 | P01-FR-011 | P01-SPEC-012 | AC-P01-013 | P01-TR-012 | P01-GAP-008 | unit | automated | `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,FeedbackFailureHandlingTest,CommercialAbuseControlTest,UsageQuotaGateTest test` | passed | `docs/reports/test_report.md` |
| TC-P01-016 | P01-SI-007, P01-SI-011 | P01-FR-011 | P01-SPEC-012 | AC-P01-013 | P01-TR-012 | P01-GAP-008 | contract | automated | `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayTest.java`, `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayIntegrationTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,FeedbackFailureHandlingTest,CommercialAbuseControlTest,UsageQuotaGateTest test` | passed | `docs/reports/test_report.md` |
| TC-P01-017 | P01-SI-007, P01-SI-011 | P01-FR-011 | P01-SPEC-012 | AC-P01-013 | P01-TR-012 | P01-GAP-008 | unit | automated | `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayTest.java`, `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayIntegrationTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,FeedbackFailureHandlingTest,CommercialAbuseControlTest,UsageQuotaGateTest test` | passed | `docs/reports/test_report.md` |
| TC-P01-018 | P01-SI-008, P01-SI-011 | P01-FR-011 | P01-SPEC-012 | AC-P01-013 | P01-TR-012 | P01-GAP-008 | unit | automated | `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayTest.java`, `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayIntegrationTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,FeedbackFailureHandlingTest,CommercialAbuseControlTest,UsageQuotaGateTest test` | passed | `docs/reports/test_report.md` |
| TC-P01-019 | P01-SI-007, P01-SI-008, P01-SI-011 | P01-FR-011 | P01-SPEC-012 | AC-P01-013 | P01-TR-012 | P01-GAP-008 | integration | automated | `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayIntegrationTest.java`, `backend/src/test/java/com/speakeasy/CommercialAbuseControlTest.java`, `backend/src/test/java/com/speakeasy/UsageQuotaGateTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,FeedbackFailureHandlingTest,CommercialAbuseControlTest,UsageQuotaGateTest test` | passed | `docs/reports/test_report.md` |
| TC-P01-020 | P01-SI-007, P01-SI-008, P01-SI-011 | P01-FR-011 | P01-SPEC-012 | AC-P01-013 | P01-TR-012 | P01-GAP-008 | contract | automated | `backend/src/test/java/com/speakeasy/ProviderGatewaySecurityContractTest.java`, `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayTest.java`, `backend/src/test/java/com/speakeasy/DashScopeProviderGatewayIntegrationTest.java` | `JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=DashScopeProviderGatewayTest,DashScopeProviderGatewayIntegrationTest,ProviderGatewaySecurityContractTest,ProviderGatewayControllerTest,ProviderGatewayFailureTest,FeedbackFailureHandlingTest,CommercialAbuseControlTest,UsageQuotaGateTest test` | passed | `docs/reports/test_report.md` |

## Coverage Map
| Acceptance Criteria | Primary TC | Supporting TC | Coverage status |
| --- | --- | --- | --- |
| AC-P01-001 | TC-P01-001 | TC-P01-013 | Core entry/resume/unsupported-scene checks passed；integration remains planned |
| AC-P01-002 | TC-P01-002 | TC-P01-013 | Action chain mapping checks passed；integration remains planned |
| AC-P01-003 | TC-P01-003 | TC-P01-013 | Micro-action state checks passed；integration remains planned |
| AC-P01-004 | TC-P01-004 | TC-P01-013 | Planner decision checks passed；integration remains planned |
| AC-P01-005 | TC-P01-005 | TC-P01-004 | Hint ladder checks passed |
| AC-P01-006 | TC-P01-006 | TC-P01-013 | Voice control widget checks passed；integration remains planned |
| AC-P01-007 | TC-P01-007 | TC-P01-011 | Text fallback and recoverable failure checks passed |
| AC-P01-008 | TC-P01-008 | TC-P01-014 | Feedback schema checks passed；AI eval remains planned |
| AC-P01-009 | TC-P01-009 | TC-P01-013 | Pressure check planner checks passed；integration remains planned |
| AC-P01-010 | TC-P01-010 | TC-P01-013 | Learning evidence candidate and recap checks passed；integration remains planned |
| AC-P01-011 | TC-P01-011 | TC-P01-014 | Recoverable failure checks passed；AI eval remains planned |
| AC-P01-012 | TC-P01-012 | TC-P01-013 | Scope boundary checks passed；integration remains planned |
| AC-P01-013 | TC-P01-015, TC-P01-016, TC-P01-017, TC-P01-018, TC-P01-019, TC-P01-020 | TC-MVP-BE-016 through TC-MVP-BE-019 | Backend provider adapter, media ref guard, TTS cache, LLM schema fallback, usage boundary, tier policy telemetry and no-secret contract passed in local fake-provider suite；live provider/object-storage evidence remains release residual |

## AC-P01-013 Detailed Coverage
| Design obligation | Primary TC | Required assertions |
| --- | --- | --- |
| LLM/TTS/ASR 1：DashScope is selected as first real provider while deterministic remains default test/dev provider | TC-P01-015, TC-P01-019 | Passed：provider properties select deterministic or dashscope；test profile does not require live credentials；DashScope adapter uses configured Qwen/TTS/ASR model names |
| LLM/TTS/ASR 2：real provider adapter behind current `AiProviderGateway` | TC-P01-015, TC-P01-019, TC-P01-020 | Passed：`DashScopeAiProviderGateway` implements `AiProviderGateway`；existing AI REST and `AiGatewayService` usage boundary are reused；Flutter cannot submit provider secret or provider tier |
| LLM/TTS/ASR 3：ASR `audio_ref` is backend/provider accessible and guarded | TC-P01-016, TC-P01-019 | Partial passed：local file path、unsigned HTTP ref、oversized/over-duration signed media input and provider no-result return typed failure；valid backend-signed provider-accessible media ref maps to transcript/status；backend/object-storage upload lifecycle remains residual and is planned in `commercial-ai-provider-hardening` |
| LLM/TTS/ASR 4：TTS cache by text/model/voice | TC-P01-017, TC-P01-019 | Partial passed：repeated same text/model/voice uses same cache key and avoids duplicate provider call within process；provider unavailable returns typed status；persistent media cache remains residual and is planned in `commercial-ai-provider-hardening` |
| LLM/TTS/ASR 5：LLM output is schema constrained and fallback-safe | TC-P01-018, TC-P01-019 | Passed：valid strict JSON maps to feedback；invalid enum、missing required field、out-of-range score、unsupported extra field and final mastery fields return recoverable fallback without accepted evidence |
| Commercial 1：cost control | TC-P01-019 | Passed：usage reservation/commit/release remains active；provider metadata includes family/provider/model/status/latency/fallback reason plus token estimate, audio duration or estimated cost bucket where applicable |
| Commercial 2：plan/tier policy | TC-P01-019 | Passed for current gateway：free/pro/enterprise policy is server-side derived from entitlement plan and covered by entitlement-backed integration tests；policy caps text length, audio duration and audio size before provider call；client `provider_tier` cannot override server facts；request frequency remains covered by existing usage quota reservation |
| Commercial 3：provider replaceability | TC-P01-015 | Passed：provider implementation is selected by server config through `AiProviderGateway`; deterministic rollback path remains available |
| Commercial 4：observability and abuse control | TC-P01-019, TC-P01-020 | Passed：provider calls expose sanitized metadata only；ASR oversized/over-duration inputs fail before provider call；high-frequency calls remain covered by usage quota tests；AI cost dashboard remains release residual and is planned in `commercial-ai-provider-hardening` |
| Commercial 5：data and compliance | TC-P01-020 | Passed for local contract：responses exclude provider secret/tier, provider telemetry excludes provider secret/raw full transcript, and usage audit stores hashed media refs instead of full signed audio URLs；retention/deletion boundary remains a documented release residual until persistent media storage exists and is planned in `commercial-ai-provider-hardening` |

## Test Design Notes
- Planner、action chain、hint ladder、pressure check、learning evidence 优先使用 unit/contract tests，避免把可确定逻辑推到高成本 E2E。
- 录音、播放、文本兜底和可恢复错误需要 widget tests；真实 ASR/TTS/LLM 依赖必须 mock，不允许用 live third-party service 作为默认 CI 前置条件。
- AI feedback 以 schema validator 和 eval cases 双层覆盖；LLM 输出只能作为候选反馈，不得直接写入最终掌握状态。
- Scope boundary 使用 release-check 或 contract test，确保实现不新增第三官方场景、不承诺任意场景生成、不验收跨天调度或完整 L0-L5。

## Execution Evidence Policy
- 本文件只关闭 pre-implementation 的 AC-to-TC mapping gate。
- 未执行的用例不得标记为 `passed`。
- 实现完成后，QA 必须把实际命令、结果、失败原因和证据链接写入 `docs/reports/test_report.md`，并回写本增量 traceability 的 Test Evidence。
