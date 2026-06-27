# 完成定义

只有满足以下条件，feature 才能标记为完成：

- [ ] Feature spec 已存在。
- [ ] Acceptance criteria 已存在，并已映射到测试。
- [ ] 实现开始前已存在 increment test case library，且每条已批准 AC 都映射到稳定 TC ID 或明确例外。
- [ ] 如果数据发生变化，Domain schema 已更新。
- [ ] 如果 frontend/backend boundary 发生变化，API contract 已更新。
- [ ] 如果 UI 发生变化，Screen spec 已更新。
- [ ] 如果 LLM 行为发生变化，AI output schema 已更新。
- [ ] 当变更影响稳定 SWC topology、data flow 或 reusable component boundary 时，已引用或更新 Global SWC architecture baseline。
- [ ] 对于 cross-layer、persistence、API、AI runtime、provider 或 reusable-module 变更，已存在 SWC allocation，或已记录明确 no-SWC-impact exception。
- [ ] 当变更触及既有能力时，SWC allocation 已包含 Existing Implementation Baseline，并列出具体 existing user flow、code path、SWC、Flow ID、API/OpenAPI call、domain/data ownership、tests/evidence、non-regression behavior 和 legacy/deprecated parts。
- [ ] SWC allocation 已包含 Delta From Existing Baseline，并列出 reused SWC/Flow ID、changed/unchanged behavior、allowed/forbidden new code、existing code modified、migration/deprecation impact 和 regression proof required。
- [ ] SWC allocation 已引用适用的 global `SWC-FLOW-*` ID，或把 local flow 分类为 `one-off`、`proposed-global` 或 `legacy-compatible`。
- [ ] 适用时，SWC allocation 已把受影响 FR/AC 映射到 frontend SWC、backend SWC、API/OpenAPI、domain entity、DB table/migration 和 test case。
- [ ] 实现前已审查 required reuse 和 forbidden duplicate-build boundary。
- [ ] 对 implementation-impacting 变更，`python3 scripts/check_swc_allocation.py --scope changed --base-ref <base-ref>` 已通过。
- [ ] 涉及持久化项目文档变更时，新增或修改的自然语言内容默认中文；若保留英文原文，则英文正文块后必须紧跟中文翻译；`python3 scripts/check_document_language.py --scope changed --base-ref <base-ref>` 已通过。
- [ ] 实现已完成。
- [ ] Unit test 已新增或更新。
- [ ] 风险需要时，integration/widget/e2e test 已新增。
- [ ] Regression check 已通过，或 gap 已记录。
- [ ] 面向用户的变更已完成 UX review。
- [ ] Implementation report 已更新。
- [ ] Release checklist impact 已审查。

## 完成规则
任何必需复选项未完成且没有明确记录例外时，不得把 feature 标记为完成。
