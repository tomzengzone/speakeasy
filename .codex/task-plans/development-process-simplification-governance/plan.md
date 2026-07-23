---
schema_version: 1
task_id: development-process-simplification-governance
title: 开发流程精简治理
status: in_progress
delivery_target: protected_branch_ci
created_at: 2026-07-17T15:26:03+08:00
updated_at: 2026-07-23T11:38:59+08:00
---
# 开发流程精简治理

## Goal

删除 Feature Spec 和 Acceptance Criteria 两个强制环节，保留 `Capability/Sub-capability -> User Story -> Vertical Slice -> mandatory Functional Requirement` 产品事实链，以及 FR、Engineering Contract、VS 三类分层 Test Case。旧 Product Base / Increment 文档原地保留但退出 active authority。

交付采用业界常规 GitHub 流程：PR 自动执行编译、静态分析和测试；CI 失败阻止合并；保护默认分支；GitHub 将检查结果绑定到被检查的 commit SHA。

## Success Criteria

- PR-001 已完成；PR-002 已 superseded；PR-003 完成治理切换；PR-004 用真实功能验证精简流程。
- Governance Contract 是 Artifact/Gate 路径、owner、lifecycle 和 routing 的唯一 authority。
- Story Map、FR Catalog、三类 TC 与 derived traceability 不重复拥有 direct edge。
- 旧 Spec/AC 路由和 Gate 不再进入 active authority graph。
- CI 仅保留常规 push/PR 触发、自动 checkout、静态校验、测试和构建；不包含可信 controller、双 checkout、基线/候选关系校验、重复 HEAD/摘要检查、attestation 或分阶段发布审批。

## Scope

包含 ADR、workflow、Definition of Done、Governance Contract、active Agents/Skills、validators、tests、CI 和一个真实功能试点。

不包含旧产品文档迁移或重写、远程 PR 创建、merge、push、force push及生产发布。

## Constraints

- 同一时刻最多一个 active PR unit。
- 修改目标、范围、允许路径或验收标准时递增 PR revision 并记录审批。
- 保留无关工作树修改。
- 普通 CI 失败时不得合并；分支保护设置由 GitHub 仓库管理。
- task plan 只记录执行状态，不替代产品、工程、测试或 CI source of truth。

## PR Sequence

- [PR-001](prs/PR-001.md) — 精简流程决策与迁移安全合同
- [PR-002](prs/PR-002.md) — superseded，未实施
- [PR-003](prs/PR-003.md) — 前瞻式开发治理切换与普通 CI
- [PR-004](prs/PR-004.md) — 真实功能试点与效率质量闭环

## Cross-PR Dependencies

PR-003 依赖已完成并验收的 PR-001。PR-004 依赖 PR-003 完成并通过普通 PR CI。任何上游 PR 被修订或撤销时，下游批准必须重新评估。

## Target Definition of Done

- approved VS 具有 mandatory FR；FR 与 typed TC 的 direct upstream 唯一。
- applicable Contract 与测试同步。
- validators、静态分析、测试和构建通过。
- GitHub CI 结果绑定被检查的 commit SHA，受保护分支拒绝失败检查。
- 无重复 authority、无 active Spec/AC Gate、无高强度 exact-commit 交付机制。

## Overall Evidence

- PR-001：已完成并验收。
- PR-002：已 superseded，未实施。
- PR-003：revision 15 正在实施；删除高强度交付治理、恢复普通 CI，并清理阻塞 PR #5 的 Flutter analyzer/Android build 问题。
- PR-004：等待 PR-003 完成后选择试点。

## Overall Verification

PR-003 完成后运行治理 validators、Skill validator、task-plan validator 和相关单元测试；PR-004 完成后补充真实功能的定向测试证据。

## Current Summary

PR-003 revision 15 正在实施，目标是保留普通 PR CI、删除专用 exact-commit 交付机制，并让 PR #5 的 CI 全量通过。

## Next Action

完成 PR-003 revision 15 的 GitHub CI、合并与对抗性审查。

## Next Approval Required

PR #5 CI 通过并合并后完成 PR-003；未完成前不启动 PR-004。
