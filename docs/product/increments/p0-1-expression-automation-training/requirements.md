# P0.1 Increment Requirements：表达自动化训练 Agent

## 状态
Draft - 从 legacy P0.1 spec 迁移生成，作为本 increment 的标准 requirements。

## Product Object
- Classification: `feature-increment`
- Increment: `p0-1-expression-automation-training`
- Active stage: `docs/product/stages/p0-1-expression-automation.md`
- Primary feature: `expression-automation-training`
- Affected features: `voice-scenario-practice`, `official-scenario-library`, `listening-shadowing`, `expression-practice-queue`, `learning-memory-review`, `scoring-feedback`

## 上游来源
- `docs/product/increments/p0-1-expression-automation-training/definition.md`
- `docs/product/baselines/current-mvp.md`
- `docs/product/feature_registry.md`
- `docs/process/change_request.md`
- Legacy source: `docs/product/features/mvp-learning-loop-spec.md`

## 用户目标
学习者在现有官方场景中不再面对开放式“大任务”，而是在训练型 Agent 引导下完成一个个小动作，通过语音优先、文本兜底的训练闭环，把目标表达练到能在场景中自然说出。

## 用户路径
1. 用户从 `job_interview` 或 `onboarding_introduction` 进入 P0.1 训练。
2. 系统按场景、等级、action chain 和已有学习证据创建或恢复训练 session。
3. Session planner 选择当前 action chain step、target expression、micro-action 和 hint level。
4. 用户只完成一个小动作：听一句、选一个、回一句、跟一句、补一句或在追问下继续说。
5. 用户优先语音作答；ASR 失败、麦克风拒绝或调试模式下可使用文本兜底。
6. 系统即时反馈表达完成度、场景任务完成度、必要的发音反馈和更地道表达建议。
7. Planner 根据表现决定重试、提示升级、任务升级或轻量压力检测。
8. 用户连续通过后，系统减少提示并进入轻量追问或近场景复现。
9. 本轮结束后，系统写回学习证据，并展示 recap 和下一步建议。

## Functional Requirements

### P01-FR-001 官方场景入口
- 系统必须只在 `job_interview` 和 `onboarding_introduction` 两个现有官方场景中启用 P0.1 训练。
- 用户必须能从当前官方场景和目标等级进入训练型 Agent session。
- 进入训练前必须保留当前 MVP 的场景选择、等级切换和会话恢复边界。

### P01-FR-002 Action chain
- 每个 P0.1 场景必须能映射到 action chain step：开场、说明目的、表达观点、回应追问、确认下一步、结束。
- 系统必须能在 session 中记录当前 action chain step。
- 缺失显式标注的场景资产，可以先使用本地映射补齐，但不得承诺新增官方场景内容。

### P01-FR-003 Micro-action flow
- 系统必须把训练拆成 micro-action：听一句、选一个、回一句、跟一句、补一句、在追问下继续说。
- 每次用户只应看到或听到一个主要动作。
- 每个 micro-action 必须有可判定的通过信号或重试路径。

### P01-FR-004 Session planner
- Planner 必须根据场景、等级、action chain、目标表达、最近尝试结果、ASR 状态、评分信号和学习证据选择下一步。
- Planner 必须输出 micro-action、target expression、hint level、是否重试、是否降级、是否升级、是否进入 pressure check。
- Planner 决策必须可测试，不能只依赖自由 LLM 对话。

### P01-FR-005 Hint ladder
- 系统必须支持从低到高的提示阶梯：无提示、句框、选项、chunk shadowing、model-then-retry。
- 用户连续失败时，系统必须提高支架或提供更明确的 model-then-retry。
- 用户连续通过时，系统必须降低支架或进入轻量压力检测。

### P01-FR-006 语音主路径与文本兜底
- 用户作答必须以语音为主路径，支持录音、取消、提交、重录和播放。
- ASR 失败、麦克风拒绝或调试模式下，系统必须提供文本兜底。
- 文本兜底不得成为默认主路径。

### P01-FR-007 即时反馈与评分边界
- 用户提交有效作答后，系统必须给出表达完成度、场景任务完成度和更地道表达建议中的核心反馈。
- 发音评分可用时必须进入反馈；不可用时不得阻断训练闭环。
- 发音低分不能单独决定用户不通过，必须结合表达完成度和场景任务完成度。

### P01-FR-008 In-session pressure check
- 用户连续通过后，系统必须减少提示。
- 系统必须进入轻量追问或近场景复现，以检测用户是否能在更少支架下说出目标表达。
- P0.1 的 pressure check 只限 session 内，不承诺跨天、跨场景或完整 L0-L5。

### P01-FR-009 学习证据写回
- 本轮训练结束后，系统必须写回掌握、薄弱、复习、个人素材或下一步建议中的至少一种学习证据。
- 写回结果必须能进入首页、推荐表达、个人 Wiki 或 session recap 的至少一个后续入口。
- LLM 不得直接拥有最终持久化掌握状态的变更权；持久化更新必须由应用规则执行。

### P01-FR-010 可恢复失败
- 场景、表达、历史证据、音频资源、TTS、ASR、LLM、评分或本地写回失败时，系统必须展示可恢复错误。
- ASR 失败不能直接判定用户不会，必须允许重录或文本兜底。
- 服务失败不得阻断用户退出 session 或查看已可用的 recap。

## 成功标准
- 用户能在两个官方场景中进入训练型 Agent session。
- 用户每一步只面对一个明确 micro-action。
- Planner 能根据用户表现选择重试、提示升降级、升级或轻量压力检测。
- 连续通过后，系统减少提示并进入轻量追问或近场景复现。
- ASR、麦克风或外部服务失败时存在可恢复路径。
- 本轮结束后学习证据写回，并能影响至少一个后续学习入口。

## 非目标
- 不新增第三个官方场景。
- 不实现任意场景生成或用户自定义公开场景。
- 不实现完整 A1/A2/B1/B2/C1/C2 内容体系。
- 不实现跨 session、跨天、跨场景的长期训练调度。
- 不实现完整 L0-L5 掌握阶梯。
- 不把任意短语/单词查询和笔记本产品化放入 P0.1。
- 不把完整评分体系、学习报告或商业权益 gating 作为 P0.1 阻塞项。

## 假设
- 当前 TTS、录音、ASR/转写、LLM 教练反馈和基础评分链路可复用。
- 官方场景资产已提供目标表达、等级轨道和示范对话。
- P0.1 学习证据本地优先写回；是否云端同步由后续 API/domain contract 决定。

## 开放问题
- P0.1 session 状态是否只本地持久化，还是需要 repository-backed 同步。
- action chain 映射先写在本地常量、场景资产扩展字段，还是独立内容 schema。
- 训练页是改造现有 `interview_practice_page`，还是拆出专门的 training session view。
