# Story 和 Slice 就绪门

只有记录创建、语义重写、拆分/合并或批准就绪工作才可以读取本 reference。

## Story 和 Slice 语义

- 一个 Story 表达一个用户价值场景。其 description 必须清楚说明参与者、上下文、产品对象、目标/操作和可见结果。独立旅程或主要结果应该拆分。
- 一个 Child Slice 是 Story 下用户可以感知的最小交付闭环。必须说明触发条件、操作、业务对象、决策/状态影响、可见结果，以及任何会改变决策的例外。
- 只有触发条件、结果、状态影响、业务决策或可独立验证价值不同时，才应该拆分同级 Slice；不得按照 CRUD 标签或通用 loading/save/retry 脚手架拆分。

## 信息与权威边界

每个新增或重写的 Slice 必须包含至少两个无法从 Capability 名称推导的具体产品事实，例如对象、选择、状态含义、范围差异、交接、例外或数据边界。移除产品名词后如果只剩通用动词，必须返回歧义发现项。

持久化前，必须在当前任务或审查证据中声明范围模式、目标记录、来源清单、遗漏范围、非目标和未解决决策；这些是批准输入，不是额外的 Story Map 列。每条记录必须分类为 `draft proposal`、`PM-provided behavior`、`existing canonical fact` 或 `proposed ambiguity`。受影响的 Capability ID 必须标识真实的跨 Capability 影响或 `none`；registry 记录只提供分类边界，不得提供缺失的行为。

## 就绪决定

- 结构：`US-<Prefix>-<NNN>` 必须唯一；按 Story 分组的 `VS-<Prefix>-<Story NNN>-<Child N>` ID（例如 `VS-CONTENT-001-1`）必须唯一；VS 的 Story 编号必须与父级 Story 一致，并具有五列、正确的 Capability 章节、一个父级且没有下游字段。
- 叙事：Story 必须包含场景/对象/操作/结果；Slice 必须包含触发条件/对象/决策/结果；同级 Slice 必须具有独立价值。
- 权威边界：来源覆盖、遗漏范围、非目标、未解决决策和 Capability 映射必须在当前任务或审查证据中明确；不得为此增加额外的 Story Map 字段，且 `draft` 不代表批准。
- 校验：针对本次修改范围运行 `python .agents/skills/story-map-develop/scripts/validate_story_map.py --capability <CAP-ID>`，然后运行适用的 contract、language 和 checker Gate。
