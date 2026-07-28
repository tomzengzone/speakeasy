## 7. 技能训练编排与自动化（CAP-TRAIN / skill-training-automation）

### US-TRAIN-001 - 学习者完成官方场景练习后理解训练结果

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-001` | 作为准备职场英语场景表达的学习者，在已选择官方场景并完成一轮语音场景练习后，我希望看到包含本轮掌握、总进度、遗忘曲线、薄弱标签、下轮重点和关键反馈的清晰总结，以便知道这次练习是否有效、哪些表达需要继续巩固，以及下一步该回到哪里继续学习。 | `approved` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-001` | 当学习者从官方场景模拟页完成当前一轮语音练习并触发结束动作时，系统给出本轮练习总结和可见的后续学习入口；成功时学习者看到本轮总结、关键反馈和进度变化；失败或无可用结果时学习者看到可恢复的错误或空状态，且进度不会被错误推进；产品状态变化为本轮练习完成状态与学习证据候选被记录。 | `approved` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-002` | 当本轮训练结果可用时，系统展示本轮掌握、薄弱标签和下轮重点；成功时学习者知道哪些表达需要继续巩固；无可用结果时展示空状态，不生成错误结论。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-003` | 当训练结果可交接给学习事实时，系统展示总进度和遗忘曲线摘要；成功时学习者能观察进度变化；状态更新失败时保持原进度并提示重试。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-004` | 学习者在总结页选择继续练习、复习薄弱表达或返回首页；成功时进入对应入口；入口不可用时展示替代路径。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |

### US-TRAIN-002 - 已加入场景的学习者完成推荐表达队列训练

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-002` | 作为已加入场景的学习者，当我进入推荐表达页处理今日训练时，我希望看到每日表达队列，并围绕复习、薄弱和表达变体依次完成训练，以便持续把表达练成自己的话。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-005` | 当已加入场景的学习者进入推荐表达页时，系统展示每日表达队列及每条表达的训练原因；成功时学习者知道今天要练什么；无队列时展示空状态和回到场景入口。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-006` | 学习者选择队列中的表达或点击继续；成功时系统交接到对应练习单元；练习素材不可用时展示可恢复提示。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-007` | 学习者完成表达小任务后，队列更新复习、薄弱、变体或完成状态；成功时学习者看到队列进度；更新失败时不错误标记完成。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-008` | 当每日表达队列完成或无更多可练项时，系统展示下一步入口；成功时学习者可返回首页、继续场景或查看复盘；状态不可用时展示保守提示。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PLAN` |

### US-TRAIN-003 - 中途退出的学习者恢复未完成训练会话

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-003` | 作为中途退出的学习者，当我下次进入同一场景同一等级时，我希望恢复未完成会话，以便不用从头开始并继续完成上次中断的练习。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-009` | 当学习者再次进入场景时，系统检查是否存在可恢复会话；成功时展示继续入口；状态不可用时不展示错误恢复入口。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-010` | 学习者选择继续后，系统恢复当前问题、目标进度和场景导航；成功时可继续练习；恢复失败时允许从头开始或返回首页。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-011` | 当未完成会话过期、内容版本变化或状态损坏时，系统展示原因和替代入口；成功时学习者知道可以重新开始或选择其他任务。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |

### US-TRAIN-004 - 学习者在训练中处理节奏与状态

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-004` | 作为正在训练的学习者，当我需要暂停、继续、跳过、重做或处理不可用内容时，我希望训练会话清楚展示当前练习单元状态和可选动作，以便不中断学习控制权并避免错误推进训练进度。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-012` | 学习者在训练会话中暂停并稍后继续；成功时当前计划训练项、训练流位置和练习单元游标可恢复；暂停或继续失败时展示可恢复提示。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-013` | 学习者对当前练习单元选择跳过、重做或重新开始；成功时练习单元状态和训练节奏更新；操作失败时保持原状态并允许继续当前练习。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN` |
| `VS-TRAIN-014` | 当训练流内容不可用或需要 fallback 时，系统展示原因和替代训练入口；成功时学习者能继续其他可用训练；无替代入口时展示可返回状态。 | `draft` | `CAP-TRAIN` | `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-PLAN` |
| `VS-TRAIN-015` | 学习者查看计划训练项或练习单元的部分完成、中断、失败或 stale 状态；成功时知道下一步可继续、重试、重算或返回；状态不可用时不错误标记完成。 | `draft` | `CAP-TRAIN` | `CAP-PRACTICE`, `CAP-MEMORY`, `CAP-PLAN` |

### US-TRAIN-005 - 学习者从计划训练项进入可解释训练会话

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-TRAIN-005` | 作为学习者，当我从学习计划选择一个计划训练项时，我希望进入训练前看到训练来源、完成规则、训练对象和可用训练流，以便知道这次训练为什么出现以及如何完成。 | `draft` | `CAP-TRAIN` | `CAP-PLAN`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-TRAIN-016` | 学习者从计划训练项进入训练会话入口；成功时看到计划来源、训练对象、训练流引用、预期时长和完成规则；入口加载失败时可返回计划页。 | `draft` | `CAP-TRAIN` | `CAP-PLAN`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-MEMORY` |
| `VS-TRAIN-017` | 当训练对象或训练流不可用时，训练入口展示不可用原因和替代入口；成功时学习者可选择其他可练项、返回计划或等待内容恢复。 | `draft` | `CAP-TRAIN` | `CAP-PLAN`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-MEMORY` |

