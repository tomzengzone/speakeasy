---
schema_version: 1
task_id: development-process-simplification-governance
title: 开发流程精简治理
status: in_progress
delivery_target: local
created_at: 2026-07-17T15:26:03+08:00
updated_at: 2026-07-19T20:45:19+08:00
---
# 开发流程精简治理

## Goal

精简 AI 辅助开发的正式交付流程：删除 Feature Spec 和 Acceptance Criteria 两个强制环节，消除同一行为在 Story/VS、FR、Spec、AC、TC 与 traceability 中的重复翻译；将长期产品事实、持久工程 Contract、可执行测试 oracle 和一次性交付状态分别放回唯一 owning source。目标流程以 approved User Story / Vertical Slice 为产品输入，以可选稳定 FR 表达跨 Slice 复用规则，以自包含 TC 驱动 test-first 实现，以事实变化决定 Contract 更新、以风险决定额外治理，并通过小批量 PR、快速本地反馈和 exact-commit CI 形成可执行、可验证、可审计的成熟工程闭环。

## Success Criteria

- PR-001 至 PR-004 严格串行，每个 PR 都有独立批准、自动验证、只读治理审查和用户验收记录。
- 新流程不再把 Spec/AC 作为默认必经文档或 Gate；approved VS 之后只创建实际需要的可选 FR、TC 和受事实变化影响的 Contract。
- 产品事实与交付治理彻底分离：Story/VS/FR 不承载 PR、阶段、rollout 或执行状态；Stage/Increment/Work Package 不成为产品行为、FR、TC 或 Contract 的权威上游。
- AI coding 的最小上下文包收敛为 selected approved VS、适用 FR、受影响 Contract、相邻代码/测试和验证命令，不再要求加载无关 Stage/Increment/Spec/AC 文档链。
- 测试先于实现：TC 自包含 pass/fail oracle、边界、测试层级和稳定 selector；执行结果只由绑定 exact commit 的 CI/测试系统保存。
- 普通可逆单 Slice 变更走最短反馈路径；Contract 按事实变化触发，ADR、安全/数据/发布/迁移/独立审查按实际风险追加，不因删掉 Spec/AC 而降低质量控制。
- PR1/PR2 期间 ADR 0001、现有 workflow、Definition of Done、`G-SPEC`、`G-AC-TC` 和 Spec/AC Skills 始终是唯一 runtime authority。
- 116 份 legacy Increment 文档中的 262 个 Spec/AC 定义 ID 全部具有经 owner 核验的终态和零歧义迁移去向；不得静默丢弃仍有效的产品规则、Contract 约束或回归 oracle。
- PR3 在同一候选 commit 中建立 canonical FR/TC 路由、更新全部适用治理 authority、归档旧 Spec/AC/Increment 测试与 traceability authority，并以全量 Gate 和 exact-commit CI 证据一次性激活；任何必要项失败时不允许部分生效。
- Stage、Increment 和 Work Package 仅保留规划语义，不再成为产品行为、FR、TC 或 Engineering Contract 的权威上游。
- PR4 使用一个 PM 已批准的真实功能完成 test-first 实现、自动测试和 CI 验证，证明强制文档跳数、重复事实和 legacy authority 引用均为零，且不创建临时 Spec/AC 绕过新模型。
- 全部 PR 验收后形成 Overall Evidence，并由用户明确验收整个任务。

## Scope

包含开发流程精简的决策与量化基线、迁移安全合同、影子流程/Schema/fixture/validator、legacy 事实分类、AI coding 最小上下文合同、新 canonical FR/TC authority、workflow/DoD/Gate/Actor/Exchange/Intent/Skill/validator/CI 原子切换、历史 authority 归档，以及一个真实功能试点。

不包含未经 PR-004 明确选择的产品功能开发，不借流程精简重写产品行为，不把 User Story/Vertical Slice 本身当作治理目标，不修改 ADR 0001 的历史文本，不把本任务计划或迁移 manifest 变成产品/工程/测试 source of truth，也不授权提交、推送、创建、合并或关闭远程 PR。任务 ID `development-process-simplification-governance` 直接表达“开发流程精简治理”，仅作为稳定续接键，不承载额外产品语义。

## Constraints

