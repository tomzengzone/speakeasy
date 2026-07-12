# Story Map Develop Spec

## Purpose
定义与当前 `docs/product/story_map.md` 完全一致的 User Story / Child Vertical Slice 创建、拆分和 ready-gate 方法，同时防止 Story/Slice 规则扩散到下游 artifact。

## Scope
本 skill 只处理：

- capability 章节中的 User Story 标题与五列表格行；
- Parent Story 下 `Child Vertical Slices` 的五列表格行；
- 就近 Boundary note；
- draft structural gate、narrative quality gate 与 approval semantic gate findings。

本 skill 不生成或修改 FR、spec、AC、TC、contract、increment、SWC allocation、implementation report、code 或 tests。

## Trigger Context
- Product Manager 新增、修改或拆分 story map 中的 User Story / Child Vertical Slice。
- Product Manager 检查某个 `draft` 是否结构完整或可升为 `approved`。
- Story/Slice 输出需要与当前五列表格结构保持一致。
- 相邻 Story/Slice 出现边界重叠、模糊叙事或 capability ownership 冲突。

## Inputs
- `.agents/skills/story-map-develop/SKILL.md`
- `.agents/skills/story-map-develop/assets/user-story-card.template.md`
- `.agents/skills/story-map-develop/assets/vertical-slice-card.template.md`
- `.agents/skills/story-map-develop/assets/ready-gate-output.template.md`
- `docs/product/story_map.md` 的相关章节
- `docs/product/feature_registry.md` 的相关 capability boundary
- PM-provided product behavior、assumptions 和 non-goals
- 目标区域的业务对象、用户选择、生命周期状态、作用范围和跨 capability 交接 inventory
- scope mode、row-level source coverage 和 explicit omitted scope

## Outputs
- 与当前 story map 同构的 Story/Slice Markdown 行。
- Split、boundary、ambiguity 或 ready-gate finding。
- PM approval required 说明。

## Format Contract
- User Story：`### US-... - <title>` + 单行五列表格。
- Vertical Slice：所在 Story 的 `Child Vertical Slices:` 五列表格中的一行。
- 固定列：`Id | description | Status | Primary Capability ID | Affected Capability IDs`。
- `description` 是产品语义源。
- Parent Story 由章节嵌套表达。
- Non-goals、source、共享 assumptions 和边界冲突写在文档级说明或就近 Boundary note。
- 状态只使用当前文件已有的 `draft` / `approved`。

## Quality Bar
- 不创建与当前 story map 并存的 expanded metadata card。
- 不要求 Parent User Story ID、Actor、Scenario、Success State 等重复列。
- Draft structural gate 检查结构和边界；approval semantic gate 检查 description 的语义完整性。
- Narrative quality gate 拒绝只包含页面动作、通用成功/失败和重试提示的 low-information rows。
- 每个 Slice 至少承载两类不可由 capability 名称直接推导的产品事实，并能与 sibling slices 说明独立差异。
- 不强制统一叙事句式；通用 loading / save / retry 行为只有改变业务决策、事实保护或恢复路径时才写入 story map。
- 写入前必须区分行为来源与边界来源；registry 只能提供 ownership / adjacency。每个 changed row 必须分类为 user-authorized draft proposal、PM-provided behavior、existing canonical fact 或 proposed ambiguity。
- Combined ready gate 必须覆盖 scope mode、source inventory、row-level coverage、registry adjacency 和 omitted scope。
- Story map 级 pass 不被误写成所有 draft rows 已 approved。
- Capability 只做 ownership / boundary mapping。
- 不从 Story/Slice 变更自动派生下游治理或交付文件修改。
- Product Manager approval 始终保留。

## Maintenance Notes
- 当 `docs/product/story_map.md` 的实际列、嵌套方式或状态枚举变化时，先以该文件为准，再同步本 skill 与三个 assets。
- 不因下游 traceability、FR、spec、AC、TC 或 SWC 的格式变化反向扩展 Story/Slice 表格。
- 当真实使用暴露出重复句式、空洞叙事或 sibling slice 无法区分时，先修正可复用的 semantic gate 和模板，再重写受影响 rows；不要追加仅针对单个 capability 的特例规则。
- 修改后运行 `python scripts/validate_agent_skills.py`。

## Verification
- SKILL 与 assets 使用相同五列。
- Story 模板与当前 User Story 段落一致。
- Slice 模板与当前 `Child Vertical Slices` 表一致。
- Ready Gate 输出不要求重复 metadata。
- Ready Gate 输出包含 information density 与 sibling differentiation finding。
- Ready Gate 输出包含 source authority、row-level coverage、registry adjacency 与 omitted-scope finding。
- 模板不强制“成功时 / 失败时”句式，且明确输入不足时应输出 ambiguity finding。
- `python .agents/skills/story-map-develop/scripts/validate_story_map.py --capability <CAP-ID>` exits with code 0 for each changed capability。
- `python scripts/validate_agent_skills.py` exits with code 0。

## External References
- GitHub Copilot Agent Skills: https://docs.github.com/en/copilot/how-tos/copilot-on-github/customize-copilot/customize-cloud-agent/add-skills
- OpenAI Codex skill sample: https://github.com/openai/codex/tree/main/codex-rs/skills/src/assets/samples

这些参考只用于 skill 包结构和维护方式；Story/Slice 产品语义只来自本项目的 PM 输入与 `docs/product/story_map.md`。
