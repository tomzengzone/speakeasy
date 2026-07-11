# Increment Definition：P0.1 表达自动化训练 Agent

## 状态
Implementation-review ready - active increment definition with production-hardening remediation overlay。2026-06-04 P0.1 Product Base/production-hardening local implementation review and API drift sync passed；PM Product Base merge approval and P0 commercial / paid AI external gates remain separate；不得新增 stage。

## Increment ID
`p0-1-expression-automation-training`

## Active Stage
`docs/product/stages/p0-1-expression-automation.md`

## Primary Capability
- Capability ID：`CAP-TRAIN`
- Sub-capability ID：`CAP-TRAIN-03`

## Affected Capabilities
- Capability IDs：`CAP-PRACTICE`、`CAP-CONTENT`、`CAP-MEMORY`、`CAP-COACH`
- Sub-capability IDs：`CAP-TRAIN-02`、`CAP-TRAIN-04`、`CAP-TRAIN-05`、`CAP-TRAIN-06`、`CAP-PRACTICE-01`、`CAP-PRACTICE-02`、`CAP-PRACTICE-03`、`CAP-CONTENT-03`、`CAP-MEMORY-02`、`CAP-COACH-02`、`CAP-COACH-03`、`CAP-COACH-05`

## 上游决策
- `docs/process/change_request.md`：`CR-20260523-001 表达自动化训练 Agent`
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- `docs/product/feature_registry.md`

## Scope
- 在两个现有官方场景中，把现有语音场景模拟升级为训练型 Agent。
- 定义 action chain：开场、说明目的、表达观点、回应追问、确认下一步、结束。
- 定义 micro-action：听一句、选一个、回一句、跟一句、补一句、在追问下继续说。
- 定义 session 内训练 planner：选择当前动作、目标表达、提示等级、重试、降级、升级和轻量施压。
- 定义 hint ladder：无提示、句框、选项、chunk shadowing、model-then-retry。
- 定义 in-session pressure check：连续通过后减少提示并进入轻量追问。
- 语音为主路径，文本为 ASR 失败、麦克风拒绝或调试兜底。
- 训练结束写回学习证据：掌握、薄弱、复习、个人素材、下一步建议。
- 商业软件整改覆盖同一 P0.1 stage：实现或明确阻断后端 Training API、服务端训练事实源、学习证据 rule trace、版本化训练内容、真实 media/AI pipeline、planner decision audit、训练运营指标和 rollout/release gates。

## Covered Stage Scope Items
| Stage Scope ID | Coverage note |
| --- | --- |
| P01-SI-001 | 通过 `P01-FR-001` 覆盖两个现有官方场景入口和恢复边界。 |
| P01-SI-002 | 通过 `P01-FR-004` 覆盖 session planner 决策。 |
| P01-SI-003 | 通过 `P01-FR-002` 覆盖 action chain。 |
| P01-SI-004 | 通过 `P01-FR-003` 覆盖 micro-action flow。 |
| P01-SI-005 | 通过 `P01-FR-005` 覆盖 hint ladder。 |
| P01-SI-006 | 通过 `P01-FR-008` 覆盖 in-session pressure check。 |
| P01-SI-007 | 通过 `P01-FR-006` 覆盖语音主路径与文本兜底。 |
| P01-SI-008 | 通过 `P01-FR-007` 覆盖即时反馈与评分边界。 |
| P01-SI-009 | 通过 `P01-FR-009` 覆盖学习证据写回。 |
| P01-SI-010 | 通过非目标和 `AC-P01-012` 覆盖 P0.1 范围边界守护。 |
| P01-SI-011 | 通过 `P01-FR-010` 覆盖可恢复失败。 |

## Excluded Stage Scope Items
- 无。本 increment 是 P0.1 当前唯一 planned increment，覆盖 P0.1 stage 的全部 required Stage Scope Items。

## Uncovered Required Stage Scope Items
- 无。下游契约、实现和测试缺口记录在 `docs/product/increments/p0-1-expression-automation-training/traceability.md`。

## Non-goals
- 不新增第三个官方场景。
- 不实现任意场景生成。
- 不实现完整 A1-C2 内容体系。
- 不实现跨 session/跨天长期调度。
- 不实现完整 L0-L5 掌握阶梯。
- 不把笔记本、完整评分产品化或商业权益 gating 纳入 P0.1 阻塞范围。

## Required Artifacts
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`
- `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- `docs/product/increments/p0-1-expression-automation-training/traceability.md`
- 必要时更新 `docs/domain/`、`docs/architecture/`、`docs/ai_runtime/`、`docs/ux/`
- 实现完成后更新 `docs/reports/implementation_report.md` 和质量/测试报告

