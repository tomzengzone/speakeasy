---
schema_version: 1
task_id: content-catalog-course-detail-vs-delivery
title: Content 全景架构基线与课程目录/详情顺序交付
status: in_progress
delivery_target: local
created_at: 2026-08-07T10:57:42+08:00
updated_at: 2026-08-10T22:01:57+08:00
---
# Content 全景架构基线与课程目录/详情顺序交付

## Goal

在不扩大已批准产品语义的前提下，以 `US-CONTENT-001` / `VS-CONTENT-001-1`
和 `US-CONTENT-002` / `VS-CONTENT-002-1` 为唯一 normative Story/VS 输入，先建立
兼容 Content 001–012 全景风险的最小生产级 Course 架构、领域、API、测试与 UX 契约，
再顺序交付 Spring/Flyway Course 持久化与读取、Flutter 主题/课程目录和版本固定课程详情。

## Success Criteria

- `US-CONTENT-001`、`VS-CONTENT-001-1`、`US-CONTENT-002`、`VS-CONTENT-002-1`
  及已批准 `FR-CONTENT-001`、`FR-CONTENT-002` 的集合完整性、严格 CEFR、真实空状态、
  获取失败恢复、同课程同版本解析、必备信息、正值时长与可选背景边界均有可执行实现和证据。
- `US-CONTENT-003` 至 `US-CONTENT-012` 及其 Child VS 只作为 compatibility、non-goal
  和 architecture-risk 输入；计划与下游契约不得把其 draft 行为改写为当前需求或完成事实。
- PR-001 在 `SOFTWARE_COMPONENT_ARCHITECTURE` 中为 `US-CONTENT-003` 至 `US-CONTENT-012`
  分别建立一行 Architecture Coverage Matrix，明确 owning SWC、Course/version 关系、稳定引用、
  Course 禁止拥有的运行时事实、未来 Contract 类型和重新触发 ADR 的条件，使后续已批准 Slice
  默认只做局部 architecture-impact check，而不是重复整套全景分析。
- 架构明确 `Course != Scenario`；`CourseVersion` 通过 `CourseContentBinding` 同时绑定一个
  `ScenarioVersion` 与同一 Scenario 下的一个 `ScenarioLevel`。既有 `ScenarioLevel` 保留，
  本任务不删除、不重命名、不伪装成 Course。
- `Course`、`CourseVersion`、`CourseContentBinding` 的身份、版本、关系、生命周期、不变量、
  持久化归属、API 读边界、OpenAPI/generated Dart 和 Contract-TC 形成一致链路。
- 生产 Flyway migration 只建立 Course、CourseVersion 与 CourseContentBinding 所需的 schema、constraints
  和 indexes，不插入任何 Course 内容；迁移完成后相关表可保持为空。
- 六条既有 Course 样例只供 backend test setup/fixtures 使用，以验证 schema、读取边界和失败语义；不得
  进入 main resources、runtime 配置或生产发布，也不构成产品内容事实。
- Flutter 可浏览全部已发布且对当前学习者可见的主题与课程摘要，零课程主题显示真实空状态，
  失败状态保留已知上下文和恢复入口；课程详情固定解析并展示卡片所选的同一版本。
- 适用的架构、领域、API、测试、追溯、UX、Backend、Flutter、观测、灰度与回滚验证通过；
  七个 PR 单元均独立批准、验证并由用户验收后，任务才可完成。

## Scope

包含：

- Content 001–012 的一次性全景架构风险扫描，以及 003–012 逐 US Architecture Coverage Matrix；
  仅 001/002 是当前 normative 行为，003–012 只用于兼容性、所有权、扩展缝和 non-goal 判定。
- 最小 Course SWC、数据流、ADR、领域/关系/持久化/API/OpenAPI/generated Dart、Contract-TC、
  TRACEABILITY、Screen Spec、User Flow 与 UX 状态契约。
