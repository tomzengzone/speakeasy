# Test Cases：商业 AI Provider 生产化加固

## 状态
Draft - AC-to-TC gate planned；尚未实现或执行。

## Owner
Test Case Development Agent

## Source
- `docs/product/increments/commercial-ai-provider-hardening/definition.md`
- `docs/product/increments/commercial-ai-provider-hardening/requirements.md`
- `docs/product/increments/commercial-ai-provider-hardening/spec.md`
- `docs/product/increments/commercial-ai-provider-hardening/acceptance.md`
- `docs/product/increments/commercial-ai-provider-hardening/traceability.md`

## AC-to-TC Coverage Summary
| Acceptance Criteria | Traceability Row | Test Case IDs | Gate status |
| --- | --- | --- | --- |
| AC-COM-AI-001 | COM-AI-TR-001 | TC-COM-AI-001, TC-COM-AI-002 | mapped / planned |
| AC-COM-AI-002 | COM-AI-TR-002 | TC-COM-AI-003 | mapped / planned |
| AC-COM-AI-003 | COM-AI-TR-003 | TC-COM-AI-004 | mapped / external planned |
| AC-COM-AI-004 | COM-AI-TR-004 | TC-COM-AI-005 | mapped / planned |
| AC-COM-AI-005 | COM-AI-TR-005 | TC-COM-AI-006, TC-COM-AI-007 | mapped / planned |

## Requirement-to-Test Coverage
| Requirement | Stage Scope ID | Acceptance Criteria | Test Case IDs | Coverage status |
| --- | --- | --- | --- | --- |
| FR-COM-AI-001 | COM-SI-013 | AC-COM-AI-001 | TC-COM-AI-001, TC-COM-AI-002 | 100% mapped |
| FR-COM-AI-002 | COM-SI-014 | AC-COM-AI-002 | TC-COM-AI-003 | 100% mapped |
| FR-COM-AI-003 | COM-SI-015 | AC-COM-AI-003 | TC-COM-AI-004 | 100% mapped |
| FR-COM-AI-004 | COM-SI-016 | AC-COM-AI-004 | TC-COM-AI-005 | 100% mapped |
| FR-COM-AI-005 | COM-SI-017 | AC-COM-AI-005 | TC-COM-AI-006, TC-COM-AI-007 | 100% mapped |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-COM-AI-001 | COM-SI-013 | FR-COM-AI-001 | COM-AI-SPEC-001 | AC-COM-AI-001 | COM-AI-TR-001 | COM-AI-GAP-001 | integration | planned | `backend/src/test/java/com/speakeasy/ai/MediaUploadReferenceServiceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest test` | planned | `docs/reports/test_report.md` | Valid audio upload, oversize file, unsupported mime, expired ref | 后端生成带可信元数据的 `audio_ref`；非法输入被拒绝且不调用 provider。 |
| TC-COM-AI-002 | COM-SI-013 | FR-COM-AI-001 | COM-AI-SPEC-001 | AC-COM-AI-001 | COM-AI-TR-001 | COM-AI-GAP-001 | integration | planned | `backend/src/test/java/com/speakeasy/ai/ProductionAsrMediaRefTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProductionAsrMediaRefTest test` | planned | `docs/reports/test_report.md` | Local path, unsigned URL, forged signature, valid media ref | 生产 ASR 只接受后端签发 media ref；usage/audit 只记录 hash。 |
| TC-COM-AI-003 | COM-SI-014 | FR-COM-AI-002 | COM-AI-SPEC-002 | AC-COM-AI-002 | COM-AI-TR-002 | COM-AI-GAP-002 | integration | planned | `backend/src/test/java/com/speakeasy/ai/PersistentTtsCacheTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PersistentTtsCacheTest test` | planned | `docs/reports/test_report.md` | Same text/model/voice across simulated restart and cache expiry | 有效持久缓存命中不重复调用 provider；过期/删除后按策略处理。 |
| TC-COM-AI-004 | COM-SI-015 | FR-COM-AI-003 | COM-AI-SPEC-003 | AC-COM-AI-003 | COM-AI-TR-003 | COM-AI-GAP-003 | manual | external-dependency | `tests/commercial/ai_provider_sandbox_matrix.md` | manual DashScope sandbox execution plus future strict evidence gate | external pending | `docs/reports/test_report.md` | DashScope LLM, Paraformer ASR, TTS fixtures | 真实 provider 证据记录 latency、error、cost、format compatibility、fallback 和独立审查。 |
| TC-COM-AI-005 | COM-SI-016 | FR-COM-AI-004 | COM-AI-SPEC-004 | AC-COM-AI-004 | COM-AI-TR-004 | COM-AI-GAP-004 | integration | planned | `backend/src/test/java/com/speakeasy/ai/AiCostDashboardTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest test` | planned | `docs/reports/test_report.md` | Free/pro/enterprise usage, cache hit, provider error, budget warning | 成本看板按套餐、用户 hash、provider、模型和状态聚合并暴露预算风险。 |
| TC-COM-AI-006 | COM-SI-017 | FR-COM-AI-005 | COM-AI-SPEC-005 | AC-COM-AI-005 | COM-AI-TR-005 | COM-AI-GAP-005 | integration | planned | `backend/src/test/java/com/speakeasy/ai/AiRetentionPolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiRetentionPolicyTest test` | planned | `docs/reports/test_report.md` | Audio, transcript, provider payload, TTS cache retention fixtures | retention job 删除、匿名化或保留最小审计字段，并记录脱敏证据。 |
| TC-COM-AI-007 | COM-SI-017 | FR-COM-AI-005 | COM-AI-SPEC-005 | AC-COM-AI-005 | COM-AI-TR-005 | COM-AI-GAP-005 | integration | planned | `backend/src/test/java/com/speakeasy/ai/AiAccountDeletionMediaCleanupTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiAccountDeletionMediaCleanupTest test` | planned | `docs/reports/test_report.md` | Account with audio refs, transcript refs and TTS cache ownership | 账号删除覆盖 AI 媒体、转写、TTS cache 和 provider-derived private content。 |

## Gate Result
- AC-to-TC mapping: planned pass. `AC-COM-AI-001` through `AC-COM-AI-005` all map to one or more stable TC IDs.
- Implementation/QA status: not started.
- External/manual exceptions: `TC-COM-AI-004` requires real DashScope sandbox / controlled live evidence and independent review.

## Handoff Notes
- TC-COM-AI IDs are stable and must not be merged into TC-COM-001..023.
- This increment closes the production AI provider residual only after code, tests, live evidence, implementation report and quality report are updated.
