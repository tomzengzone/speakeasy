# Requirements：商业化订阅上线准备

## 状态
Draft - 由 Product Manager 接受的 P0 商业化发布阻塞增量需求。

## Product Object
- Increment：`commercial-subscription-readiness`
- Stage：`docs/product/stages/p0-commercial-readiness.md`
- Primary feature：`commercial-subscription`
- Affected features：`profile-membership`、`access-onboarding`、`voice-scenario-practice`、`official-scenario-library`、`learning-memory-review`、`scoring-feedback`

## 上游来源
- `docs/product/increments/commercial-subscription-readiness/definition.md`
- `docs/process/change_request.md`：`CR-20260524-001 商业化订阅上线准备`
- Product Base：`docs/product/base/requirements.md`、`docs/product/base/spec.md`、`docs/product/base/acceptance.md`、`docs/product/base/traceability.md`
- Product Manager 商业化就绪审查结论

## Stage Scope Coverage
| Stage Scope ID | Requirement ID | Coverage status |
| --- | --- | --- |
| COM-SI-001 | FR-COM-001 | Covered |
| COM-SI-002 | FR-COM-002 | Covered |
| COM-SI-003 | FR-COM-003 | Covered |
| COM-SI-004 | FR-COM-004 | Covered |
| COM-SI-005 | FR-COM-005 | Covered |
| COM-SI-006 | FR-COM-008 | Covered |
| COM-SI-007 | FR-COM-006 | Covered |
| COM-SI-008 | FR-COM-007 | Covered |
| COM-SI-009 | FR-COM-009 | Covered |
| COM-SI-010 | FR-COM-010 | Covered |
| COM-SI-011 | FR-COM-011 | Covered |
| COM-SI-012 | FR-COM-012 | Covered |

## 目标用户与业务目标
- 作为学习者，我希望购买订阅后权益能立即生效、跨设备恢复、过期后有清晰提示，以便放心付费使用。
- 作为免费用户，我希望在触达付费边界时看到明确、真实的升级说明，以便判断是否订阅。
- 作为产品运营者，我希望订阅状态、权益、退款、过期、用量和账号删除可追踪，以便处理客服、风控和合规问题。
- 作为发布负责人，我希望商业化发布有明确门禁，以便避免错误配置、虚假承诺或无法恢复的付费事故进入生产。

## Assumptions
- 当前代码基线只承认会员页和 Apple IAP 前端雏形，不承认完整商业付费闭环。
- 服务端是订阅权益事实来源；客户端不得把本地 `memberPlan` 作为唯一付费状态依据。
- 付费权益必须先由产品定义，再由后端、前端、QA 和发布流程承接。
- 未完成的权益可以从会员页和商店文案中移除，而不是强行纳入本增量实现。

## Functional Requirements

### FR-COM-001 服务端订阅权益事实
系统必须由服务端保存和返回用户当前权益状态，包括订阅计划、状态、来源平台、生效时间、过期时间、宽限期、退款或撤销状态。

### FR-COM-002 Apple 订阅校验
系统必须通过后端校验 Apple 购买和恢复购买结果，匹配商品、交易和用户身份，并处理续订、退款、宽限期、过期和撤销。

### FR-COM-003 Android 订阅闭环
系统必须接入 Google Play Billing 购买和恢复购买，并通过后端校验 purchase token 后才授予权益。

### FR-COM-004 生产账号体系
系统必须使用后端账号状态和 token 作为登录事实，替换 demo email/member flow，并保证发布构建关闭测试手机号登录。

### FR-COM-005 社交登录生产配置
系统必须使用真实微信 AppID、Universal Link、URL scheme、后端回调配置，以及 Apple 登录开发者能力和签名配置。

### FR-COM-006 商业权益 gating
系统必须定义免费和付费用户可用能力，包括练习次数、AI 深度反馈、场景包、学习报告、离线能力或其他会员权益，并在无权益、额度耗尽、订阅过期时展示可恢复状态。

### FR-COM-007 官方场景库 gating
若场景包或场景数量作为会员权益，系统必须在官方场景库、场景入口和训练入口保持一致 gating，不得只在会员页承诺。

### FR-COM-008 账号注销与数据删除
系统必须支持账号注销，删除或匿名化云端学习数据，并清理本地登录、学习进度、收藏、个人 Wiki、会话和缓存数据，保留必要的合规审计日志。

### FR-COM-009 商业文案一致性
会员页、商店文案、隐私说明和实际能力必须一致。离线内容、成就、500+ 句型库、专属学习报告等未完成能力不得作为已兑现付费承诺。

### FR-COM-010 AI 成本与滥用控制
系统必须对 AI、ASR、TTS、发音评分等高成本能力实施用量限制、速率限制、成本预算、滥用检测和审计。

### FR-COM-011 商业边界测试
系统必须覆盖首次安装、旧数据升级、购买、恢复、退款、过期、宽限期、账号切换、注销、弱网、权限拒绝、崩溃恢复和 AI 额度耗尽等商业边界。

### FR-COM-012 发布门禁
商业化发布必须校验生产 API、支付商品、签名、release secrets、测试登录关闭、Sentry 符号表、商店审核材料、订阅条款、隐私申报和回滚方案。

## Non-goals
- 不实现 P0.1 训练 Agent 的 session 内训练逻辑。
- 不新增官方场景包或 A1-C2 内容体系。
- 不实现 CMS、社区、真人导师市场或课程市场。
- 不强制在本增量内完成离线内容包或成就系统；若未完成，必须移除对应商业承诺。

## Success Criteria
- 用户付款后权益以服务端状态生效，并可恢复。
- 退款、过期、撤销或账号切换后，权益能正确降级。
- 免费用户触达限制时，看到明确升级入口和当前不可用原因。
- 账号注销后，用户数据删除或匿名化范围可追踪。
- 会员页和商店文案不承诺未完成能力。
- 商业发布前有可执行测试矩阵和 release checklist。
