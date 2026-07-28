## 5. 内容资产（CAP-CONTENT / content-curriculum-scenario）

### US-CONTENT-001 - 学习者浏览并理解官方职场场景

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-001` | 作为学习者，当我浏览可练内容时，我希望看到英语面试和入职介绍两个官方场景，并能查看场景简介、标签、目标等级、表达数量和内容可用状态，以便判断哪个真实职场场景适合加入学习。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-001` | 当学习者进入情景学习入口时，系统展示英语面试和入职介绍两个官方场景；成功时学习者能选择真实可练的职场场景；无内容时展示空状态。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-CONTENT-002` | 学习者打开场景详情后，可以看到简介、场景标签和适用目标；成功时能判断场景是否符合当前目标；加载失败时展示重试入口。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-CONTENT-003` | 场景详情展示目标等级、表达数量和内容可用状态；成功时学习者能判断是否加入学习；内容状态不可用时展示保守提示，不伪造学习状态。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-CONTENT-004` | 学习者从场景详情进入可训练内容上下文；成功时系统展示后续练习可引用的对话、表达或训练对象摘要；内容版本不可用时展示可恢复提示。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-MEMORY` |

Boundary note:

- 用户学习进度不归入 `CAP-CONTENT`；内容页如需展示进度，只能引用 `CAP-MEMORY`、`CAP-TRAIN` 或 `CAP-PLAN` 的外部只读摘要，不把进度状态作为内容资产自身行为。

### US-CONTENT-002 - 学习者查看场景表达与训练素材

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-002` | 作为学习者，当我进入已选择的官方场景时，我希望看到该场景中的对话、表达、候选人台词和可练素材摘要，以便理解后续听力热身、表达练习和语音模拟会围绕哪些内容展开。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-005` | 学习者进入场景素材页后，系统展示完整场景对话和角色信息；成功时学习者能理解语境；内容缺失时展示空状态并阻止进入依赖该素材的练习。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |
| `VS-CONTENT-006` | 学习者查看场景中的表达、句型或关键短语清单；成功时知道后续会练哪些表达；加载失败时展示重试提示。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |
| `VS-CONTENT-007` | 学习者查看候选人台词与训练对象的对应关系；成功时能理解跟读和语音模拟的练习对象；关系不可用时不进入需要该关系的训练流。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-COACH` |

### US-CONTENT-003 - 学习者浏览完整官方内容目录

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-003` | 作为学习者，当我从首页、内容入口或学习路线选择内容时，我希望按目录、等级、主题或课程路径浏览官方内容，并能搜索、筛选和排序，以便找到适合当前目标和能力状态的可练课程。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-008` | 学习者按目录、等级、主题或课程路径浏览官方内容；成功时看到可进入的内容集合；无内容时展示空状态和返回入口。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-COM` |
| `VS-CONTENT-009` | 学习者搜索、筛选或排序官方内容；成功时看到匹配结果和清除条件入口；无结果、筛选条件冲突或加载失败时展示可恢复状态。 | `draft` | `CAP-CONTENT` | `CAP-INTENT`, `CAP-PLAN`, `CAP-COM` |
| `VS-CONTENT-010` | 学习者打开不可用、无权限、下架或暂不支持的官方内容时，系统展示明确状态和可返回路径；成功时学习者知道为何不能继续，而不误以为内容已加入路线。 | `draft` | `CAP-CONTENT` | `CAP-COM`, `CAP-INTENT`, `CAP-PLAN` |

### US-CONTENT-004 - 学习者理解课程条目与训练流

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-CONTENT-004` | 作为学习者，当我打开一个官方课程或场景条目时，我希望理解课程定义、预计时长、能力标签、适用人群、学习活动规划、训练对象、练习单元和训练流状态，以便确认该课程能如何被练习、训练和复习引用。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-CONTENT-011` | 学习者查看课程定义、预计时长、能力标签和适用人群；成功时能判断课程是否适合自己；字段缺失或加载失败时展示保守状态。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN`, `CAP-COM` |
| `VS-CONTENT-012` | 学习者查看课程内学习活动规划；成功时知道课程包含哪些学习活动和大致顺序；规划不可用时不承诺可进入完整训练。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN` |
| `VS-CONTENT-013` | 学习者查看训练对象、练习单元和训练流可用状态；成功时知道哪些对象可被练习、训练或复习引用；训练流不可用时展示不可进入原因。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN` |
| `VS-CONTENT-014` | 学习者查看内容版本、更新时间或内容不可用提示；成功时知道当前内容是否仍可用于后续练习；版本冲突或下架时展示替代入口。 | `draft` | `CAP-CONTENT` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-PLAN`, `CAP-COM` |

