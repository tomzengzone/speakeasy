## 15. 账单与支付服务（CAP-BILLING / billing-payment-service）

### US-BILLING-001 - 学习者理解自己的交易历史与凭证

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-BILLING-001` | 作为发生过购买、续费、恢复购买或退款的学习者，我希望按时间和状态查看交易，理解一笔订单的金额、渠道、处理进度及对应凭证，以便核对支付事实，并与当前会员权益状态区分开。 | `draft` | `CAP-BILLING` | `CAP-ACC`, `CAP-COM` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-BILLING-001-1` | 学习者在账单中心按时间范围、交易类型和状态筛选订单，列表显示商品、实付金额与币种、支付渠道、交易时间和当前状态；没有记录时说明当前账号未找到对应交易，并提供核对购买账号的入口。 | `draft` | `CAP-BILLING` | `CAP-ACC`, `CAP-COM` |
| `VS-BILLING-001-2` | 学习者打开订单后，可以查看订单号、商品与计费周期、金额明细、支付渠道、状态时间线和关联退款，并明确区分“交易已完成”与“权益当前可用”是两个由不同能力维护的状态。 | `draft` | `CAP-BILLING` | `CAP-COM` |
| `VS-BILLING-001-3` | 对已有凭证的订单，学习者可以查看或获取支付渠道提供的收据；需要账单证明或发票类材料时，订单页说明当前支持类型、申请入口和由外部渠道提供凭证时的获取路径。 | `draft` | `CAP-BILLING` | `CAP-ACC`, `CAP-SUPPORT` |

### US-BILLING-002 - 学习者从支付异常中恢复

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-BILLING-002` | 作为刚刚发起购买但没有得到明确结果的学习者，我希望知道支付仍在处理、已经失败还是可以恢复，并获得不会造成重复扣款的下一步操作，以便安全完成购买或回到账单支持路径。 | `draft` | `CAP-BILLING` | `CAP-COM`, `CAP-SUPPORT` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-BILLING-002-1` | 支付渠道返回处理中或结果未知时，学习者看到待确认订单及最近更新时间，页面阻止对同一订单直接重复支付，并提供刷新状态、稍后查看和联系支持三种安全路径。 | `draft` | `CAP-BILLING` | `CAP-COM`, `CAP-SUPPORT` |
| `VS-BILLING-002-2` | 支付失败或被取消后，学习者看到可理解的失败类别，并据此选择重试原方式、更换可用方式、前往外部商店处理或结束购买；原订单保留失败或取消事实，不被显示成已付款。 | `draft` | `CAP-BILLING` | `CAP-COM` |
| `VS-BILLING-002-3` | 学习者选择恢复购买时，系统核对当前账号在所选渠道的历史交易，并返回“已恢复”“权益本已存在”“找到交易但无法匹配权益”或“未找到可恢复交易”；需要授予权益的结果交由 `CAP-COM` 处理。 | `draft` | `CAP-BILLING` | `CAP-ACC`, `CAP-COM`, `CAP-SUPPORT` |

### US-BILLING-003 - 学习者处理退款和账单争议

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-BILLING-003` | 作为对某笔交易需要退款或有金额争议的学习者，我希望从订单判断可用处理路径、提交或跳转到正确渠道，并持续查看退款状态，以便理解谁在处理、当前进度以及交易事实是否已经变化。 | `draft` | `CAP-BILLING` | `CAP-COM`, `CAP-SUPPORT` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-BILLING-003-1` | 学习者从订单发起退款或账单争议时，页面依据支付渠道和订单状态说明当前可申请的事项、处理责任方和需要准备的信息；不符合入口条件时说明原因，但不把“暂无入口”表述成退款已被拒绝。 | `draft` | `CAP-BILLING` | `CAP-SUPPORT` |
| `VS-BILLING-003-2` | 对 App 内可受理的请求，学习者确认退款对象、原因和必要证据后获得请求编号；对必须由应用商店或其他外部支付渠道处理的订单，页面带着订单识别信息跳转并说明返回后如何查询进度。 | `draft` | `CAP-BILLING` | `CAP-SUPPORT` |
| `VS-BILLING-003-3` | 学习者在原订单上查看退款的“已提交、外部处理中、需补充、部分退款、全部退款、被拒绝或已取消”时间线；退款状态只反映交易处理，后续权益变化由 `CAP-COM` 单独展示。 | `draft` | `CAP-BILLING` | `CAP-COM`, `CAP-SUPPORT` |

### US-BILLING-004 - 学习者解决账号与交易不匹配问题

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-BILLING-004` | 作为确认已经付款但在当前账号找不到订单或权益的学习者，我希望用购买渠道和交易线索定位付款、区分交易匹配与权益恢复进度，并在无法自助解决时生成带有必要证据的支持请求，以便避免重复购买和重复说明。 | `draft` | `CAP-BILLING` | `CAP-ACC`, `CAP-COM`, `CAP-SUPPORT` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-BILLING-004-1` | 当前账号没有显示预期订单时，学习者可以选择原购买渠道、核对可能使用的登录账号，并输入订单号或选择渠道交易记录；匹配结果明确区分“已与当前账号匹配”“需要核对购买账号”和“尚未找到交易”，不披露其他账号身份。 | `draft` | `CAP-BILLING` | `CAP-ACC` |
| `VS-BILLING-004-2` | 当付款已被确认但权益未生效时，账单页保留已确认的交易事实，并把权益恢复请求交给 `CAP-COM`；学习者分别看到“交易已匹配”和“权益处理中/已恢复/无法恢复”，避免把两步合并成模糊的恢复成功。 | `draft` | `CAP-BILLING` | `CAP-COM` |
| `VS-BILLING-004-3` | 自助匹配仍无法定位交易时，学习者可创建账单支持请求，系统附带已脱敏的渠道、订单号、交易时间、金额和已尝试步骤，并让学习者确认补充凭证；工单建立后由 `CAP-SUPPORT` 承接沟通。 | `draft` | `CAP-BILLING` | `CAP-ACC`, `CAP-SUPPORT` |

Boundary note:

- `CAP-BILLING` 拥有订单、支付尝试、退款和凭证的交易事实与用户可见处理状态。会员计划、权益授予和商业 access gate 归 `CAP-COM`；账号归属归 `CAP-ACC`；人工沟通归 `CAP-SUPPORT`；支付、税务和外部商店的内部审批规则不在本节定义。