- Spring Boot/JPA/Flyway 的 Course schema、读模型、查询边界与使用 test-only fixtures 的定向测试。
- Flutter 主题目录、课程摘要、真实空状态/失败恢复、版本固定课程详情与对应 FR-TC/VS-TC。
- 不执行生产部署的本地集成验收、观测检查、灰度启用前提和可恢复回滚证据。

不包含：

- 批准、重写或实现 `US-CONTENT-003` 至 `US-CONTENT-012` 及其 draft VS。
- 课程学习路线/阶段进度、任务挑战、AI 多轮对话、学习证据交接、课程精讲、词汇/表达深层内容、
  对话播放、逐句学习、跟读、录音、ASR、评分或学习报告实现。
- 通用 CMS、内容生产后台、任意 Course authoring、任意场景生成、完整六级内容库存承诺。
- 任何生产 Course 默认库存、内容 seed 或把测试样例打包进 main resources/runtime/生产发布。
- 删除或重命名 `Scenario`、`ScenarioVersion`、`ScenarioLevel`，或用 Course 替代现有训练内容轨道。
- 提交、推送、创建/合并远程 PR、生产发布、远程迁移执行或改变正式产品批准状态。

### Test Example Classification

此前列出的六条 Course 记录统一分类为 backend 测试样例，不是正式、生产或长期维护内容，也不是本任务的
交付输入。它们只能由 `backend/src/test/**` 下的 test setup/fixtures 创建和清理，用于确定性测试 oracle；
不得进入 `backend/src/main/resources/**`、runtime 配置或任何生产发布。Task Plan 只记录这项执行限制，
不拥有或批准产品内容事实。

## Constraints

- 本计划是执行状态与审批记录，不替代 `STORY_MAP`、适用 FR、Engineering Contract、TC、
  TRACEABILITY、代码、测试或发布事实源。
- WP/PR 只管理交付顺序、执行范围、状态与证据；已批准 VS 与适用 FR 管产品行为，Engineering Contract
  管工程边界，Contract-TC 与 VS/FR-TC 管对应验证设计。
- 总计划批准前不实施；每个 PR 必须单独批准开始、单独提交证据并进入
  `awaiting_acceptance` 等待用户验收。当前 PR 未完成并验收时不得启动下一 PR。
- 同一时间最多一个 PR 处于 `in_progress` 或 `awaiting_acceptance`。目标、范围、Allowed Paths、
  验收或验证变化时必须递增 revision、清空批准并重新审批。
- 创建基线为 branch `agent/simplify-governance-and-story-delivery`、HEAD
  `177be6e9a5a769fcb5654e5eed273e7cc5eb70f6`。开始任何 PR 时必须由 `approve-pr` 重新记录
  当时 branch、HEAD 和 revision；出现漂移先停止报告。
- 创建时工作树已有用户/其他 Agent 所有的改动：
  `.agents/skills/screen-spec-generate/SKILL.md`、`.agents/skills/story-map-develop/SKILL.md`、
  `.agents/skills/story-map-develop/references/ready-gates.md`、
  `docs/process/governance/artifacts/engineering.json`、
  `docs/process/governance/artifacts/product.json`、`docs/product/story_map.md`、
  `scripts/validate_story_slice_cutover.py`、`tests/test_validate_story_slice_cutover.py`、
  `tests/test_validate_story_slice_delivery.py`，以及未跟踪
  `docs/task-plans/vertical-slice-governance-balance/`。本任务不得清理、覆盖、暂存、提交或回退这些改动。
- PR 开始前必须检查 Allowed Paths 与当时脏工作树是否重叠；无法安全隔离时停止并请求用户处理，
  不得自行 stash、reset、checkout 或创建替代事实源。
- 003–012 的兼容输入只允许影响可扩展边界、稳定 ID/版本引用、所有权和 non-goal；若候选方案需要
  其具体行为、字段或状态，必须停止并返回 Product Manager，不得在本任务中批准或推断。
- Migration 只能新增，既有已执行 migration 不得改写；本任务的 production migration 只允许
  schema/constraints/indexes DDL，不得包含 Course、CourseVersion 或 CourseContentBinding 内容 DML。
  回滚采用关闭新读取路径、恢复兼容应用版本和保留新增空表的可恢复策略，不以 runtime legacy alias、
  dual-read 或删除 `ScenarioLevel` 回滚。
