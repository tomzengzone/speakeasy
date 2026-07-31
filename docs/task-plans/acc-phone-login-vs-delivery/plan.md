---
schema_version: 1
task_id: acc-phone-login-vs-delivery
title: 手机号验证码登录 VS 交付包
status: awaiting_approval
delivery_target: local
created_at: 2026-07-23T22:44:49+08:00
updated_at: 2026-07-23T22:46:25+08:00
---
# 手机号验证码登录 VS 交付包

## Goal

按可独立审查、验证且合并后仍有效的边界，将 `US-ACC-001` 下
`VS-ACC-001-1`～`VS-ACC-001-13` 实现为四个顺序交付包，最终形成完整的手机号
短信验证码注册/登录主链路，并将虚拟运营商号段风险接入保持为独立交付边界。

## Success Criteria

- `VS-ACC-001-1`～`VS-ACC-001-13` 均且仅映射到一个 WP/PR 单元，没有遗漏或重叠。
- WP-1～WP-3 顺序交付可形成手机号输入、验证码发送、验证码提交、自动注册或登录的完整主链路。
- WP-4 独立验证虚拟运营商号段“不直接拒绝、只传递风险因子”的行为。
- 每个 PR 单元的目标、范围、允许路径、验收标准、验证命令和下一审批动作均完整。
- 全部 PR 经逐项批准、验证和用户验收后，任务才可标记完成。

## Scope

包含：

- WP-1：`VS-ACC-001-1`～`VS-ACC-001-6`，手机号输入、发送资格、主动发送、倒计时和脱敏反馈。
- WP-2：`VS-ACC-001-7`～`VS-ACC-001-9`，验证码数字输入、6 位提交资格和移动端自动填充。
- WP-3：`VS-ACC-001-10`～`VS-ACC-001-12`，验证成功后的账号判定、自动注册或直接登录。
- WP-4：`VS-ACC-001-13`，虚拟运营商号段风险因子接入。

不包含：邮箱登录、微信/Apple 登录、账号中心、账号绑定，以及 `US-110`
风控策略本身的定义或实现。

## Constraints

- 本计划仅记录执行边界和状态，不替代 Story、VS、FR、Engineering Contract 或测试用例等正式事实来源。
- 总计划批准前不实施；每个 PR 必须单独批准、顺序执行并单独验收。
- 同一时间最多一个 PR 处于 `in_progress` 或 `awaiting_acceptance`。
- 保留现有工作树改动；每个 PR 只修改其卡片列出的允许路径。
- `VS-ACC-001-1`～`VS-ACC-001-13` 当前为 `draft`；实施前必须确认其行为边界已达到可执行状态。
- WP-2 开始前确认 Android OTP API 与 iOS 短信建议能力是否同时纳入当前交付；若平台能力未就绪，须修订计划并重新审批，不在执行中静默拆包。
- WP-4 依赖既有 `US-110` 风控接口或可替代契约；本任务不自行定义风控决策。

## PR Sequence

- [PR-001](prs/PR-001.md) — WP-1 手机号输入与验证码发送（VS-ACC-001-1～006）
- [PR-002](prs/PR-002.md) — WP-2 验证码输入与自动填充（VS-ACC-001-7～009）
- [PR-003](prs/PR-003.md) — WP-3 自动注册或登录判定（VS-ACC-001-10～012）
- [PR-004](prs/PR-004.md) — WP-4 虚拟运营商号段风险接入（VS-ACC-001-13）

## Cross-PR Dependencies

- PR-002 依赖 PR-001 提供发送成功后的验证码输入状态。
- PR-003 依赖 PR-002 提供合法的 6 位验证码提交入口及验证成功结果。
- PR-004 逻辑上可独立实现，但为保持单活动 PR 和主链路优先，排在 PR-003 之后。

## Overall Verification

- `flutter analyze`
- `flutter test`
- `mvn -f backend/pom.xml test`
- 各 PR 卡片列出的定向测试。
- `python .agents/skills/manage-task-plan/scripts/task_plan.py validate acc-phone-login-vs-delivery`

## Overall Evidence

尚无。仅在四个 PR 单元全部完成并经用户验收后填写。

## Current Summary

已依据 `docs/product/user_stories/user_story_CAP_ACC.md` 中的 `VS-ACC-001-1`～`VS-ACC-001-13`
建立四个顺序 WP/PR 单元。当前仅完成计划记录，尚未批准或实施任何 PR。

## Next Approval Required

Approve the task plan before any PR unit starts.
