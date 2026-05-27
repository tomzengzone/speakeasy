# 变更请求

## 状态
模板与流程基线。

## 必填字段
- id
- date
- requester
- affected feature
- change summary
- reason
- scope impact
- architecture impact
- domain impact
- API impact
- AI runtime impact
- UX impact
- test impact
- release impact
- decision
- follow-up

## 决策取值
- proposed
- accepted
- rejected
- deferred

## 规则
被接受的变更请求必须先更新相关源文档，之后才能开始实现。

## CR-20260523-001 表达自动化训练 Agent

### id
CR-20260523-001

### date
2026-05-23

### requester
当前规划线程中的产品请求。

### affected feature
场景练习、表达学习、复习、AI runtime、用户进度。

### change summary
将现有语音场景模拟升级为训练型 Agent：在 `job_interview` 和 `onboarding_introduction` 两个官方场景中，把场景动作链拆成听一句、选一个、回一句、跟一句、补一句、在追问下继续说等 micro-action；由 session 内 planner 接管训练组织、提示阶梯、重试、降级、升级、即时反馈和轻量压力检测，并把每轮学习证据写回。跨 session/跨天复现、L0-L5 掌握阶梯和长期记忆调度放入 P0.2。

### reason
当前 MVP 已覆盖场景练习、结构化纠错、表达保存和基础复习。该增量用于强化产品核心承诺：让教练主动编排训练，而不是只对开放练习回合做被动回应。

### scope impact
扩展 MVP 行为。P0.1 第一版限制为 2 个现有官方场景、1 套 session 内训练 planner、1 套 micro-action flow、1 套 hint ladder、1 套 in-session pressure check 和训练证据写回规则；不新增第三个场景，不承诺跨 session/跨天调度，不引入完整 L0-L5 掌握阶梯。

### architecture impact
需要新增 session 内训练 planner，或扩展当前场景编排器，使当前小动作、目标表达、提示等级、重试、降级、升级和轻量施压的决策保持确定性并可测试。长期掌握状态推进和跨 session 调度留到 P0.2。

### domain impact
P0.1 需要正式定义训练单元、action chain step、micro-action、hint level、session 阶段、轻量压力检测和学习证据写回。表达技能图谱、L0-L5 用户表达掌握等级、跨天复现规则和长期记忆调度属于 P0.2 域模型扩展。

### API impact
如果训练状态需要在本地存储之外持久化，可能影响前后端契约。第一版可根据实现阶段选择本地或 repository-backed 方式。

### AI runtime impact
需要更新 prompt 契约，使 LLM 返回结构化提示、反馈和追问建议；LLM 不得直接拥有持久化掌握状态的变更权。

### UX impact
需要支持一次一个微动作、支架化重试、场景 drill、hint ladder、轻量追问、session recap 和本轮下一步建议等 UI 状态。跨天复现安排不进入 P0.1 UI 承诺。

### test impact
需要补充 session 阶段流转、planner 决策、hint ladder 升降级、轻量压力检测、训练证据写回的单元测试；AI 输出 schema 校验测试；训练闭环的 widget 测试。L0-L5 掌握状态推进和跨 session 回退规则测试留到 P0.2。

### release impact
建议通过小场景包或 feature flag 发布，先验证训练闭环再扩大内容范围。

### decision
accepted

### follow-up
Product Manager 接受该变更为后续产品路线，但分阶段落地：
- P0.1：在现有 `job_interview` 和 `onboarding_introduction` 官方场景中落地语音优先、文本兜底的 FSI 式表达自动化训练闭环，并明确包含 session 内训练 planner、micro-action UI/flow、hint ladder 和 in-session pressure check。
- P0.2：强化跨 session/跨天训练编排、压力阶梯、L0-L5 掌握等级和长期记忆引擎。
- P1/P2：再扩展任意短语笔记、评分产品化、更多场景包和 A1-C2 内容体系。

P0.1 标准起始工件：`docs/product/increments/p0-1-expression-automation-training/definition.md`。

Legacy P0.1 spec source：`docs/product/features/mvp-learning-loop-spec.md`，已迁移或提炼到：
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`
- `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- `docs/product/increments/p0-1-expression-automation-training/traceability.md`

