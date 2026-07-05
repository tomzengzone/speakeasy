# Copywriting Guideline

## Tone
- Direct.
- Supportive.
- Specific.
- Short.

- 语气直接，避免绕弯。
- 保持支持性，不责备学习者。
- 表达要具体，指出可执行的改进点。
- 文案尽量短，不增加界面负担。

## Feedback Copy
- Prefer "Try this:" over "You are wrong".
- Explain one issue at a time.
- Use Chinese explanation only when it helps comprehension.

- 优先使用“Try this:”这类引导式表达，不使用“You are wrong”这类否定学习者的说法。
- 每次反馈只解释一个主要问题。
- 只有在能帮助理解时才加入中文解释。

## Button Copy
- Use action verbs.
- Avoid vague labels such as "OK" when a specific action exists.

- 按钮使用明确的动作动词。
- 当存在具体动作时，避免使用“OK”这类含糊标签。

## Error Copy
- State what happened.
- State what the learner can do next.
- Preserve user work.

- 先说明发生了什么。
- 再说明学习者接下来可以做什么。
- 错误文案必须体现用户已完成内容会被保留或可恢复。

## P0 Commercial Copy
- Paid benefit copy must match `SubscriptionPlan` and `EntitlementRule`; do not describe unavailable benefits as included.
- Prefer concrete entitlement labels such as "AI 深度反馈" or "本月剩余练习次数" over broad claims.
- Restore empty state must say no active subscription was found, not imply failure or purchase loss.
- Expired, refunded, revoked, or quota-exhausted states must explain the current limitation and the next available action.
- Account deletion copy must state that local data will be cleared only after the backend deletion or anonymization request is accepted.
- Store copy, membership page copy, privacy copy, and in-app gating copy must use the same benefit names.

- 付费权益文案必须与 `SubscriptionPlan` 和 `EntitlementRule` 一致；不可把当前不可用的权益描述成已包含。
- 优先使用“AI 深度反馈”或“本月剩余练习次数”这类具体权益名称，不使用泛化承诺。
- 恢复购买为空时，应说明未找到有效订阅，不暗示恢复失败或购买丢失。
- 过期、退款、撤销或额度用尽状态必须说明当前限制和可用的下一步操作。
- 账号删除文案必须说明，只有后端删除或匿名化请求被接受后，才会清理本地数据。
- 商店文案、会员页文案、隐私文案和应用内门控文案必须使用一致的权益名称。

## P0.1 Training Copy
- Micro-action copy should start with the action, for example "Listen", "Choose", "Say", "Shadow", "Fill", or "Answer the follow-up".
- Hint copy should be concrete and short; avoid explaining the full training method in the UI.
- Feedback copy should mention one main improvement and one immediately usable expression.
- ASR failure copy must say the audio was not understood, not that the learner was wrong.
- Text fallback copy must make it clear that typing is a fallback.
- Pressure check copy should feel like a short follow-up, not an exam or a long assessment.
- Recap copy should name the next focus without promising cross-day scheduling or full L0-L5 mastery.

- 微动作文案应以动作开头，例如 "Listen"、"Choose"、"Say"、"Shadow"、"Fill" 或 "Answer the follow-up"。
- 提示文案要具体且简短，避免在界面中解释完整训练方法。
- 反馈文案只说明一个主要改进点和一个可以立刻使用的表达。
- ASR 失败文案必须说明音频未被理解，不能说学习者答错。
- 文本输入兜底文案必须明确打字只是兜底路径。
- Pressure check 文案应像一次简短追问，不像考试或长评估。
- 回顾文案只说明下一步重点，不承诺跨天排期或完整 L0-L5 掌握。
