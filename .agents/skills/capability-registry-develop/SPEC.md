# Capability Registry Develop Spec

## Purpose
定义与 `docs/product/feature_registry.md` 一致的 V2 Capability、一级 Sub-capability 和 Legacy Mapping 开发方法，把 registry 专属操作规则从 Product Manager Agent 和通用文档治理规则中分离，同时保留 Product Manager 的产品事实与批准权。

## Scope
本 skill 只处理：

- 候选业务对象进入 Registry 前的 destination classification finding 和 routing handoff；
- Product Manager 确认对象类型后，Capability / Sub-capability 各自的颗粒度检查；
- 按 Capability 章节嵌套的 Capability、Level-1 Sub-capability 和 Legacy Mapping 同构 Markdown 行；
- admission、identity、boundary、adjacency、prefix 和 migration 检查；
- `editorial`、`boundary-change`、`add`、`split`、`merge`、`deprecate` 变更分类；
- downstream impact inventory、omitted scope、ready-gate finding 和 checker handoff。

本 skill 不定义 Story/Slice、stage、increment、FR、spec、AC、TC、contract、architecture、implementation、test、priority 或 release decision。

## Trigger Context
- 候选业务对象尚未确认应归为 Capability、Sub-capability、Story/Slice、stage/increment 或技术支撑对象。
- Product Manager 新增、修改、拆分、合并、废弃或重新归类 Capability / Sub-capability。
- Product Manager 维护 V1 到 V2 的历史映射。
- Registry proposal 需要结构或语义 ready gate。
- Registry 变更可能影响 Story/Slice 分类、stage/increment scope guard 或下游 Capability 引用。

## Inputs
- `.agents/skills/capability-registry-develop/SKILL.md`
- `.agents/skills/capability-registry-develop/assets/candidate-object-routing.template.md`
- `.agents/skills/capability-registry-develop/assets/granularity-evaluation.template.md`
- `.agents/skills/capability-registry-develop/assets/capability-section.template.md`
- `.agents/skills/capability-registry-develop/assets/capability-row.template.md`
- `.agents/skills/capability-registry-develop/assets/sub-capability-row.template.md`
- `.agents/skills/capability-registry-develop/assets/legacy-mapping-row.template.md`
- `.agents/skills/capability-registry-develop/assets/ready-gate-output.template.md`
- `docs/product/feature_registry.md` 的目标、父级和相邻行
- `scripts/validate_capability_registry.py`
- `docs/product/baselines/feature-registry-v1-<date>.md` 的相关历史事实
- PM-provided candidate facts、boundary decision、assumptions 和 non-goals；初始 destination 可以尚未确认
- Gate A 后由 Product Manager 确认的 destination、target object type、现有目标 ID 或拟新增 provisional ID、父 ID（适用时）和 change mode
- 结构性变更涉及的相关 Story/Slice、stage、increment、Product Base 和下游引用

## Outputs
- Candidate Object Destination Finding 和下一 owning workflow。
- Product Manager Destination Confirmation 要求。
- 对已确认 Registry 对象的 Type-specific Granularity Finding。
- 与当前 registry 同构的 Capability 章节或 Markdown 行。
- Change mode 和影响清单。
- Structural / semantic ready-gate finding。
- PM approval required 说明。
- 持久化语义变更的 Product Object Governance Check handoff。
- 对每个已持久化 Capability / Sub-capability 语义变更的必需精简 checker audit record 要求；记录路径为 `docs/reports/product_object_governance_check_report.md`，但 checker 结论不由本 skill 生成。

## Format Contract
- 每个 Capability 使用 `## CAP-<PREFIX> - <Capability name>` 二级章节。
- 每章的 `### Capability` 使用当前十二列且只包含该 Capability 一行。
- 每章的 `### Level-1 Sub-capabilities` 使用当前九列且只包含该 Capability 的直属一级 Sub-capability。
- 章节标题 ID/名称、Capability 行和 Sub-capability 父 ID 必须一致。
- 所有 Capability 章节之后保留唯一的 `Legacy Mapping` 三列表。
- 未经单独 governance change，不增加、删除、重命名或重排列章节层级与列契约，也不恢复平铺总表。
- Draft proposal 默认不写入 active registry。

## Candidate Object Destination Contract
Gate A 是对象归宿分类，不是 Capability 颗粒度检查。它必须先于任何新增或重新分类的 registry row proposal，并且只能输出 recommendation / finding，不能代替 Product Manager 确认产品对象类型。

