---
schema_version: 1
task_id: vertical-slice-governance-balance
title: 均衡 Vertical Slice 治理定义落地
status: completed
delivery_target: local
created_at: 2026-08-06T17:05:05+08:00
updated_at: 2026-08-06T21:49:46+08:00
---
# 均衡 Vertical Slice 治理定义落地

## Goal

建立一套均衡、可复用且不过度臃肿的 Child Vertical Slice 治理定义，使用户价值、可观察结果、相对独立性、端到端完整性、可交付性、规模、可验证性、恢复边界和事实分层得到一致判定，并让 `STORY_MAP` 与 `SCREEN_SPEC` 的权威边界清晰可执行。

## Success Criteria

- `story-map-develop` 使用统一 VS 定义和多维就绪标准，不增加 UI 特例规则。
- 自然业务前置关系不再被等同于无独立价值，同时不得以端到端为由制造过大 VS。
- 用户交互语义与具体界面呈现的事实归属在 Governance Contract 和两个 method Skill 中一致。
- `docs/product/story_map.md` 只保留简洁的文档边界说明，不复制完整方法规则。
- 所有适用 Skill、Governance Contract、Story/Slice 和文档语言校验通过，独立治理检查返回 `pass`。

## Scope

包含：`story-map-develop` 主定义和直接 reference、`STORY_MAP`/`SCREEN_SPEC` Artifact applicability、`screen-spec-generate` 的上下游边界、Story Map 文档头部重复规则清理。

不包含：重写现有 User Story/VS、创建 FR/TC/Engineering Contract、修改应用代码、调整 Gate/Agent/Workflow、提交或发布远程 PR。

## Constraints

- 按 PR-001 → PR-002 → PR-003 串行执行；一次只允许一个活动 PR 单元。
- 总计划和每个 PR revision 必须分别获得用户批准。
- 只编辑当前 owning authority，不创建平行规则、兼容说明或新治理文件。
- 保留 `docs/product/story_map.md` 当前已有的未提交 Story/VS 工作；PR-003 只允许修改文档头部说明。
- 使用 `product-object-governance-change` 执行治理变更，适用时由只读 checker 独立审查。
- 控制 token 开销：每个 PR 只加载该单元的权威文件与验证证据，不重复扫描无关目录。

## PR Sequence

- [PR-001](prs/PR-001.md) — 重建 Story Map 的 VS 定义与就绪规则
- [PR-002](prs/PR-002.md) — 对齐 Story Map 与 Screen Spec 权威边界
- [PR-003](prs/PR-003.md) — 清理文档重复规则并完成全量治理验证

## Cross-PR Dependencies

PR-002 以 PR-001 的统一 VS 语义为上游，负责对齐跨 Artifact 边界；PR-003 只在前两项规则稳定后清理 canonical Story Map 中的重复说明并执行全量复核。

## Overall Verification

- `python scripts/validate_agent_skills.py`
- `python scripts/validate_governance_contracts.py`
- `python scripts/validate_story_slice_cutover.py`
- `python scripts/validate_story_slice_delivery.py`
- `python scripts/check_document_language.py --scope changed --include-worktree`
- `git diff --check`
- `skill-quality-check` 语义检查与 `product-object-governance-check` 独立只读审查

## Overall Evidence

- PR-001 revision 1、PR-002 revision 2 和 PR-003 revision 2 均已获得用户验收并标记为 `completed`。
- 九文件组合 candidate exact scope SHA-256：`f80aec652c522e8e68baa889aeb0786542de331faef2a3fcb5f429c0a0286d7d`。
- `story-map-develop` 已建立统一 VS 定义和 12 个均衡判定维度；Story Map、Screen Spec 与 Test Case 的事实归属已形成单向下游边界。
- Story Map 仅保留简洁分层说明；从 `## 编号与记录规则` 到 EOF 的 SHA-256 在修改前后均为 `3d397e451ea938b62a10daea07e341aac16962815c5557a7f144e104f4e6aaee`，既有 Story/VS 正文保持逐字节不变。
- Cutover 与 delivery validator 单元测试分别通过 24 和 22 个用例；Skill、Governance Contract、Story/Slice、文档语言和格式校验全部通过。
- `skill-quality-check` 和 `product-object-governance-check` 均返回 `pass`，无 required corrections。

## Current Summary

三个顺序 PR 单元已全部完成并获得用户验收。均衡 VS 定义、跨 Artifact 权威边界、精简 Story Map 头部及防漂移校验证据已形成一致闭环；用户已验收总任务。

## Next Approval Required

无；总任务已获得用户验收。
