# Increment Definition：P0.1 表达自动化训练 Agent

## 状态
Draft - active increment definition。

## Increment ID
`p0-1-expression-automation-training`

## Active Stage
`docs/product/stages/p0-1-expression-automation.md`

## Primary Feature
`expression-automation-training`

## Affected Features
- `voice-scenario-practice`
- `official-scenario-library`
- `listening-shadowing`
- `expression-practice-queue`
- `learning-memory-review`
- `scoring-feedback`

## 上游决策
- `docs/process/change_request.md`：`CR-20260523-001 表达自动化训练 Agent`
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- `docs/product/feature_registry.md`
- `docs/product/features/mvp-learning-loop-spec.md`：legacy P0.1 spec source，已作为本 increment requirements/spec/acceptance/traceability 的迁移来源。

## Scope
- 在两个现有官方场景中，把现有语音场景模拟升级为训练型 Agent。
- 定义 action chain：开场、说明目的、表达观点、回应追问、确认下一步、结束。
- 定义 micro-action：听一句、选一个、回一句、跟一句、补一句、在追问下继续说。
- 定义 session 内训练 planner：选择当前动作、目标表达、提示等级、重试、降级、升级和轻量施压。
- 定义 hint ladder：无提示、句框、选项、chunk shadowing、model-then-retry。
- 定义 in-session pressure check：连续通过后减少提示并进入轻量追问。
- 语音为主路径，文本为 ASR 失败、麦克风拒绝或调试兜底。
- 训练结束写回学习证据：掌握、薄弱、复习、个人素材、下一步建议。

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
| 4 | P01-REG-001 | Product Manager | 更新 `expression-automation-training` feature 状态，并保留 paid AI voice residual 指向 `commercial-ai-provider-hardening` | P01-SI-007, P01-SI-008, P01-SI-011 | `docs/product/feature_registry.md` update | Product Object Governance Check |

合入范围只允许覆盖两个官方场景中的 session 内训练 planner、action chain、micro-action、hint ladder、pressure check、语音主路径/文本兜底、反馈边界、学习证据写回和可恢复失败。跨 session/跨天调度、完整 L0-L5、笔记本、完整评分产品化、场景包扩展和商业权益 gating 均不进入本次 Product Base 合入。

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent，随后由 Product Manager Agent 复审整体产品一致性。