- 总计划必须先由用户显式批准；批准总计划只会把四张卡片转为 `planned`，不会启动 PR-001。
- 每个 PR 必须单独通过 `approve-pr`；完成验证后转为 `awaiting_acceptance` 并停止，用户验收后才可完成并请求下一 PR 批准。
- 同一时刻最多一个 `in_progress` 或 `awaiting_acceptance` PR；依赖 PR 未完成时不得批准下游 PR。
- 目标、范围、允许路径、验收或验证命令变化时必须运行 `revise-pr`，递增 revision 并清空旧批准。
- 跨会话续接必须运行 `resume`，核对 revision、branch、HEAD、允许路径和工作树漂移；发现漂移先停止报告。
- PR-001/PR-002 禁止提前修改正式 workflow、DoD、Gate、Skill 或 active artifact route；PR-002 产物必须显式标记 shadow/non-canonical。
- PR-003 必须采用单候选提交原子激活，不允许 legacy 与新模型部分并行；事实变化触发 Contract，同风险等级无关，额外治理按实际风险触发。
- PR-004 revision 3 不授予任何应用代码路径；选定 PM-approved VS 后必须先修订卡片并重新审批。
- 保留工作树中的无关改动；`delivery_target: local` 不包含 commit、push 或远程 PR 操作。
- `.codex/task-plans/**` 只记录执行状态、批准和证据，不替代 ADR、产品事实、Engineering Contract、Gate 或 CI 结果。

## PR Sequence

- [PR-001](prs/PR-001.md) — PR1 精简流程决策与迁移安全合同
- [PR-002](prs/PR-002.md) — PR2 精简流程影子验证与事实迁移演练
- [PR-003](prs/PR-003.md) — PR3 精简开发治理原子切换
- [PR-004](prs/PR-004.md) — PR4 真实功能试点与效率质量闭环

## Cross-PR Dependencies

PR-002 依赖 PR-001 的精简目标、现状基线与迁移合同被用户验收；PR-003 依赖 PR-002 同时证明流程更短、AI 上下文更小、质量语义不降级且 262 条 legacy 去向无缺口；PR-004 依赖 PR-003 已在 exact commit 上完成原子激活。任何上游 PR 被修订或撤销时，下游批准无效并必须重新评估 revision。

PR-003 的精确 canonical/归档路径须由 PR-002 结果固化；PR-004 的 VS ID、FR/TC/Contract 和代码路径须在 PR-003 完成后由 PM 选择，并通过 `revise-pr` 写入后才可审批。

## File-Level Delivery Order

以下是文件构建与验证顺序，不是分阶段激活顺序。特别是 PR-003，任何单组文件都不得独立成为 authority；只有同一候选 commit 的全部文件和 Gate 通过后才能一次性激活。

1. PR-001：先完成 `docs/architecture/adr/0007-story-slice-led-delivery.md`，再完成 `docs/process/migrations/spec-ac-retirement.json`、对应 Schema、专用 validator/tests，最后只登记所需 governance route 和 artifact rows；不改 workflow/DoD/Gate/Skill。
2. PR-002：在 `docs/process/governance/shadow/story-slice-delivery/**` 建立 non-canonical 旧/新流程对照、FR/TC/coverage/context-bundle fixtures；随后实现 shadow validator/tests，最后在 migration manifest 中记录经 owner 核验的 typed destinations；active governance 文件保持不变。
3. PR-003：先由 PR-002 结果确定 canonical FR/TC、archive 和 validator 的精确路径；在同一候选变更中构建 canonical artifacts 与 cutover validator，迁移并归档 legacy authority，再同步修改 workflow、DoD、governance artifact/gate/actor/exchange/intent、相关 Skills/Agents、tests 和 CI。治理 `status` 与新 route 激活放在逻辑上的最后一步，但仍属于同一候选 commit。
4. PR-004：先由 PM 固化真实功能及 approved VS，再通过 `revise-pr` 写入精确 Story/VS、可选 FR、TC、Contract、代码和测试路径；执行顺序为 TC/test-first failure -> 最小实现 -> 定向验证 -> exact-commit CI -> 独立审查 -> 用户验收。

## Target Definition of Done

新流程切换后，一个变更只有同时满足以下条件才算 Done：

- 产品输入引用一个完整且 approved 的 User Story/Vertical Slice；实现者和 AI 不得在代码或 TC 中发明缺失行为。
- 只有跨多个 Slice 复用的稳定规则才建立或更新 FR；单 Slice 规则留在 owning VS，不为形式完整增加翻译层。
- 不要求创建 Feature Spec 或 Acceptance Criteria；异常、边界和 pass/fail 语义必须在 VS、适用 FR、TC 或 owning Contract 中有唯一归属。
- TC 直接引用 approved VS、可选 FR 和受影响 Contract，包含自足 Given/When/Then、边界/负例、测试层级和稳定 selector。
- 受影响的 API、Domain、Persistence、AI 或 UX 事实发生变化时，相应 Contract 已同步更新并通过 contract/integration/migration/eval 验证；低风险不能豁免事实同步。
- 测试先于实现，保留可归因的先失败、后通过证据；实现只覆盖 selected VS 的最小范围。
- 本地定向检查通过，CI 对同一 exact commit 通过；TC catalog 不保存易过期的执行状态。
- 已完成风险分类；安全、隐私、支付、数据完整性、不可逆迁移、跨系统兼容或生产发布风险按需追加独立审查、迁移、flag/canary、回滚和 release Gate。
- Issue/PR 只记录本次交付选择、状态和证据；Stage/Increment/Work Package、archived Spec/AC 不作为产品行为、TC 或 Contract 的 authoritative input。
- 无重复事实、无双写、无未解释例外；适用 owner 和独立 checker 已通过，用户要求的 PR 验收已完成。

