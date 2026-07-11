# 产品对象治理整改方案

## 状态
Active remediation record - 当前 active 规则已使用 Capability、Story/Slice、stage、increment、baseline、change request 和 artifact 的对象边界；本文记录从旧 feature 模型迁移到 V2 Capability Registry 的治理依据。

## 背景
当前项目已经具备 roadmap、change request、Product Base、V2 Capability Registry、Story Map、stage、increment、acceptance criteria 和 traceability matrix，但历史文档曾把“APP 稳定能力分类”和“开发阶段/交付增量”混在一起。

典型问题是旧 feature slug 同时承担稳定分类、阶段范围和增量交付语义。当前决策是使用 V2 Capability / Sub-capability 做稳定分类，Story/Slice 做行为来源，Stage/Increment 做交付结构；V1 snapshot 只保留历史追溯。

## 治理目标
- Capability / Sub-capability 代表 APP 长期稳定产品分类，不代表开发阶段，也不直接定义产品行为。
- User Story / Vertical Slice 是 Requirement Development 的直接产品行为上游。
- Stage 代表开发阶段或优先级窗口，例如 MVP baseline、P0.1、P0.2、P1、P2。
- Increment 代表某个 stage 内交付的具体垂直切片，使用 primary/affected Capability ID 与 Sub-capability ID 做分类。
- Baseline 代表当前已实现能力快照，用于事实记录、回归和差距分析，不承载未来新增需求。
- Change Request 记录范围变化和决策，不定义 feature 本身。
- Artifact 是围绕 increment 或 baseline 产生的需求、规格、验收、契约、测试、报告和发布证据。

## 目标工作流
```text
idea/change intake
-> product classification
-> candidate destination confirmation; run capability-registry-develop Gate A first when unresolved
   |-- non-Registry -> owning workflow -> STOP Registry development
   `-- Registry -> Product Manager confirms target object / target ID / change mode
       -> matching type-specific Gate B
       -> Registry row proposal
       -> Product Manager exact-row final approval and persistence
       -> registry validator and Product Object Governance Check
       -> stage scope check
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
| Capability Registry | PM-approved 稳定 Capability / Sub-capability 分类事实、owner 和边界 | Story/Slice 行为、阶段计划、实现任务、测试证据 |
| Stage Scope | 阶段目标、阶段入口/出口、纳入和排除的 increment | 具体 API schema、UI 布局、代码实现 |
| Baseline | 已实现能力快照、事实来源、回归边界 | 未来新增需求、未批准计划 |
| Increment Definition | 本次交付切片、primary/affected Capability 与 Sub-capability、范围和非目标 | 详细实现、验收用例、测试报告 |
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
| 4 | Product Object Governance Change Agent | Product Object Governance Check Agent | `docs/process/skill_quality_standard.md` 和文档治理 skill | 路径和内容边界区分 Capability/stage/increment/baseline |
| 5 | Product Object Governance Change Agent | Product Object Governance Check Agent | requirement/spec/acceptance 生成类 skill | 生成类 skill 不再把 stage 当 Capability 或行为输入 |
| 6 | Product Object Governance Check Agent | Product Manager Agent | 检查结果和后续迁移建议 | 无非预期迁移，skill 校验通过，遗留风险明确 |
| 7 | Product Object Governance Change Agent | Product Object Governance Check Agent | `capability-registry-develop`、Gate templates、PM/workflow/checker routing | Gate A、PM destination confirmation、Gate B、PM exact-row final approval 串行独立；非 Registry 分支停止；每步独立检查 |

## 当前决策
- 清理活跃产品/流程文档中的旧 feature 目录引用。
- Product Base 文件作为需求初版/稳定 Product Base，不记录旧 feature 文档来源。
- `docs/product/feature_registry.md` 是 PM-owned V2 canonical registry；普通产品事实维护使用 `capability-registry-develop`，不分配 feature 文档目录，也不拥有 stage/increment 交付计划。
- 候选对象归宿与同类型颗粒度必须分开：Gate A 先判定并由 PM 确认 destination/target，只有 Registry destination 才进入匹配类型的 Gate B；PM destination confirmation 不代替 exact-row final approval。
- 每个已持久化 Capability / Sub-capability 语义变更由 Product Object Governance Check 在现有 report 路径保留精简审计摘要；该摘要不是第二个 Registry source of truth。
- 旧 feature 目录实体删除留到后续独立步骤；本步骤不删除实体文件。
- 不改动 Flutter 业务代码。

## 迁移建议
规则落地后，再单独发起实体清理步骤：
- 删除旧 feature 目录实体文件。
- 保持 Product Base、Story Map、Capability Registry、stage、increment、baseline 和 change request 的对象化路径。
- 更新仍指向旧 feature 目录的非活跃历史引用时，必须确认不会改写历史报告事实。

## 完成标准
- workflow 明确区分 Capability、Story/Slice、stage、increment、baseline 和 artifact。
- workflow 与专属 skill 明确执行 Gate A -> PM destination confirmation -> Gate B -> PM exact-row final approval，并对 non-Registry destination 显式 STOP。
- 生成类 skill 在创建 requirements/spec/acceptance 前必须确认对象类型。
- 文档治理 skill 能判断路径、内容边界和追踪链路是否混淆。
- Development Orchestrator 在路由实现前必须检查 increment definition 和必要下游契约。
- 检查 agent 每步都能判断“变更符合预期、没有引入新问题、没有非预期变更”。
