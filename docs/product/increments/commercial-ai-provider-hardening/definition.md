# Increment Definition：商业 AI Provider 生产化加固

## 状态
Draft - Product Manager planning accepted；本增量把 P0.1 DashScope provider adapter 的 release residual 提升为 P0 商业化发布阻塞规划项。尚未进入实现。

## Increment ID
`commercial-ai-provider-hardening`

## Active Stage
`docs/product/stages/p0-commercial-readiness.md`

## Primary Capability
- Capability ID：`CAP-PRACTICE`
- Sub-capability ID：`CAP-PRACTICE-03`

## Affected Capabilities
- Capability IDs：`CAP-COACH`、`CAP-TRAIN`、`CAP-COM`、`CAP-ACC`、`CAP-MEMORY`
- Sub-capability IDs：`CAP-PRACTICE-01`、`CAP-COACH-02`、`CAP-COACH-03`、`CAP-COACH-04`、`CAP-TRAIN-02`、`CAP-COM-03`、`CAP-ACC-03`、`CAP-ACC-04`、`CAP-MEMORY-02`

## 上游决策
- `docs/process/change_request.md`：`CR-20260601-002 商业 AI Provider 生产化加固`
- P0 商业化 stage：`docs/product/stages/p0-commercial-readiness.md`
- P0.1 provider adapter residual：`docs/product/increments/p0-1-expression-automation-training/traceability.md#P01-GAP-008`
- P0.1 backend provider test report：`docs/reports/test_report.md`

## Scope
- 建立 Flutter 录音上传到后端或对象存储的生产链路，由后端生成可信 `audio_ref`。
- 建立持久化 TTS 媒体缓存，支持多实例、重启、CDN/对象存储复用和删除策略。
- 执行真实 DashScope sandbox / controlled live evidence，覆盖 LLM、Paraformer ASR、TTS 的延迟、错误码、费用和音频格式兼容性。
- 建立 AI 成本看板，按套餐、用户、provider family、模型和调用状态统计成本、毛利和异常。
- 定义并实现生产级 AI 数据策略，覆盖音频、转写、provider payload、TTS cache、日志、账号注销和保留/删除证明。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| COM-SI-013 | 通过 `FR-COM-AI-001` 覆盖对象存储上传链路和可信 `audio_ref`。 |
| COM-SI-014 | 通过 `FR-COM-AI-002` 覆盖持久化 TTS 媒体缓存。 |
| COM-SI-015 | 通过 `FR-COM-AI-003` 覆盖真实 DashScope sandbox / controlled live provider evidence。 |
| COM-SI-016 | 通过 `FR-COM-AI-004` 覆盖 AI 成本看板和 unit economics。 |
| COM-SI-017 | 通过 `FR-COM-AI-005` 覆盖生产级 AI 数据保留、删除和日志策略。 |

## Stage Placement
| 优化项 | 推荐阶段 | 原因 |
| --- | --- | --- |
| 对象存储上传链路 | P0 release-blocking | 没有可信 `audio_ref`，真实 ASR 不能安全面向生产用户开放。 |
| 持久化 TTS 缓存 | P0 release-blocking minimum，P1 优化命中率和 CDN | 付费流量前需要控制重复生成成本；精细化策略可后续迭代。 |
| 真实 DashScope sandbox 测试 | P0 release-blocking | 本地 fake transport 不能证明真实 provider SLA、格式兼容和费用。 |
| 成本看板 | P0 minimum dashboard，P1 unit-economics analytics | P0 需要避免盲目开放付费 AI；P1 再做毛利预测、provider A/B 和定价优化。 |
| 生产级数据策略 | P0 release-blocking | 音频、转写和 provider payload 涉及敏感数据、账号删除和商店隐私披露。 |

