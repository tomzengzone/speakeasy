# P0.1 Increment Spec：表达自动化训练 Agent

## 状态
Draft - 可作为 P0.1 acceptance criteria 的直接上游输入。

## 上游引用
- Increment definition: `docs/product/increments/p0-1-expression-automation-training/definition.md`
- Increment requirements: `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- Product Base: `docs/product/base/requirements.md`, `docs/product/base/spec.md`, `docs/product/base/acceptance.md`, `docs/product/base/traceability.md`
- Feature registry: `docs/product/feature_registry.md`
- Change request: `docs/process/change_request.md`
- Legacy source: `docs/product/features/mvp-learning-loop-spec.md`

## Product Object
- Active stage: P0.1 表达自动化训练闭环
- Primary feature: `expression-automation-training`
- Affected features: `voice-scenario-practice`, `official-scenario-library`, `listening-shadowing`, `expression-practice-queue`, `learning-memory-review`, `scoring-feedback`

## Spec Trace IDs
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| P01-SPEC-001 | P01-SI-001 | P01-FR-001 | Inputs, State Model `Loading` / `Ready`, official scene entry assumptions |
| P01-SPEC-002 | P01-SI-003 | P01-FR-002 | Inputs `actionChainStep`, State Model, Planner Rules |
| P01-SPEC-003 | P01-SI-004 | P01-FR-003 | Micro-action Contract |
| P01-SPEC-004 | P01-SI-002 | P01-FR-004 | Planner Rules, State Model transitions |
| P01-SPEC-005 | P01-SI-005 | P01-FR-005 | Planner Rules, hint level transitions |
| P01-SPEC-006 | P01-SI-007 | P01-FR-006 | Inputs `asrStatus`, Micro-action Contract fallback, Failure Handling |
| P01-SPEC-007 | P01-SI-008 | P01-FR-007 | Outputs, Planner Rules, Module Impact |
| P01-SPEC-008 | P01-SI-006 | P01-FR-008 | State Model `PressureCheck`, Planner Rules |
| P01-SPEC-009 | P01-SI-009 | P01-FR-009 | State Model `Recap`, Outputs, Failure Handling |
| P01-SPEC-010 | P01-SI-011 | P01-FR-010 | State Model `RecoverableError`, Failure Handling |
| P01-SPEC-011 | P01-SI-010 | P0.1 非目标边界 | Non-goals |

## Goal
把现有语音场景模拟升级为训练型 Agent：系统在 session 内接管训练组织、节奏控制、难度拆解、重复推进、即时反馈和轻量场景施压，用户只完成可快速响应的小动作。

## Inputs
- `sceneId`: `job_interview` 或 `onboarding_introduction`
- `targetLevel`: 当前官方场景等级
- `actionChainStep`: 当前动作链位置
- `targetExpression`: 当前要自动化的表达或表达簇
- `microAction`: 当前用户小动作
- `hintLevel`: 当前提示等级
- `attemptResult`: 最近尝试结果
- `asrStatus`: 可用、失败、麦克风拒绝或无结果
- `scoreSignal`: 可用评分、低置信度评分或不可用
- `learningEvidence`: 既有掌握、薄弱、复习、个人素材或下一步建议

## Outputs
- 当前 micro-action 任务
- 目标表达和示范输入
- 提示、句框、选项、chunk shadowing 或 model-then-retry
- 即时反馈：表达完成度、场景任务完成度、地道表达建议、可用评分反馈
- Planner 决策：重试、降级、升级、轻量 pressure check、recap
- 本轮 learning evidence 写回结果

## State Model
| State | Meaning | Next states |
| --- | --- | --- |
| `Loading` | 加载场景、表达、历史证据或音频资源 | `Ready`, `RecoverableError` |
| `Ready` | 等待用户开始当前 micro-action | `Listening`, `Recording`, `Feedback` |
| `Listening` | 播放 TTS 或示范音频 | `Ready`, `RecoverableError` |
| `Recording` | 用户录音中 | `Transcribing`, `Ready`, `RecoverableError` |
| `Transcribing` | ASR/转写中 | `Evaluating`, `Retry`, `RecoverableError` |
| `Evaluating` | 评估表达、任务完成度和可用评分信号 | `Feedback`, `RecoverableError` |
| `Feedback` | 展示反馈、重试建议和地道表达提示 | `Retry`, `PressureCheck`, `Ready`, `Recap` |
| `Retry` | 按当前或更高 hint level 重试 | `Ready`, `Listening`, `Recording` |
| `PressureCheck` | 轻量追问或近场景复现 | `Recording`, `Feedback`, `Recap` |
| `Recap` | 展示总结并写回学习证据 | terminal |
| `RecoverableError` | 可恢复失败 | previous valid state, `Retry`, `Recap` |

## Planner Rules
- 连续失败时，hint level 必须按无提示 -> 句框 -> 选项 -> chunk shadowing -> model-then-retry 提升。
- 连续通过时，hint level 必须下降或进入 `PressureCheck`。
- ASR 失败不能直接判定表达失败；必须进入重录或文本兜底。
- 发音低分不能单独阻断通过；必须结合表达完成度和场景任务完成度。
- LLM 可以生成候选反馈和追问建议，但最终 planner 决策必须由应用层规则裁决。
- LLM 不得直接写入最终掌握状态。

## Micro-action Contract
| MicroAction | User action | Pass signal | Fallback |
| --- | --- | --- | --- |
| `ListenOne` | 听一句目标表达或场景提示 | 完成播放或确认继续 | TTS 失败时展示文本和可恢复错误 |
| `ChooseOne` | 从选项中选择合适表达 | 选择匹配目标意图或可接受变体 | 提供解释并进入重试 |
| `SayOne` | 说出一句目标表达 | 命中核心语义且任务完成度达标 | ASR 失败时重录或文本兜底 |
| `ShadowOne` | 跟一句或 chunk shadowing | 完整度和基础发音信号达标；不可用时以完成和转写为主 | model-then-retry |
| `FillOne` | 补一句或补 chunk | 补全核心槽位且语义匹配 | 句框或选项提示 |
| `ContinueUnderPrompt` | 在追问下继续说 | 在少提示或无提示下完成当前 action step | 降级到 SayOne 或 model-then-retry |

## Module Impact
| Area | Impact |
| --- | --- |
| Product | P0.1 increment，primary feature 为 `expression-automation-training` |
| Scenario content | 两个官方场景需要 action chain 映射 |
| Domain | 需要训练 session、action chain step、micro-action、hint level、pressure check、learning evidence 模型 |
| AI runtime | 需要结构化反馈、提示、重试、下一步建议和追问建议 schema |
| UX | 训练页需要呈现一个 micro-action、hint level、反馈、重试、pressure check 和 recap |
| API | 如果只本地持久化则无新增后端 API；如果云端同步，需要 API contract |
| Tests | 需要 planner、hint ladder、micro-action、AI schema、widget 和回归测试 |

## Failure Handling
- 场景或表达加载失败：展示可恢复错误，不进入空白训练页。
- 音频播放失败：展示文本备选和错误提示。
- 麦克风拒绝：提示授权或进入文本兜底。
- ASR 无结果：提示重录或进入文本兜底。
- LLM 失败：允许重试或给出 deterministic fallback。
- 评分失败：继续表达完成度和任务完成度反馈，不阻断。
- 本地写回失败：提示可恢复错误，并不得丢失当前 session recap。

## Required Downstream Artifacts
- Acceptance: `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- Traceability: `docs/product/increments/p0-1-expression-automation-training/traceability.md`
- Domain model update under `docs/domain/`
- AI runtime prompt/schema update under `docs/ai_runtime/`
- UX screen spec update under `docs/ux/`
- Test plan or test cases under `test/` and/or `docs/reports/test_report.md`

## Non-goals
- 不新增第三个官方场景。
- 不实现任意场景生成。
- 不实现跨 session/跨天长期调度。
- 不实现完整 L0-L5 掌握阶梯。
- 不产品化任意词句笔记本。
- 不把完整评分体系或商业权益 gating 作为 P0.1 阻塞项。

## Acceptance Readiness
本 spec 已满足 P0.1 acceptance generation 的上游要求：目标、范围、非目标、状态、输入、输出、失败路径、模块影响和测试期望均已明确。
