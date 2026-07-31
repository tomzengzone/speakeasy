# 功能需求目录

## 文档状态

- Artifact ID: `FUNCTIONAL_REQUIREMENT_CATALOG`
- Status: candidate

本目录只保存 Product Manager 决定从已批准 Vertical Slice 表达为 Functional Requirement 的产品行为。FR 可包含一个或多个独立规则、不变量、边界或失败条件；每条 FR 只能通过 `source_vs_ids` 直接引用一个或多个 approved VS。Capability 与 Sub-capability 字段仅用于分类、编号和影响筛选，不构成第二条产品 lineage。Stage、Increment、Work Package、PR、实现和执行结果不属于本目录。

当前条目仅把已批准 `VS-TRAIN-001-1` 的既有行为登记到新治理目录；它不是 PR-003 产品实现，也不表示旧文档迁移或完整历史覆盖。

## FR-TRAIN / CAP-TRAIN-06 训练闭环展示状态

### FR-TRAIN-001 — 完成练习后的闭环展示

- Status: `approved`
- source_vs_ids: `VS-TRAIN-001-1`
- primary_capability_id: `CAP-TRAIN`
- primary_sub_capability_id: `CAP-TRAIN-06`
- affected_capability_ids: `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN`
- Rule: 学习者完成当前官方场景的一轮语音练习并触发结束动作后，系统必须展示本轮练习总结和可见的后续学习入口。
- Boundary: 当练习结果失败或不可用时，系统展示可恢复的错误或空状态，不得错误推进学习进度。
- Approval basis: `VS-TRAIN-001-1` existing approved product fact; PR-003 revision 11 authorizes governance cataloging only.

## 维护规则

- Product Manager 按 implementing VS 决定是否创建 FR；零条 FR 不会仅因缺少 FR 而阻止交付。
- FR 存在时必须保持 approved 状态和非空 `source_vs_ids`；其一个或多个规则、不变量、边界或失败条件不得在 TC 或 Contract 中重新定义。
- FR 变化由 Product Manager 批准；需求开发者按 `FUNCTIONAL_REQUIREMENT_CATALOG` Artifact contract 贡献内容。
