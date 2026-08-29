---
schema_version: 1
task_id: content-learning-route-task-challenge-delivery
title: US-CONTENT-003/004 课程学习路线与任务挑战顺序交付
status: awaiting_approval
delivery_target: local
created_at: 2026-08-11T07:35:41+08:00
updated_at: 2026-08-11T07:42:04+08:00
---
# US-CONTENT-003/004 课程学习路线与任务挑战顺序交付

## Goal

在不改变现有 Course identity、运行时事实所有权、provider/storage/security boundary 的前提下，先把
`US-CONTENT-003`、`US-CONTENT-004` 及 Child Vertical Slice 从 draft 经 Product Manager 审查为可实现事实，
再按产品、架构、领域、API、AI、UX、Backend、Flutter 和全链验收的顺序，交付“课程详情五阶段学习路线”和
“进入任务挑战后理解课程情境、查看历史消息并安全回放历史语音”的本地实现。

## Success Criteria

- PR-001 先完成并批准 003/004 的 Story/VS、适用 FR、FR-TC 与四条 VS-TC；Task Plan 不代替这些产品事实源。
- 学习路线固定返回五个有序阶段；仅 `01 任务挑战` 可进入。`02` 至 `05` 必须返回
  `progress_status=unknown`、`availability=unavailable`、`reason_code=STAGE_NOT_DELIVERED`，不得显示为“尚未开始”。
- `BE-LEARNING` 组合 Course authored facts 与 Practice owner 的 learner progress；Content 继续只拥有
  `Course`、`CourseVersion`、`CourseContentBinding`，不持有 learner progress。
- `GET /courses/{course_id}/versions/{course_version_id}/learning-route` 返回精确 Course/version、五阶段、状态、
  可用性、原因及 nullable `next_stage_code`；任务挑战完成或进度未知时不推荐下一阶段。
- `POST /practice/sessions` 保持 legacy `scenario_id + level_code` 兼容，并增加与其互斥的 `course_launch`；
  Backend 重新解析 published/visible CourseVersion 与冻结 binding，只恢复同一用户、版本和 binding 的活动会话。
- Course 启动会话返回 nullable `course_context`、历史消息和 `audio_available`；AI opener 以
  `PracticeOpeningCandidate(schema_version=1)` 生成、持久化一次，恢复时不重复调用，异常走确定性 fallback。
- 历史语音通过 session/message scoped authenticated proxy 返回 `audio/*` 与
  `Cache-Control: private, no-store`；不泄漏 object key、signed URL 或 provider read URL。
- 不新增 stage 表、第二套 Course/route/session/message store、第二套 DTO/client/runtime、生产 Course seed 或破坏性 migration。
- 十二个 PR 单元分别获批、执行、验证并由用户验收；任何时刻最多一个 PR 为活动状态。

## Scope

包含：

- 003/004 Story/VS 的产品就绪审查、批准、FR/FR-TC/VS-TC 与 TRACEABILITY。
- 现有架构矩阵的局部 impact check，以及 Learning route、Course-to-Practice launch、AI opener、authenticated audio playback 流。
- PracticeSession 的 nullable Course launch reference、单一 opener、course-linked progress projection 领域与持久化契约。
- learning-route、Practice start/resume 增量分支、PracticeSession response 和 message audio proxy 的 API/OpenAPI/generated Dart 契约。
- opener prompt/schema/fallback/eval；课程路线与挑战页的 Screen Spec、User Flow、可访问性 selector 和 UX Contract-TC。
- 两个 additive Flyway migration、Spring route/launch/opener/audio 实现、Flutter route/challenge/playback 实现和定向全链验收。

不包含：

- `US-CONTENT-005`、`US-CONTENT-007` 至 `US-CONTENT-012`，以及录音、转写提交、新对话轮次、多轮回复、训练、报告完成或课程内容库存。
- 通用 CMS、新 provider、新 storage/security boundary、新跨 SWC 原子写、Course identity 重定义或 learner progress 所有权迁移。
- 生产 Course seed、生产 migration 执行、部署、提交、推送或创建远程 PR。

## Architecture and Public Contract Baseline

- 当前事实依据为 `docs/architecture/system_overview.md`、`module_boundary.md`、
  `software_component_architecture.md`、`swc_catalog.md`、`data_flow.md` 与 ADR-0008。
- `software_component_architecture.md` 对 003/004 的现有结论均为 `fits-baseline`：CourseVersion 只提供稳定上下文；
  Practice/AI/Media/Learning 保持运行时所有权；新工作必须复用 `FE-API-CLIENT`、`FE-PRACTICE-RUNTIME`、
  `FE-AUDIO-PLATFORM`、`BE-PRACTICE`、`BE-AI-GATEWAY` 与 `BE-MEDIA-STORAGE`。
