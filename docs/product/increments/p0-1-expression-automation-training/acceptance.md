# P0.1 Acceptance Criteria：表达自动化训练 Agent

## 状态
Draft - 基于 P0.1 increment spec 生成，供 QA、测试用例和实现计划使用。

## 上游来源
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`

## AC-P01-001 官方场景入口
- 给定用户打开 `job_interview` 或 `onboarding_introduction` 的当前等级，当用户进入训练入口时，必须进入训练型 Agent session。
- 给定用户打开非 P0.1 官方场景或不存在的场景 id，当用户尝试进入 P0.1 训练时，系统不得创建训练 session，并必须显示不可用或回退提示。
- 给定用户已存在同场景同等级未完成训练 session，当再次进入时，系统必须恢复可继续的训练状态。

## AC-P01-002 Action chain
- 给定用户进入 P0.1 session，系统必须能识别当前 action chain step。
- 给定当前 step 是开场、说明目的、表达观点、回应追问、确认下一步或结束，页面必须只呈现该 step 相关的训练任务。
- 给定场景资产缺少显式 action chain 标注，系统必须使用本地映射继续训练，不得把缺失标注暴露为不可恢复失败。

## AC-P01-003 Micro-action 单步训练
- 给定 session 已 ready，用户一次只能看到或听到一个主要 micro-action。
- 给定 micro-action 为听一句、选一个、回一句、跟一句、补一句或追问继续说，系统必须展示对应用户动作和完成入口。
- 给定用户完成当前 micro-action，系统必须进入评估、反馈、重试、下一个动作或 recap 中的一个明确状态。

## AC-P01-004 Session planner 决策
- 给定用户最近一次作答失败，planner 必须选择重试、提高 hint level 或 model-then-retry 中的至少一种。
- 给定用户连续通过，planner 必须降低提示、升级任务或进入 pressure check 中的至少一种。
- 给定 ASR 失败，planner 不得直接判定用户表达失败，必须提供重录或文本兜底。
- 给定评分不可用，planner 不得阻断 session 继续。

## AC-P01-005 Hint ladder
- 给定用户在无提示下连续失败，系统必须提供句框、选项、chunk shadowing 或 model-then-retry。
- 给定用户在高支架下通过，系统必须在后续任务中尝试降低支架或进入轻量追问。
- 给定 hint level 变化，页面必须让用户可见当前提示或支架内容。

## AC-P01-006 语音主路径
- 给定当前 micro-action 需要口语作答，页面必须提供录音、取消、提交和重录能力。
- 给定用户提交有效录音，系统必须转写并进入评估。
- 给定用户取消录音，系统必须丢弃当前录音并回到可作答状态。
- 给定用户语音消息可播放，页面必须支持播放；播放失败时必须展示可恢复错误。

## AC-P01-007 文本兜底
- 给定麦克风权限被拒绝，页面必须提示授权或提供文本兜底入口。
- 给定 ASR 连续失败，页面必须允许重录或文本兜底。
- 给定文本兜底可用，页面必须明确其为兜底路径，不得替代默认语音主路径。

## AC-P01-008 即时反馈
- 给定用户提交有效回答，页面必须展示表达完成度、场景任务完成度、重试建议或更地道表达提示中的核心反馈。
- 给定回答命中目标表达，系统必须能进入通过、升级或 pressure check。
- 给定回答暴露薄弱点，系统必须能进入重试、提高提示或记录薄弱证据。
- 给定发音评分可用，页面必须展示发音相关反馈；不可用时不得阻断表达反馈。

## AC-P01-009 In-session pressure check
- 给定用户连续通过，系统必须减少提示并进入轻量追问或近场景复现。
- 给定用户在 pressure check 中通过，系统必须允许进入下一个 step 或 recap。
- 给定用户在 pressure check 中失败，系统必须允许回到更高 hint level 的重试。
- P0.1 pressure check 不得展示或承诺跨天调度、跨场景复现或完整 L0-L5。

## AC-P01-010 Learning evidence 写回
- 给定 session 结束，系统必须写回掌握、薄弱、复习、个人素材或下一步建议中的至少一种。
- 给定写回成功，学习证据必须能进入首页、推荐表达、个人 Wiki 或 session recap 中的至少一个后续入口。
- 给定写回失败，系统必须展示可恢复错误，且不得丢失用户可见 recap。
- 给定 LLM 生成反馈，LLM 不得直接写入最终持久化掌握状态。

## AC-P01-011 可恢复失败
- 给定场景、表达、历史证据或音频资源加载失败，页面必须展示可恢复错误。
- 给定 TTS、ASR、LLM 或评分服务失败，用户必须能重试、降级、退出 session 或查看已可用结果。
- 给定服务失败发生在 recap 前，系统不得进入无反馈的死状态。

## AC-P01-012 P0.1 范围边界
- P0.1 不得新增第三个官方场景。
- P0.1 不得承诺任意场景生成或用户自定义公开场景。
- P0.1 不得把跨 session、跨天、跨场景长期调度验收为已完成。
- P0.1 不得把完整 L0-L5 掌握阶梯、完整笔记本、完整评分产品化或商业权益 gating 作为完成条件。
