---
name: capability-registry-develop
description: Use when Product Manager needs to create, change, split, merge, deprecate, map, or ready-gate Capability and Sub-capability entries in docs/product/feature_registry.md; Do not use to define Story/Slice behavior, delivery stage scope, requirements, specifications, acceptance criteria, tests, architecture, or implementation.
---

# Capability Registry Develop

## Overview
用于判定候选业务对象是否应进入 V2 Capability Registry，并创建、修改、拆分、合并、废弃和检查 `docs/product/feature_registry.md` 中按章节嵌套的 V2 Capability、一级 Sub-capability 与 Legacy Mapping。

本 skill 只定义注册表的操作方法、格式契约、影响分析和 ready gate。Product Manager 拥有产品分类事实、业务边界取舍、状态批准和下游承诺；skill 不自行批准产品事实。

## When to Use
- 候选业务对象尚未确认应归为 Capability、Sub-capability、Story/Slice、stage/increment 或技术支撑对象，需要先做对象归宿判断。
- 新增或修改 V2 Capability 或一级 Sub-capability。
- 调整 `Owns`、`Does not own`、主要结果、相邻能力或 downstream prefix。
- 拆分、合并、废弃或重新归类已发布 Capability / Sub-capability。
- 新增或修正 V1 slug 到 V2 的 Legacy Mapping。
- 检查 registry 行是否符合当前格式、边界和迁移规则。

## When NOT to Use
- 创建、拆分或批准 User Story / Vertical Slice；使用 `story-map-develop`。
- 定义 stage、Stage Scope Item、increment、roadmap 或 priority。
- 生成 FR、spec、AC、TC、traceability、contract、architecture、implementation plan、code 或 test。
- 仅凭 Capability 名称推导用户行为或下游需求。
- 修改 registry 的 canonical path、文档类别或 source-of-truth 规则；使用 `document-governance`。

## Ownership Boundary
- Canonical Capability facts 只写入 `docs/product/feature_registry.md`，由 Product Manager 管理和批准。
- 本 skill 可以输出 draft row、impact finding、migration proposal 或 ready-gate finding，但不能自行批准、排序或承诺下游工作。
- Product Object Governance Change Agent 维护本 skill 和相关治理规则，不修改 registry 中的产品事实。
- 持久化的 Capability / Sub-capability 语义变更必须交给 Product Object Governance Check Agent 独立检查。
- Registry 变化不会自动创建或改写 Story、FR、spec、AC、TC、stage、increment、architecture 或 evidence。

## Inputs
- Product Manager 提供的候选对象事实，包括拟解决的用户/商业结果、稳定职责、可观察行为、交付特征、技术/运营特征、边界、非目标和变更原因；对象归宿可以尚未确认。
- Gate A 完成后，由 Product Manager 确认的 target object type、现有目标 ID 或拟新增 provisional ID、父 Capability ID（适用时）和 change mode。
- `docs/product/feature_registry.md` 的目标行、父级 Capability、相邻 Capability 和相关 Legacy Mapping。
- `docs/product/story_map.md` 中受分类影响的相关 Story/Slice，仅用于 impact inventory，不作为 registry 事实来源。
- `docs/product/stages/`、`docs/product/increments/`、`docs/product/base/` 和相关下游 artifact 中的现有 Capability 引用，仅用于影响分析。

默认只读取目标 Capability、相邻边界和受影响引用；拆分、合并、废弃或 ID 变更时必须扩大为全仓引用清单。

## Outputs
- Candidate Object Destination Finding，以及需要 Product Manager 确认的对象类型、目标 ID、change mode 和下一 owning workflow。
- 对已确认 Registry 对象的 Capability 或 Sub-capability Granularity Finding。
- 与当前 registry 同构的 Capability 章节、Sub-capability 子表或 Legacy Mapping Markdown 行。
- Change mode：`editorial`、`boundary-change`、`add`、`split`、`merge` 或 `deprecate`。
- Boundary、ID、adjacency、prefix、legacy mapping 和 downstream impact finding。
- Product Object Governance Check handoff，适用于持久化语义变更。
- Checker handoff 要求对每个已持久化 Capability / Sub-capability 语义变更在 `docs/reports/product_object_governance_check_report.md` 留下精简审计记录；本 skill 不自行写 checker 结论。
- `PM Approval Required` 说明。