- 六类全局触发器——Course identity 变化、progress ownership 迁入 Content、新跨 SWC 原子事务、稳定 binding identity 变化、
  新 provider/storage/security boundary、第三套对话/音频 runtime——预期均不命中；PR-002 必须逐项复核。未命中则不新增 ADR。
- 计划中的 API/字段/状态是待 PR-001 产品批准并由 PR-003 至 PR-005 Engineering Contract 固化的交付目标；
  Task Plan 自身不成为行为或架构事实源。

## Constraints

- 总计划批准前不得实施；批准总计划只把 PR 卡转为 `planned`，不等于批准 PR-001。
- 每个 PR 必须单独批准当前 revision；目标、范围、Allowed Paths、验证或 context budget 变化时必须先修订、清除旧批准并重新审批。
- 每个 PR 完成验证后进入 `awaiting_acceptance`；用户验收前不得开始下一 PR。
- 每卡 context budget 不超过标明上限；预计超限时先拆分/修订卡片，不静默扩大范围。
- 文档/契约 PR 只运行其 validator/checker；Backend PR 只运行本卡新增或直接受影响的 Spring/Migration/Media 测试；
  Flutter PR 不运行 Maven/Flyway；全量 Maven/Flutter 仅在 PR-012 运行一次。
- 全量验收出现既有范围外失败时，记录 exact baseline 与影响；修复或获得明确例外前，总任务不得完成。
- migration 只能 additive；不得改写既有 migration 或写入生产 Course 数据。回滚关闭现有 Course detail flag 下的新入口，
  保留 nullable 列与历史会话数据，不执行破坏性 down migration。
- 创建基线：branch `agent/simplify-governance-and-story-delivery`，HEAD
  `47401a8aa17c3ee40153d6827bdd218ecfcce630`，工作树干净。每次 `approve-pr` 重新记录当时 branch/HEAD 并检查重叠。
- `delivery_target: local`；除非另行授权，不提交、不推送、不创建远程 PR、不部署、不执行生产 migration。

## PR Sequence

- [PR-001](prs/PR-001.md) — 产品批准、FR 与测试意图
- [PR-002](prs/PR-002.md) — 架构影响与复用边界
- [PR-003](prs/PR-003.md) — 领域与持久化契约
- [PR-004](prs/PR-004.md) — API/OpenAPI/generated client
- [PR-005](prs/PR-005.md) — AI 开场契约与 eval
- [PR-006](prs/PR-006.md) — 路线与挑战 UX 契约
- [PR-007](prs/PR-007.md) — Backend 学习路线投影
- [PR-008](prs/PR-008.md) — Backend Course 启动与 AI opener
- [PR-009](prs/PR-009.md) — Backend 历史语音安全回放
- [PR-010](prs/PR-010.md) — Flutter 课程学习路线
- [PR-011](prs/PR-011.md) — Flutter 任务挑战与回放
- [PR-012](prs/PR-012.md) — 全链验收与交付记录

## Cross-PR Dependencies

- PR-001 是所有后续工作的产品 authority 前置；PR-002 只对已批准事实执行局部架构 impact check。
- PR-003 至 PR-006 依次固化 Domain、API、AI 和 UX 契约；如上游契约改变，下游卡必须修订后重新审批。
- PR-007 至 PR-009 按 route projection、Course launch/opener、audio proxy 拆分 Backend 责任和测试，不跨卡重复全量验证。
- PR-010 只交付课程路线；PR-011 才交付挑战页、session controller 与语音回放，避免一个前端 PR 同时承担两个 VS。
- PR-012 只做全链 integration、全量回归、traceability/status/report 和独立检查；若发现实现缺陷，必须回到 owning card 或先修订
  PR-012 的具体 Allowed Paths，不能用验收卡静默扩大修复范围。

## Overall Verification

- PR-001 至 PR-006：各卡列出的 governance validator、contract checker、独立只读 review；不运行无关应用测试。
- PR-007 至 PR-009：各卡列出的精确 Maven test selectors。
- PR-010 至 PR-011：各卡列出的精确 Flutter tests 与受影响文件静态分析。
- PR-012：一次全量 `mvn -f backend/pom.xml test`、`flutter analyze`、`flutter test`，以及定向 integration test、
  API/AI/Story validators、文档语言检查、`git diff --check` 和适用独立治理/质量/QA 检查。
- 每次计划写入或状态变更后运行
  `python .agents/skills/manage-task-plan/scripts/task_plan.py validate content-learning-route-task-challenge-delivery`。

## Overall Evidence

尚无。当前只建立执行计划与审批边界，未开始 PR-001，也未修改产品、架构、契约或应用代码。

## Current Summary

总计划和十二张 revision 1 PR 卡已完成编制，等待总计划批准。所有实现单元均保持 `proposed`；尚无活动 PR。

## Next Approval Required

请先批准总计划 `content-learning-route-task-challenge-delivery`。总计划批准后，仍需单独批准 PR-001 revision 1 才能开始产品就绪审查。
