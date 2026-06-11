# Test Cases：商业 AI Provider 生产化加固

## 状态
In progress - TC-COM-AI-001 through TC-COM-AI-008 have local backend/evidence-gate coverage；paid AI external evidence checklist and strict aggregate gate now cover DashScope、object storage、cost dashboard and retention refs。Strict paid AI release remains blocked until `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`、`AI_MEDIA_STORAGE_EVIDENCE_REF`、`AI_COST_DASHBOARD_EVIDENCE_REF`、`AI_RETENTION_POLICY_EVIDENCE_REF` and independent external reviews are supplied.

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
| AC-COM-AI-001 | COM-AI-TR-001 | TC-COM-AI-001, TC-COM-AI-002, TC-COM-AI-008 | automated / passed locally |
| AC-COM-AI-002 | COM-AI-TR-002 | TC-COM-AI-003 | automated / passed locally |
| AC-COM-AI-003 | COM-AI-TR-003 | TC-COM-AI-004 | local endpoint evidence passed + controlled live sanity passed / strict external evidence blocked |
| AC-COM-AI-004 | COM-AI-TR-004 | TC-COM-AI-005 | automated / passed locally |
| AC-COM-AI-005 | COM-AI-TR-005 | TC-COM-AI-006, TC-COM-AI-007 | automated / passed locally |

## Requirement-to-Test Coverage
| Requirement | Stage Scope ID | Acceptance Criteria | Test Case IDs | Coverage status |
| --- | --- | --- | --- | --- |
| FR-COM-AI-001 | COM-SI-013 | AC-COM-AI-001 | TC-COM-AI-001, TC-COM-AI-002, TC-COM-AI-008 | 100% mapped |
| FR-COM-AI-002 | COM-SI-014 | AC-COM-AI-002 | TC-COM-AI-003 | 100% mapped |
| FR-COM-AI-003 | COM-SI-015 | AC-COM-AI-003 | TC-COM-AI-004 | 100% mapped |
| FR-COM-AI-004 | COM-SI-016 | AC-COM-AI-004 | TC-COM-AI-005 | 100% mapped |
| FR-COM-AI-005 | COM-SI-017 | AC-COM-AI-005 | TC-COM-AI-006, TC-COM-AI-007 | 100% mapped |

