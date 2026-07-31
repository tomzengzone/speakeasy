## 3. 学习目标与偏好（CAP-INTENT / learning-intent-preference）

### US-INTENT-001 - 学习者设定目标偏好并理解当前支持状态

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-001` | 作为学习者，当我完成首评并需要建立初始学习方向时，我希望选择目标方向、表达卡点、当前输出水平和每日分钟数，并看到该方向是否被当前 MVP 完整支持，以便 App 保存我的偏好且不会把暂未完整支持的方向误导为已有完整场景可练。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-001-1` | 学习者在目标设置中选择英语面试、入职介绍、日常服务或其他方向；成功时系统记录目标方向；若方向暂未支持，展示明确支持状态而不是进入不可练流程。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |
| `VS-INTENT-001-2` | 学习者选择表达卡点、口语输出问题或能力重点；成功时偏好可用于后续路线和推荐；失败时展示保存失败并保留原选择。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |
| `VS-INTENT-001-3` | 学习者设置每日可投入分钟数；成功时形成学习投入约束；无效输入或保存失败时展示可恢复提示，不生成错误计划。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |
| `VS-INTENT-001-4` | 当学习者选择日常服务等暂未完整支持方向时，系统允许完成首评进入首页，但明确展示该方向的支持状态；成功时学习者不会误以为已有完整日常服务场景可练。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |
| `VS-INTENT-001-5` | 当目标、卡点、水平和时间约束都可用时，系统保存偏好并交接给计划能力；成功时学习者进入首页或路线预览；失败时展示可恢复错误且不丢失已填写信息。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-CONTENT` |

### US-INTENT-002 - 学习者维护官方场景学习路线

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-002` | 作为学习者，当我从官方内容中选择适合自己的学习方向后，我希望能加入、移除、设为当前场景并切换目标等级，以便让学习路线持续匹配我的当前目标和能力状态。 | `draft` | `CAP-INTENT` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-002-1` | 学习者加入或移除英语面试、入职介绍等官方场景；成功时个人路线状态更新；失败时保持原路线并提示可重试。 | `draft` | `CAP-INTENT` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-TRAIN` |
| `VS-INTENT-002-2` | 学习者将某个已加入场景设为当前学习场景；成功时首页和训练入口引用该场景；失败时不切换当前路线。 | `draft` | `CAP-INTENT` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-TRAIN` |
| `VS-INTENT-002-3` | 学习者为已加入场景切换目标等级；成功时后续计划和训练入口使用新等级；若该等级无可用内容，展示不可用状态并保留原等级或提供退回选择。 | `draft` | `CAP-INTENT` | `CAP-CONTENT`, `CAP-PLAN`, `CAP-TRAIN` |

Boundary note:

- 官方内容的搜索、筛选、排序和目录浏览归入 `CAP-CONTENT`；`CAP-INTENT` 只承接用户把内容选择转化为个人学习路线、当前场景和目标等级的状态变化。

### US-INTENT-003 - 学习者维护完整目标生命周期

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-003` | 作为学习者，当我的学习目标发生变化或暂时不再适用时，我希望设置目标水平、期限和成功标准，并暂停、恢复或归档目标，以便学习路线和后续计划始终反映当前真实目标状态。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-TRAIN` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-003-1` | 学习者从目标设置页补充目标水平、期限和成功标准；成功时形成可追踪目标定义；输入无效或保存失败时保留原目标状态。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-TRAIN` |
| `VS-INTENT-003-2` | 学习者暂停、恢复或归档学习目标；成功时目标生命周期状态更新并展示对路线入口的影响；失败时目标状态保持不变。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-TRAIN` |
| `VS-INTENT-003-3` | 学习者查看目标支持状态和原因；成功时知道目标当前是 supported、partial 还是 unsupported；状态不可用时展示保守提示，不误导用户进入不可练流程。 | `draft` | `CAP-INTENT` | `CAP-LEVEL`, `CAP-PLAN`, `CAP-TRAIN` |

### US-INTENT-004 - 学习者设置学习方式与反馈偏好

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-004` | 作为学习者，当我调整自己的学习方式时，我希望设置练习形式、反馈深度、纠错频率以及语音或文本优先偏好，以便后续练习和反馈更贴近我当前愿意采用的学习方式。 | `draft` | `CAP-INTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-004-1` | 学习者设置练习形式偏好，例如听、说、读、写或混合练习；成功时偏好被保存供后续路线和训练引用；保存失败时保留原偏好。 | `draft` | `CAP-INTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |
| `VS-INTENT-004-2` | 学习者设置反馈深度和纠错频率；成功时后续反馈入口能引用该偏好；无效设置或保存失败时展示可恢复提示。 | `draft` | `CAP-INTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |
| `VS-INTENT-004-3` | 学习者设置语音或文本优先偏好；成功时系统在可用练习入口中展示匹配的默认方式；对应方式不可用时展示替代路径。 | `draft` | `CAP-INTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |

### US-INTENT-005 - 学习者维护时间约束

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-INTENT-005` | 作为学习者，当我的可学习时间和投入强度变化时，我希望维护每日/每周投入、学习强度、可学习时间段和不可用时段，以便后续计划和提醒不会基于错误时间约束。 | `draft` | `CAP-INTENT` | `CAP-PLAN`, `CAP-ENGAGE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-INTENT-005-1` | 学习者设置每日/每周投入和学习强度；成功时形成可用于计划的时间约束；输入无效或保存失败时不生成错误约束。 | `draft` | `CAP-INTENT` | `CAP-PLAN`, `CAP-ENGAGE` |
| `VS-INTENT-005-2` | 学习者设置可学习时间段和不可用时段；成功时后续计划和提醒可引用这些时间窗口；冲突或保存失败时展示可恢复提示并保留原设置。 | `draft` | `CAP-INTENT` | `CAP-PLAN`, `CAP-ENGAGE` |

