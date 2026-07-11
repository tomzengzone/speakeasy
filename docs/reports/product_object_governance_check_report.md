# 产品对象治理整改检查报告

## 检查日期
2026-05-24

## 检查角色
`codex/agents/product_object_governance_check.md`

## 检查范围
- `docs/process/product_object_governance_remediation.md`
- `codex/agents/product_object_governance_change.md`
- `codex/agents/product_object_governance_check.md`
- `docs/process/workflow.md`
- `docs/process/skill_quality_standard.md`
- `.agents/skills/document-path-governance/`
- `.agents/skills/document-content-contract/`
- `.agents/skills/document-governance/`
- `.agents/skills/requirement-refine/`
- `.agents/skills/feature-spec-generate/`
- `.agents/skills/acceptance-criteria-generate/`
- `.agents/skills/domain-model-generate/`
- `.agents/skills/api-contract-generate/`
- `.agents/skills/prompt-contract-generate/`
- `.agents/skills/screen-spec-generate/`
- `.agents/skills/test-case-generate/`
- `.agents/skills/implementation-report-generate/`

## 分步检查结果

### 1. 整改方案
Result: pass

检查结论：
- 已定义产品对象模型：Feature、Stage、Increment、Baseline、Change Request、Artifact。
- 已把整改拆成小步任务，并明确当前不迁移、不改名、不改应用代码。
- 已明确完成标准和后续迁移方向。

### 2. 变更 Agent 与检查 Agent
Result: pass

检查结论：
- `product_object_governance_change` 只允许在授权小步内修改治理、workflow、skill、agent 文档。
- `product_object_governance_check` 独立检查变更范围、对象边界、非预期变更、skill 校验和后续风险。
- 两个 agent 均明确禁止未授权移动既有产品文档或修改 Flutter 应用代码。

### 3. Workflow 门禁
Result: pass

检查结论：
- workflow 已加入 Product Planning Layer。
- 已加入 Product Object Model。
- 已加入 Product Classification Gate、Increment Definition Gate 和 Governance Change Control。
- 标准链路已从需求前置改为：intake -> classification -> registry/stage check -> increment definition -> requirements/spec/acceptance/contracts/plan/code/tests/report。

### 4. 路径与内容治理
Result: pass

检查结论：
- `skill_quality_standard` 已定义新的对象化产品路径。
- `document-path-governance` 已定义 feature、stage、increment、baseline 的路径边界。
- `document-content-contract` 已定义各对象文档的内容边界。
- `document-governance` 已定义混用 feature/stage/baseline 时的阻断和拆分规则。

### 5. 生成类 Skill
Result: pass

检查结论：
- requirement、spec、acceptance 三个核心生成 skill 已改为先分类产品对象，再选择 feature/stage/increment/baseline 路径。
- domain、API、prompt、screen、test、implementation report 等下游 skill 已补充 owning increment / stable feature 约束。
- 新产品工作优先从 `docs/product/increments/<increment-id>/` 进入；旧扁平 feature 工件不再作为兼容路径。

## 执行过的检查命令
- `rg -n "Product Object Model|Product Classification Gate|Increment Definition Gate|Governance Change Control|baseline-consolidation|feature-increment|No feature/increment" docs\process\workflow.md`
- `rg -n "Feature Registry|Product Object Governance|Product Object Path Rules|feature_registry|baselines/<baseline-slug>|stages/<stage-id>|increments/<increment-id>" docs\process\skill_quality_standard.md .agents\skills\document-path-governance\SKILL.md .agents\skills\document-content-contract\SKILL.md .agents\skills\document-governance\SKILL.md`
- `rg -n "Product Object Rules|Product Object Outputs|increments/<increment-id>|owning increment|stable feature|stage goal|roadmap text" .agents\skills`
- `python scripts\validate_agent_skills.py`

## 总结
Result: pass

本次整改符合预期：只修改治理文档、agent 定义和 skill 规则；没有迁移既有产品需求文档；没有修改 Flutter 应用代码；没有把 P0.1 具体产品内容写入全局治理规则。

## 遗留风险
- 旧扁平 feature 工件的对象化迁移状态已由后续治理步骤处理。
- `docs/product/feature_registry.md`、`docs/product/stages/<stage-id>.md`、`docs/product/increments/<increment-id>/` 仍需要在下一步按新规则创建或迁移。
- 旧扁平 feature 工件路径兼容状态已由后续治理步骤清理。
- 本次是流程和文档治理变更，未运行应用层测试。

## 2026-07-11 Capability Registry 候选对象落表检查

Result: pass

检查步骤：
- 当前步骤为 Product Manager 按 `capability-registry-develop` 流程将候选对象落入 `docs/product/feature_registry.md`，不生成 Story、FR、Spec、AC、TC、stage、increment、架构或代码。

目标与变更模式：
- `CAP-SETTING`：`add`，新增顶层 Capability 和 `CAP-SETTING-01..04`。
- `CAP-SUPPORT`：`add`，新增顶层 Capability 和 `CAP-SUPPORT-01..04`。
- `CAP-BILLING`：`add`，新增顶层 Capability 和 `CAP-BILLING-01..04`。
- `CAP-ACC`、`CAP-COM`、`CAP-COM-02`、`CAP-COM-04` 及相关相邻 Capability 行：`boundary-change`，用于明确账号、会员权益、应用设置、用户支持、账单支付之间的 ownership 边界。
- `profile-membership`、`commercial-subscription` Legacy Mapping：`legacy-mapping-only` 更新。

Gate 与 PM 确认：
- Gate A：通过。PM 确认通用 App 设置、用户支持服务、账单与支付服务均为 Registry destination，目标对象类型为 Capability，目标 ID 分别为 `CAP-SETTING`、`CAP-SUPPORT`、`CAP-BILLING`。
- Gate B：通过。三项新增 Capability 均有独立长期业务结果，且分别与 `CAP-ACC`、`CAP-COM`、`CAP-ENGAGE`、`CAP-PRACTICE`、`CAP-COACH`、`CAP-CONTENT` 等相邻能力完成边界比较。
- PM exact-row final approval：已确认并持久化上述 Capability 行、12 条 Sub-capability 行、`CAP-COM-02`、`CAP-COM-04`、相关边界/相邻关系行和 Legacy Mapping 行。

验证：
- `python scripts/validate_capability_registry.py` 通过。
- Validator rows：capabilities=15，sub_capabilities=73，legacy_mappings=14。
- Validator warning：none。

独立检查：
- Checker：tool-backed independent Product Object Governance Check Agent。
- Checker result：pass。
- Checker finding：新增 `CAP-SETTING`、`CAP-SUPPORT`、`CAP-BILLING` 与既有 `CAP-ACC`、`CAP-COM`、`CAP-ENGAGE`、`CAP-PRACTICE` 等边界分离清楚；未发现 split/merge/deprecate successor 伪持久化；未发现本轮 row-level scope 外的下游改写。

残留风险：
- 工作区存在大量本轮开始前已存在的 dirty / untracked 文件，未作为本轮 blocker。
- `docs/product/feature_registry.md` 顶部治理说明相关 diff 不是本轮 row-level registry 变更审查范围；若后续要声明该治理文案为本轮产物，需要单独治理证据。
- 本轮没有迁移已有 Story、Product Base、increment、requirements、spec、AC、TC 或实现引用；相关文档在后续被触碰时应按新的 Capability Registry 边界重新分类。
