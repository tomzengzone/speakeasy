---
schema_version: 1
task_id: development-process-simplification-governance
title: 开发流程精简治理
status: in_progress
delivery_target: exact_sha_baseline
created_at: 2026-07-17T15:26:03+08:00
updated_at: 2026-07-21T15:33:01+08:00
---
# 开发流程精简治理

## Goal

精简 AI 辅助开发的正式交付流程：删除 Feature Spec 和 Acceptance Criteria 两个强制环节，消除重复翻译，同时保留 `Capability/Sub-capability classification -> User Story -> Vertical Slice -> mandatory Functional Requirement` 的逐级产品事实链。Story Map、FR Catalog 与三类 TC 各自只维护唯一一级直接上游，canonical traceability 从 owning sources 派生完整链路而不成为第二个 edge owner；每条 FR 先以低成本 FR-TC 快速验证，受影响 Contract 以 Contract-TC 验证，每个实施中的 VS 再以用户可感知 integration/E2E VS-TC 验证完整闭环。旧 Product Base / Increment 文档原地保留但退出 active authority，不做内容迁移；最终执行状态只由绑定 exact commit 的测试/CI 保存，受保护 `refs/heads/speakeasy-20260705` 所指 exact SHA 是机器可读 active baseline。

## Success Criteria

- PR-001 已完成；PR-002 在未批准、未实施状态下被 `superseded`；PR-003 与 PR-004 继续逐单元批准、验证、独立审查和用户验收。
- 新流程不再要求 Spec/AC；每个进入实现的 approved VS 必须有 mandatory FR，每条 FR 只直接引用 VS 并归属一个 Primary Capability/Sub-capability。
- Capability Registry 只分类和划定模块边界；Story Map 持有 Story 到 Capability 与 Child VS 到 Story 的直接关系；FR Catalog 只持有 FR 到 VS 的 lineage；canonical traceability 从 owning sources 派生完整分支图，不独立编辑直接边。
- FR-TC、Contract-TC、VS-TC 分别只直接引用 FR、Engineering Contract、VS；每条 FR 具有可按 Capability/Sub-capability 定向运行的最低成本 FR-TC，Contract 事实变化具有 Contract-TC，每个实施中的 VS 具有用户可感知 integration/E2E VS-TC，其全部 FR coverage 由 traceability 派生校验。
- FR/Contract 快速测试先于 VS 全链路测试，不把最终 release E2E 当作首次发现模块缺陷的验证点。
- Story/VS/FR/TC/Contract 不承载 PR、Stage、Increment、rollout 或执行状态；Stage/Increment/Work Package 不成为产品行为、FR、TC 或 Contract 的权威上游。
- AI coding 最小上下文只包含 selected approved VS、mandatory FR、受影响 Contract、分层 TC、相邻代码/测试和命令，不加载无关 Stage/Increment/Spec/AC/legacy 文档链。
- 旧 `user_stories`、Product Base 和 Increment 文档原地保持不变，active route 和新增 authoritative reference 均为零；本任务不声明 legacy 事实无损继承。
- PR-003 在同一候选 commit 中建立 canonical FR/TC/traceability 路由并完成全部 legacy Artifact disposition；Governance Contract 独占 Artifact/Gate authority，Agent、Skill、Workflow、Template 不得重新定义或保存冲突副本，允许由 validator 对照一致的 derived operational pointer。候选 SHA 只有在全部 CI/独立检查通过并经用户授权 fast-forward 到受保护 `refs/heads/speakeasy-20260705` 后才成为 active graph。
- ADR 0007 必须以定向 validator 证明 current decision 已统一为 mandatory FR、三类 TC direct-edge matrix、derived traceability、forward-only/no-migration、PR-002 superseded、legacy historical-only、无 Hook 和 exact-SHA baseline；Story Map 必须证明旧 `user_stories` 与 Product Base/Increment Spec/AC 等来源链为零，Stage/Increment 仅 planning-only。
- Governance Contract 独占治理事实；Agent/native permission 负责角色与实际写权限，validator、CI 对最终候选 diff 验证 scope、legacy 隔离、mandatory FR、三层 TC、traceability、Contract 上游和 Gate，不建立 project-local Hook、runtime resolver、ephemeral bundle或首次写入拦截。
- PR-003 的最终候选从 checkout 到全部 required checks 结束始终绑定同一 exact SHA，并生成机器可读 CI attestation；PR revision 审批只授权本地实施，本地 PASS 后依次单独授权 candidate commit、candidate branch push/远程 CI，以及 baseline ref 从已核对 base SHA 到 attested candidate SHA 的 fast-forward。任何授权都不包含 PR 创建、merge commit、force push 或无关变更。
- PR-004 使用一个 PM-approved VS 完成 mandatory FR、FR/Contract/VS 分层 TC、test-first 实现和 exact-commit CI，且不创建临时 Spec/AC。
- 全部适用 PR 验收后形成 Overall Evidence，并由用户明确验收整个任务。

