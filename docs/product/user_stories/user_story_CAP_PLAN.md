## 4. 学习计划与计划版本（CAP-PLAN / learning-plan-version）

### US-PLAN-001 - 学习者在首页找到当前最该继续的学习入口

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PLAN-001` | 作为学习者，当我进入首页查看今日学习状态时，我希望看到情景学习、推荐表达和我的三个主入口，并优先看到未完成会话、到期复习、薄弱表达或下一条未掌握表达，以便直接继续当前最该做的练习。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PLAN-001` | 当学习者进入首页时，系统展示情景学习、推荐表达和我的入口；成功时学习者知道当前 MVP 的核心流程；加载失败时展示可恢复状态。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |
| `VS-PLAN-002` | 当存在未完成训练会话时，首页优先展示继续入口；成功时学习者可回到同一场景同一等级继续；状态不可用时不错误提示可恢复会话。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |
| `VS-PLAN-003` | 当存在到期复习、薄弱表达或下一条未掌握表达时，首页展示对应入口；成功时学习者能直接进入相关训练；无任务时展示清晰空状态。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |
| `VS-PLAN-004` | 当学习者已有当前官方场景和目标等级时，首页入口展示对应场景上下文；成功时学习者知道下一步练什么；路线信息不可用时展示选择场景入口。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY`, `CAP-CONTENT`, `CAP-ENGAGE` |

### US-PLAN-002 - 学习者获得可解释的学习计划版本

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PLAN-002` | 作为学习者，当我完成当前水平和目标偏好设置后，我希望看到一个可解释的日/周学习计划版本，包含当前水平到目标的差距、计划训练项、优先级、时间约束和复习安排，以便知道今天为什么练这些内容。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-CONTENT`, `CAP-MEMORY`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PLAN-005` | 学习者从计划页查看当前水平与目标之间的差距说明；成功时看到能力差距和阶段差距摘要；差距数据不可用时展示需要补充水平或目标的信息。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY` |
| `VS-PLAN-006` | 学习者生成或查看当前日计划和周计划；成功时看到计划版本、计划周期和计划训练项清单；生成失败时展示可恢复状态，不替换已有计划。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-CONTENT`, `CAP-TRAIN` |
| `VS-PLAN-007` | 学习者查看某个计划训练项的训练对象、预期时长、完成规则和计划原因；成功时知道该项为何被安排；引用内容不可用时展示替代入口或不可用状态。 | `draft` | `CAP-PLAN` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-PLAN-008` | 学习者查看计划优先级和时间约束解释；成功时理解计划如何引用目标、能力重点和可用时间；解释不可用时保留计划但不展示无依据结论。 | `draft` | `CAP-PLAN` | `CAP-INTENT`, `CAP-LEVEL`, `CAP-MEMORY` |
| `VS-PLAN-009` | 学习者查看复习与记忆调度安排；成功时看到到期窗口、跨天安排和可进入的复习入口；记忆事实不足时展示暂无到期复习的空状态。 | `draft` | `CAP-PLAN` | `CAP-MEMORY`, `CAP-ENGAGE`, `CAP-TRAIN` |
| `VS-PLAN-010` | 学习者选择某个计划训练项并进入对应训练或复习入口；成功时系统把训练对象、训练流引用、预期时长、完成规则和计划来源交给后续入口；引用缺失或入口不可用时展示替代路径或不可用原因。 | `draft` | `CAP-PLAN` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-MEMORY` |

### US-PLAN-003 - 学习者处理计划变更和重算

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PLAN-003` | 作为学习者，当我的目标、水平、时间约束或学习事实发生变化时，我希望知道当前计划是否已经过期，并能触发重算、查看新旧差异或恢复已有计划版本，以便继续使用可信的学习安排。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PLAN-011` | 当目标、水平、时间约束或学习事实变化后，系统在计划页提示当前计划 stale 或需要重算；成功时学习者知道计划为何不再可信；判断不可用时保留原计划并提示稍后检查。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY`, `CAP-TRAIN` |
| `VS-PLAN-012` | 学习者触发计划重算后查看新旧计划差异；成功时看到训练项、优先级或时间安排的变化；重算失败时保留旧计划并允许重试。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY`, `CAP-TRAIN` |
| `VS-PLAN-013` | 学习者取消当前计划版本；成功时计划版本变为取消状态并展示当前无生效计划或替代入口；取消失败时保持原计划生效状态。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-PLAN-014` | 学习者恢复一个可恢复的计划版本；成功时该计划重新成为可用计划并展示恢复后的下一步入口；恢复失败或版本不可恢复时保持当前状态并说明原因。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-PLAN-015` | 学习者用新计划版本替换当前计划；成功时系统展示新生效版本和旧版本状态；替换失败时保留原计划并允许返回或重试。 | `draft` | `CAP-PLAN` | `CAP-TRAIN`, `CAP-MEMORY` |

### US-PLAN-004 - 学习者查看阶段检查点与达标预测

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PLAN-004` | 作为学习者，当我想确认当前学习是否按计划推进时，我希望查看阶段检查点、达标预测和风险解释，以便判断是否需要调整目标、投入或学习节奏。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PLAN-016` | 学习者从计划页查看阶段检查点；成功时看到阶段目标、当前进展和下一检查点；检查点不可用时展示需要更多学习事实或目标信息。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY` |
| `VS-PLAN-017` | 学习者查看达标预测和风险解释；成功时知道当前风险来自时间、进度或能力差距；预测不可用时展示不确定状态，不承诺达标结果。 | `draft` | `CAP-PLAN` | `CAP-LEVEL`, `CAP-INTENT`, `CAP-MEMORY` |

