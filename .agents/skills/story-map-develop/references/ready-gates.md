# Story 和 Slice 就绪门

只有记录创建、语义重写、拆分/合并或批准就绪工作才可以读取本 reference。

## 层级模型与业界等价关系

- Capability 是稳定的业务能力和产品事实归属边界，应该体现一致的业务语言、规则、状态和长期责任；它不是页面集合、用户旅程步骤、代码 package 或一次交付批次。
- Parent User Story 是 Story Map 中的用户价值场景，表达一个参与者在特定情境下要完成的一个目标和主要结果。它用于保持叙事上下文，不是 sprint-ready 工作量单位。
- Child Vertical Slice 是实际可进入交付的 backlog 单元，对应业界常说的 sprint-ready User Story 或 vertical Product Backlog Item。它必须独立产生用户可感知价值、业务价值或可验证学习，并形成端到端反馈闭环。
- Story Map release slice 是为达成阶段性目标而从完整叙事流中选择的一组条目，不等同于单个端到端 Child Vertical Slice；它属于适用的 Stage/Increment planning，不在 Story Map 行中保存交付 metadata。
- 实现 task 是完成 Child VS 的开发计划，可以按层、组件或专业分工继续拆解，但不得进入 Story Map。

层级之间不得用固定数量换算。一个 Story 需要多少 Child VS 由可独立排序的价值和反馈边界决定；Child 数量只能触发审查，不能替代语义判断。

## Capability 与 module 边界

- Primary Capability 选择拥有主要业务决策、业务状态或用户结果的边界，而不是拥有入口页面、通用组件或最多代码改动的边界。
- Affected Capability 只记录完成该用户闭环所需的真实产品交接、状态消费或责任域协作。共享 UI、基础设施、数据库访问或技术调用本身不构成 affected classification。
- 一个 Child VS 可以跨多个技术 module 和架构层；如果为完成一次用户价值必须分别等待 UI、backend、data 或 QA 工单，则这些是同一 Vertical Slice 的 tasks，不是 sibling Slice。
- 候选 Story 长期混合不同业务词义、核心规则或状态所有权时，返回 Capability 边界 finding，由 owning workflow 决定是否调整 Registry；不得在本 Skill 中直接重构 Capability。

## Story 和 Slice 语义

- 一个 Story 表达一个用户价值场景。其 description 必须清楚说明参与者、上下文、产品对象、目标/操作和可见结果。独立旅程或主要结果应该拆分。
- Story 标题应该使用能表达用户目标的动宾短语；`作为……我希望……以便……` 只能用于检查语义，不能替代参与者、情境、对象和结果事实。
- 一个 Child Slice 是 Story 下用户可以感知的最小交付闭环。必须说明触发条件或入口、业务对象、最小可用路径、决策/状态影响、可见结果，以及任何会改变用户下一步选择的关键失败或恢复路径。
- Child Slice 必须端到端穿过实现该结果所需的产品边界。端到端不表示每个 Slice 必须修改所有技术层，而是不得把一次结果按 UI、API、domain、persistence 或测试专业横向拆开。
- 只有触发条件、主要结果、业务状态/决策、目标用户差异或可独立验证价值不同时，才应该拆分 sibling Slice；不得按照 CRUD 标签或通用 loading/save/retry 脚手架拆分。

## 颗粒度与 ready 诊断

使用 `INVEST` 检查 Child VS，不把它作为写作格式：

- Independent：能够独立排序、验证，并在不破坏其他 sibling 的情况下启用、隐藏或回退；已知业务依赖必须显式，不得伪装成技术层 Slice。
- Negotiable：记录要达到的产品行为和边界，不预先冻结 UI 设计或实现方案。
- Valuable：删除该 Slice 会移除一种可排序的用户价值、业务价值或验证学习；若只减少一个开发步骤，它不是独立 Slice。
- Estimable：交付团队有足够产品事实判断范围和主要风险；无法估算时返回 ambiguity 或先处理最小 learning slice，不用虚构细节。
- Small：一个跨职能团队能够在一个迭代内达到适用 Definition of Done；成熟团队应该继续寻找更短反馈周期，但 Story Map 不记录 Story Point 或工期。
- Testable：能够从触发到可见结果验证业务状态和关键边界；精确规则由适用的下游 FR/TC/Contract 持有，Story Map 不复制其正文。

同时满足以下问题，候选条目才是 delivery-grade Child VS：