## 文档路径约定
- Canonical registry：`docs/product/feature_registry.md`。
- Persisted semantic change check record：`docs/reports/product_object_governance_check_report.md`，只记录 Gate/approval/validation/check 摘要，不复制完整分析或成为产品事实来源。
- V1 frozen snapshot：`docs/product/baselines/feature-registry-v1-<date>.md`，只读历史基线。
- Skill rules：`.agents/skills/capability-registry-develop/SKILL.md` 和 `.agents/skills/capability-registry-develop/SPEC.md`。
- Copy-ready templates：`.agents/skills/capability-registry-develop/assets/`，分别包含候选对象归宿、类型颗粒度、Capability 章节、Capability/Sub-capability/Legacy Mapping row template 和 ready-gate output template。
- 默认输出为 non-persistent proposal；只有 Product Manager 批准后才写入 canonical registry。
- 本 skill 不创建独立 feature 目录或下游产品、设计、实现、测试和发布 artifact。

## Current Registry Format Contract
当前 `docs/product/feature_registry.md` 是产品事实和表结构权威。本 skill 必须按“一个 Capability 章节包含一个 Capability 单行表和其直属一级 Sub-capability 表”的方式表达父子关系，不引入平铺总表或并行 schema。

每个 Capability 使用二级章节，标题固定为：

```text
## CAP-<PREFIX> - <Capability name>
```

章内先使用 `### Capability`，并使用以下固定十二列且只包含当前 Capability 一行：

```text
Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping
```

随后使用 `### Level-1 Sub-capabilities`，并使用以下固定九列，只包含当前 Capability 的直属一级 Sub-capability：

```text
Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status
```

所有 Capability 章节之后保留唯一的 `## Legacy Mapping`，固定列为：

```text
V1 slug | V2 mapping | Migration note
```

章节标题中的 Capability ID 和名称必须与章内 Capability 行一致；每个子行的 `Capability ID` 必须等于当前章节 ID。格式、章节层级或列结构需要变化时，不得在普通 registry 编辑中顺带修改；必须单独进入 documentation / product-object governance change。

## Gate A - Candidate Object Destination
Gate A 先回答“候选对象是什么”，不得预设候选对象已经是 Capability。Skill 输出分类 finding 和路由建议，Product Manager 拥有最终对象类型、目标 ID 和 change mode 的确认权。

允许的 destination：

- `new-capability`：候选对象可能成为新的顶层 Capability。
- `existing-capability-change`：候选对象应由一个现有 Capability 吸收或通过边界变更表达；必须同时给出目标 Capability ID 和 change mode。
- `new-sub-capability`：候选对象可能成为某个现有 Capability 下的一级 Sub-capability；必须给出候选父 Capability ID。
- `existing-sub-capability-change`：候选对象应由一个现有 Sub-capability 吸收或通过边界变更表达；必须同时给出目标 Sub-capability ID 和 change mode。
- `story-slice`：候选对象描述用户行为、可交付流程或可验收切片，路由 Product Manager 使用 `story-map-develop`，本 skill 停止 Registry proposal。
- `stage-increment`：候选对象描述交付时序、阶段范围或增量承诺，返回 Product Manager 的 stage/increment workflow，本 skill 停止 Registry proposal。
- `technical-support-object`：候选对象属于 Domain、SWC、provider、基础设施、架构或运营支撑，路由对应 owning agent/workflow，本 skill 停止 Registry proposal。
- `insufficient-information`：证据不足以确认归宿，列出 missing information，不得进入 Gate B。

Gate A 必须基于候选对象的长期结果、职责稳定性、行为/交付特征和技术属性给出理由。“为什么不是其他对象类型”属于 Gate A，不属于颗粒度判断。