## Test Cases
| TC ID | Stage Scope ID | FR | Spec | AC | Traceability Row | Gap | 测试层级 | 自动化状态 | 测试脚本路径 | 执行命令 | 结果状态 | 证据报告 | Fixture / 数据 | 预期断言 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TC-COM-AI-001 | COM-SI-013 | FR-COM-AI-001 | COM-AI-SPEC-001 | AC-COM-AI-001 | COM-AI-TR-001 | COM-AI-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/MediaUploadReferenceServiceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-be-001-media-upload-and-asr-ref-tests` | Valid audio upload, oversize file, unsupported mime, idempotent upload, completion | 后端生成带可信元数据的 `audio_ref`；非法输入被拒绝。 |
| TC-COM-AI-002 | COM-SI-013 | FR-COM-AI-001 | COM-AI-SPEC-001 | AC-COM-AI-001 | COM-AI-TR-001 | COM-AI-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/ProductionAsrMediaRefTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=ProductionAsrMediaRefTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-be-001-media-upload-and-asr-ref-tests` | Local path, unsigned URL, unvalidated media ref, valid media ref | 生产 ASR 只接受后端签发且 validated 的 media ref；非法输入在 provider 调用前拒绝。 |
| TC-COM-AI-008 | COM-SI-013 | FR-COM-AI-001 | COM-AI-SPEC-001 | AC-COM-AI-001 | COM-AI-TR-001 | COM-AI-GAP-001 | integration | automated | `backend/src/test/java/com/speakeasy/MediaUploadReferenceServiceTest.java`; `backend/src/test/java/com/speakeasy/ai/AiMediaStorageServiceTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=MediaUploadReferenceServiceTest,AiMediaStorageServiceTest test` | passed | `docs/reports/test_report.md#2026-06-03-p0-ai-oss-storage-implementation` | 阿里云 OSS private bucket config、短 TTL upload/read URL、canonical `oss://bucket/key` object_ref、伪造 object_ref 拒绝 | 后端生成对象存储上传会话和 canonical object_ref；complete 只能接受后端-owned object_ref；provider read URL 由后端按需签发。 |
| TC-COM-AI-003 | COM-SI-014 | FR-COM-AI-002 | COM-AI-SPEC-002 | AC-COM-AI-002 | COM-AI-TR-002 | COM-AI-GAP-002 | integration | automated | `backend/src/test/java/com/speakeasy/PersistentTtsCacheTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=PersistentTtsCacheTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-be-002-persistent-tts-cache-tests` | Same text/model/voice/language across provider calls, cache expiry refresh | 有效持久缓存命中不重复调用 provider；过期/删除后按策略处理。 |
| TC-COM-AI-004 | COM-SI-015 | FR-COM-AI-003 | COM-AI-SPEC-003 | AC-COM-AI-003 | COM-AI-TR-003 | COM-AI-GAP-003 | integration + manual + release gate | automated endpoint + controlled-live evidence-prep + structural gate / external-dependency | `backend/src/test/java/com/speakeasy/AiProviderEvidenceControllerTest.java`; `tests/commercial/ai_provider_sandbox_matrix.md`; `scripts/check_ai_provider_sandbox_evidence.py`; `scripts/run_dashscope_sandbox_matrix.py` | endpoint: `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiProviderEvidenceControllerTest,AiCostDashboardTest,AiRetentionPolicyTest test`; evidence-prep: `python3 scripts/run_dashscope_sandbox_matrix.py`; non-strict: `python3 scripts/check_ai_provider_sandbox_evidence.py`; strict: `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external` | local endpoint evidence passed on 2026-06-09；controlled live evidence-prep passed and wrote `build/reports/dashscope-sandbox-20260602T223557Z-3359fcc82fafa457.json`; non-strict gate passed; strict gate fails until evidence ref supplied | `docs/reports/test_report.md#2026-06-09-p0-ai-provider-evidence-endpoint-tests`; `docs/reports/test_report.md#2026-06-03-p01-local-blocker-closure-and-commercial-external-gate-revalidation`; local artifact `build/reports/dashscope-sandbox-20260602T223557Z-3359fcc82fafa457.json` | ProviderSandboxRun rows including approved, pending and blocked evidence; signed URL/API key/raw payload/full transcript leak fixture; DashScope Qwen LLM, Paraformer ASR, TTS plus local fallback/cache/reject/error guards | OPS-only endpoint returns OpenAPI-aligned evidence metadata, stable sorting and redacted evidence refs；raw provider payload、provider key、raw audio、full transcript、full signed URL、internal model/fixture/error fields 不进入 response；本地 endpoint evidence 不替代外部证据包；缺少 `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` 时不得关闭 release gate。 |
| TC-COM-AI-005 | COM-SI-016 | FR-COM-AI-004 | COM-AI-SPEC-004 | AC-COM-AI-004 | COM-AI-TR-004 | COM-AI-GAP-004 | integration | automated | `backend/src/test/java/com/speakeasy/AiCostDashboardTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiCostDashboardTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-ops-001-ai-cost-dashboard-tests` | Free/pro/premium usage, cache hit, provider error, budget warning, provider anomaly | 成本看板按套餐、用户 hash、provider、模型和状态聚合并暴露预算风险；OPS-only API 不暴露 raw user content。 |
| TC-COM-AI-006 | COM-SI-017 | FR-COM-AI-005 | COM-AI-SPEC-005 | AC-COM-AI-005 | COM-AI-TR-005 | COM-AI-GAP-005 | integration | automated | `backend/src/test/java/com/speakeasy/AiRetentionPolicyTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiRetentionPolicyTest test`; focused XCB-006 regression: `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AdminAuditControllerTest,AiRetentionPolicyTest test` | passed | `docs/reports/test_report.md#2026-06-01-p0-ai-sec-001-ai-retention-and-deletion-tests`; `docs/reports/test_report.md#2026-06-11-xcb-006-data-lifecycle-boundary-hardening` | Expired audio media and TTS cache retention fixtures; retention audit DB row and `/admin/audit` API projection fixtures | retention job 删除、匿名化或保留最小审计字段；审计证据以 JSON 形式保留安全聚合计数和 `evidence_ref`，不持久化或返回 raw audio、full transcript、provider payload、signed/upload URL。 |
| TC-COM-AI-007 | COM-SI-017 | FR-COM-AI-005 | COM-AI-SPEC-005 | AC-COM-AI-005 | COM-AI-TR-005 | COM-AI-GAP-005 | integration | automated | `backend/src/test/java/com/speakeasy/AiAccountDeletionMediaCleanupTest.java` | `cd backend && JAVA_HOME=/opt/homebrew/opt/openjdk@17 mvn -q -Dmaven.repo.local=.m2/repository -Dtest=AiAccountDeletionMediaCleanupTest test` | passed | `docs/reports/test_report.md#2026-06-02-p0-ai-external-gate-recheck-and-tts-cache-multi-owner-tests` | Account with audio refs, shared TTS cache owner refs and AI provider metrics | 账号删除覆盖 AI 媒体、TTS cache owner ref 移除、最后 owner 删除 cache、provider-derived metric cleanup 和脱敏审计证据。 |