1. 能否向用户或业务方单独演示一个有意义的结果？
2. 能否通过产品边界独立验证，而不是只检查一个组件存在？
3. 能否单独排序、延后或取消，而不会让其余 sibling 全部失去意义？
4. 能否由同一跨职能团队在一个迭代内完成到适用 Definition of Done？
5. 是否只包含一个主要结果，而不是多个可分别验证的用户闭环？

任何一项为否时，必须合并、继续切分或输出 finding；不得仅通过补写成功/失败句式使其看起来完整。

## 切分顺序

优先寻找贯穿工作流起点和结果的最薄可用路径，再按以下差异逐步增强：

1. 工作流路径：先交付能从触发走到结果的最短路径，再扩展中间步骤或替代路径；不得只交付工作流前半段。
2. 业务规则变体：先处理一个可用规则子集，再增加确实可以独立排序的规则变体。
3. 数据、用户群或 channel 变体：当不同类型能独立产生价值和验证时分别切分；纯字段差异不成立。
4. 简单与复杂：先交付可用的简单核心，再增加高级行为或复杂交互。
5. Operations：只有不同操作各自对应独立用户目标和结果时才拆分；“管理某对象”不得机械展开为 CRUD 行。
6. Non-functional behavior：只有基础版本仍安全、合规、完整且可用时，才可以延后性能或体验增强；security、privacy、data integrity、legal compliance 和正确性底线不得被切到以后。

切分后至少应该出现一个可以独立提前验证、延后或取消的 Child VS。若所有结果必须同时存在才可用，候选内容通常仍是一个 Slice 的 tasks 或 acceptance details。

## 候选条目分类

| 类型 | 判定 | 处理 |
| --- | --- | --- |
| `delivery slice` | 具有独立触发、端到端路径、主要结果和可验证价值 | 可以成为 Child VS |
| `acceptance detail` | 字段、格式校验、按钮状态、文案、loading、单个错误或同一结果的边界规则 | 合并到所属 Slice 的必要语义，或由适用下游 Artifact 持有 |
| `engineering task` | UI、API、database、migration、组件、测试自动化或部署步骤 | 留在实现计划，不进入 Story Map |
| `cross-cutting constraint` | security、privacy、performance、availability、compliance 等跨条目约束 | 交给 owning Artifact；只在改变该 Slice 用户决策时摘要到 description |
| `ambiguity` | 缺少行为来源、主要结果、状态归属或可验证边界 | 返回 finding，等待 Product Manager 决策 |

## 信息与权威边界

每个新增或重写的 Slice 必须包含至少两个无法从 Capability 名称推导的具体产品事实，例如对象、选择、状态含义、范围差异、交接、例外或数据边界。移除产品名词后如果只剩通用动词，必须返回歧义发现项。

持久化前，必须在当前任务或审查证据中声明范围模式、目标记录、来源清单、遗漏范围、非目标和未解决决策；这些是批准输入，不是额外的 Story Map 列。每条记录必须分类为 `draft proposal`、`PM-provided behavior`、`existing canonical fact` 或 `proposed ambiguity`。受影响的 Capability ID 必须标识真实的跨 Capability 影响或 `none`；registry 记录只提供分类边界，不得提供缺失的行为。

## 就绪决定

- 结构：`US-<Prefix>-<NNN>` 必须唯一；按 Story 分组的 `VS-<Prefix>-<Story NNN>-<Child N>` ID（例如 `VS-CONTENT-001-1`）必须唯一；VS 的 Story 编号必须与父级 Story 一致，并具有五列、正确的 Capability 章节、一个父级且没有下游字段。
- 叙事：Story 必须包含参与者/情境/对象/目标/主要结果；Slice 必须包含触发或入口/对象/最小路径/决策或状态/可见结果；同级 Slice 必须具有独立价值并通过 delivery-grade 诊断。
- 颗粒度：Slice 必须是一个迭代内可完成的端到端产品行为；页面/组件/字段/技术层/验收细节不能独立通过。
- 权威边界：来源覆盖、遗漏范围、非目标、未解决决策和 Capability 映射必须在当前任务或审查证据中明确；不得为此增加额外的 Story Map 字段，且 `draft` 不代表批准。
- 校验：先对本次修改范围运行 package 内的确定性 Story Map helper，再解析并运行 `STORY_MAP.validation_command`、适用的 language Gate 和 checker Gate。helper 只证明结构，不得替代 narrative、颗粒度或独立语义检查。
