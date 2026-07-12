---
name: story-map-develop
description: Use when Product Manager needs to create, split, rewrite, review, or ready-gate business-specific User Stories and Child Vertical Slices in docs/product/story_map.md, including rejecting formulaic or low-information narratives; Do not use to generate FR, spec, AC, TC, contracts, implementation plans, code, roadmap, priority, or release decisions.
---

# Story Map Develop

## Overview
用于创建、拆分、检查和 ready-gate `docs/product/story_map.md` 中的 User Story 与 Child Vertical Slice。

本 skill 只定义 Story/Slice 的开发方法和检查规则。Product Manager 拥有产品事实、状态批准、优先级、排序、拆分决定和下游承诺。

## When to Use
- 新增或修改 User Story。
- 在 User Story 下新增、拆分或调整 Child Vertical Slices。
- 检查 Story/Slice 是否过大、模糊、边界重叠或可批准。
- 检查 Story/Slice 是否与当前 story map 的表格结构一致。

## When NOT to Use
- 生成 FR、spec、pass/fail AC、TC、API/domain/UX/SWC contract、实现计划、代码或测试。
- 决定 roadmap、priority、stage、increment、acceptance、release 或 deferral。
- 仅凭 Capability Registry、Stage、Roadmap 或 Increment title 推导用户行为。
- 批量改写下游 Agent、Skill、模板、流程文档或历史 artifact。

## Ownership Boundary
- Canonical Story/Slice facts 只写入 `docs/product/story_map.md`，由 Product Manager 管理。
- `docs/product/feature_registry.md` 只提供 capability boundary 和 classification。
- Skill 可以输出 draft、split 或 ready-gate finding，但不能自行把条目标记为 `approved`。
- Story map 的变化不会自动触发 requirements、spec、AC、TC、SWC、报告或脚本变更。

## Inputs
- 用户或 Product Manager 提供的用户可见产品行为、边界与非目标。
- 每个目标区域可确认的业务对象、用户决策、生命周期状态、跨 capability 交接和有业务意义的例外；未知项必须保留为 ambiguity，不得用通用句式补齐。
- Scope mode：`capability`、`story`、`slice-review` 或 `ready-gate`。
- Source inventory：逐项区分 user-authorized draft proposal、PM-provided behavior、既有 canonical Story/Slice、legacy evidence、仅用于边界的 registry 条目和仍未确认的 proposed behavior。
- `docs/product/story_map.md` 中相关 capability 章节、目标 Story 和相邻 Story/Slice。
- `docs/product/feature_registry.md` 中相关 capability 边界。
- Existing User Story ID / Vertical Slice ID when updating existing scope。

默认只读取相关章节，不加载整个 story map。

## Outputs
- 可直接放入当前 story map 的 User Story 表格行。
- 可直接放入对应 Story 下的 Child Vertical Slice 表格行。
- Boundary note 建议。
- Split、ambiguity 或 ready-gate finding。
- PM approval required 说明。

## 文档路径约定
- Canonical Story/Slice facts：`docs/product/story_map.md`。
- Capability boundary reference：`docs/product/feature_registry.md`。
- Skill rules：`.agents/skills/story-map-develop/SKILL.md` 和 `.agents/skills/story-map-develop/SPEC.md`。
- Copy-ready templates：`.agents/skills/story-map-develop/assets/`。
- 默认输出为 non-persistent finding；只有 Product Manager 批准后才写入 story map。
- 本 skill 不创建或修改 requirements、spec、AC、TC、increment、SWC、report 或 release 文件。

## Current Story Map Format Contract
当前 `docs/product/story_map.md` 的格式是本 skill 的结构权威：

1. 一级章节按 capability 组织。
2. 每个 User Story 使用 `### US-... - <title>` 标题。
3. 标题下使用一行 User Story 表格。
4. `Child Vertical Slices:` 下使用同样列结构的多行 Slice 表格。
5. Story/Slice 表格只使用以下五列：

