# 完成定义

只有实际适用的条目全部满足或存在 contract 允许的明确例外，工作才可标记完成。

## 产品与测试

- [ ] 产品行为变化已引用完整且 approved 的 Story / Child VS；Story/VS 缺口由 Product Manager 修正。
- [ ] 每个 selected approved VS 至少关联一条 approved、atomic FR，且 FR 只直接引用 VS。
- [ ] 每条适用 FR 有最低成本 FR-TC，或有 owner、原因、影响与失效期限明确的例外。
- [ ] 每个实施中的 selected VS 有用户可感知的 integration/E2E VS-TC，覆盖关键失败/降级路径。
- [ ] 三类 TC 只保存各自唯一 direct edge，并具有自包含 oracle、Given/When/Then、边界/负例、层级、scope、selector、脚本路径和执行命令。
- [ ] Derived canonical traceability 可从 owning sources 重建，无悬空引用或重复 edge ownership。

## 工程事实与实现

- [ ] API/OpenAPI、Domain/Persistence、AI、UX 或架构事实发生变化时，owning Engineering Contract 已同步。
- [ ] 每个发生事实变化的 Contract 有适用 Contract-TC；低风险未被用作跳过 Contract 同步的理由。
- [ ] 稳定共享 SWC topology、system flow 或 reusable boundary 变化时，当前 SWC 架构与 catalog 已更新并完成独立架构检查。
- [ ] 触碰既有能力时已复用当前实现和跨切面边界；新增组件或旁路有明确必要性和迁移责任。
- [ ] 实现范围只覆盖 selected VS / FR，未在代码、TC、Contract 或 Issue 中发明产品行为。

## 验证与证据

- [ ] 先运行受影响 FR/Contract 的最窄快速测试，再运行 selected VS 的定向全链路测试。
- [ ] Unit、contract、integration、migration、AI eval、widget 或 E2E 测试已按实际影响新增或更新。
- [ ] Applicable governance validator、语言检查和风险 Gate 已通过。
- [ ] PR 的编译、静态分析和测试均通过，CI 结果绑定被检查的 commit SHA；TC Catalog 和 traceability 未复制运行状态。
- [ ] 用户可见变化完成适用 UX review；release scope 命中时完成 release checklist、rollback 与发布控制。
- [ ] 需要持久报告时，报告只记录本次范围、文件、测试、风险和后续项；不复制产品或治理 authority。

## 完成规则

Stage、Increment、Work Package 或 PR 状态不能替代上述事实和证据。任一 required item 缺失、候选 SHA 漂移、独立 checker 缺失或未关闭 blocker 都会阻止完成与 baseline 激活。