允许的 destination 为：

- `new-capability`
- `existing-capability-change`
- `new-sub-capability`
- `existing-sub-capability-change`
- `story-slice`
- `stage-increment`
- `technical-support-object`
- `insufficient-information`

`existing-capability-change` 和 `existing-sub-capability-change` 必须携带明确 target object type、目标 ID 和 change mode。`new-capability` 和 `new-sub-capability` 必须携带拟新增 provisional ID；`new-sub-capability` 还必须携带父 Capability ID。Product Manager 未确认这些字段前，不得进入 Gate B。

`story-slice`、`stage-increment` 和 `technical-support-object` 完成 owning workflow handoff 后结束本 skill，不生成 Registry row。`insufficient-information` 返回 missing information 并停止。

纯 `editorial` 和 `legacy-mapping-only` 维护可以按 SKILL 的 Gate applicability 对 Gate A/Gate B 记录明确 `N/A`。这不是绕过候选对象分类，而是声明该操作没有创建或重新分类业务对象。

已由 PM 确认对象类型和目标 ID 的现有 Registry `boundary-change` 可以复用该 destination confirmation，不重复执行跨类型 Gate A，但仍必须执行匹配对象类型的 Gate B。`split`、`merge`、`deprecate` 在当前 schema 下继续 fail closed；若同时包含候选 successor 分类，只能对 non-persistent proposal 执行适用 Gate A/Gate B，不得生成可持久化 successor row。

## Type-specific Granularity Contract
Gate B 只检查 PM 已确认对象类型的颗粒度，不重新决定对象归宿，也不包含“为什么不是 Story/Slice、stage/increment 或技术支撑”的跨类型判断。

Capability granularity 至少覆盖：

- 与两个最接近现有顶层 Capability 的 outcome、`Owns`、`Does not own` 和 adjacency 比较；
- 独立且长期稳定的用户/商业结果；
- 跨多个行为或交付切片持续存在的完整业务边界；
- 可以合理分解为稳定一级职责，但不按 Sub-capability 数量机械判定；
- 无法自然归入现有 Capability 的证据。

Sub-capability granularity 至少覆盖：

- 明确父 Capability 和 parent-fit；
- 与同父级最接近 sibling 的 outcome、`Owns`、`Does not own`、entry 和 output 比较；
- sibling 不足两个时记录实际比较对象和 comparison gap；
- 稳定一级职责，而非单个页面、动作、Story/Slice、API、数据表或代码模块；
- 未越过父边界，且不与现有 sibling 重复拥有同一职责。

Gate B `fail` 时只返回修正方向或返回 Gate A 的理由，不生成可持久化 row，不自行改变 PM 已确认 destination。

## Classification Examples
以下仅为说明 Gate A/Gate B 区别的假设性示例，不构成当前产品事实、PM classification 或 Registry 变更决定。实际对象必须基于当次候选事实重新执行 Gate A 并由 Product Manager 确认。

| Candidate | Destination | Reason |
| --- | --- | --- |
| 假设候选“练习会话与互动” | `new-capability` 或 `existing-capability-change` | 若候选事实证明其具有独立练习结果并覆盖多种长期稳定职责，进入相应顶层 Capability 颗粒度检查；本例不预先批准归属。 |
| 假设候选“AI 对话练习” | `new-sub-capability` 或 `existing-sub-capability-change` | 若候选事实证明其结果属于已确认父能力且构成稳定一级职责，进入 Sub-capability 颗粒度检查；本例不预先批准父级或边界。 |
| 用户完成一次 AI 对话并查看反馈 | `story-slice` | 描述一次可交付、可验收的用户行为流程，不是稳定分类对象。 |
| LLM provider 路由与故障切换 | `technical-support-object` | 属于 AI runtime、架构或运维支撑，不是用户/商业 Capability。 |
| 在现有练习页增加重试按钮 | `story-slice` | 假设它只表达具体用户行为变化时，应进入 Story/Slice workflow；不得因为 UI 入口存在而新增 Capability/Sub-capability。 |