## Scope

包含开发流程精简决策、前瞻式 authority cutover、mandatory FR 与 direct-VS lineage、FR/Contract/VS 分层 TC、canonical traceability、AI coding 最小上下文、新 canonical FR/TC authority、完整 legacy Artifact disposition、active authority graph 与职责去重校验、最终 diff validator、exact-commit verifier/attestation/独立激活授权、workflow/DoD/Gate/Actor/Exchange/Intent/Skill/validator/CI 原子切换，以及一个真实功能试点。

不包含未经 PR-004 明确选择的产品功能开发，不迁移、重写、移动或删除旧产品文档，不逐条分类 262 个 legacy ID，不声明历史行为无损覆盖，不修改 ADR 0001 历史文本，也不创建远程 PR、merge commit、rebase/squash merge 或 force push。任务计划只记录执行状态，不替代产品、工程、测试或 CI source of truth；`delivery_target` 只描述最终 exact-SHA baseline 交付，不替代每个 Git/CI 动作的单独用户授权。

## Constraints

- 总计划必须先由用户显式批准；批准总计划只会把四张卡片转为 `planned`，不会启动 PR-001。
- 每个 PR 必须单独通过 `approve-pr`；完成验证后转为 `awaiting_acceptance` 并停止，用户验收后才可完成并请求下一 PR 批准。
- 同一时刻最多一个 `in_progress` 或 `awaiting_acceptance` PR；依赖 PR 未完成时不得批准下游 PR。
- 目标、范围、允许路径、验收或验证命令变化时必须运行 `revise-pr`，递增 revision 并清空旧批准。
- 跨会话续接必须运行 `resume`，核对 revision、branch、HEAD、允许路径和工作树漂移；发现漂移先停止报告。
- PR-002 已被用户选择的前瞻式切换 supersede，不得再建立 shadow fixture 或 legacy 迁移产物。
- PR-003 必须采用单候选内容提交并以受保护 `refs/heads/speakeasy-20260705` 原子激活，不允许 legacy 与新模型部分并行；候选分支不等于 active baseline，旧文档必须保持原地且内容不变，但 baseline 激活后的 legacy active route 和新增 authoritative reference 必须为零。
- Active legacy reference 以 `index.json` 路由生成的 active authority graph 判断，不以全仓关键词清零替代语义校验；旧产品文档和已退出 route 的 migration-only 文件可保留历史文字，但不得成为 active dependency、runtime definition、默认 context 或新增 authoritative input。
- PR-003 不建立 project-local Hook、runtime governance resolver、ephemeral bundle、首次写入 deny/retry 或 actor/session/turn 匹配；治理事实由 Governance Contract 持有，写权限由用户授权、native sandbox 与 Agent permission 决定，最终 diff 由 validator、CI 和独立 checker 验证。
- FR 必须 direct-to-VS、mandatory、原子且可测试；FR 的 Capability 字段只作分类，不构成第二条 lineage。FR-TC、Contract-TC、VS-TC 分别只 direct-to-FR、Contract、VS；完整 lineage/coverage 只能由 canonical traceability 从 owning sources 派生，不在 TC 或 traceability 中重复拥有直接边。
- FR/Contract 快速测试必须先于 selected VS 全链路测试；事实变化触发 Contract，同风险等级无关，额外治理按实际风险触发。
- PR-004 revision 3 不授予任何应用代码路径；选定 PM-approved VS 后必须先修订卡片并重新审批。
- 保留工作树中的无关改动；`delivery_target: exact_sha_baseline` 仅声明最终目标是 attested candidate SHA fast-forward 成为 `refs/heads/speakeasy-20260705` HEAD，不自动授权 commit、push、CI 或 baseline 更新。
- 批准 PR-003 revision 只授权本地实施。本地候选全部 PASS 后取得 candidate-commit approval；得到真实 SHA 后取得 exact-SHA CI approval，才可推送 candidate branch 并触发 CI；CI 与独立 checker PASS 后取得 baseline-activation approval，才可把 baseline ref 从已展示 base fast-forward 到同一 candidate SHA。三个授权均不包含 PR、merge commit、force push 或无关改动。
- `.codex/task-plans/**` 只记录执行状态、批准和证据，不替代 ADR、产品事实、Engineering Contract、Gate 或 CI 结果。

