## 14. 用户支持、反馈与服务（CAP-SUPPORT / user-support-feedback-service）

### US-SUPPORT-001 - 学习者获得与当前问题相关的自助帮助

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-SUPPORT-001` | 作为在具体功能中遇到问题的学习者，我希望从当前上下文获得适用的帮助内容、搜索其他问题并完成引导式排障，以便优先自行解决问题；无法解决时，已确认的信息可以继续用于人工服务。 | `draft` | `CAP-SUPPORT` | `CAP-ACC`, `CAP-CONTENT`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-SUPPORT-001-1` | 学习者从登录、练习、内容或会员页面打开帮助时，帮助中心优先呈现与当前功能、当前状态和设备平台相符的主题，同时允许切换到完整帮助分类；学习者不必先猜测内部模块名称。 | `draft` | `CAP-SUPPORT` | `CAP-ACC`, `CAP-CONTENT`, `CAP-COM` |
| `VS-SUPPORT-001-2` | 学习者按问题关键词搜索时，可以继续按产品区域、问题类型和设备平台缩小结果，并在每条结果上判断适用对象和解决目标；没有匹配内容时，可改用分类浏览或带着搜索词发起反馈。 | `draft` | `CAP-SUPPORT` | `CAP-ACC`, `CAP-CONTENT`, `CAP-COM` |
| `VS-SUPPORT-001-3` | 学习者进入引导式排障后，按可观察现象逐步确认网络、权限、账号状态或内容可用性，并看到已完成步骤与下一步；问题未解决时，可将问题类型和已尝试步骤带入人工服务请求。 | `draft` | `CAP-SUPPORT` | `CAP-ACC`, `CAP-CONTENT` |

### US-SUPPORT-002 - 学习者提交可定位、可追踪的产品与内容反馈

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-SUPPORT-002` | 作为发现内容错误、产品问题或 AI 反馈质量异常的学习者，我希望从问题发生处提交带有必要上下文的反馈，并在反馈中心跟踪处理结果，以便团队能定位问题，我也无需反复描述同一情况。 | `draft` | `CAP-SUPPORT` | `CAP-CONTENT`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-SUPPORT-002-1` | 学习者从课程、表达或练习素材发起内容错误反馈时，反馈自动关联内容标识和具体位置，并让学习者选择错别字、翻译、音频、答案或其他问题类型，再补充说明和证据。 | `draft` | `CAP-SUPPORT` | `CAP-CONTENT` |
| `VS-SUPPORT-002-2` | 学习者对 AI 回答、评分或教练建议反馈质量问题时，可以在隐私提示后附带本次输入、系统输出、评分结果和问题类型；提交只创建质量反馈记录，不直接改写原回答、分数或学习记录。 | `draft` | `CAP-SUPPORT` | `CAP-COACH` |
| `VS-SUPPORT-002-3` | 学习者在反馈中心按“已收到、评估中、需补充、已回复、已关闭”查看自己提交的反馈，并在需要补充时继续追加信息；同一反馈的回复和状态保留在一条时间线上。 | `draft` | `CAP-SUPPORT` | `CAP-CONTENT`, `CAP-COACH` |

### US-SUPPORT-003 - 学习者进入人工服务并持续跟进

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-SUPPORT-003` | 作为自助帮助不足以解决问题的学习者，我希望根据问题紧急度和可用时间选择人工服务渠道，提交一次完整请求，并持续查看回复、待办和处理状态，以便明确知道由谁处理、下一步需要我做什么。 | `draft` | `CAP-SUPPORT` | `CAP-ACC`, `CAP-COM`, `CAP-BILLING` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-SUPPORT-003-1` | 学习者进入人工服务时，可以比较当前可用的在线客服、邮件和工单渠道，以及各渠道公开的服务时间、响应说明和适用问题；渠道暂不可用时，页面给出后续可用说明或替代渠道。 | `draft` | `CAP-SUPPORT` | `CAP-ACC`, `CAP-COM`, `CAP-BILLING` |
| `VS-SUPPORT-003-2` | 学习者选择问题类型后，只需补齐该类问题必需的信息；系统沿用帮助或排障阶段已有的页面、订单或账号上下文，并在提交前让学习者确认将发送的内容，随后生成可查询的工单编号。 | `draft` | `CAP-SUPPORT` | `CAP-ACC`, `CAP-COM`, `CAP-BILLING` |
| `VS-SUPPORT-003-3` | 学习者打开工单详情时，可以在同一时间线查看双方消息、附件、当前负责人状态和自己的待补充事项；工单关闭后仍可查看结论，并在问题未解决时按规则重新打开或创建关联工单。 | `draft` | `CAP-SUPPORT` | `CAP-ACC`, `CAP-COM`, `CAP-BILLING` |

### US-SUPPORT-004 - 学习者发起申诉或争议并理解处理边界

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-SUPPORT-004` | 作为认为账号处置、内容或 AI 评估、会员权益或交易结果存在错误的学习者，我希望选择正确的申诉或争议类型、提交必要证据并跟踪审查状态，以便进入对应责任域的人工复核，而不是把普通反馈误当成正式申诉。 | `draft` | `CAP-SUPPORT` | `CAP-ACC`, `CAP-CONTENT`, `CAP-COACH`, `CAP-COM`, `CAP-BILLING` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-SUPPORT-004-1` | 学习者对账号限制或异常状态发起申诉时，入口说明可申诉的处置对象、身份核验要求和可补充证据；提交后进入账号安全责任域复核，申诉记录本身不会自动恢复账号状态。 | `draft` | `CAP-SUPPORT` | `CAP-ACC` |
| `VS-SUPPORT-004-2` | 学习者对内容结论、AI 评分或教练反馈发起争议时，可以选择被争议的具体结果、说明理由并附加证据；页面区分“报告质量问题”和“请求复核结果”，复核期间保留原内容与评分事实。 | `draft` | `CAP-SUPPORT` | `CAP-CONTENT`, `CAP-COACH` |
| `VS-SUPPORT-004-3` | 学习者选择会员权益或账单争议时，系统先区分“已支付但权益未生效”和“交易金额、退款或重复扣款问题”：前者交给权益处理，后者带订单上下文进入账单处理，学习者可在统一争议记录中查看两类状态。 | `draft` | `CAP-SUPPORT` | `CAP-COM`, `CAP-BILLING` |

Boundary note:

- `CAP-SUPPORT` 拥有帮助内容入口、反馈记录、客服工单和申诉/争议流程状态，但不拥有被反馈对象的业务结论。Bug 修复、内容改写、AI 评分调整、账号风控结论、退款审批和会员权益判定仍由对应 capability 或外部处理方负责。