## Final Acceptance Metrics

- 新功能强制创建的 Spec 数量为 0，强制创建的 AC 数量为 0；active `G-SPEC`、`G-AC-TC` 和 legacy Spec/AC route 数量在 PR-003 后为 0。
- 单 Slice 目标链路最多为 `approved VS -> TC` 两个事实/验证节点；存在跨 Slice 稳定规则时最多为 `approved VS -> FR -> TC` 三个节点。相对 legacy 五节点链路分别减少至少 60% 和 40%。
- 同一行为或规则的 canonical owning source 数量为 1；新 canonical Artifact 中指向 Stage/Increment/Work Package/archived Spec/AC 的 authoritative reference 数量为 0，双写数量为 0。
- 116 份 legacy 文件路径与 262 个 Spec/AC ID 的 disposition 覆盖率为 100%；仍有效事实迁移覆盖率为 100%，未解释的 `grandfathered-unverified` 当前行为数量为 0。
- Approved VS 到 executable regression TC 的覆盖率为 100%；TC 具备自包含 oracle、边界、层级和稳定 selector 的比例为 100%。
- 事实发生变化的 Engineering Contract 同步率和适用 contract/integration/migration/eval 验证率均为 100%。
- 在 PR-002 的同一代表性 fixture 上，AI 默认 context bundle 不包含 Stage/Increment/Spec/AC 全文，文件/引用总量或 UTF-8 字节数不高于 legacy 必需上下文的 60%，同时行为与边界覆盖保持 100%。
- 每个 PR 的适用自动验证、治理 validator 和 exact-commit CI 通过率为 100%；未关闭 blocker finding 数量为 0；独立 checker 缺失数量为 0。
- PR-004 试点新增 Spec/AC 文件数、legacy authority 引用数和重复事实数均为 0；测试先失败/后通过、最小 context bundle、Contract 影响和 exact-commit CI 证据完整率为 100%。

## Overall Verification

- 每次计划状态写入后：`python .agents/skills/manage-task-plan/scripts/task_plan.py validate development-process-simplification-governance`
- 每个 PR 执行卡片中列出的定向 validator 和 unittest，并保存命令、结果、branch/HEAD 或 commit 证据。
- 所有治理 PR：`python scripts/validate_governance_contracts.py`、`python scripts/validate_agent_skills.py`、`python -m unittest tests.test_validate_governance_contracts -v`。
- 适用文档运行定向语言检查和 governance write-scope 检查，避免用全仓既有欠债替代本 PR 归因。
- 每个 PR 在 `awaiting_acceptance` 前执行独立只读 `product_object_governance_check`；涉及架构或应用代码时追加相应架构/代码质量 checker。
- PR-003/PR-004 必须由 CI 对同一 exact commit 给出机器可读通过证据；本地通过不能代替 exact-commit CI。

## Overall Evidence

尚无。仅在 PR-001 至 PR-004 全部由用户验收后汇总，不把预检或计划创建记录当作完成证据。

## Current Summary

2026-07-17 创建计划后，用户纠正任务目标为“开发流程精简治理”；`Story/Vertical Slice` 仅是目标流程的产品输入方式。随后补齐总计划级 File-Level Delivery Order、Target Definition of Done 和 Final Acceptance Metrics，四张 PR 卡片已全部递增到 revision 3 并清空批准。当前分支 `speakeasy-20260705`，检查时 HEAD 为 `6c1e19f36f3e1167f8e33ddb45e0506d989e5a57`。PR1 的 8 个候选文件已经存在于未跟踪工作树，专用 validator 预检为 116 files / 262 IDs / 262 records，但这些候选变更是在本计划批准前形成，尚未获得本任务的 PR-001 批准或验收；后续必须按新的流程精简目标重新核验，不追认旧证据。

## Next Approval Required

总计划已于 2026-07-19 获用户显式批准，四个 PR 已转为 `planned`。下一审批门是用户单独批准 PR-001 revision 3；在该批准前不得启动或修改 PR-001 范围内实现。