## PR Sequence

- [PR-001](prs/PR-001.md) — PR1 精简流程决策与迁移安全合同
- [PR-002](prs/PR-002.md) — PR2 精简流程影子验证与事实迁移演练（superseded，未实施）
- [PR-003](prs/PR-003.md) — PR3 前瞻式开发治理原子切换
- [PR-004](prs/PR-004.md) — PR4 真实功能试点与效率质量闭环

## Cross-PR Dependencies

PR-002 已被 supersede。PR-003 revision 11 仅依赖已完成并验收的 PR-001，不依赖 shadow 演练或 legacy 迁移；PR-004 依赖 PR-003 的 attested candidate exact SHA 已 fast-forward 成为受保护 `refs/heads/speakeasy-20260705` baseline。任何上游 PR 被修订或撤销时，下游批准无效并必须重新评估 revision。

PR-004 的 VS ID、mandatory FR、FR/Contract/VS TC、Contract 和代码路径须在 PR-003 完成后由 PM 选择，并通过 `revise-pr` 写入后才可审批。

## File-Level Delivery Order

以下是文件构建与验证顺序，不是分阶段激活顺序。特别是 PR-003，任何单组文件都不得独立成为 authority；只有同一候选 commit 的全部文件和 Gate 通过后才能一次性激活。

1. PR-001：先完成 `docs/architecture/adr/0007-story-slice-led-delivery.md`，再完成 `docs/process/migrations/spec-ac-retirement.json`、对应 Schema、专用 validator/tests，最后只登记所需 governance route 和 artifact rows；不改 workflow/DoD/Gate/Skill。
2. PR-002：superseded，不产生 shadow 或迁移文件。
3. PR-003：先建立 canonical FR、TC、traceability schema/validator和 direct-edge matrix，再完成 legacy Artifact disposition 与 surviving Engineering Artifact rewire，随后按 policy 清理 workflow、DoD、Skill Quality Standard、Artifact/Gate/Actor/Exchange/Intent、active Skills/Agents/resources/templates 的冲突 authority 副本；再完成最终 diff validator 和 exact-commit verifier/attestation，最后同步 tests 与 CI。旧文档不改动，不建立 Hook/resolver/bundle。全部内容属于同一 candidate commit；本地 PASS 后取得 Candidate-commit approval，生成真实 SHA 后取得 Exact-SHA CI approval，CI/独立检查 PASS 后再取得 Baseline-activation approval fast-forward `refs/heads/speakeasy-20260705`。
4. PR-004：先由 PM 固化真实功能及 approved VS，再通过 `revise-pr` 写入 precise mandatory FR、FR/Contract/VS TC、Contract、代码和测试路径；执行顺序为 FR/Contract test-first failure -> 最小实现 -> VS 定向全链路验证 -> exact-commit CI -> 独立审查 -> 用户验收。

## Target Definition of Done

新流程切换后，一个变更只有同时满足以下条件才算 Done：