## 2026-06-03 PM 下一步执行批次
TC-P01-013 和 TC-P01-014 已经本地关闭；本增量下一步不是继续扩大训练功能，而是进行 Product Base 合入复核。

| Order | Work Package ID | Route / Owner | Scope | Stage Scope Items | Required output | Gate / checker |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | P01-PM-ACCEPT-001 | Product Manager | 复核 P0.1 traceability、test report、quality report 和非目标边界 | P01-SI-001..011 | PM acceptance finding in `docs/product/development_status.md` | Product Object Governance Check |
| 2 | P01-GOV-001 | Product Object Governance Check | 独立确认 P01-SI-001..011 均由本 increment 覆盖，且未把 P0.2/P1/P2 范围误记为完成 | P01-SI-001..011 | checker finding | Documentation Governance as needed |
| 3 | P01-BASE-001 | Product Manager / Requirement Development | 若复核通过，将已验证 session 内训练能力合入 `docs/product/base/` | P01-SI-001..011 | Product Base requirements/spec/acceptance/traceability updates | PM approval |
| 4 | P01-REG-001 | Product Manager | 确认 `CAP-TRAIN` / `CAP-TRAIN-03` 分类，并保留 paid AI voice residual 指向 `commercial-ai-provider-hardening` | P01-SI-007, P01-SI-008, P01-SI-011 | Increment definition classification update | Product Object Governance Check |

合入范围只允许覆盖两个官方场景中的 session 内训练 planner、action chain、micro-action、hint ladder、pressure check、语音主路径/文本兜底、反馈边界、学习证据写回和可恢复失败。跨 session/跨天调度、完整 L0-L5、笔记本、完整评分产品化、场景包扩展和商业权益 gating 均不进入本次 Product Base 合入。

## 2026-06-03 商业软件整改执行批次
本批次不新增 stage、不新增 increment、不扩大到 P0.2/P1/P2；它只把已验证的 P0.1 session 内训练能力从 local-first demo hardening 为可被商业软件接受的后端事实源、可审计证据、可运营训练能力。

| Order | Work Package ID | Route / Owner | Scope | Stage Scope Items | Required output | Gate / checker |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | P01-HARDEN-001 | Product Manager / Requirement Development / System Architect | 决定并落实 `/training/sessions...` OpenAPI 与后端实现的一致性；未实现时不得把 API 当作可用能力 | P01-SI-001, P01-SI-002, P01-SI-004, P01-SI-011 | requirements/spec/API contract/traceability updates | Product Object Governance Check |
| 2 | P01-HARDEN-002 | Domain / Backend / Security | 将 TrainingSession、TrainingTurn、PlannerDecision、TrainingRecap、LearningEvidenceCandidate 和 rule trace 纳入服务端事实源与账号删除/retention 边界 | P01-SI-002, P01-SI-009, P01-SI-011 | domain model and test case updates | QA + Security review |
| 3 | P01-HARDEN-003 | Product / Backend / Content | 把本地 action chain 常量升级为版本化训练内容映射，仍只覆盖两个官方场景 | P01-SI-001, P01-SI-003, P01-SI-004, P01-SI-010 | content versioning contract and migration plan | Product Object Governance Check |
| 4 | P01-HARDEN-004 | Backend / AI Runtime / Frontend | 将训练 turn 接入 media upload、可信 `audio_ref`、ASR/TTS/LLM gateway、schema validator 和 fallback | P01-SI-007, P01-SI-008, P01-SI-011 | backend/frontend/API integration design and tests | QA + AI Runtime review |
| 5 | P01-HARDEN-005 | Backend / AI Runtime | 将 planner 抽成可回放、可配置、可审计的 deterministic domain service；LLM 仍只能给候选 | P01-SI-002, P01-SI-005, P01-SI-006, P01-SI-008, P01-SI-010 | planner decision audit contract and tests | QA |
| 6 | P01-HARDEN-006 | Ops / Backend / Product | 增加训练 funnel、fallback、hint、pressure、evidence、provider cost 运营指标和 rollout controls | P01-SI-007, P01-SI-008, P01-SI-009, P01-SI-011 | observability/release gate requirements and tests | Ops + QA |
| 7 | P01-HARDEN-007 | QA / Product Object Governance Check | 为以上整改补齐 AC-to-TC、traceability、报告和 Product Base 合入前验收口径 | P01-SI-001..011 | updated acceptance/test_cases/traceability and PM acceptance readiness finding | Product Object Governance Check |

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent，随后由 Product Manager Agent 复审整体产品一致性。