Product Manager 未确认 destination、target object type、现有目标 ID 或拟新增 provisional ID、适用的父 ID 和 change mode 前，不得进入 Gate B，不得生成十二列 Capability 行或九列 Sub-capability 行。非 Registry destination 在完成 handoff 后结束本 skill。

### Gate applicability
- 候选对象归宿尚未确认，或请求可能新增、重新归类、重设父级时，Gate A 必须执行。
- 已确认对象类型和目标 ID 的现有 Registry 行 `boundary-change` 可以复用 PM-provided destination confirmation，不重复进行跨类型分类，但 Gate B 仍必须按已确认类型执行。
- 纯 `editorial` 变更不改变对象类型、边界或颗粒度时，Gate A 和 Gate B 记录 `N/A - confirmed existing registry object, no semantic scope change`，直接进入格式和结构检查。
- 纯 Legacy Mapping 新增或修正不创建候选业务对象，Gate A 和 Gate B 记录 `N/A - legacy-mapping-only`，按 Legacy Mapping、impact 和 structural gate 路径执行。
- `split`、`merge`、`deprecate` 仍按当前 schema fail closed；若同时包含候选 successor 分类，只能对 non-persistent proposal 执行适用的 Gate A/Gate B，不得生成可持久化 successor row。

## Capability Admission Rule
本规则只在 Gate A 的 destination 被 Product Manager 确认为 `new-capability` 或 `existing-capability-change` 后使用。

顶层 Capability 必须同时满足：

- 表达长期稳定的用户或商业能力，而不是一次交付切片。
- 有明确 `Primary user/business outcome`。
- `Owns` 与 `Does not own` 能区分相邻业务边界。
- 不以 onboarding journey、页面、stage、increment、roadmap horizon、Domain、SWC、provider、基础设施或运营任务作为顶层能力。
- 不从现有 Story、架构模块或实现代码名称机械反推 Capability。

一级 Sub-capability 准入只在 Gate A 的 destination 被 Product Manager 确认为 `new-sub-capability` 或 `existing-sub-capability-change` 后使用。它必须属于一个已存在的父 Capability，表达该业务域内稳定的一级职责，并具备入口、输出和明确非职责。若候选对象具有跨域独立结果，应返回 Gate A 重新分类，不能强塞进现有父级。

## Gate B - Type-specific Granularity
Gate B 只回答“已确认类型的对象是否具有正确颗粒度”，不重新决定对象归宿。

### Capability granularity
- 与至少两个业务结果或边界最接近的现有顶层 Capability 比较；比较对象必须按 outcome、`Owns`、`Does not own` 和 adjacency 相关性选择，不能任意挑选。
- 候选对象具有独立且长期稳定的用户或商业结果，能够跨多个 Story/Slice、stage 或 increment 持续存在。
- 候选对象拥有完整业务边界，而不是单一页面、动作、流程、交付切片或技术实现。
- 候选对象可以合理分解为多个稳定一级职责，但不得仅用 Sub-capability 数量机械决定顶层身份。
- 候选对象无法自然归入某个现有 Capability；若可以归入，返回 Gate A 改为 `existing-capability-change` 或 `new-sub-capability`。

### Sub-capability granularity
- 明确父 Capability，并证明候选职责属于父能力边界且不产生跨域独立业务结果。
- 与同一父级下业务边界最接近的 sibling 比较 outcome、`Owns`、`Does not own`、entry 和 output；优先比较两个 sibling，不足两个时记录实际可用对象和 comparison gap。
- 候选对象表达稳定的一级职责，不是单个页面、用户动作、Story/Slice、API、数据表或代码模块。
- 候选对象具有明确入口、输出和非职责，且不会与现有 sibling 重复拥有同一边界。
- 候选对象过宽或越过父边界时返回 Gate A 重新分类；过窄或仅表达一次行为时路由 `story-slice`。

Gate B 输出 `pass` 或 `fail`。`fail` 必须给出修正方向或返回 Gate A 的原因；不得为了生成 registry 行而自动改变 PM 已确认的 destination。

