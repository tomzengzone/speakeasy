## 12. 参与、通知与留存（CAP-ENGAGE / engagement-notification-retention）

### US-ENGAGE-001 - 学习者配置每日学习提醒

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-001` | 作为学习者，当我设置学习节奏时，我希望设置每日提醒时间和开关，以便按自己的安排接收练习提醒。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-001` | 学习者进入提醒设置后，系统展示当前每日提醒时间、开关和权限状态；成功时学习者知道当前提醒配置；加载失败时展示可恢复提示。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ENGAGE-002` | 学习者设置每日提醒时间；成功时提醒时间保存；无效时间或保存失败时展示可恢复提示。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ENGAGE-003` | 学习者切换每日提醒开关；成功时开关状态更新；权限不足或保存失败时展示说明，不误报已开启。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ENGAGE-004` | 当存在到期复习或计划提醒时，系统让提醒配置引用这些任务；成功时学习者能按节奏收到提醒；无任务时保留提醒偏好但不生成虚假提醒。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |

### US-ENGAGE-002 - 学习者管理触达偏好

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-002` | 作为学习者，当我配置学习触达方式时，我希望管理提醒、push、邮件和活动触达偏好，并看到权限不足时的影响和开启路径，以便按自己接受的方式接收学习提示。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-005` | 学习者设置 push、邮件或活动触达偏好；成功时偏好保存并展示当前触达方式；保存失败时保留原偏好并允许重试。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-ENGAGE-006` | 当触达权限不足或触达方式不可用时，系统展示影响说明和开启路径；成功时学习者知道哪些提醒无法送达；状态不可用时不误报已开启。 | `draft` | `CAP-ENGAGE` | `CAP-ACC`, `CAP-PLAN`, `CAP-MEMORY` |

### US-ENGAGE-003 - 学习者保持连续学习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-003` | 作为学习者，当我持续完成学习时，我希望看到连续学习状态和完成学习后的轻量反馈，以便知道自己是否保持节奏并获得继续学习的可见提示。 | `draft` | `CAP-ENGAGE` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-007` | 学习者查看连续学习状态；成功时看到连续天数、今日是否已计入和状态说明；状态不可用时展示保守提示。 | `draft` | `CAP-ENGAGE` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |
| `VS-ENGAGE-008` | 学习者完成一次有效学习后看到连续学习反馈；成功时知道本次学习是否影响连续状态；反馈不可用时不错误改变连续状态。 | `draft` | `CAP-ENGAGE` | `CAP-MEMORY`, `CAP-TRAIN`, `CAP-PLAN` |

### US-ENGAGE-004 - 中断学习者恢复学习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-004` | 作为一段时间未学习的学习者，当我回到 App 或从提醒入口进入时，我希望看到恢复学习入口并回到上次相关学习上下文，以便不用重新判断从哪里继续。 | `draft` | `CAP-ENGAGE` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-009` | 学习者回流后看到恢复学习入口；成功时入口说明上次可继续的计划、训练或复习上下文；上下文不可用时展示替代学习入口。 | `draft` | `CAP-ENGAGE` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-ENGAGE-010` | 学习者从提醒或召回入口回到上次学习上下文；成功时进入对应计划、训练或复习入口；入口失效时展示返回首页或选择其他任务。 | `draft` | `CAP-ENGAGE` | `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

### US-ENGAGE-005 - 学习者参与活动或挑战

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-ENGAGE-005` | 作为学习者，当产品提供学习活动或挑战时，我希望看到活动入口、参与状态和不可用原因，以便判断是否可以加入当前活动或返回常规学习路径。 | `draft` | `CAP-ENGAGE` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-ENGAGE-011` | 学习者查看活动或挑战入口和参与状态；成功时知道活动是否可参加、是否已参与或是否可继续；加载失败时展示可恢复提示。 | `draft` | `CAP-ENGAGE` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-COM` |
| `VS-ENGAGE-012` | 当活动不可用、已结束或学习者未满足参与条件时，系统展示明确状态和返回常规学习路径；成功时学习者不会误以为活动仍可参加。 | `draft` | `CAP-ENGAGE` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-COM` |