```text
Id | description | Status | Primary Capability ID | Affected Capability IDs
```

6. `description` 是产品语义源；不得再创建 Actor、Scenario、Success State 等重复 metadata 字段。
7. Vertical Slice 的 Parent User Story 由所在 Story 章节表达；不得为了重复父子关系而增加 `Parent User Story ID` 列。
8. Non-goals、来源、共享假设或 capability 边界优先写在文档级说明或就近 `Boundary note`，不在每行重复。
9. 现行状态只使用 `draft` 和 `approved`。只有 Product Manager 可以批准。
10. 不把现有 story map 批量转换成另一种 card、YAML 或字段表格式。

## User Story Rule
一个 User Story 只表达一个 user-value scenario。`description` 应以可读叙事说明：

- actor；
- concrete scenario or app context；
- concrete product object；
- action / goal；
- user-visible outcome / value。

可使用 `作为 <Actor>，当/在 <Scenario> 时，我希望 <Action / Goal>，以便 <Outcome / Value>。` 帮助检查语义，但不得把它当作强制输出句式。标题应优先命名用户要完成的业务目标，不使用“查看页面”“管理模块”这类容器名称代替价值。

当一个 Story 包含可独立交付的多个用户目标、不同旅程或不同主要结果时，先拆 Story，再拆 Slice。Capability 相同不能作为不拆分的理由。

## Vertical Slice Rule
Child Vertical Slice 是 Parent User Story 下最小的 user-perceivable delivery loop。每行 `description` 应尽量在一段叙事中说明：

- entry point or trigger；
- user action or system event；
- concrete business object；
- user decision, state transition or cross-capability handoff；
- primary user-visible result and why it matters；
- meaningful exception, empty state or unavailable state when it changes the user's decision；
- data or product state effect when applicable。

不要机械追加“成功时……；失败时……”或“加载失败时可重试”。通用加载、保存和重试行为只有在会改变业务事实、用户选择、数据保护或恢复路径时才进入 Slice；否则留给下游 spec / AC。句式应随业务叙事自然变化，不能以统一模板代替产品信息。

一个 Slice 只能有一个主要闭环。若删除其中一部分后，剩余部分仍有独立用户价值或独立验证路径，则应拆成 sibling slices。

异常状态若只是同一动作的分支，写入同一行 description；只有不同触发、不同结果、不同状态效果且可独立验证时才拆成 sibling slice。

## Business Information Density Gate
所有新建或重写的 Story/Slice 在 structural gate 之后必须通过本门禁：

- 每个 Slice 至少包含两类不可由 capability 名称直接推导的产品事实：可识别业务对象、用户可选方案、状态及其含义、作用范围差异、跨 capability 交接、有业务意义的例外或数据保护边界。
- 删除产品名词后，如果一行只剩“进入页面、看到当前值、成功后保存、失败后重试”，判定为 low-information，必须重写或删除。
- 相邻 sibling slices 必须能分别用一句话说明其独立用户价值或独立业务状态；仅把“查看、修改、失败”拆成三行不构成 vertical slicing。
- 列举设置项、字段或状态不是充分条件；description 必须说明这些差异如何改变用户决策、后续行为或责任域交接。
- 不为凑齐 success / failure / empty state 而虚构行为。输入不足时输出 ambiguity finding，并列出需要 PM 决定的具体问题。
- Story 标题、Story description 与其 Child Slices 必须形成同一价值闭环；Slice 不得只是页面目录，也不得引入 Parent Story 未承诺的新旅程。

## Source Authority And Coverage Gate
在写入 canonical story map 或给出 pass finding 前：