## Quality Bar
- Skill 是 registry 操作规则的唯一专属来源，不复制 PM 的产品决策职责。
- Product Manager 始终拥有产品事实、边界取舍、状态批准和下游承诺。
- Gate A 与 Gate B 串行且职责分离；Gate A 未确认前不生成 Registry row。
- PM destination confirmation 和 PM final row approval 是两个不同决策点，不得合并表述。
- Gate B 必须匹配已确认 target object type；Capability 和 Sub-capability 不共用模糊颗粒度结论。
- Capability / Sub-capability 只做 classification、ownership 和 boundary mapping。
- 结构性变更保留已发布身份、Legacy Mapping、downstream impact inventory 和 omitted scope。
- 当前 schema 无法表达 V2 Capability / Sub-capability successor 时，`split`、`merge`、`deprecate` 必须保持 non-persistent、fail closed，并路由到单独 schema/content-governance change。
- Adjacency 强校验只覆盖本次新增或触碰的关系；未触碰的历史不对称关系只形成 baseline finding。
- 普通维护不自动修改 Story、requirements、spec、AC、TC、stage、increment 或实现 artifact。
- Skill gate、PM approval 和 Product Object Governance Check pass 三种结论不得混写。
- 完整 Gate 分析保留在执行 handoff；canonical registry 只保存批准后的产品事实，checker report 只保存 target、Gate/approval/validation/check 结论摘要。

## Maintenance Notes
- 当前章节层级或表结构变化时，先按 governance change 修改 canonical schema，再同步 SKILL、SPEC、Capability section/row templates、ready-gate asset 和可执行 validator。
- 若要支持 V2 `split`、`merge`、`deprecate` 持久化，schema change 必须同时定义 Capability 和 Sub-capability 的 lifecycle、successor 与历史身份保留方式；不得复用 V1 Legacy Mapping 承载 V2 successor。
- Capability 准入规则变化属于产品对象治理变化，必须由 Product Object Governance Change Agent 实施并由 Product Object Governance Check Agent 独立检查。
- Destination 枚举、Gate applicability 或类型颗粒度规则变化时，必须同步 SKILL、SPEC、candidate routing template、granularity template、ready-gate template、Product Manager 高层 routing 和 Product Object Governance Check 协议。
- Product Manager Agent 只保留 ownership、approval、mandatory routing 和 product invariants；字段级操作规则维护在本 skill。
- 通用文档治理 skill 只保留 path/source-of-truth 或 content boundary，不复制本 skill 的 ID、变更模式和 ready gate。
- 修改 skill 后运行 `python scripts/validate_agent_skills.py`；PM 批准并持久化 registry 变更后运行 `python scripts/validate_capability_registry.py`。

## Verification
- Candidate Object Destination Contract 的枚举、必填 ID/change mode 和停止路由与 SKILL、candidate routing template 一致。
- Capability / Sub-capability granularity contract 与 SKILL、granularity template 一致，跨类型排除理由只出现在 Gate A。
- Gate A、PM destination confirmation、Gate B、row proposal、PM final approval 的顺序与 ready-gate template 一致。
- Editorial 和 legacy-mapping-only 的 `N/A` 适用性在 SKILL、SPEC 和模板中一致。
- SKILL 的 Capability 章节层级与 `capability-section.template.md` 一致，三类行的列契约分别与 capability、sub-capability、legacy-mapping row template 表头一致；ready-gate asset 与 SKILL/SPEC 的 finding、approval 和 checker handoff 字段一致。
- 每个 Capability 章节标题与父行 ID/名称一致，Sub-capability 行只出现在匹配父章节中；validator 对章节缺失、重复、错配和遗留平铺总表 fail closed。
- Change modes、影响分析和 gate 在 SKILL、SPEC、ready-gate template 中一致。
- 当前 schema 下的 V2 lifecycle/successor blocker 与 touched-adjacency 范围在 SKILL 和 assets 中一致。
- 输出明确要求 PM approval 和独立 checker。
- 持久化语义变更要求 checker report 精简记录，且该记录不成为第二个 Registry source of truth。
- 没有新增第二个 registry source of truth。
- `python scripts/validate_capability_registry.py` exits with code 0；asymmetric-adjacency warning 不替代 touched-boundary semantic review，也不自行把关系分类为历史基线。
- `python scripts/validate_agent_skills.py` exits with code 0。

## External References
- GitHub Copilot Agent Skills：https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot
- OpenAI Codex skill sample：https://github.com/openai/codex/tree/main/codex-rs/skills/src/assets/samples

外部资料只用于 skill 包结构和维护方式；Capability 产品事实、字段和边界只来自本项目的 Product Manager 决策与 canonical registry。