## Non-goals
- 不替代 P0.1 训练 Agent 的 planner、micro-action、hint ladder 或 learning evidence 规则。
- 不新增第三方 provider 多路由、provider bidding 或实时语音 LiveKit 产品化；这些可进入 P1/P2。
- 不把现有本地 fake-provider 测试误记为真实 provider 通过证据。
- 不在本增量内承诺完整 BI 系统；P0 只要求最小可审计成本看板和 release gate。

## Required Product Artifacts
- `docs/product/increments/commercial-ai-provider-hardening/requirements.md`
- `docs/product/increments/commercial-ai-provider-hardening/spec.md`
- `docs/product/increments/commercial-ai-provider-hardening/acceptance.md`
- `docs/product/increments/commercial-ai-provider-hardening/test_cases.md`
- `docs/product/increments/commercial-ai-provider-hardening/traceability.md`

## Required Downstream Gates
- Domain Schema：MediaAsset、TtsCacheEntry、ProviderSandboxRun、AiCostMetric、RetentionPolicy。
- API Contract：media upload/signing、media access/ref resolution、admin/provider evidence、cost dashboard read API。
- Architecture / Security：对象存储、signed URL、cache invalidation、retention/deletion、provider evidence 和日志脱敏。
- AI Runtime：DashScope live eval cases、prompt/schema compatibility、provider error mapping、fallback decision。
- UX / Ops：用户不可见的生产链路；需要后台/ops 可见成本和 provider health。
- QA / Test Plan：上传、ASR、TTS cache、DashScope sandbox、成本看板、删除策略和 release gate 测试。
- DevOps / Release：对象存储 bucket、KMS/secret、CDN、DashScope sandbox evidence refs、预算告警和 retention job。

## PM 阶段开发计划
| Order | Work Package ID | Route / Owner | Scope | Stage Scope Items | Required output | Gate / checker |
| --- | --- | --- | --- | --- | --- | --- |
| 0 | P0-AI-PM-001 | Product Manager | 锁定 AI provider 生产化范围、阶段归属和 release residual 处理 | COM-SI-013..017 | 本 increment 文档链路 | Documentation Governance |
| 1 | P0-AI-ARCH-001 | System Architect / Security | 对象存储、signed media ref、TTS persistent cache、retention/deletion 和成本观测架构 | COM-SI-013,014,016,017 | architecture/security/API updates | document-traceability-check |
| 2 | P0-AI-BE-001 | Backend Agent | media upload/signing、ASR ref resolution、object store lifecycle | COM-SI-013 | backend code、migration、contract tests | Backend/API tests |
| 3 | P0-AI-BE-002 | Backend Agent | persistent TTS cache、cache metadata、expiry、delete hooks | COM-SI-014,017 | backend code、migration、cache tests | Backend/security review |
| 4 | P0-AI-QA-001 | QA / AI Runtime | DashScope sandbox matrix：LLM/ASR/TTS latency、errors、cost、format compatibility | COM-SI-015 | `tests/commercial/ai_provider_sandbox_matrix.md` evidence | AI runtime review |
| 5 | P0-AI-OPS-001 | Backend / Ops | AI cost dashboard、budget alerts、provider health and margin metrics | COM-SI-016 | dashboard/API/ops report | Ops review |
| 6 | P0-AI-SEC-001 | Security / Backend | production retention/deletion execution and proof for audio/transcript/provider cache | COM-SI-017 | retention policy, deletion tests, privacy evidence | Security review |
| 7 | P0-AI-REPORT-001 | Development Orchestrator | 汇总 test/implementation/quality/release evidence | COM-SI-013..017 | reports and traceability updates | PM release decision |

## 当前合法下一步
`P0-AI-ARCH-001` through `P0-AI-REPORT-001` 的本地实现、测试和报告链路已完成；2026-06-03 sanitized controlled-live LLM/TTS/ASR evidence-prep passed；2026-06-03 阿里云 OSS storage adapter、canonical object_ref、signed upload/read URL 和 forged object_ref regression 已在本 stage 内完成并通过本地测试。当前合法下一步是补齐 strict external evidence refs：`DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`、`AI_MEDIA_STORAGE_EVIDENCE_REF`、`AI_COST_DASHBOARD_EVIDENCE_REF`、`AI_RETENTION_POLICY_EVIDENCE_REF`，并通过独立审查后再考虑 paid AI voice release closure。