- 本任务 `delivery_target: local`；未经另行授权不得提交、推送、创建远程 PR、部署或执行生产迁移。

## PR Sequence

- [PR-001](prs/PR-001.md) — Content 001–012 Architecture Coverage Matrix、SWC/数据流/ADR
- [PR-002](prs/PR-002.md) — Course/CourseVersion/CourseContentBinding 领域与持久化契约
- [PR-003](prs/PR-003.md) — API Contract/OpenAPI/generated Dart/Contract-TC/Traceability
- [PR-004](prs/PR-004.md) — Screen Spec/User Flow/UX 状态契约
- [PR-005](prs/PR-005.md) — Spring/Flyway Course schema 与后端读取实现
- [PR-006](prs/PR-006.md) — Flutter 主题/课程目录（VS-CONTENT-001-1）
- [PR-007](prs/PR-007.md) — Flutter 版本固定详情（VS-CONTENT-002-1）与集成验收

## Cross-PR Dependencies

- PR-001 先锁定跨模块责任、Course/Scenario 分离、数据流、兼容 non-goal 和回滚方向。
- PR-002 依赖 PR-001，以架构边界建立领域、关系与持久化契约。
- PR-003 依赖 PR-002，以领域事实定义 API/OpenAPI/generated client 和 Contract-TC/追溯。
- PR-004 依赖 PR-003，以已接受 API 和错误语义定义两条 VS 的屏幕与交互状态。
- PR-005 依赖 PR-004；按已批准 VS/FR 与已接受的领域/API/UX 契约实现 schema-only migration、后端读取
  和 test-only fixtures；不新增生产内容、产品行为或产品/内容事实权威。
- PR-006 依赖 PR-005 提供可验证的读取边界和 typed contract；客户端验证使用测试数据或 mock，不依赖
  PR-005 向生产 schema 预置 Course 内容，并独立交付、验收 `VS-CONTENT-001-1`。
- PR-007 依赖 PR-006 的稳定课程卡片和版本引用，交付 VS-CONTENT-002-1 后完成全链验收；
  任何上游修订都必须先修订受影响 PR 卡片并重新审批。

## Overall Verification

- `python scripts/validate_story_slice_delivery.py`
- `npm run check:api-contract`
- `mvn -f backend/pom.xml test`
- `flutter analyze`
- `flutter test`
- `flutter test test/features/content/content_catalog_contract_test.dart`
- `flutter test test/features/content/course_detail_contract_test.dart`
- `flutter test integration_test/course_detail_header_test.dart`
- `python scripts/check_document_language.py --scope changed --include-worktree`
- `git diff --check`
- 各 PR 卡片声明的适用 owner/Gate/checker 证据。
- `python .agents/skills/manage-task-plan/scripts/task_plan.py validate content-catalog-course-detail-vs-delivery`

## Overall Evidence

尚无。只有七个 PR 单元全部完成、各自获得用户验收、整体命令通过且用户确认任务验收后填写。

## Current Summary

PR-001 至 PR-006 均已完成并获用户验收；架构、领域、API/Contract、UX、Spring/Flyway 读取和 Flutter
课程目录已顺序交付。PR-007 revision 2 已获批准并完成本地实现：exact-detail generated DTO/API seam、
版本固定详情、全 identity 防替换、错误恢复、可访问性、入口回退和脱敏观测均已落地。目标与全量
Flutter、相关 Spring Course/Scenario、API/治理 gates 已通过；独立 code quality 为 APPROVE，DevOps 本地
实现门为 PASS。全量 Maven 的 3 个范围外失败、无产品设备的 canonical integration 命令和未生成 exact
commit 均已在 PR 卡片如实记录；生产 rollout 保持 BLOCKED，未执行 commit、push、部署或 release。

## Next Approval Required

等待用户验收 PR-007 revision 2。验收后仍不得自动完成总任务；必须再请求用户确认整体任务验收。
