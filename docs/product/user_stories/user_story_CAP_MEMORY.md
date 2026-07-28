## 9. 学习事实、进度与复盘（CAP-MEMORY / learning-facts-progress-review）

### US-MEMORY-001 - 学习者用练习结果聚焦后续学习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-MEMORY-001` | 作为学习者，当我完成表达或场景练习后，我希望掌握表达、薄弱表达、复习状态和个人素材能影响后续首页或推荐表达，以便之后的练习更聚焦于真正需要巩固的内容。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-MEMORY-001` | 当训练会话产生练习结果摘要或反馈信号时，系统记录学习证据候选；成功时后续状态可引用；失败时不更新掌握或薄弱状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-002` | 当证据被接受后，系统更新表达的掌握或薄弱状态；成功时后续入口能引用；证据不足时保持原状态并标记不确定。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-003` | 当表达需要复习或存在遗忘风险时，系统更新复习到期状态；成功时首页或推荐表达可提示；计算不可用时不生成错误提醒。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-004` | 当收藏、个人表达或学习素材可被引用时，系统将其作为后续推荐或复习依据；成功时学习者看到更聚焦的任务；不可用时不阻断基础训练入口。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

### US-MEMORY-002 - 学习者回顾长期学习结果

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-MEMORY-002` | 作为学习者，当我进入个人中心回顾学习沉淀时，我希望看到学习概览、收藏摘要、技能分布、学习历史、学习报告入口和已完成场景入口，以便理解长期学习结果并回到相关学习证据。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-MEMORY-005` | 学习者进入个人中心后，系统展示学习概览和技能分布；成功时能理解长期进展；数据不可用时展示空状态。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-MEMORY-006` | 学习者打开学习历史入口；成功时看到练习、复习和场景完成记录；加载失败时允许重试，不误报历史为空。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-MEMORY-007` | 学习者看到学习报告入口和可用状态；成功时可进入报告；报告不可用时展示原因，不承诺完整报告已生成。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-MEMORY-008` | 学习者查看已完成场景入口；成功时能回到相关场景结果；状态不可用时展示可恢复提示。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-MEMORY-009` | 学习者在个人中心看到收藏摘要；成功时能进入收藏页复看；收藏状态不可用时展示保守提示。 | `draft` | `CAP-MEMORY` | `CAP-NOTE`, `CAP-LEVEL`, `CAP-CONTENT`, `CAP-TRAIN` |

### US-MEMORY-003 - 学习者查看可追溯学习历史

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-MEMORY-003` | 作为学习者，当我回顾自己学过什么时，我希望按时间查看练习、复习、跳过和中断记录，并能看到记录来源、关联场景和表达，以便追溯学习事实来自哪里。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-MEMORY-010` | 学习者从学习历史入口查看按时间排序的练习、复习、跳过和中断记录；成功时看到发生时间和记录类型；历史不可用时展示可恢复状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-011` | 学习者打开一条学习历史记录查看来源引用、关联场景、表达或练习单元；成功时知道该事实来自哪个训练或反馈；来源缺失时展示不完整状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

### US-MEMORY-004 - 学习者查看复盘和学习报告

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-MEMORY-004` | 作为学习者，当我想复盘近期学习效果时，我希望看到每日学习总结卡、单次练习复盘、阶段报告和报告依据，以便理解实际完成、进度变化和后续需要关注的学习事实。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-MEMORY-012` | 学习者查看每日学习总结卡；成功时看到当天完成、复习、薄弱或中断摘要；当天无记录时展示空状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-013` | 学习者查看单次练习复盘；成功时看到本次练习的可追溯事实、反馈摘要和后续入口；复盘依据不足时展示不完整状态。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-014` | 学习者查看阶段报告和依据；成功时看到阶段内学习事实、进度口径和变化原因；依据不足时展示需要更多学习记录。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |
| `VS-MEMORY-015` | 当学习报告不可用或生成不足时，系统展示原因和后续可补充路径；成功时学习者知道为什么暂时没有报告；状态不可用时允许稍后重试。 | `draft` | `CAP-MEMORY` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-COACH`, `CAP-NOTE` |

