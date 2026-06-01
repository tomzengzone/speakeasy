# Traceability：商业 AI Provider 生产化加固

## 状态
Draft - 需求、规格、验收和测试映射已规划；代码、测试执行、live evidence、实现报告和质量报告均未开始。

## 版本和状态管理
| 字段 | 值 |
| --- | --- |
| Traceability version | v0.1-planning |
| Last updated | 2026-06-01 |
| Owner | Product Manager Agent |
| Scope change | 新增 P0 AI provider 生产化加固 increment，用于承接 P01-GAP-008 release residual。 |
| Workflow state | Planning ready；等待 architecture/API/security/test gates。 |

## 上游
- Definition：`docs/product/increments/commercial-ai-provider-hardening/definition.md`
- Requirements：`docs/product/increments/commercial-ai-provider-hardening/requirements.md`
- Spec：`docs/product/increments/commercial-ai-provider-hardening/spec.md`
- Acceptance：`docs/product/increments/commercial-ai-provider-hardening/acceptance.md`
- Test cases：`docs/product/increments/commercial-ai-provider-hardening/test_cases.md`

## Full Traceability Matrix
| Traceability Row ID | Stage Scope ID | Increment ID | Requirement | Spec | Acceptance | Contract Evidence | Code Evidence | Test Evidence | Release Evidence | Status | Gap / notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| COM-AI-TR-001 | COM-SI-013 | commercial-ai-provider-hardening | FR-COM-AI-001 对象存储上传链路 | COM-AI-SPEC-001 | AC-COM-AI-001 | Required: API/Architecture/Security media upload contract | Pending | TC-COM-AI-001, TC-COM-AI-002 planned | Required before paid AI voice release | Planned | COM-AI-GAP-001 open |
| COM-AI-TR-002 | COM-SI-014 | commercial-ai-provider-hardening | FR-COM-AI-002 持久化 TTS 媒体缓存 | COM-AI-SPEC-002 | AC-COM-AI-002 | Required: cache domain/API/storage contract | Pending | TC-COM-AI-003 planned | Required before paid AI scale | Planned | COM-AI-GAP-002 open |
| COM-AI-TR-003 | COM-SI-015 | commercial-ai-provider-hardening | FR-COM-AI-003 真实 DashScope sandbox / controlled live 测试 | COM-AI-SPEC-003 | AC-COM-AI-003 | Required: AI runtime eval and evidence matrix | Pending | TC-COM-AI-004 external planned | DashScope evidence ref required | External pending | COM-AI-GAP-003 open |
| COM-AI-TR-004 | COM-SI-016 | commercial-ai-provider-hardening | FR-COM-AI-004 AI 成本看板 | COM-AI-SPEC-004 | AC-COM-AI-004 | Required: ops dashboard metric contract | Pending | TC-COM-AI-005 planned | Budget/margin gate required | Planned | COM-AI-GAP-004 open |
| COM-AI-TR-005 | COM-SI-017 | commercial-ai-provider-hardening | FR-COM-AI-005 生产级 AI 数据策略 | COM-AI-SPEC-005 | AC-COM-AI-005 | Required: security/data retention contract | Pending | TC-COM-AI-006, TC-COM-AI-007 planned | Privacy/store evidence required | Planned | COM-AI-GAP-005 open |

## Gap Register
| Gap ID | Gap | Affected traceability rows | Owner / next route | Status |
| --- | --- | --- | --- | --- |
| COM-AI-GAP-001 | Flutter-to-backend/object-storage media upload and trusted `audio_ref` lifecycle not implemented. | COM-AI-TR-001 | Backend / System Architect | Open |
| COM-AI-GAP-002 | TTS cache is process-local only; no persistent cache metadata, object storage, expiry or delete hook. | COM-AI-TR-002 | Backend / Security | Open |
| COM-AI-GAP-003 | No real DashScope LLM/ASR/TTS sandbox or controlled live evidence. | COM-AI-TR-003 | QA / AI Runtime / DevOps | Open / external |
| COM-AI-GAP-004 | No PM/Ops cost dashboard for provider cost, cache hit, plan margin or budget alerts. | COM-AI-TR-004 | Ops / Backend / PM | Open |
| COM-AI-GAP-005 | Production AI data retention/deletion policy and execution evidence incomplete for audio, transcripts, provider payload and cache. | COM-AI-TR-005 | Security / Backend / PM | Open |

## Required Downstream Evidence
- Domain Schema：MediaAsset、TtsCacheEntry、ProviderInvocationMetric、ProviderSandboxRun、RetentionPolicy。
- API Contract：media upload/signing、cost dashboard read、admin provider evidence status。
- Architecture / Security：object storage, signed URL TTL, KMS, retention/deletion, logs and no raw sensitive payload。
- AI Runtime：DashScope sandbox/eval matrix and fallback compatibility evidence。
- QA / Test Plan：TC-COM-AI-001 through TC-COM-AI-007 execution evidence。
- DevOps / Release：storage lifecycle, budget alert, provider evidence refs and retention job schedule。
- Implementation Report：must be updated after implementation starts。
- Test Report：must record execution commands, results and external evidence refs。
- Quality Report：must record independent review before release gate closure。
