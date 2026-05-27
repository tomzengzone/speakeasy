# Traceability：商业化订阅上线准备

## 状态
Draft - 增量级需求、规格、验收和下游证据追溯矩阵。

## 上游
- Definition：`docs/product/increments/commercial-subscription-readiness/definition.md`
- Requirements：`docs/product/increments/commercial-subscription-readiness/requirements.md`
- Spec：`docs/product/increments/commercial-subscription-readiness/spec.md`
- Acceptance：`docs/product/increments/commercial-subscription-readiness/acceptance.md`

## Traceability Matrix

| Requirement | User Story / Goal | Acceptance Criteria | Code Evidence | Test Evidence | Status |
| --- | --- | --- | --- | --- | --- |
| FR-COM-001 服务端订阅权益事实 | 学习者购买后权益可恢复；运营者可追踪权益 | AC-COM-001, AC-COM-005, AC-COM-006 | 待实现 | 待生成 | Planned |
| FR-COM-002 Apple 订阅校验 | iOS 用户购买和恢复后权益可靠 | AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004 | 待实现 | 待生成；需沙盒验收 | Planned |
| FR-COM-003 Android 订阅闭环 | Android 用户可购买、恢复和降级 | AC-COM-001, AC-COM-002, AC-COM-003, AC-COM-004 | 待实现 | 待生成；需 Google Play 内测验收 | Planned |
| FR-COM-004 生产账号体系 | 付费用户状态不依赖 demo flow | AC-COM-008 | 待实现 | 待生成 | Planned |
| FR-COM-005 社交登录生产配置 | 微信/Apple 登录可用于商店版本 | AC-COM-009 | 待实现 | 待生成；需平台配置验收 | Planned |
| FR-COM-006 商业权益 gating | 免费和付费用户边界清晰 | AC-COM-006, AC-COM-012 | 待实现 | 待生成 | Planned |
| FR-COM-007 官方场景库 gating | 场景包权益在所有入口一致 | AC-COM-007 | 待实现 | 待生成 | Planned |
| FR-COM-008 账号注销与数据删除 | 用户可注销并删除/匿名化数据 | AC-COM-010 | 待实现 | 待生成 | Planned |
| FR-COM-009 商业文案一致性 | 用户不会为未完成权益付费 | AC-COM-011 | 待实现 | 待生成；需人工文案验收 | Planned |
| FR-COM-010 AI 成本与滥用控制 | 运营者控制成本和滥用风险 | AC-COM-012 | 待实现 | 待生成 | Planned |
| FR-COM-011 商业边界测试 | 发布前覆盖商业事故路径 | AC-COM-013 | 不适用 | 待生成 QA 记录 | Planned |
| FR-COM-012 发布门禁 | 发布负责人可阻断错误配置 | AC-COM-014 | 待实现 | 待生成 release 验收 | Planned |

## Required Downstream Evidence
- Domain Schema：待创建或更新。
- API Contract：待创建或更新。
- Architecture / Security：待创建或更新。
- UX / Screen Spec：待创建或更新。
- QA / Test Plan：待创建或更新。
- DevOps / Release：待创建或更新。
- Implementation Report：待实现后更新。
- Test Report：待测试后更新。
- Quality Report：待质量复审后更新。

