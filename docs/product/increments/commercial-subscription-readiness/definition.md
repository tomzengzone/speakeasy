# Increment Definition：商业化订阅上线准备

## 状态
Draft - Product Manager accepted；进入 Requirement Development 的增量定义。

## Increment ID
`commercial-subscription-readiness`

## Active Stage
`docs/product/stages/p0-commercial-readiness.md`

## Primary Feature
`commercial-subscription`

## Affected Features
- `profile-membership`
- `access-onboarding`
- `voice-scenario-practice`
- `official-scenario-library`
- `learning-memory-review`
- `scoring-feedback`

## 上游决策
- `docs/process/change_request.md`：`CR-20260524-001 商业化订阅上线准备`
- `docs/product/baselines/current-mvp.md`
- `docs/product/feature_registry.md`
- Product Manager 商业化就绪审查结论：当前具备会员入口和 Apple IAP 前端雏形，但尚不具备真实商业订阅上线条件。

## Scope
- 将会员状态从本地展示字段升级为服务端权益事实。
- 建立 Apple 和 Google Play 订阅购买、恢复、校验、续订、退款、宽限期、过期和降级闭环。
- 建立免费/付费权益 gating，覆盖练习次数、AI 深度反馈、场景包、学习报告、离线或其他付费承诺。
- 替换 demo email/member flow，发布构建关闭测试手机号登录，并阻止错误配置进入生产。
- 完成微信、Apple 登录生产配置和后端回调校验。
- 完成账号注销、云端学习数据删除或匿名化、本地学习数据清理、删除日志和用户可理解反馈。
- 对齐会员页、商店文案、隐私申报和真实能力；未完成权益必须隐藏、降级或从付费承诺中移除。
- 建立商业风控：AI 成本控制、速率限制、滥用检测、支付审计、账号操作审计和数据删除审计。
- 补齐商业边界测试和发布准备。

## Non-goals
- 不负责训练 Agent 的 session 内 planner、micro-action、hint ladder 或 pressure check。
- 不负责新增 3-5 个场景包、A1-C2 内容体系、CMS 或内容生产工具。
- 不承诺离线内容包和成就系统在本增量内完成；如果它们作为会员权益保留，则必须单独拆分并进入商业承诺一致性检查。
- 不直接实现代码；本定义用于后续 Requirements、Spec、Acceptance、Traceability 和下游契约门禁。

## Required Product Artifacts
- `docs/product/increments/commercial-subscription-readiness/requirements.md`
- `docs/product/increments/commercial-subscription-readiness/spec.md`
- `docs/product/increments/commercial-subscription-readiness/acceptance.md`
- `docs/product/increments/commercial-subscription-readiness/traceability.md`

## Required Downstream Gates
- Domain Schema：订阅、权益、计划、购买、退款、宽限期、用量、账号删除和审计日志域对象。
- API Contract：订阅校验、权益查询、恢复购买、Google purchase token 校验、账号删除、用量查询和用量扣减接口。
- Architecture / Security：服务端权益事实、支付校验边界、AI 成本控制、数据删除、审计日志和密钥管理方案。
- UX / Screen Spec：付费墙、超限态、购买失败、恢复购买为空、订阅过期、退款后降级、账号注销确认和文案一致性。
- QA / Test Plan：商业边界测试矩阵和自动化/人工验收记录。
- DevOps / Release：iOS/Android 发布链路、release secrets、签名、Sentry 符号表、商店审核材料和回滚策略。
- Product Object Governance Check：每个下游门禁完成后需独立复核是否偏离本 increment。
- Documentation Governance：发布前复核 requirements/spec/acceptance/traceability、release checklist 和测试报告链路是否完整。

## Owner Agent
Product Manager Agent

## Checker Agent
Product Object Governance Check Agent；商业化实现完成前还需要 Documentation Governance、QA、DevOps 和安全/合规复核。

