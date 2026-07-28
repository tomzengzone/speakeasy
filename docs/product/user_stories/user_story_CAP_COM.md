## 11. 会员、商业化与权益（CAP-COM / membership-commerce-entitlement）

### US-COM-001 - 学习者查看会员方案并管理购买入口

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COM-001` | 作为学习者，当我需要了解订阅或权益入口时，我希望查看会员方案、发起购买或恢复购买，以便理解当前可用的订阅入口和权益获取方式。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COM-001` | 学习者进入会员入口后，系统展示会员方案和权益说明；成功时学习者理解可购买内容；加载失败时展示可恢复提示。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-002` | 学习者选择会员方案并发起购买；成功时进入购买流程状态；失败、取消或购买入口暂不可用时展示可恢复提示。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-003` | 学习者选择恢复购买；成功时系统展示恢复结果或当前订阅状态；失败时说明原因并允许重试。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-004` | 学习者查看当前订阅入口或权益状态摘要；成功时知道是否已拥有对应权益；状态不可用时不错误授予或撤销权益。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

### US-COM-002 - 学习者在受限功能前理解权益限制

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COM-002` | 作为学习者，当我访问会员限定内容、额度受限练习或高级反馈时，我希望在继续前理解当前权益限制、升级选择和可用免费路径，以便决定升级、等待额度恢复或返回可用功能。 | `draft` | `CAP-COM` | `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COM-005` | 学习者访问受限功能时看到付费墙和权益说明；成功时知道该限制对应哪个会员权益；权益状态不可用时不错误放行或阻断。 | `draft` | `CAP-COM` | `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-006` | 学习者在用量耗尽时看到升级、等待恢复或查看额度说明；成功时知道下一步选择；额度状态不可用时展示保守提示。 | `draft` | `CAP-COM` | `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-007` | 学习者无权益时可返回、升级或继续免费路径；成功时不会被困在受限流程；可用路径加载失败时展示返回入口。 | `draft` | `CAP-COM` | `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

### US-COM-003 - 学习者管理订阅生命周期

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-COM-003` | 作为已订阅或曾订阅的学习者，当我进入会员与订阅页面时，我希望查看当前计划、到期、宽限、退款、恢复和降级状态，并能进入取消或管理订阅入口，以便理解订阅变化对权益的影响。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-COM-008` | 学习者查看当前计划、到期时间、宽限、退款或恢复状态；成功时知道当前订阅是否可用；状态不可用时展示保守提示，不错误授予或撤销权益。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-009` | 学习者进入取消订阅或管理订阅入口；成功时看到可继续处理订阅的路径；入口不可用或订阅管理状态暂不可确认时展示说明和返回路径。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |
| `VS-COM-010` | 学习者在订阅降级、过期或权益变化后查看权益变化说明；成功时知道哪些功能仍可用、哪些受限；说明不可用时不误导用户继续受限功能。 | `draft` | `CAP-COM` | `CAP-ACC`, `CAP-CONTENT`, `CAP-PRACTICE`, `CAP-COACH` |