## 2026-06-03 PM 下一步执行批次
本增量当前不需要重新做 `P0-AI-ARCH-001` 或本地 fake-provider 测试；下一阶段必须把本地 evidence-prep 升级为可审查的 strict external evidence package。

| Order | Work Package ID | Route / Owner | Scope | Stage Scope Items | Required evidence | Gate / checker |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | P0-AI-EXT-001 | AI Runtime / QA / Product Manager | DashScope LLM/ASR/TTS sandbox 或 controlled-live 外部 evidence package | COM-SI-015 | `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF`，覆盖 latency、error、cost、format compatibility、fallback 和独立 reviewer 结论 | `python3 scripts/check_ai_provider_sandbox_evidence.py --strict-external`、AI Runtime review |
| 2 | P0-AI-STORAGE-001 | DevOps / Security | 对象存储 bucket、signed media ref、provider 可访问性和生命周期删除外部证据；本地 backend adapter 已完成 | COM-SI-013, COM-SI-017 | `AI_MEDIA_STORAGE_EVIDENCE_REF` | Security review、Documentation Governance |
| 3 | P0-AI-COST-001 | Backend / Ops / Product Manager | 最小 AI 成本看板、预算阈值、告警和套餐毛利风险证据 | COM-SI-016 | `AI_COST_DASHBOARD_EVIDENCE_REF` | Ops review、PM unit-economics approval |
| 4 | P0-AI-RETENTION-001 | Security / Backend / Product Manager | 音频、转写、provider payload、TTS cache、日志和账号注销删除策略批准与执行证据 | COM-SI-017 | `AI_RETENTION_POLICY_EVIDENCE_REF` | Security review、privacy/release review |
| 5 | P0-AI-QA-002 | QA / Product Object Governance Check | 汇总 strict AI evidence 并 rerun paid AI release gates | COM-SI-013..017 | `tests/commercial/ai_external_release_evidence_checklist.md`、`docs/reports/test_report.md`、`docs/reports/quality_report.md`、release checklist updates | `python3 scripts/check_ai_external_release_evidence.py --strict-external`、PM paid AI voice release decision |

PM 只在四类 external evidence refs 均可追踪、`python3 scripts/check_ai_external_release_evidence.py --strict-external` 和聚合 release gate 通过且独立审核完成后，才允许把 `P01-GAP-008` 从 Partial 推向 release closure。controlled-live local report 可作为 evidence-prep 输入，不能单独作为 paid AI voice release evidence。

## Dependency And Blocker Register
| Blocker ID | 阻塞内容 | 影响 | 解除条件 |
| --- | --- | --- | --- |
| P0-AI-BLOCK-001 | 对象存储 provider、bucket、签名密钥和访问策略未选型 | 不能实现生产 ASR upload/ref lifecycle | 架构决策和 secret/storage 配置可用 |
| P0-AI-BLOCK-002 | DashScope controlled-live evidence-prep 已通过，但完整外部 evidence package/ref 和独立审查缺失 | 不能关闭真实 provider release evidence | 提供 `DASHSCOPE_AI_SANDBOX_EVIDENCE_REF` 并通过独立审查 |
| P0-AI-BLOCK-003 | 成本单价、套餐成本预算和毛利阈值未定义 | 成本看板无法判断盈亏 | PM/Ops 定义最小 unit economics 指标 |
| P0-AI-BLOCK-004 | 生产 retention/deletion 策略未批准 | 不能声明隐私/合规 ready | Security/PM 批准策略并提供执行测试 |

## Owner Agent
Product Manager Agent

## Checker Agent
Documentation Governance；Product Object Governance Check；后续实现阶段还需要 QA、Security、AI Runtime 和 Ops 独立审查。