## Identity And Boundary Rule
- Capability ID 使用 `CAP-<PREFIX>`；Sub-capability ID 使用 `CAP-<PREFIX>-<NN>`。
- `Capability slug`、Capability ID、Sub-capability ID 和 downstream prefix 在 active registry 内必须唯一。
- 已发布 ID、slug 和 prefix 默认不可重编号或复用；必须变更时按结构性变更处理并保留迁移映射。
- `Owner` 表示产品决策 owner，不表示软件组件、代码或运行值班 owner。
- `Downstream document prefix` 和 `Related FR prefix` 只提供命名 namespace，不是 FR 或产品行为来源。
- 本次新增或触碰的 `Adjacent capabilities` 默认双向一致；若业务关系有意单向，proposal 必须写明理由并由 PM 批准。
- 未触碰的历史单向 adjacency 只记录为 baseline finding，不自动修改产品事实，也不单独阻塞无关 proposal；一旦本次变更触碰任一相关边界，就必须补齐双向关系或记录单向理由。
- Capability / Sub-capability mapping 只做 ownership、boundary 和 classification，不能扩大 Story/Slice description 或生成下游行为。

## Change Mode And Impact Rule
- `editorial`：不改变 ID、分类、边界、状态、映射、prefix 或下游解释的文字修正。
- `boundary-change`：改变 `Owns`、`Does not own`、结果、父子归属或相邻关系，但不新增或废弃 ID。
- `add`：增加新的稳定 Capability / Sub-capability。
- `split`：一个已发布对象拆成多个对象；旧 ID 不得静默消失。
- `merge`：多个已发布对象合并；所有旧 ID 必须保留迁移去向。
- `deprecate`：停止 active 使用但保留历史身份和替代说明。

`boundary-change`、`add`、`split`、`merge` 和 `deprecate` 必须输出：变更理由、受影响 registry 行、相邻边界、Legacy Mapping、受影响 Story/Slice、stage/increment、Product Base / increment artifacts、架构或契约引用，以及明确的 omitted scope。旧文档不得自动批量改写；只输出迁移清单，由 owning workflow 决定何时触碰。

当前 schema 只为 V1 slug 提供三列 `Legacy Mapping`，不能无损记录已发布 V2 Capability 或 Sub-capability 的 successor。因而 `split`、`merge`、`deprecate` 只能产生 non-persistent proposal 和 impact finding，必须返回 `fail - schema governance required`，并路由到单独的 schema/content-governance change；在 canonical schema 同时支持 Capability 与 Sub-capability 的 lifecycle 和 successor mapping 前，不得持久化这些变更。不得把 V2 successor 偷写进 V1 Legacy Mapping 或自由文本备注。

## Draft And Ready Gate
草案默认只存在于 skill 输出，不以未经批准的 `draft` 行写入 active registry。

### Destination gate
- Gate A finding 包含候选事实、destination、classification rationale、target object type、现有目标 ID 或拟新增 provisional ID、适用的父 ID、change mode、下一 owning workflow 和 missing information。
- Product Manager 已明确确认 destination、target object type、现有目标 ID 或拟新增 provisional ID、适用的父 ID 和 change mode。
- 非 Registry destination 已正确 handoff，且没有生成 registry row。
- Gate A 不适用时具有符合 Gate applicability 的明确 `N/A` 理由。

### Granularity gate
- 只有已确认的 Registry destination 才执行 Gate B。
- Capability 使用 Capability granularity；Sub-capability 使用 Sub-capability granularity，不得交叉套用。
- Comparison evidence 覆盖规定的 peer/sibling、outcome、ownership 和 boundary；comparison gap 被明确记录。
- Gate B `fail` 时没有生成可持久化 registry row。
- Gate B 不适用时具有符合 Gate applicability 的明确 `N/A` 理由。

