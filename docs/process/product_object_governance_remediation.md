# 产品对象治理整改方案

## 状态
Draft - 用于治理 feature、stage、increment、baseline、change request 和 artifact 的职责边界。

## 背景
当前项目已经具备 roadmap、feature backlog、MVP scope、change request、feature requirements、feature spec、acceptance criteria 和 traceability matrix，但这些文档把“APP 稳定功能结构”和“开发阶段/交付增量”混在了一起。

典型问题是 `mvp-learning-loop-requirements.md` 实际描述当前 MVP 基线，却位于 feature requirements 路径下；P0.1 表达自动化训练闭环是一个开发阶段增量，却被直接写成 `mvp-learning-loop-spec.md`。这类问题不能靠单次重命名解决，必须补齐产品对象治理规则。

## 治理目标
- Feature 代表 APP 长期稳定功能域，不代表开发阶段。
- Stage 代表开发阶段或优先级窗口，例如 MVP baseline、P0.1、P0.2、P1、P2。
- Increment 代表某个 stage 内交付的具体垂直切片，可以影响一个 primary feature 和多个 affected features。
- Baseline 代表当前已实现能力快照，用于事实记录、回归和差距分析，不承载未来新增需求。
- Change Request 记录范围变化和决策，不定义 feature 本身。
- Artifact 是围绕 increment 或 baseline 产生的需求、规格、验收、契约、测试、报告和发布证据。

## 目标工作流
```text
idea/change intake
-> product classification
-> feature registry / stage scope check
-> increment definition
-> requirement development
-> increment spec
-> acceptance criteria
-> architecture/domain/API/AI/UX contracts
-> implementation plan
-> code
-> tests
-> review/report/release
```

## 输出物边界
| 对象 | 默认职责 | 不应包含 |
| --- | --- | --- |
| Feature Registry | APP 稳定功能地图、feature owner、边界和状态 | 阶段计划、实现任务、测试证据 |
| Stage Scope | 阶段目标、阶段入口/出口、纳入和排除的 increment | 具体 API schema、UI 布局、代码实现 |
| Baseline | 已实现能力快照、事实来源、回归边界 | 未来新增需求、未批准计划 |
| Increment Definition | 本次交付切片、primary/affected features、范围和非目标 | 详细实现、验收用例、测试报告 |
| Increment Requirements | 用户目标、路径、成功标准、非目标、开放问题 | API 字段、prompt schema、UI 布局 |
| Increment Spec | 状态、输入输出、依赖、失败路径、模块影响、测试映射 | 代码实现、产品阶段决策 |
| Acceptance Criteria | 可观察 pass/fail 行为 | 类名、函数名、数据库字段 |
| Contracts | domain/API/AI/UX 各自边界内的契约 | 产品优先级或跨阶段范围决策 |
| Implementation Plan | 切分、文件影响、测试策略、风险 | 新增需求或改写验收 |
| Reports | 实际完成、验证、风险、发布结论 | 补写需求或替代验收标准 |

## 小步整改任务
| 步骤 | 变更 Agent | 检查 Agent | 目标产物 | 检查点 |
| --- | --- | --- | --- | --- |
| 1 | Product Object Governance Change Agent | Product Object Governance Check Agent | 本整改方案 | 只新增治理计划，不迁移业务文档 |
| 2 | Product Object Governance Change Agent | Product Object Governance Check Agent | 两个 agent 定义 | agent 职责、Allowed Paths 和检查输出清楚 |
| 3 | Product Object Governance Change Agent | Product Object Governance Check Agent | `docs/process/workflow.md` | workflow 增加 classification、stage scope、increment gates |
| 4 | Product Object Governance Change Agent | Product Object Governance Check Agent | `docs/process/skill_quality_standard.md` 和文档治理 skill | 路径和内容边界区分 feature/stage/increment/baseline |
| 5 | Product Object Governance Change Agent | Product Object Governance Check Agent | requirement/spec/acceptance 生成类 skill | 生成类 skill 不再默认把 stage 当 feature |
| 6 | Product Object Governance Check Agent | Product Manager Agent | 检查结果和后续迁移建议 | 无非预期迁移，skill 校验通过，遗留风险明确 |

## 当前不做
- 不在本轮直接删除或移动 `mvp-learning-loop-requirements.md`。
- 不在本轮直接删除或移动 `mvp-learning-loop-spec.md`。
- 不在本轮改动 Flutter 业务代码。
- 不在本轮生成 P0.1 的完整 acceptance/domain/API/AI/UX 契约。
- 不在治理规则稳定前大规模迁移 traceability matrix。

## 迁移建议
规则落地后，再单独发起文档迁移 increment：
- 将当前 MVP 基线迁移到 `docs/product/baselines/current-mvp.md` 或等价路径。
- 将 P0.1 表达自动化训练闭环迁移到 increment 路径。
- 建立 `docs/product/feature_registry.md`，把训练 Agent、语音场景模拟、表达练习、学习记忆、评分、笔记本、场景库等登记为稳定 feature。
- 更新 roadmap、development status、change request 和 traceability matrix 的引用。

## 完成标准
- workflow 明确区分 feature、stage、increment、baseline 和 artifact。
- 生成类 skill 在创建 requirements/spec/acceptance 前必须确认对象类型。
- 文档治理 skill 能判断路径、内容边界和追踪链路是否混淆。
- Development Orchestrator 在路由实现前必须检查 increment definition 和必要下游契约。
- 检查 agent 每步都能判断“变更符合预期、没有引入新问题、没有非预期变更”。
