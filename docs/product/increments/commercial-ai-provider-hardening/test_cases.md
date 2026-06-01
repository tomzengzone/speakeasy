# Test Cases：商业 AI Provider 生产化加固

## 状态
In progress - TC-COM-AI-001 through TC-COM-AI-007 have local backend/evidence-gate coverage；TC-COM-AI-004 remains external-blocked until real DashScope evidence is supplied.

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
| AC-COM-AI-001 | COM-AI-TR-001 | TC-COM-AI-001, TC-COM-AI-002 | automated / passed locally |
| AC-COM-AI-002 | COM-AI-TR-002 | TC-COM-AI-003 | automated / passed locally |
| AC-COM-AI-003 | COM-AI-TR-003 | TC-COM-AI-004 | structural gate passed / external evidence blocked |
| AC-COM-AI-004 | COM-AI-TR-004 | TC-COM-AI-005 | automated / passed locally |
| AC-COM-AI-005 | COM-AI-TR-005 | TC-COM-AI-006, TC-COM-AI-007 | automated / passed locally |

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
| TC-COM-AI-001 | COM-SI-013 | FR-COM-AI-001 | COM-AI-SPEC-001 | AC-COM-AI-001 | COM-AI-TR-001 | COM-AI-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/MediaUploadReferenceServiceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-be-001-media-upload-and-asr-ref-tests` | Valid audio upload, oversize file, unsupported mime, idempotent upload, completion | 后端生成带可信元数据的 `audio_ref`；非法输入被拒绝。 |
| TC-COM-AI-002 | COM-SI-013 | FR-COM-AI-001 | COM-AI-SPEC-001 | AC-COM-AI-001 | COM-AI-TR-001 | COM-AI-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/ProductionAsrMediaRefTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProductionAsrMediaRefTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-be-001-media-upload-and-asr-ref-tests` | Local path, unsigned URL, unvalidated media ref, valid media ref | 生产 ASR 只接受后端签发且 validated 的 media ref；非法输入在 provider 调用前拒绝。 |
| TC-COM-AI-003 | COM-SI-014 | FR-COM-AI-002 | COM-AI-SPEC-002 | AC-COM-AI-002 | COM-AI-TR-002 | COM-AI-GAP-002 | integration | automated | `backend/src/test/java/com/speakeasy/PersistentTtsCacheTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PersistentTtsCacheTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-be-002-persistent-tts-cache-tests` | Same text/model/voice/language across provider calls, cache expiry refresh | 有效持久缓存命中不重复调用 provider；过期/删除后按策略处理。 |
| TC-COM-AI-004 | COM-SI-015 | FR-COM-AI-003 | COM-AI-SPEC-003 | AC-COM-AI-003 | COM-AI-TR-003 | COM-AI-GAP-003 | manual + release gate | structural automated gate / external-dependency | `tests/commercial/ai_provider_sandbox_matrix.md`; `scripts/check_ai_provider_sandbox_evidence.py` | `python3 scripts/check_ai_provider_sandbox_evidence.py`; strict: `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` | structural gate passed; strict gate fails until evidence ref supplied | `docs/reports/test_report.md#2026-06-01-p0-ai-qa-001-dashscope-sandbox-evidence-gate` | DashScope Qwen LLM, Paraformer ASR, TTS and provider error fixtures | 真实 provider 证据记录 latency、error code、cost、format compatibility、fallback 和独立审查；缺少 `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` 时不得关闭。 |
| TC-COM-AI-005 | COM-SI-016 | FR-COM-AI-004 | COM-AI-SPEC-004 | AC-COM-AI-004 | COM-AI-TR-004 | COM-AI-GAP-004 | integration | automated | `backend/src/test/java/com/speakeasy/AiCostDashboardTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-ops-001-ai-cost-dashboard-tests` | Free/pro/premium usage, cache hit, provider error, budget warning, provider anomaly | 成本看板按套餐、用户 hash、provider、模型和状态聚合并暴露预算风险；OPS-only API 不暴露 raw user content。 |
| TC-COM-AI-006 | COM-SI-017 | FR-COM-AI-005 | COM-AI-SPEC-005 | AC-COM-AI-005 | COM-AI-TR-005 | COM-AI-GAP-005 | integration | automated | `backend/src/test/java/com/speakeasy/AiRetentionPolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiRetentionPolicyTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-sec-001-ai-retention-and-deletion-tests` | Expired audio media and TTS cache retention fixtures | retention job 删除、匿名化或保留最小审计字段，并记录脱敏证据。 |
| TC-COM-AI-007 | COM-SI-017 | FR-COM-AI-005 | COM-AI-SPEC-005 | AC-COM-AI-005 | COM-AI-TR-005 | COM-AI-GAP-005 | integration | automated | `backend/src/test/java/com/speakeasy/AiAccountDeletionMediaCleanupTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiAccountDeletionMediaCleanupTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-sec-001-ai-retention-and-deletion-tests` | Account with audio refs, TTS cache ownership and AI provider metrics | 账号删除覆盖 AI 媒体、TTS cache owner hash、provider-derived metric cleanup 和脱敏审计证据。 |

## Gate Result
- AC-to-TC mapping: planned pass. `AC-COM-AI-001` through `AC-COM-AI-005` all map to one or more stable TC IDs.
- Implementation/QA status: TC-COM-AI-001 through TC-COM-AI-003 and TC-COM-AI-005 through TC-COM-AI-007 have local automated evidence；TC-COM-AI-004 has a structural evidence gate.
- External/manual exceptions: `TC-COM-AI-004` still requires real DashScope sandbox / controlled live execution, `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` and independent review.

## Handoff Notes
- TC-COM-AI IDs are stable and must not be merged into TC-COM-001..023.
- This increment closes the production AI provider residual only after code, tests, live evidence, implementation report and quality report are updated.
