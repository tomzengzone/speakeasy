# Usability Checklist

- [ ] User can identify the next action within 3 seconds.
- [ ] Primary action is visually clear.
- [ ] Loading state explains what is happening.
- [ ] Error state preserves user input.
- [ ] Feedback is no longer than needed.
- [ ] Correction tone is supportive and specific.
- [ ] Mobile layout avoids dense text blocks.
- [ ] Saved or completed state is visible immediately.
- [ ] Empty state includes a useful next step.
- [ ] MVP scope does not introduce hidden workflows.

- [ ] 用户能在 3 秒内识别下一步动作。
- [ ] 主操作在视觉上足够清晰。
- [ ] 加载状态会说明当前正在发生什么。
- [ ] 错误状态会保留用户输入。
- [ ] 反馈长度不超过必要信息量。
- [ ] 纠错语气保持支持性且具体。
- [ ] 移动端布局避免密集大段文字。
- [ ] 保存或完成状态会立即可见。
- [ ] 空状态包含有用的下一步。
- [ ] MVP 范围不会引入隐藏工作流。

## P0 Commercial

- [ ] Membership page shows server entitlement state and does not rely on local `memberPlan` as final truth.
- [ ] Purchase, restore, empty restore, invalid receipt, and provider unavailable states each have a clear next action.
- [ ] Paywall and protected feature entry use the same gating result for scenario list, scenario detail, training entry, AI feedback, and reports.
- [ ] Expired, refunded, revoked, grace-period, and quota-exhausted states are visually distinct.
- [ ] Account deletion confirmation explains cloud deletion/anonymization and local cleanup before the destructive action.
- [ ] Commercial copy matches store metadata, privacy copy, and actual implemented entitlement rules.

- [ ] 会员页展示服务端权益状态，不把本地 `memberPlan` 当作最终事实。
- [ ] 购买、恢复购买、空恢复、无效票据和供应商不可用状态都提供清晰的下一步。
- [ ] 付费墙和受保护功能入口在场景列表、场景详情、训练入口、AI 反馈和报告中使用同一门控结果。
- [ ] 过期、退款、撤销、宽限期和额度用尽状态在视觉上可区分。
- [ ] 账号删除确认在破坏性操作前说明云端删除或匿名化，以及本地清理规则。
- [ ] 商业文案与商店元数据、隐私文案和实际实现的权益规则一致。

## P0.1 Expression Automation Training

- [ ] The learner sees exactly one primary micro-action in the active training panel.
- [ ] The current action chain step is visible but does not crowd the main action.
- [ ] Voice answer controls include record, cancel, submit and re-record states.
- [ ] Text fallback appears only after mic denial, ASR failure or debug mode.
- [ ] Hint level changes are visible through concrete support: sentence frame, options, chunk shadowing or model-then-retry.
- [ ] Feedback names one main issue and one next action.
- [ ] Pronunciation unavailable state does not block progress.
- [ ] Pressure check is visually distinct from normal retry and stays session-only.
- [ ] Recoverable error preserves user input or recap where possible.
- [ ] Recap stays available even when learning evidence write-back is retryable.
- [ ] P0.1 screens do not show third-scene creation, arbitrary scene generation, cross-day schedule, full L0-L5 mastery or commercial gating as completion conditions.

- [ ] 学习者在当前训练面板中只看到一个主要微动作。
- [ ] 当前动作链步骤可见，但不会挤压主操作。
- [ ] 语音回答控件包含录音、取消、提交和重新录制状态。
- [ ] 文本兜底只在麦克风拒绝、ASR 失败或调试模式下出现。
- [ ] 提示等级变化通过具体支持方式体现：句子框架、选项、分块跟读或示范后重试。
- [ ] 反馈只指出一个主要问题和一个下一步动作。
- [ ] 发音评分不可用时不阻断训练进度。
- [ ] Pressure check 在视觉上区别于普通重试，并且只属于当前 session。
- [ ] 可恢复错误尽可能保留用户输入或回顾内容。
- [ ] 即使学习证据回写可重试，回顾内容也保持可用。
- [ ] P0.1 页面不得把第三场景创建、任意场景生成、跨天排期、完整 L0-L5 掌握或商业门控展示为完成条件。
