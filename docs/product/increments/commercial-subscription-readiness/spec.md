# Spec：商业化订阅上线准备

## 状态
Draft - 可作为 acceptance criteria 的直接上游输入；实现前仍需下游 Domain/API/Architecture/UX/QA/DevOps 契约。

## Product Object
- Increment：`commercial-subscription-readiness`
- Requirements：`docs/product/increments/commercial-subscription-readiness/requirements.md`
- Active stage：`docs/product/stages/p0-commercial-readiness.md`
- Primary feature：`commercial-subscription`

## Feature Goal
让 SpeakEasy 从“会员入口和前端支付雏形”升级为可真实收费、可恢复、可降级、可审计、可发布的订阅系统。

## Core User Flows

### Flow-COM-001 购买订阅
1. 已登录用户打开会员页。
2. 客户端展示真实可售计划和当前权益状态。
3. 用户选择计划并发起 Apple 或 Google Play 购买。
4. 客户端把商店返回的交易凭据发送到后端。
5. 后端校验交易和商品，保存权益状态。
6. 客户端刷新权益，并展示订阅已生效。

### Flow-COM-002 恢复购买
1. 用户点击恢复购买。
2. 客户端从商店拉取可恢复购买。
3. 后端校验交易或 purchase token。
4. 有有效订阅时恢复权益；没有有效订阅时展示空结果。

### Flow-COM-003 付费权益 gating
1. 用户进入受限功能，例如 AI 深度反馈、场景包或学习报告。
2. 客户端查询服务端权益或使用缓存的服务端权益快照。
3. 有权益时进入功能。
4. 无权益、额度耗尽或订阅过期时展示付费墙或降级体验。

### Flow-COM-004 订阅过期、退款或撤销
1. 后端收到商店状态更新或在权益刷新时检测状态变化。
2. 后端更新 entitlement。
3. 客户端刷新后展示降级状态。
4. 用户可重新订阅或查看订阅管理说明。

### Flow-COM-005 账号注销
1. 用户在个人中心确认注销账号。
2. 客户端调用账号删除接口。
3. 后端删除或匿名化云端学习数据，记录删除日志。
4. 客户端清理本地会话、学习状态、收藏、个人 Wiki、会话和缓存。
5. 用户返回未登录状态。

## Required States
- 加载中：权益查询、购买处理中、恢复购买处理中、账号删除处理中。
- 成功：购买成功、恢复成功、权益刷新成功、账号删除成功。
- 空状态：没有可恢复购买、没有可用付费权益。
- 错误：未登录、商店不可用、收据无效、商品不匹配、网络失败、服务端校验失败。
- 降级：订阅过期、退款、撤销、额度耗尽。
- 配置阻断：测试登录开启、支付商品缺失、生产 API 缺失、签名或 release secret 缺失。

## Required Downstream Contracts
- Domain Schema：订阅、权益、购买、退款、宽限期、用量、账号删除和审计对象。
- API Contract：权益查询、Apple receipt 校验、Google purchase token 校验、恢复购买、账号删除、用量查询和扣减。
- Architecture / Security：服务端权益事实、密钥管理、支付校验边界、AI 成本控制、数据删除和审计策略。
- UX / Screen Spec：付费墙、会员页真实价格、恢复购买、过期降级、注销确认和文案一致性。
- QA / Test Plan：商业边界测试矩阵。
- DevOps / Release：iOS/Android 发布链路、商店配置、release secrets、符号表上传、回滚方案。

## Module Impact
- Backend：认证、支付、权益、用量、账号删除、审计。
- Frontend：会员页、个人中心、登录、付费墙、权益刷新、Android Billing、购买/恢复状态。
- Official scenario library：若场景包作为会员权益，场景列表和场景入口必须与权益状态一致。
- AI runtime：高成本能力必须接入用量和权益限制。
- Release：商店、签名、隐私、订阅条款、审核材料。

## Non-goals
- 不实现训练 Agent P0.1。
- 不扩展新场景包或 A1-C2 内容。
- 不实现 CMS、公开社区、真人导师市场或课程市场。

## Rollout Notes
- 商业化能力不得在缺少服务端权益和商业边界测试时对真实用户开放。
- 若离线内容、成就、500+ 句型库或专属学习报告无法在发布前完成，必须从会员页和商店文案中移除。
- 任何商业化实现完成后都不得直接 merge Product Base，必须先补齐验收、测试、实现报告和质量报告。