## CR-20260524-001 商业化订阅上线准备

### id
CR-20260524-001

### date
2026-05-24

### requester
当前规划线程中的商业化订阅产品请求。

### affected feature
`commercial-subscription`、`profile-membership`、`access-onboarding`、`voice-scenario-practice`、`official-scenario-library`、`learning-memory-review`、`scoring-feedback`。

### change summary
将当前“会员页 + Apple IAP 前端雏形”升级为真实商业订阅上线准备增量。范围包括生产账号、Apple/Google 订阅校验、服务端权益持久化、Android Billing、免费/付费权益 gating、账号注销与数据删除、会员页文案一致性、商业风控、AI 成本控制、支付审计、隐私申报和商店发布门禁。

### reason
Product Manager 商业化就绪审查判断：当前 APP 适合继续内测或做付费前准备，但不适合直接面向真实用户收费。主要原因是缺少服务端权益、Android 支付、生产账号、完整商业 gating、账号删除闭环和商业发布测试矩阵。若直接上线付费，会出现付款后权益不可恢复、退款或过期后继续开放、客户端伪造会员状态、AI 成本失控、商店文案承诺无法兑现等风险。

### scope impact
新增 P0 商业化发布阻塞阶段和 `commercial-subscription-readiness` 增量。该增量与 P0.1 表达自动化训练闭环并行，不替代训练 Agent，也不把商业 gating 作为 P0.1 训练闭环前置条件。商业化付费发布前必须补齐本变更范围。

### architecture impact
需要明确客户端、后端、商店、AI runtime、账号服务和发布流水线的边界。订阅权益事实必须由服务端产生和保存，客户端只展示和请求刷新权益。AI/ASR/TTS 用量限制、权益 gating 和审计日志应在服务端或可信边界执行。

### domain impact
需要定义 subscription、entitlement、plan、purchase、receipt verification、refund、grace period、usage quota、account deletion job、audit log 等域对象。需要定义订阅状态机和权益状态机，覆盖 free、pending、active、grace、expired、refunded、revoked 等状态。

### API impact
需要补齐或确认订阅校验、权益查询、恢复购买、Google purchase token 校验、账号删除、用量查询、用量扣减、审计日志等 API 契约。错误码必须覆盖未登录、无权益、额度耗尽、收据无效、商品不匹配、订阅过期、恢复购买为空等情况。

### AI runtime impact
AI runtime 需要接入用量限制、成本控制和无权益/额度耗尽兜底。LLM、ASR、TTS、发音评分等高成本能力不能只依赖前端开关控制。

### UX impact
需要新增或调整付费墙、超限态、购买处理中、购买失败、恢复购买为空、订阅过期、退款后降级、账号切换后权益刷新、账号注销确认和数据删除反馈。会员页、商店文案和实际能力必须一致；未完成权益不得作为已兑现承诺。

### test impact
需要补充商业边界测试矩阵：首次安装、旧本地数据升级、手机号/Apple/微信登录、购买、恢复、退款、过期、宽限期、账号切换、注销、弱网、麦克风/语音权限拒绝、崩溃恢复、AI 额度耗尽和滥用防护。支付、权益 gating、账号生命周期和文案一致性必须有自动化或人工验收记录。

### release impact
付费发布前必须补齐 App Store Connect / Play Console 元数据、订阅条款、隐私申报、支持 URL、审核测试账号、iOS/TestFlight/App Store 发布链路、Android/Play Console 发布链路、签名、release secrets、Sentry 符号表上传和回滚策略。

### decision
accepted

### follow-up
Product Manager 接受该变更为付费上线前的 P0 发布阻塞增量：
- 新增 stable feature：`commercial-subscription`。
- 新增 stage：`docs/product/stages/p0-commercial-readiness.md`。
- 新增 increment definition：`docs/product/increments/commercial-subscription-readiness/definition.md`。
- 已补齐 `commercial-subscription-readiness` 的 requirements、spec、acceptance 和 traceability。
- Development Orchestrator 后续应路由 Domain Schema、API Contract、Architecture/Security、UX/Screen Spec、Backend、Frontend、QA/Test Plan、DevOps/Release 和独立 checker agent，逐步补齐商业发布门禁。
