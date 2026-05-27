# P0.1 Traceability：表达自动化训练 Agent

## 状态
Draft - pre-implementation traceability。本文记录需求到验收、契约、代码证据和测试证据的链路状态；不新增需求，不替代验收标准。

## 上游链路
```text
docs/product/feature_registry.md
docs/product/baselines/current-mvp.md
docs/product/stages/p0-1-expression-automation.md
docs/product/increments/p0-1-expression-automation-training/definition.md
  -> docs/product/increments/p0-1-expression-automation-training/requirements.md
  -> docs/product/increments/p0-1-expression-automation-training/spec.md
  -> docs/product/increments/p0-1-expression-automation-training/acceptance.md
  -> docs/product/increments/p0-1-expression-automation-training/traceability.md
```

## Requirement -> Acceptance -> Evidence
| Requirement | Acceptance | Required contracts | Code Evidence | Test Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| P01-FR-001 官方场景入口 | AC-P01-001 | UX screen spec；必要时 routing/module boundary | 待实现：`lib/features/interview/interview_practice_page.dart` 或训练入口相关文件 | 待补：widget/route tests；回归测试两个官方场景入口 | Planned |
| P01-FR-002 Action chain | AC-P01-002 | Domain model；可能需要 scene content mapping | 待实现：action chain 映射和场景资产适配 | 待补：action chain mapping unit tests | Planned |
| P01-FR-003 Micro-action flow | AC-P01-003 | Domain model；UX screen spec | 待实现：micro-action 状态与页面展示 | 待补：micro-action state unit/widget tests | Planned |
| P01-FR-004 Session planner | AC-P01-004 | Architecture/module boundary；domain model | 待实现：session planner 或现有编排器扩展 | 待补：planner decision unit tests | Planned |
| P01-FR-005 Hint ladder | AC-P01-005 | Domain model；UX screen spec | 待实现：hint level 和支架化重试 | 待补：hint ladder unit/widget tests | Planned |
| P01-FR-006 语音主路径与文本兜底 | AC-P01-006, AC-P01-007 | UX screen spec；可能需要 API/service failure contract | 待实现：录音、重录、文本兜底入口复用或改造 | 待补：voice flow widget tests；ASR failure fallback tests | Planned |
| P01-FR-007 即时反馈与评分边界 | AC-P01-008 | AI runtime prompt/schema；domain model | 待实现：结构化反馈、评分边界和通过判定 | 待补：AI schema tests；feedback widget tests | Planned |
| P01-FR-008 In-session pressure check | AC-P01-009 | Domain model；planner rules | 待实现：连续通过计数、降支架和轻量追问 | 待补：pressure check planner tests | Planned |
| P01-FR-009 学习证据写回 | AC-P01-010 | Domain model；必要时 API contract | 待实现：LearningEvidence 写回和 recap 链接 | 待补：evidence write-back tests；recap widget tests | Planned |
| P01-FR-010 可恢复失败 | AC-P01-011 | UX screen spec；AI/API fallback strategy | 待实现：RecoverableError 状态和降级路径 | 待补：failure-state widget tests；service failure tests | Planned |
| P0.1 非目标边界 | AC-P01-012 | Product stage scope | 文档边界已存在：`docs/product/stages/p0-1-expression-automation.md` | 人工验收：检查未新增第三场景、任意场景、跨天调度、完整 L0-L5 承诺 | Planned boundary guard |

## Contract Gaps
| Contract | Status | Next owner |
| --- | --- | --- |
| Domain model for TrainingSession, ActionChainStep, MicroAction, HintLevel, PressureCheck, LearningEvidence | Missing | `domain-model-generate` |
| AI runtime prompt/schema for structured feedback, hint, retry, next action, pressure prompt | Missing | `prompt-contract-generate` |
| UX screen spec for training page states, fallback, recap | Missing | `screen-spec-generate` |
| Architecture/module boundary for planner and existing interview module | Missing | Architect / Development Orchestrator |
| API contract for cloud sync | Not required unless repository-backed persistence is chosen | Product Manager + API contract if needed |

## Completion Gate
P0.1 不得进入实现完成状态，除非：
- 每个 P01-FR 至少有一个 AC 覆盖。
- 每个 AC 有实现证据或明确处于 planned/pre-implementation 状态。
- 每个 AC 有自动化测试、人工验收、外部服务依赖或暂不可自动化说明。
- Domain/AI/UX/Architecture contract gaps 被补齐或明确不适用。
- 实现报告记录实际 changed files、validation commands、test gaps 和 residual risks。