- 声明 scope mode、目标 ID 范围和 source inventory。Capability Registry 只能证明 ownership / boundary / adjacency，不能证明具体用户行为。
- 为每个新增或改写 row 记录非持久化 source coverage：`Row ID -> user-authorized draft proposal / PM-provided behavior / existing canonical fact / proposed ambiguity`。用户明确要求“将以上方案写入”可作为 `user-authorized draft proposal` 写入 `draft`；它不等于 PM approval，也不产生 downstream commitment。
- 未获得 PM 明确输入的产品选择、状态枚举、provider 规则或跨域交接不得伪装成既有事实；保留为 proposed ambiguity，并阻止 approval semantic pass。
- 明确列出 omitted scope，包括本轮不决定的 provider、SLA、审批规则、治理结论和下游交付 artifact。
- `Affected Capability IDs` 只能使用 registry 为 Primary Capability 声明的 adjacent capabilities；非相邻 capability 只能作为不拥有/不改变的边界说明，或先进入单独的 registry governance。
- Source coverage、adjacency 或 omitted-scope 任一缺失时，combined ready gate 不得标记为 pass。

## Capability Mapping Rule
- `Primary Capability ID` 表示主要 ownership。
- `Affected Capability IDs` 只列受影响的相邻 capability；没有时写 `none`。
- Capability mapping 必须支持 description，不能扩展或反推产品行为。
- 跨 capability 的独立用户结果应拆分或写 Boundary note，不得用一行宽泛描述掩盖 ownership 冲突。

## Draft And Ready Gate
`draft` 与 `approved` 使用不同强度的检查：

### Draft structural gate
- ID 唯一且符合 `US-<Capability Prefix>-<NNN>` 或 `VS-<Capability Prefix>-<NNN>`。
- 标题、description、Status、Primary Capability ID、Affected Capability IDs 齐全。
- User Story 位于正确 capability 章节。
- Vertical Slice 位于且仅位于一个 Parent User Story 的 `Child Vertical Slices` 表中。
- description 不包含 FR、AC、TC、接口、数据库或实现细节。

### Narrative quality gate
- 每条新建或重写的 Slice 通过 Business Information Density Gate。
- 同一 Story 下的 sibling slices 通过独立价值差异测试，不以 CRUD 阶段或通用异常机械拆分。
- 句式不要求统一；同一批输出不得重复套用“进入后看到 / 成功时 / 失败时”的骨架。
- 业务对象、可选方案、状态含义和 ownership 交接均来自 PM 输入或既有产品事实。

### Source and coverage gate
- Scope mode、target rows、source inventory 与 omitted scope 已明确。
- 每个新增或改写 row 均有 user-authorized draft proposal、PM-provided behavior、既有 canonical fact 或 proposed ambiguity 分类。
- Capability mapping 通过 registry adjacency 检查；不存在用 Affected mapping 暗改 registry 的情况。

### Approval semantic gate
- User Story description 能回答 actor、scenario、product object、action/goal 和 outcome/value。
- Vertical Slice description 能回答 trigger/action、业务对象、主要可见结果、用户决策或状态变化，以及适用的业务例外和 ownership 交接。
- Non-goals、来源和共享假设能从文档级说明或就近 Boundary note 明确获得。
- Story/Slice 没有多个独立价值闭环，也不要求下游发明产品语义。
- Capability mapping 与 description 一致。

缺失内容应优先补入现有 description 或就近 Boundary note；不得通过新增重复列来“补齐 metadata”。Story map 级别的结构检查通过，不代表其中所有 `draft` 行已经通过 approval gate。

## Ambiguity Rule
出现 exercise、practice、session、completion、status、progress、result、feedback、recovery、recommendation、saved、synced 等模糊词时，必须能从同一行或就近上下文判断：

- 具体对象；
- 入口或触发；
- 用户看到的结果；
- 产品状态变化；
- 明确不包含什么。

无法判断时输出 ambiguity finding，不补写 FR、spec 或实现方案。

