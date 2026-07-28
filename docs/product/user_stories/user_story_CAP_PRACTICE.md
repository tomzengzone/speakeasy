## 6. 练习会话与互动（CAP-PRACTICE / practice-session-runtime）

### US-PRACTICE-001 - 学习者完成听力热身和跟读练习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-001` | 作为学习者，当我进入具体场景练习前，我希望先播放完整场景对话，并能上一句/下一句切换、暂停、循环播放或切换到跟读模式录制候选人台词，以便熟悉语境、回答节奏并获得基础完整度或发音反馈。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-001` | 学习者进入听力热身后播放完整场景对话；成功时熟悉语境和回答节奏；音频或文本不可用时展示可恢复错误。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-002` | 学习者上一句/下一句切换、暂停或循环播放；成功时能按自己的节奏听；控制失败时保持当前播放状态并提示重试。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-003` | 学习者切换到跟读模式并录制候选人台词；成功时生成跟读输入；麦克风不可用、录制失败或中断时展示可恢复提示。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-004` | 跟读提交后系统展示完整度或发音反馈；成功时学习者知道是否需要重读；反馈不可用时保留录音结果并提示稍后重试。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |

### US-PRACTICE-002 - 学习者完成表达小任务

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-002` | 作为学习者，当我处理推荐表达或场景中的练习单元时，我希望完成选择题、填空、意图回忆、接下句、替换槽位、变体改写、流利挑战或跟读等小任务，以便逐步把表达练成自己的话。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-005` | 学习者进入对应练习单元并提交答案；成功时获得练习结果摘要；答案无效、题目不可用或提交失败时展示可恢复状态。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-006` | 学习者根据语境补全下一句或替换表达槽位；成功时系统记录作答结果；失败时保留当前题目并允许重试。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-007` | 学习者提交表达变体改写；成功时看到结果摘要或反馈入口；评估不可用时不错误推进掌握状态。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-008` | 学习者完成限时或语音类表达练习；成功时生成练习结果摘要；录音、计时或提交失败时展示可恢复提示。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |

### US-PRACTICE-003 - 学习者完成语音模拟回答

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-003` | 作为学习者，当我按场景和目标等级进入语音模拟时，我希望查看当前目标进度和场景导航，卡住时请求提示，录音后自动转写并提交回答，以便练习真实口语输出并进入后续反馈。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-009` | 学习者从官方场景和目标等级进入语音模拟；成功时系统展示当前问题和练习上下文；入口状态不可用时展示可恢复提示。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |
| `VS-PRACTICE-010` | 语音模拟页展示当前目标进度、场景导航和本轮正在练的表达；成功时学习者知道当前练习位置；进度不可用时展示保守状态。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |
| `VS-PRACTICE-011` | 学习者在当前问题卡住时请求提示；成功时系统给出可帮助继续回答的提示；提示不可用时允许继续作答或跳过。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |
| `VS-PRACTICE-012` | 学习者录音后系统自动转写并提交回答；成功时生成练习输入并进入反馈流程；录音、转写或提交失败时展示可恢复错误，不推进本题完成状态。 | `draft` | `CAP-PRACTICE` | `CAP-TRAIN`, `CAP-COACH`, `CAP-CONTENT` |

### US-PRACTICE-004 - 学习者完成课程内文本与听写专项练习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-004` | 作为学习者，当我进入包含听写或文本输入节点的课程内容时，我希望按课程节点完成听写、文本输入和专项练习提交，以便在具体课程语境中产出可交接的练习结果摘要。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-013` | 学习者从课程节点进入听写练习并提交听写内容；成功时生成听写作答记录和结果摘要；音频、题目或提交不可用时展示可恢复错误。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-014` | 学习者从课程节点进入文本输入练习并提交回答；成功时生成文本作答记录和结果摘要；输入无效或提交失败时保留当前题目并允许重试。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-015` | 学习者完成课程内专项练习后查看本次互动结果摘要；成功时知道本节点是否完成以及可进入的下一步；结果摘要不可用时不错误推进练习状态。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-COACH`, `CAP-MEMORY` |

### US-PRACTICE-005 - 学习者完成连续 AI 对话练习

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-PRACTICE-005` | 作为学习者，当我进入 AI 对话练习时，我希望看到当前对话上下文，并通过文本或语音连续多轮提交输入，以便围绕同一场景完成可追踪的对话互动练习。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-PRACTICE-016` | 学习者从练习单元、场景内容或主动入口进入 AI 对话练习；成功时看到对话目标、上下文和可用输入方式；上下文不可用时展示可恢复状态。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-017` | 学习者在同一 AI 对话中提交多轮文本或语音输入；成功时对话记录和本轮互动状态更新；提交失败、转写失败或回复不可用时允许重试或保留当前轮次。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |
| `VS-PRACTICE-018` | 学习者中断、重试、恢复或结束 AI 对话练习；成功时看到对话练习状态和结果摘要入口；状态损坏或过期时展示重新开始或返回路径。 | `draft` | `CAP-PRACTICE` | `CAP-CONTENT`, `CAP-TRAIN`, `CAP-COACH`, `CAP-MEMORY` |

