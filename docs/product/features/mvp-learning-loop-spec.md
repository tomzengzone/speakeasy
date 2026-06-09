# P0.1 表达自动化训练闭环 Feature Spec

## 文档状态
Legacy P0.1 spec source - 本文是 P0.1 表达自动化训练闭环的早期 feature spec 来源，不是当前 MVP Product Base spec。

当前稳定 Product Base source of truth：
- `docs/product/base/spec.md`
- `docs/product/base/requirements.md`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`

当前 P0.1 increment source of truth：
- `docs/product/increments/p0-1-expression-automation-training/spec.md`
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- `docs/product/increments/p0-1-expression-automation-training/traceability.md`

本文只作为 P0.1 legacy spec source 和历史参考保留。不得整份作为 MVP Product Base spec 迁移来源。

## 状态
Draft - P0.1 feature spec，供后续 acceptance criteria、AI runtime schema、dialogue state machine、domain model、screen spec 和测试用例使用。

## 上游依据
- `docs/product/roadmap.md`：Now / P0.1 表达自动化训练闭环。
- `docs/product/development_status.md`：P0.1 范围已收紧为 session 内训练接管。
- `docs/product/feature_backlog.md`：P0.1 backlog 条目。
- `docs/process/change_request.md`：`CR-20260523-001 表达自动化训练 Agent`。
- `docs/product/features/mvp-learning-loop-requirements.md`：当前 MVP 代码基线需求。
- 当前代码能力：`lib/features/interview/interview_practice_page.dart`、`lib/features/interview/interview_engine.dart`、`lib/features/interview/interview_llm_scheduler.dart`、`lib/features/interview/interview_expression_learning_page.dart`、`lib/features/interview/interview_wiki_store.dart`、`lib/services/audio_service.dart`、`lib/services/voice_chat_service.dart`；本地 oral assessment provider 服务已退役，生产发音评分必须走 trusted upload + Backend AI Gateway。
- 当前内容资产：`assets/data/interview_scene_catalog.json`、`assets/data/interview_scene_wikis/job_interview.json`、`assets/data/interview_scene_wikis/onboarding_introduction.json`。

## 功能目标
把现有语音场景模拟升级为训练型 Agent：用户只完成听一句、选一个、回一句、跟一句、补一句、在追问下继续说等小动作；agent 在 session 内接管训练组织、节奏控制、难度拆解、重复推进、即时反馈和轻量场景施压，帮助用户把目标表达练到可在场景中自然说出。

## 用户价值
- 学习者不需要自己决定当前练什么、怎么练、错了怎么重试或什么时候进入下一步。
- 学习者每次只面对一个小动作，降低开始和重复练习的阻力。
- 学习者能通过语音主路径得到即时表达反馈、基础发音反馈和下一步训练动作。
- 学习证据能写回现有首页、推荐表达、个人 Wiki 或 session summary 的后续入口。

## 范围
- 只覆盖两个现有官方场景：`job_interview` 和 `onboarding_introduction`。
- 每个场景按 action chain 组织：开场、说明目的、表达观点、回应追问、确认下一步、结束。
- 支持 FSI 思路的 micro-drill：模仿、替换、转换、回忆、场景回答、压力检测。
- 支持 micro-action flow：听一句、选一个、回一句、跟一句、补一句、在追问下继续说。
- 支持 session 内训练 planner：决定当前小动作、目标表达、提示等级、重试、降级、升级或轻量施压。
- 支持 hint ladder：无提示、句框、选项、chunk shadowing、model-then-retry。
- 支持 in-session pressure check：用户连续通过后减少提示，并进入轻量追问或近场景复现。
- 语音作为主路径；文本只作为 ASR 失败、麦克风拒绝或调试兜底。
- 发音评分进入反馈，但不作为唯一通关条件；表达完成度和场景任务完成度是主指标。
- 每轮训练写回学习证据：掌握、薄弱、复习、个人素材、下一步建议。

## 非目标
- 不新增第三个官方场景。
- 不承诺任意场景生成或用户自定义公开场景。
- 不实现完整 A1/A2/B1/B2/C1/C2 内容体系。
- 不实现跨 session、跨天、跨场景的长期训练调度。
- 不实现完整 L0-L5 掌握阶梯；P0.1 只写回可追踪学习证据。
- 不把任意短语/单词查询和笔记本产品化放入 P0.1。
- 不把完整评分体系、学习报告或商业权益 gating 作为 P0.1 阻塞项。
- 不允许 LLM 直接决定持久化掌握状态的最终变更。

## 假设与依赖
- 现有 TTS、录音、文本类评分和 LLM 教练反馈链路可复用；生产 ASR/发音评分必须等待 trusted upload + Backend AI Gateway，不得复用本地文件或文本派生评分。
- 官方场景资产能够提供目标表达、等级轨道和示范对话；缺失的 action chain 标注可先通过本地映射补齐。
- 外部 ASR、TTS、LLM 或评分服务不可用时，P0.1 必须可降级并保留用户可恢复路径。
- P0.1 的学习证据本地优先写回；是否同步云端由后续 API/domain contract 决定。

## 核心对象
| 对象 | P0.1 含义 |
| --- | --- |
| TrainingSession | 一次训练型 Agent session，绑定用户、场景、等级和 action chain 进度。 |
| ActionChainStep | 场景动作链中的一个沟通动作，例如开场或回应追问。 |
| TargetExpression | 当前步骤要自动化的目标表达或表达簇。 |
| MicroAction | 用户当前只需完成的最小动作。 |
| HintLevel | 当前提示等级，控制无提示、句框、选项、chunk shadowing、model-then-retry。 |
| PressureCheck | session 内轻量压力检测，不等同于长期掌握等级。 |
| LearningEvidence | 本轮产生的掌握、薄弱、复习、个人素材和下一步建议。 |

## 用户流程
1. 用户从两个官方场景之一进入训练。
2. 系统根据场景、等级、action chain 和用户已有学习证据创建或恢复 TrainingSession。
3. Session planner 选择当前 ActionChainStep、TargetExpression、MicroAction 和 HintLevel。
4. Agent 展示或播放一个小动作任务，例如听一句、跟一句或补一句。
5. 用户优先语音作答；ASR 失败、麦克风拒绝或调试模式下可走文本兜底。
6. 系统给出即时反馈，包括表达完成度、场景任务完成度、必要时的发音反馈和更地道表达提示。
7. Planner 根据结果决定重试、降级提示、升级任务或进入轻量压力检测。
8. 用户连续通过后，系统减少提示并进行轻量追问或近场景复现。
9. 本轮结束后，系统写回 LearningEvidence，并展示 session recap 和下一步建议。

## 行为模块
| 模块 | P0.1 行为 |
| --- | --- |
| 教练 | 拆解当前目标，控制节奏，给出鼓励和纠错。 |
| 导演 | 把大场景拆成 action chain 和 micro-action。 |
| 对话搭子 | 以角色对话推进用户开口，而不是让用户孤立背句。 |
| 考官 | 在连续通过后减少提示并发起轻量追问。 |
| 记忆引擎 | 读取和写回 session 内学习证据，不做跨天长期调度。 |

## Planner 决策规则
- 输入：场景 id、等级、action chain 位置、目标表达、最近尝试结果、ASR 状态、评分信号、已有学习证据。
- 输出：下一个 MicroAction、目标表达、HintLevel、是否重试、是否降级、是否升级、是否进入 PressureCheck。
- 连续失败时必须提高支架：无提示 -> 句框 -> 选项 -> chunk shadowing -> model-then-retry。
- 连续通过时必须降低支架或进入轻量追问。
- ASR 失败不能直接判定用户不会；应提示重录或进入文本兜底。
- 发音低分不能单独阻断通关；需要结合表达完成度和场景任务完成度。

## Micro-action 规格
| MicroAction | 用户动作 | 通过信号 |
| --- | --- | --- |
| ListenOne | 听一句目标表达或场景提示 | 用户完成播放或确认继续。 |
| ChooseOne | 从选项中选择合适表达 | 选择匹配目标意图或可接受变体。 |
| SayOne | 回一句目标表达 | ASR/文本命中核心语义，表达完成度达标。 |
| ShadowOne | 跟一句或 chunk shadowing | 完整度和基础发音信号可用时达标；不可用时以完成和转写为主。 |
| FillOne | 补一句或补 chunk | 补全核心槽位，语义与场景匹配。 |
| ContinueUnderPrompt | 在追问下继续说 | 能在少提示或无提示下完成当前 action step 的核心任务。 |

## 状态与失败处理
- Loading：加载场景、表达、历史证据或音频资源。
- Ready：等待用户开始当前 micro-action。
- Listening：播放 TTS 或示范音频。
- Recording：录音中。
- Transcribing：语音转写中。
- Evaluating：表达、任务完成度和可用评分信号评估中。
- Feedback：展示即时反馈、重试建议和地道表达提示。
- Retry：按当前或更高 HintLevel 重试。
- PressureCheck：轻量追问或近场景复现。
- Recap：本轮总结和证据写回结果。
- RecoverableError：麦克风拒绝、ASR 失败、TTS 失败、LLM 失败、评分失败或本地写回失败时的可恢复错误。

## AI Runtime 影响
- 需要结构化输出当前 micro-action 的反馈、提示、重试建议、下一步建议和轻量追问建议。
- LLM 可以提出候选反馈和下一步建议，但 planner 必须由确定性规则裁决。
- LLM 不得直接写入最终掌握状态；持久化更新必须由应用层根据证据和规则执行。
- 后续需要独立 prompt contract 和 schema 校验，不在本 spec 内细化字段。

## 数据与领域影响
- 需要定义 TrainingSession、ActionChainStep、MicroAction、HintLevel、PressureCheck、LearningEvidence 的持久化或本地状态边界。
- 需要明确现有 scene wiki 中目标表达如何映射到 action chain。
- P0.1 只要求写回学习证据，不要求完整 L0-L5 状态。
- 后续 domain model 需要决定 session 状态本地优先还是 repository-backed。

## UI 影响
- 训练页需要呈现“当前只做一个动作”的任务状态。
- 需要显示当前目标、提示等级、重试/继续状态和即时反馈。
- 需要支持语音主路径的录音、取消、提交、重录、播放和错误恢复。
- 文本兜底只在 ASR 失败、麦克风拒绝或调试入口出现，不作为默认主路径。
- Recap 需要展示本轮完成、薄弱点、建议复习、个人素材和下一步。

## API 与服务影响
- 如果 P0.1 只本地持久化，不要求新增后端 API。
- 如果学习证据或 session 状态需要云端同步，必须先更新 API contract。
- 现有 ASR、TTS、LLM 和评分服务失败时不能阻断 session 退出或总结。

## 测试期望
- Planner 单元测试：覆盖重试、降级、升级、连续通过后压力检测、ASR 失败兜底。
- Hint ladder 单元测试：覆盖无提示到 model-then-retry 的升降级。
- Micro-action 测试：覆盖听、选、回、跟、补、追问继续说。
- Widget 测试：覆盖训练页状态切换、错误恢复、文本兜底入口和 recap。
- AI schema 测试：覆盖结构化反馈、提示、追问建议和无效输出降级。
- 回归测试：两个官方场景仍可进入，现有语音模拟、TTS、录音、转写、反馈和总结能力不退化。

## 可验收成功标准
- 用户能在两个官方场景中进入训练型 Agent session。
- 用户每一步只看到或听到一个明确 micro-action。
- Planner 能根据用户表现决定重试、提示升降级、升级或轻量压力检测。
- 连续通过后系统减少提示并进入轻量追问或近场景复现。
- ASR 失败、麦克风拒绝或服务失败时存在可恢复路径。
- 本轮结束后学习证据写回，并能进入后续首页、推荐表达、个人 Wiki 或 session summary 的至少一个入口。
- 发音评分可用时进入反馈，不可用时不阻断主训练闭环。

## 下游工件
- `docs/product/acceptance_criteria.md`：为 P0.1 新增独立 AC 或 P0.1 分节。
- `docs/domain/*.md`：补充训练 session、micro-action、hint level 和 evidence 模型。
- `docs/architecture/*.md`：补充 session planner 和现有 interview 模块边界。
- `docs/ai_runtime/prompt_contract.md`：定义结构化反馈和 planner 输入输出候选 schema。
- `docs/ux/screen_spec.md`：补充训练型 Agent 页面状态和交互。
- `test/` 或 `tests/`：补充 planner、schema、widget 和回归测试。

## 规格状态
本 spec 足以作为 P0.1 `acceptance-criteria-generate` 的直接上游输入；在生成 acceptance criteria 前，仍需 Development Orchestrator 确认下游文档路径和必需契约清单。