## Process
1. 列出必要 assumptions 和待处理的 capability / Story / Slice 范围。
2. 读取当前 story map 的相关章节和相邻边界。
3. 确认产品行为来自 PM 输入或已有产品事实，而不是 capability 名称本身。
4. 为目标区域建立最小 behavior inventory：业务对象、用户选择、关键状态与含义、作用范围、跨 capability 交接、明确非目标和仍未知的产品决定。
5. 按 User Story Rule 检查用户价值边界。
6. 按 Vertical Slice Rule 检查最小闭环和 sibling split。
7. 按 Current Story Map Format Contract 生成五列表格行。
8. 运行 Source Authority And Coverage Gate，并记录 row-level source coverage 与 omitted scope。
9. 依次运行 draft structural gate、narrative quality gate 和 `scripts/validate_story_map.py`；准备批准时再运行 approval semantic gate。
10. 使用 `assets/ready-gate-output.template.md` 输出 finding，并明确 PM approval required。

## Rules
- Do not generate FR/spec/AC/TC。
- Do not write implementation details or downstream contracts。
- Do not modify downstream artifacts merely because Story/Slice changed。
- Do not derive product behavior from capability, stage, roadmap, or increment labels。
- Do not duplicate description semantics into expanded metadata fields。
- Do not use a sentence template as evidence that product semantics are complete。
- Do not approve product facts, priority, sequencing, acceptance, or release readiness。

## Red Flags
- Story 写成 module、page collection、roadmap item 或 capability inventory。
- Story/Slice 使用另一套字段卡，与当前五列表格并存。
- Slice 在多个 Story 下重复，或必须依赖额外 Parent ID 列才能知道归属。
- 一行包含多个独立入口、主要结果或验证路径。
- 多行只替换名词，反复使用“进入后看到、成功时保存、失败时重试”。
- 把通用 loading / empty / error UI 当作独立业务 Slice，或把查看、编辑、保存机械拆成 sibling slices。
- Slice 只有设置项、字段或状态清单，没有说明差异如何影响用户选择、后续状态或责任域。
- Capability ID 被用来生成 description。
- 为补字段而扩散修改 requirements、spec、AC、TC、SWC、报告或脚本。

## Verification
- 输出可直接粘贴到当前 story map，不需要结构转换。
- User Story 表和 Child Vertical Slice 表都严格使用五列。
- 每个 Slice 通过章节嵌套归属一个 Parent Story。
- `description` 是唯一产品语义源，没有重复 metadata。
- 抽查每个 Slice，能标出至少两类具体产品事实，并能说明它与 sibling slices 的独立差异。
- 搜索同批新增内容中的“进入后看到”“成功时”“失败时”“加载失败”等高频骨架；若重复出现，逐行证明其业务必要性或重写。
- 运行 `python .agents/skills/story-map-develop/scripts/validate_story_map.py --capability <CAP-ID> [--capability <CAP-ID> ...]`，检查五列结构、ID、状态、Primary 归属与 registry adjacency。
- Ready Gate finding 包含 scope mode、row-level source coverage、omitted scope 和未确认行为；缺失任一项不得 combined pass。
- `draft` 与 `approved` 的 gate 强度被明确区分。
- 输出没有下游 artifact、实现细节或产品批准决定。
- 修改本 skill 后，`python scripts/validate_agent_skills.py` 通过。

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| “字段越多越完整。” | 当前 story map 以 description 承载语义；重复字段会产生冲突和上下文膨胀。 |
| “Slice 应显式增加 Parent Story ID。” | 当前结构已通过嵌套表达父子关系；重复列没有新增信息。 |
| “Story map 更新后应同步所有下游规则。” | Story/Slice 开发与下游 artifact 生命周期分离；只有明确启动下游工作时才使用对应流程。 |
| “Capability 已经定义了用户行为。” | Capability 只定义边界和 ownership，不能生成产品事实。 |
| “把成功、失败和空状态都写上就完整了。” | 完整性来自业务对象、用户决策和状态语义；通用异常句式不能替代产品事实。 |
| “每个设置项各写一条就是 vertical slice。” | 字段分组不是价值拆分；只有独立用户目标、状态变化或验证路径才构成 sibling slice。 |
