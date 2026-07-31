## 2. 当前水平与能力画像（CAP-LEVEL / learner-level-profile）

### US-LEVEL-001 - 已登录新用户完成首评并获得当前学习起点

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-LEVEL-001` | 作为已登录新用户，当我首次进入学习流程且系统尚不了解我的英语输出水平时，我希望完成首评并提交当前输出水平相关信息，以便形成第一版当前水平画像并支撑后续学习路线生成。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-LEVEL-001-1` | 当已登录新用户没有当前水平画像时，系统展示首评入口和任务说明；成功时学习者知道需要完成什么；若任务不可用，展示可恢复提示并允许稍后再试。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-001-2` | 学习者选择当前输出水平、表达卡点或完成系统采样任务；成功时系统记录可用于初始画像的信息；失败时展示提交错误，不推进首评完成状态。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-001-3` | 当首评信息有效时，系统生成当前水平、关键能力标签和画像置信提示；成功时学习者知道自己当前处于什么起点；无可用结果时展示空状态并允许重试或补充信息。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-001-4` | 首评完成后，系统将当前水平结果交接给目标偏好和初始计划生成；成功时学习者可以继续设置学习目标；失败时保留首评结果，不重复要求学习者完成相同步骤。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

### US-LEVEL-002 - 学习者查看可解释的能力画像

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-LEVEL-002` | 作为学习者，当我查看当前英语能力画像时，我希望看到口语、听力、阅读、词汇、发音、流利度、语法和表达完成度等维度的解释，以及等级映射、证据来源和置信度，以便理解系统为什么这样判断我的当前水平。 | `draft` | `CAP-LEVEL` | `CAP-PLAN`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-LEVEL-002-1` | 学习者从当前水平页进入能力画像详情；成功时看到多维能力画像和各维度当前状态；画像不可用时展示原因和补充信息入口。 | `draft` | `CAP-LEVEL` | `CAP-PLAN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-LEVEL-002-2` | 学习者查看等级映射和能力标准解释；成功时能理解当前等级如何对应能力维度；映射不可用时不展示误导性的等级结论。 | `draft` | `CAP-LEVEL` | `CAP-PLAN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-LEVEL-002-3` | 学习者查看弱项证据、证据来源时间和置信度；成功时知道判断依据来自首评、复测或学习证据；证据不足时展示不确定状态。 | `draft` | `CAP-LEVEL` | `CAP-PLAN`, `CAP-COACH`, `CAP-MEMORY` |

### US-LEVEL-003 - 学习者更新或复测当前水平

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-LEVEL-003` | 作为学习者，当我认为当前水平画像已经过期或需要重新确认时，我希望主动更新自报信息或完成复测任务，并看到新旧画像差异，以便后续目标、计划和训练基于新的当前水平。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-LEVEL-003-1` | 学习者从当前水平页主动更新自报等级、分项自评、学习经历或近期能力感受；成功时形成新的自报水平事实；保存失败时保持原画像不变。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-003-2` | 学习者触发复测并完成复测任务；成功时系统生成新的测评结果和完成状态；任务不可用、中断或提交失败时展示可恢复入口，不替换原画像。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |
| `VS-LEVEL-003-3` | 当新画像生成后，系统展示画像版本前后对比、更新原因和影响提示；成功时学习者知道哪些能力判断发生变化；对比不可用时保留新画像并提示暂不可比较。 | `draft` | `CAP-LEVEL` | `CAP-INTENT`, `CAP-PLAN`, `CAP-MEMORY` |

