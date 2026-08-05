# 功能需求目录

## 文档状态

- Artifact ID: `FUNCTIONAL_REQUIREMENT_CATALOG`
- Status: candidate

本目录只保存 Product Manager 决定从已批准 Vertical Slice 表达为 Functional Requirement 的产品行为。FR 可包含一个或多个独立规则、不变量、边界或失败条件；每条 FR 只能通过 `source_vs_ids` 直接引用一个或多个 approved VS。Capability 与 Sub-capability 字段仅用于分类、编号和影响筛选，不构成第二条产品 lineage。Stage、Increment、Work Package、PR、实现和执行结果不属于本目录。

目录条目只登记经 Product Manager 批准需要表达为 Functional Requirement 的当前产品事实，不表示旧文档迁移或完整历史覆盖。

## FR-TRAIN / CAP-TRAIN-06 训练闭环展示状态

### FR-TRAIN-001 — 完成练习后的闭环展示

- Status: `approved`
- source_vs_ids: `VS-TRAIN-001-1`
- primary_capability_id: `CAP-TRAIN`
- primary_sub_capability_id: `CAP-TRAIN-06`
- affected_capability_ids: `CAP-PRACTICE`, `CAP-COACH`, `CAP-MEMORY`, `CAP-PLAN`
- Rule: 学习者完成当前官方场景的一轮语音练习并触发结束动作后，系统必须展示本轮练习总结和可见的后续学习入口。
- Boundary: 当练习结果失败或不可用时，系统展示可恢复的错误或空状态，不得错误推进学习进度。
- Approval basis: `VS-TRAIN-001-1` existing approved product fact; PR-003 revision 11 authorizes governance cataloging only.

## FR-CONTENT / CAP-CONTENT-01 官方内容库与目录结构

### FR-CONTENT-001 — 完整浏览已发布且对当前学习者可见的内容

- Status: `approved`
- source_vs_ids: `VS-CONTENT-001-1`
- primary_capability_id: `CAP-CONTENT`
- primary_sub_capability_id: `CAP-CONTENT-01`
- affected_capability_ids: `CAP-CONTENT`
- Rule: 内容资产入口中“全部”场景主题集合必须恰好包含全部已发布且对当前学习者可见的官方场景主题；选中主题后的课程摘要集合必须恰好包含该主题下全部已发布且对当前学习者可见的课程，不得有意遗漏任一符合条件的主题或课程。每条课程摘要必须包含非空英文标题、非空中文简介与唯一一个适用等级。
- Level invariant: 本范围的场景与课程等级终态值域只允许 `A1`、`A2`、`B1`、`B2`、`C1`、`C2`；每个等级字段、单个课程以及单个场景等级记录或内容轨道只能取其中一个 CEFR 值，场景主题本身可包含零个或多个不同 CEFR 的课程或内容轨道；切换完成后 `L1`、`L2`、`L3` 均为非法值并必须被拒绝。
- Boundary: 已发布且对当前学习者可见的主题即使没有可见课程也必须保留在主题集合中，其课程集合显示真实空状态。获取失败不得显示为真实空状态，而必须保留已知浏览上下文并提供恢复路径。
- Cutover boundary: `L1`→`A2`、`L2`→`B1`、`L3`→`B2` 只是全链一次性切换的迁移依据，不构成持久产品兼容规则；运行期不得把 `L1`/`L2`/`L3` 作为别名、fallback 解释或并行写入值。
- Engineering impact handoff: 适用的 `DOMAIN_SCHEMA`、`API_CONTRACT` 与 `SCREEN_SPEC` 需承接集合完整性、真实空状态/获取失败区分、摘要必备信息与等级值域约束，具体工程方案由各事实归属方决定。
- Approval basis: Product Manager 已批准全量已发布可见内容语义、课程摘要必备信息、空状态/失败边界与 CEFR 全链一次性切换决策。

## FR-CONTENT / CAP-CONTENT-02 内容条目与课程定义

### FR-CONTENT-002 — 一致展示已发布课程的基本信息与投入

- Status: `approved`
- source_vs_ids: `VS-CONTENT-002-1`
- primary_capability_id: `CAP-CONTENT`
- primary_sub_capability_id: `CAP-CONTENT-02`
- affected_capability_ids: `CAP-CONTENT`
- Rule: 一门已发布课程必须具有非空英文标题、非空中文简介、唯一一个合法 CEFR 适用等级，以及大于零且携带时间单位的典型完成时长；学习者从课程卡片或任何其他课程入口打开同一课程时，必须解析为同一已发布课程及同一版本，并展示该版本的上述信息。
- Level invariant: 课程的合法 CEFR 适用等级只能是 `A1`、`A2`、`B1`、`B2`、`C1`、`C2` 之一；切换完成后 `L1`、`L2`、`L3` 均为非法值并必须被拒绝。
- Boundary: 背景图为可选信息；背景图缺失不得阻止课程被打开，也不得阻止其他必备信息展示。任一入口无法解析到同一已发布课程及版本时，不得以其他课程或其他版本的基本信息替代。
- Cutover boundary: `L1`→`A2`、`L2`→`B1`、`L3`→`B2` 只是全链一次性切换的迁移依据，不构成持久产品兼容规则；运行期不得把 `L1`/`L2`/`L3` 作为别名、fallback 解释或并行写入值。
- Engineering impact handoff: 适用的 `DOMAIN_SCHEMA`、`API_CONTRACT` 与 `SCREEN_SPEC` 需承接课程版本一致性、必备/可选信息、时长量值与单位、等级值域以及无法解析时的不替代语义，具体工程方案由各事实归属方决定。
- Approval basis: Product Manager 已批准课程基本信息、跨入口版本一致性、背景图可选边界与 CEFR 全链一次性切换决策。

## 维护规则

- Product Manager 按 implementing VS 决定是否创建 FR；零条 FR 不会仅因缺少 FR 而阻止交付。
- FR 存在时必须保持 approved 状态和非空 `source_vs_ids`；其一个或多个规则、不变量、边界或失败条件不得在 TC 或 Contract 中重新定义。
- FR 变化由 Product Manager 批准；需求开发者按 `FUNCTIONAL_REQUIREMENT_CATALOG` Artifact contract 贡献内容。