- 产品事实链包含 approved User Story、其 Child Vertical Slice 和 mandatory FR；实现者和 AI 不得在代码或 TC 中发明缺失行为。
- 每个进入实现的 approved VS 至少具有一条 approved FR；每条 FR 只直接引用 VS、归属一个 Primary Capability/Sub-capability，并表达原子可测试规则。
- 不要求创建 Feature Spec 或 Acceptance Criteria；异常、边界和 pass/fail 语义必须在 VS、适用 FR、TC 或 owning Contract 中有唯一归属。
- FR-TC、Contract-TC、VS-TC 分别只有 FR、Contract、VS 一个直接上游；每条 FR 具有最低成本 FR-TC，每个受影响 Contract 具有适用 Contract-TC，每个实施中的 VS 具有用户可感知 integration/E2E VS-TC，全部适用 FR coverage 由 canonical traceability 派生验证。
- Canonical traceability 能从 owning sources 重建 `Capability -> Story -> VS -> FR -> FR-TC`、`FR -> Contract -> Contract-TC`、`VS -> VS-TC` 与 selector/evidence 分支；FR 不重复 Story lineage，TC 不保存跨级 edge 或执行状态，traceability 不成为第二个 direct-edge owner。
- 受影响的 API、Domain、Persistence、AI 或 UX 事实发生变化时，相应 Contract 已同步更新并通过 contract/integration/migration/eval 验证；低风险不能豁免事实同步。
- FR/Contract 快速测试先于实现，selected VS 定向全链路测试在该 VS 完成前通过；保留可归因的先失败、后通过证据。
- 本地定向检查通过，CI 对同一 exact commit 通过；TC catalog 不保存易过期的执行状态。
- 已完成风险分类；安全、隐私、支付、数据完整性、不可逆迁移、跨系统兼容或生产发布风险按需追加独立审查、迁移、flag/canary、回滚和 release Gate。
- Issue/PR 只记录本次交付选择、状态和证据；Stage/Increment/Work Package、archived Spec/AC 不作为产品行为、TC 或 Contract 的 authoritative input。
- 无重复事实、无双写、无未解释例外；适用 owner 和独立 checker 已通过，用户要求的 PR 验收已完成。
- Governance Contract 是 canonical path、owner、lifecycle、Artifact I/O 和 Gate routing 的唯一 authority；Agent、Skill、Workflow、Template 只保留各自职责，并通过 Artifact/Gate ID 动态解析 contract。执行必需的 path/command 只能作为 validator 对照一致且非权威的 derived operational pointer。
- Governance Contract 是路径、owner/contributor、Artifact inputs、lifecycle 与 Gate routing 的唯一 authority；Agent/native permission 负责实际写权限，最终候选 diff 通过结构化 validator、CI 与独立 checker，且不引入 Hook/bundle 的第二套运行时治理状态。
- CI checkout、治理检查、应用检查和 attestation 全部绑定同一 candidate exact SHA；受保护 `refs/heads/speakeasy-20260705` 是机器可读 active baseline，只有另行授权的 fast-forward 才能激活。PR 卡片在 commit 后本地记录 SHA，不写入候选 commit形成自引用；candidate commit、push/CI、baseline activation 授权彼此分离。

## Final Acceptance Metrics

- 新功能强制创建的 Spec 数量为 0，强制创建的 AC 数量为 0；active `G-SPEC`、`G-AC-TC` 和 legacy Spec/AC route 数量在 PR-003 后为 0。
- 产品事实链固定为 `approved Story -> approved VS -> mandatory FR`，相对 legacy 删除 Spec/AC 两层；FR 只直接引用 VS，完整 Story lineage 由 traceability join 得出。
- 同一直接关系的 canonical owning source 数量为 1；FR/FR-TC/Contract-TC/VS-TC direct-upstream 违反矩阵数量为 0，traceability 中无法由 owning source 派生的 edge 数量为 0；新 canonical Artifact 中指向 Stage/Increment/Work Package/archived Spec/AC 的 authoritative reference 数量为 0。
- Accepted baseline 的 active authority graph 中 legacy Artifact/Gate/Actor/Skill route、旧上游依赖和跨层冲突/权威化的 Governance Contract 字段副本数量均为 0；contract-aligned derived operational pointer、负向 validator 断言与 historical evidence 不计为 active authority。
- 最终候选 diff 的 governed Artifact scope、legacy 隔离、mandatory FR、三层 TC、traceability、Contract upstream 与 applicable Gate 检查覆盖率为 100%；新增 project-local Hook、runtime resolver、ephemeral bundle和首次写入拦截数量为 0，scope/permission 扩大数量为 0。
- Required CI checks、checkout HEAD、candidate SHA、authority graph digest 和 attestation SHA 一致率为 100%；激活后 baseline HEAD 与 attested candidate SHA 一致率为 100%，非 fast-forward/merge commit/force push 数量为 0，未获单独授权的 commit/push/baseline update 数量为 0。
- 旧 `user_stories`、Product Base、Increment 文档内容变更数量为 0，active route 和新增 authoritative reference 数量为 0；不计算 262 条迁移覆盖率。
- ADR 0007 中仍可被解释为现行规则的 optional FR、shadow/262 迁移、active Spec/AC Gate、Hook preflight、候选内 `status=active` 数量为 0；mandatory FR、三类 TC、derived traceability、forward-only/no-migration、PR-002 superseded、legacy historical-only 与 exact-SHA baseline 定向断言通过率为 100%。
- Story Map 中指向旧 `user_stories`、Product Base、Increment Requirements/Spec/Acceptance/Test/Traceability 的正向 source/prerequisite/fallback/authoritative link 数量为 0；Stage/Increment 非 planning-only 用法、Spec/AC 字段/Gate/交付步骤、FR/TC/Contract 正文复制数量均为 0。
- Approved VS 到 mandatory FR 覆盖率、FR 到 FR-TC 覆盖率、实施中 VS 到 VS-TC 覆盖率、受影响 Contract 到 Contract-TC 覆盖率均为 100%，或存在明确批准且限期的例外；VS-TC 中重复 FR ID 集合数量为 0。
- TC 具备自包含 oracle、边界、层级、scope、selector、脚本路径和执行命令的比例为 100%；TC Catalog 中易过期执行状态数量为 0。
- 事实发生变化的 Engineering Contract 同步率和适用 contract/integration/migration/eval 验证率均为 100%。
- 每个 PR 的适用自动验证、治理 validator 和 exact-commit CI 通过率为 100%；未关闭 blocker finding 数量为 0；独立 checker 缺失数量为 0。
- PR-004 试点新增 Spec/AC 文件数、legacy authority 引用数和重复事实数均为 0；mandatory FR、分层 TC、测试先失败/后通过、最小开发上下文、Contract 影响和 exact-commit CI 证据完整率为 100%。