### Structural gate
- 每个 Capability 都有且只有一个对应二级章节；章内 `Capability` 单行表和 `Level-1 Sub-capabilities` 表的列数、列名和顺序与当前 registry 一致。
- 章节标题 ID/名称与 Capability 行一致，Sub-capability 只位于其父 Capability 章节内，且父 ID 与章节 ID 一致。
- `Legacy Mapping` 是 Capability 章节之后唯一的独立映射表。
- ID、slug、prefix 唯一且格式正确。
- Sub-capability 父 ID 存在。
- 本次新增或触碰的 Adjacent Capability 和 V2 Capability mapping 引用存在；历史未触碰的单向 adjacency 作为 baseline finding，不扩大本次 gate。
- 没有使用 V1 slug、stage 名或 roadmap horizon 作为 active Capability 身份。
- `split`、`merge`、`deprecate` 在当前 schema 下返回 `fail - schema governance required`，没有伪造 V2 successor 持久化位置。

### Semantic gate
- Gate A 和 Gate B 在适用时通过，在不适用时具有符合 Gate applicability 的明确 `N/A` 理由。
- Gate A 适用时 destination 与 PM 确认一致；Gate B 适用时使用了匹配 target object type 的颗粒度规则并通过。
- 顶层 Capability 路径通过 Capability Admission Rule；Sub-capability 路径通过父级准入规则。
- `Owns`、`Does not own` 和主要结果互不矛盾。
- Sub-capability 边界覆盖父能力的一部分，但不越过父能力边界。
- 结构性变更具有完整影响清单、预期迁移去向和 omitted scope；当前 schema 无法表达 successor 时保持 non-persistent 并 fail closed。
- 没有从 registry 推导用户行为或修改产品优先级。

Structural 和 semantic gate 通过只表示 proposal 可交给 PM；不代表 PM 已批准，也不代表下游 artifact 已迁移。

## Process
1. 列出 assumptions、change mode 和候选对象或 mapping 事实，按 Gate applicability 确认执行路径。
2. Gate A 适用时，使用 `assets/candidate-object-routing.template.md` 输出 destination、理由、target object type、现有目标 ID 或拟新增 provisional ID、父 ID、change mode 和下一 owning workflow；不适用时记录规定的 `N/A` 理由。
3. Gate A 适用时，由 Product Manager 确认 destination、target object type、现有目标 ID 或拟新增 provisional ID、适用的父 ID 和 change mode。未确认或 `insufficient-information` 时停止；非 Registry destination 完成 handoff 后停止。
4. 对已确认的 Registry destination 或 mapping target 读取目标行、父子关系、peer/sibling、相邻 Capability 和相关 Legacy Mapping。
5. Gate B 适用时，使用 `assets/granularity-evaluation.template.md` 执行与 target object type 匹配的规则；Gate B `fail` 时返回修正或 Gate A，不生成可持久化行。不适用时记录规定的 `N/A` 理由。
6. Gate B 通过或按 Gate applicability 合法标记 `N/A` 后，按对应准入规则和 Current Registry Format Contract 生成或修改 Capability 章节内的 Registry row；新增 Capability 时同时创建对应章节和直属 Sub-capability 表，新增 Sub-capability 时只写入其父章节。
7. 检查章节标题、ID、名称、slug、prefix、父子章节归属、本次新增或触碰的 adjacency 和边界冲突；历史未触碰的不对称关系只记录 baseline finding。
8. 对非 `editorial` 变更生成 downstream impact inventory 和 omitted scope；`split`、`merge`、`deprecate` 在当前 schema 下 fail closed 并路由到单独 schema governance change。
9. 运行 destination、granularity、structural 和 semantic gate。
10. 使用 `assets/ready-gate-output.template.md` 输出 finding，并明确 PM final approval required；destination confirmation 不等于最终 registry row 批准。
11. Product Manager 最终批准具体 proposal row 并持久化变更后，运行 `python scripts/validate_capability_registry.py`；validator failure 必须先修正。Validator 的 asymmetric-adjacency warning 只提示 checker 判定 touched scope，不替代本 skill 对本次触碰关系的 semantic gate。
12. Validator 通过后生成 Product Object Governance Check handoff；checker pass 前不得宣称治理完成。

