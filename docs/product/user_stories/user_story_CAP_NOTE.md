## 10. 笔记、词汇与个人素材（CAP-NOTE / notebook-vocabulary-assets）

### US-NOTE-001 - 学习者收藏并复看有用表达

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-NOTE-001` | 作为学习者，当我在练习或浏览表达时，我希望收藏或取消收藏表达，并在收藏页看到去重后的收藏表达，以便复看真正有用的表达并删除不再需要的收藏。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-NOTE-001` | 学习者在表达卡片、推荐表达或练习结果中收藏表达；成功时表达进入个人收藏集合；失败时展示可恢复提示。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |
| `VS-NOTE-002` | 学习者取消收藏表达；成功时收藏集合更新；失败时保持原收藏状态并允许重试。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |
| `VS-NOTE-003` | 学习者进入收藏页后，系统展示去重后的收藏表达；成功时可复看真正有用的表达；无收藏时展示空状态。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |
| `VS-NOTE-004` | 学习者从收藏页删除不需要的表达；成功时列表和摘要更新；失败时不误删收藏。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |
| `VS-NOTE-005` | 当收藏表达可被记忆能力引用时，系统将其作为个人素材候选；成功时后续复习或推荐可引用；引用失败时不影响收藏本身。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PRACTICE`, `CAP-CONTENT` |

### US-NOTE-002 - 学习者管理个人词汇和表达资产

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-NOTE-002` | 作为学习者，当我遇到想沉淀的单词、短语、句型或表达时，我希望保存它们并查看释义、来源、例句和表达变体，以便形成可复用的个人语言素材。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PRACTICE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-NOTE-006` | 学习者从练习、内容详情或个人入口新增或保存词汇、短语；成功时个人词汇资产创建或更新；保存失败时保留原页面状态并允许重试。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PRACTICE` |
| `VS-NOTE-007` | 学习者打开个人词汇或短语条目查看释义、来源和例句；成功时知道素材来自哪里以及如何使用；来源缺失时展示不完整状态。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PRACTICE` |
| `VS-NOTE-008` | 学习者保存句型模板或表达变体；成功时模板或变体进入个人表达资产；保存失败、重复或格式无效时展示可恢复提示。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY`, `CAP-PRACTICE` |

### US-NOTE-003 - 学习者记录和管理学习笔记

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-NOTE-003` | 作为学习者，当我需要记录自己的理解、例句或场景备注时，我希望新增、编辑、删除学习笔记并添加场景标签，以便把个人理解和官方内容或练习经历关联起来。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-NOTE-009` | 学习者从内容、练习结果或个人素材入口新增学习笔记；成功时笔记条目保存并可在个人素材中找到；保存失败时展示可恢复提示。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY` |
| `VS-NOTE-010` | 学习者编辑或删除学习笔记；成功时笔记内容或删除状态更新；失败时保持原笔记不变并说明原因。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY` |
| `VS-NOTE-011` | 学习者为学习笔记添加或调整场景标签；成功时笔记可按标签被检索或归类；标签保存失败时保留原标签状态。 | `draft` | `CAP-NOTE` | `CAP-CONTENT`, `CAP-MEMORY` |

### US-NOTE-004 - 学习者检索和整理个人素材

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-NOTE-004` | 作为学习者，当我的个人词汇、表达、笔记和收藏逐渐增多时，我希望搜索、筛选、排序、批量管理、归档或软删这些素材，并从素材发起复用意图，以便持续整理和复用自己的语言资产。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-NOTE-012` | 学习者在个人素材页搜索、筛选或排序词汇、表达、笔记和收藏；成功时看到匹配结果；无结果时展示清除条件或新增素材入口。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE` |
| `VS-NOTE-013` | 学习者批量管理、归档或软删个人素材；成功时素材状态更新并可被筛选查看；操作失败时不误删素材并允许重试。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE` |
| `VS-NOTE-014` | 学习者从个人素材发起复习或训练意图；成功时系统展示可交接给计划或训练的入口；素材不可用或入口不可用时展示原因，不直接启动未定义训练流程。 | `draft` | `CAP-NOTE` | `CAP-MEMORY`, `CAP-PLAN`, `CAP-TRAIN`, `CAP-PRACTICE` |