## Overall Verification

- 每次计划状态写入后：`python .agents/skills/manage-task-plan/scripts/task_plan.py validate development-process-simplification-governance`
- 每个 PR 执行卡片中列出的定向 validator 和 unittest，并保存命令、结果、branch/HEAD 或 commit 证据。
- 所有治理 PR：`python scripts/validate_governance_contracts.py`、`python scripts/validate_agent_skills.py`、`python -m unittest tests.test_validate_governance_contracts -v`。
- 适用文档运行定向语言检查和 governance write-scope 检查，避免用全仓既有欠债替代本 PR 归因。
- 每个 PR 在 `awaiting_acceptance` 前执行独立只读 `product_object_governance_check`；涉及架构或应用代码时追加相应架构/代码质量 checker。
- PR-003/PR-004 必须由 CI 对同一 exact commit 给出机器可读通过证据；本地通过不能代替 exact-commit CI。
- PR-003 必须运行最终 diff 的 governed Artifact scope、legacy 隔离、direct-edge matrix、derived traceability、Contract/Gate 和 authority-separation validator，以及 candidate SHA/baseline base/fast-forward/checkout drift/attestation fixture；不得新增或启用 project-local Hook、runtime resolver、ephemeral bundle或首次写入 deny/retry。
- PR-003 必须运行 `python3 scripts/validate_story_slice_cutover.py --check-adr --check-story-map`，并以先失败后通过 fixture 证明 ADR 旧决策和 Story Map 旧来源链不能继续作为 active 规则。

## Overall Evidence

尚无。仅在 PR-001 至 PR-004 全部由用户验收后汇总，不把预检或计划创建记录当作完成证据。

## Current Summary

总计划和 PR-001 revision 3 已分别获得用户批准；用户于 2026-07-20 显式验收 PR-001，状态已转为 `completed`。用户随后选择前瞻式 authority cutover，取消 shadow/legacy 内容迁移，因此 PR-002 revision 3 在未批准、未实施状态下转为 `superseded`。PR-003 已修订为 revision 11：在 revision 10 的 ADR/Story Map 定向验收基础上，补入实施前 active-definition inventory 发现的存续 cross-cutting/SWC/release 治理文档、implementation report 方法和 Engineering Contract lineage/provenance 路径；这些路径只允许移除旧 Product Base/Increment/Spec/AC/SWC-allocation 正向 authority，不得改写工程行为事实。Revision 8 已删除全部 Hook/runtime resolver/bundle 方案。旧产品文档原地保持不变。PR-003 revision 11 与 PR-004 尚未获实施批准，baseline 上的 runtime legacy authority 尚未切换。

## Next Approval Required

下一审批门是用户审阅并单独批准 PR-003 revision 11。当前修改只更新任务计划和 PR 卡片；revision 11 批准只授权本地实施，本地 PASS 后依次请求 candidate-commit approval、exact-SHA CI approval 和 baseline-activation approval，不授权 PR、merge commit、force push 或无关变更。
