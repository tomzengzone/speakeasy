## 8. AI 教练、反馈与评估（CAP-COACH / ai-coach-feedback-assessment）

### US-COACH-001 - 学习者获得并复查教练反馈

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COACH-001` | 作为学习者，当我提交语音模拟或表达练习回答后，我希望看到教练反馈、重试建议、表达建议或下一问题，并能播放或翻译教练消息、播放自己的语音回答，以便知道下一步怎么改并复查听说效果。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COACH-001-1` | 学习者提交回答后，系统展示教练反馈、关键问题和表现亮点；成功时学习者知道当前回答质量；反馈生成失败时展示可恢复提示。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-001-2` | 当反馈可用时，系统给出重试建议、替代表达或下一问题入口；成功时学习者知道下一步怎么改；建议不可用时仍保留基础反馈。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-001-3` | 学习者播放或翻译教练消息；成功时能复查听说效果；播放、翻译或音频不可用时展示可恢复提示。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-001-4` | 学习者回放自己的语音回答；成功时能复查发音和表达；录音不可用时展示空状态，不影响文本反馈。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-001-5` | 当反馈、纠错或评分信号可用时，系统交接给训练节奏和学习证据候选；成功时后续练习可引用；交接失败时不错误推进掌握状态。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |

### US-COACH-002 - 学习者理解评分和评估依据

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COACH-002` | 作为学习者，当我查看一次练习反馈时，我希望看到发音、流利度、完整度、表达质量和任务完成度等评分信号，以及 rubric、证据、扣分原因和不确定性说明，以便理解反馈依据而不是只看到结论。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COACH-002-1` | 学习者在反馈详情中查看发音、流利度、完整度、表达质量和任务完成度等评分信号；成功时知道各维度表现；评分不可用时展示原因而不是空泛结论。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-002-2` | 学习者查看纠错原因、rubric 和证据片段；成功时知道反馈依据来自哪些回答内容；证据不足或不可展示时说明限制。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |
| `VS-COACH-002-3` | 当评估存在不确定性或反馈不可用时，系统展示不确定性或不可用状态；成功时学习者知道是否应重试、稍后查看或继续下一步。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY`, `CAP-LEVEL` |

### US-COACH-003 - 学习者使用纠错建议改进回答

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COACH-003` | 作为学习者，当教练指出我的回答问题时，我希望看到语法、词汇、表达、发音和任务完成度相关纠错建议，并能基于建议重试后比较结果，以便把反馈转化为下一次可执行改进。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COACH-003-1` | 学习者查看语法、词汇、表达、发音或任务完成度纠错建议；成功时看到可执行改法和更自然表达；建议不可用时保留基础反馈。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY` |
| `VS-COACH-003-2` | 学习者依据纠错建议发起重试并比较新旧反馈摘要；成功时知道重试是否改善；重试结果不可用时展示可恢复提示，不覆盖原反馈。 | `draft` | `CAP-COACH` | `CAP-PRACTICE`, `CAP-TRAIN`, `CAP-MEMORY` |