## External Release Evidence Overlay
| Evidence gate | AC | TC IDs | Checklist / script | Strict command | Required ref | Current release status |
| --- | --- | --- | --- | --- | --- | --- |
| DashScope provider matrix | AC-COM-AI-003 | TC-COM-AI-004 | `tests/commercial/ai_provider_sandbox_matrix.md`; `tests/commercial/ai_external_release_evidence_checklist.md`; `scripts/check_ai_provider_sandbox_evidence.py`; `scripts/check_ai_external_release_evidence.py` | `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external`; `python3 scripts/check_ai_external_release_evidence.py --strict-external` | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` | external-pending |
| Object storage and signed media ref lifecycle | AC-COM-AI-001, AC-COM-AI-005 | TC-COM-AI-001, TC-COM-AI-002, TC-COM-AI-006, TC-COM-AI-007, TC-COM-AI-008 | `tests/commercial/ai_external_release_evidence_checklist.md`; `scripts/check_ai_external_release_evidence.py` | `python3 scripts/check_ai_external_release_evidence.py --strict-external` | `AI_MEDIA_STORAGE_EVIDENCE_REF` | external-pending |
| AI cost dashboard and budget alert evidence | AC-COM-AI-004 | TC-COM-AI-005 | `tests/commercial/ai_external_release_evidence_checklist.md`; `scripts/check_ai_external_release_evidence.py` | `python3 scripts/check_ai_external_release_evidence.py --strict-external` | `AI_COST_DASHBOARD_EVIDENCE_REF` | external-pending |
| Retention policy approval and deletion proof | AC-COM-AI-005 | TC-COM-AI-006, TC-COM-AI-007 | `tests/commercial/ai_external_release_evidence_checklist.md`; `scripts/check_ai_external_release_evidence.py` | `python3 scripts/check_ai_external_release_evidence.py --strict-external` | `AI_RETENTION_POLICY_EVIDENCE_REF` | external-pending |

## Gate Result
- AC-to-TC mapping: pass. `AC-COM-AI-001` through `AC-COM-AI-005` all map to one or more stable TC IDs.
- Implementation/QA status: TC-COM-AI-001 through TC-COM-AI-003 and TC-COM-AI-005 through TC-COM-AI-008 have local automated evidence；TC-COM-AI-004 has local backend endpoint evidence, structural evidence gate plus a repeatable sanitized controlled-live evidence-prep report.
- External/manual exceptions: DashScope、object storage、cost dashboard and retention/deletion still require externally stored evidence packages, four evidence refs and independent reviews before paid AI release closure.

## Handoff Notes
- TC-COM-AI IDs are stable and must not be merged into TC-COM-001..023.
- This increment closes the production AI provider residual only after code, tests, live evidence, implementation report and quality report are updated.