## Rules
- Do not treat a candidate object as a Capability or Sub-capability before Gate A and Product Manager destination confirmation。
- Do not generate a registry row before the matching Gate B passes or Gate B is validly marked `N/A` under Gate applicability。
- Do not approve product facts, priority, sequencing, acceptance, delivery, or release readiness。
- Do not derive Story/Slice、FR、spec、AC 或 TC behavior from registry labels。
- Do not create a parallel registry, hidden schema, independent feature directory, or active V1 compatibility source。
- Do not silently renumber, reuse, delete, split, merge, or re-parent published IDs。
- Do not bulk-rewrite downstream artifacts as a side effect of registry maintenance。
- Do not treat a passed structural gate as product approval or completed migration。

## Red Flags
- 候选对象尚未完成 Gate A，就直接套用 Capability 十二列或 Sub-capability 九列模板。
- 把“为什么不是 Story/Slice、stage/increment 或技术支撑”写入 Gate B，导致对象归类和同类型颗粒度混在一起。
- 使用 `existing-capability-change` 或 `existing-sub-capability-change`，却没有明确 target object type、目标 ID 和 change mode。
- Gate B 使用了与 PM 确认类型不匹配的规则，或任意选择两个无关对象完成比较。
- Capability 实际是 onboarding journey、页面集合、stage、increment、技术平台或 provider 运维对象。
- `Owns` 和 `Does not own` 都使用宽泛词，无法判断与相邻能力的交界。
- 新增 Sub-capability 只因为某个 FR、API、数据表或现有代码模块存在。
- 修改 ID、slug、prefix 或父子归属，却没有影响清单和 Legacy Mapping。
- 本次新增或触碰的 `Adjacent capabilities` 指向不存在的 ID，或明显不对称且没有解释。
- 把 V2 Capability / Sub-capability successor 偷写进只面向 V1 slug 的 Legacy Mapping 或自由文本备注。
- 把 downstream prefix 当成 FR 来源或产品语义。
- 为了让 proposal 通过而自动改写 Story、requirements、spec、AC、TC 或架构文档。

## Verification
- Gate A 在适用时于任何 row proposal 之前完成，不适用时具有明确 `N/A` 理由；非 Registry destination 没有生成 registry row。
- Gate A/Gate B 适用时，Product Manager destination confirmation 与 target object type、现有目标 ID 或拟新增 provisional ID、父 ID 和 change mode 一致。
- Gate B 适用时使用正确的 Capability 或 Sub-capability 颗粒度模板，comparison evidence 完整。
- Editorial 和 legacy-mapping-only 路径具有明确 `N/A` 依据，没有伪造候选对象分类或颗粒度比较。
- 输出只触及 registry proposal、影响清单和 checker handoff，没有生成下游行为或实现 artifact。
- 所有 Capability 章节严格符合当前标题、嵌套关系和列契约，且不存在遗留平铺总表。
- ID、名称、slug、prefix、父子章节归属和相邻引用可被独立检查。
- 非 editorial 变更包含 downstream impact inventory、omitted scope 和迁移说明。
- `split`、`merge`、`deprecate` 在当前 schema 下保持 non-persistent，并明确返回 schema governance blocker。
- 输出明确区分 skill gate、PM approval 和 independent checker pass。
- 已持久化语义变更的 checker handoff 要求精简审计记录，且完整 Gate 分析没有写入 canonical registry。
- `python scripts/validate_capability_registry.py` 通过；warning 被记录但不被误写成语义 gate pass。
- 修改本 skill 后，`python scripts/validate_agent_skills.py` 通过。

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| “Capability 名称已经说明用户行为。” | Capability 只定义稳定分类和边界；用户行为必须来自 PM-approved Story/Slice。 |
| “改一个 ID 后全仓替换就行。” | 已发布 ID 是追溯身份；结构性变更必须保留迁移去向和影响清单。 |
| “先把草案写进 active registry 再让 PM 看。” | Active registry 是 canonical product fact；未批准 proposal 默认保持 non-persistent。 |
| “专属 skill 可以替 PM 判断业务边界。” | Skill 只执行方法和 gate；产品取舍与批准权始终属于 Product Manager。 |
