# Product Manager 整体变更复审报告

## 检查日期
2026-05-24

## 审查角色
`codex/agents/product_manager.md`

## 审查目标
确认当前产品对象治理、APP 基线提炼、P0.1/P0.2 阶段边界、PM/Orchestrator 协作和版本控制状态是否符合预期；识别偏离项、非预期变更和剩余风险。

## 审查范围
- `docs/product/feature_registry.md`
- `docs/product/baselines/current-mvp.md`
- `docs/product/stages/p0-1-expression-automation.md`
- `docs/product/stages/p0-2-training-memory.md`
- `docs/product/increments/p0-1-expression-automation-training/definition.md`
- `docs/product/increments/p0-1-expression-automation-training/requirements.md`
- `docs/product/increments/p0-1-expression-automation-training/spec.md`
- `docs/product/increments/p0-1-expression-automation-training/acceptance.md`
- `docs/product/increments/p0-1-expression-automation-training/traceability.md`
- `docs/product/roadmap.md`
- `docs/product/development_status.md`
- `docs/process/change_request.md`
- `codex/agents/product_manager.md`
- `codex/agents/development_orchestrator.md`
- `codex/templates/pm_orchestrator_brief.template.md`
- `docs/reports/implementation_report.md`
- 既有 legacy docs：`docs/product/features/mvp-learning-loop-requirements.md`、`docs/product/features/mvp-learning-loop-spec.md`

## 预期变更
- 从 legacy MVP requirements 提炼当前 APP 基线。
- 从当前 APP 基线和规划文档提炼稳定 feature registry。
- 将 P0.1/P0.2 表达为 stage scope，而不是 feature。
- 将 P0.1 表达自动化训练闭环表达为 active increment definition。
- 从 legacy P0.1 spec source 迁移生成 P0.1 increment requirements、spec、acceptance 和 traceability。
- 保留 legacy `mvp-learning-loop-*` 文件，不移动、不删除。
- 修复 Product Manager、Development Orchestrator 和 PM brief 没有接入 product classification / feature registry / stage / increment 的问题。
- 修复 untracked 状态导致的审查粒度问题：将治理、产品、agent、skill、report 资产 staged，供后续 diff/commit 审查。

## 审查结论
Result: pass

当前整体变更符合预期，没有发现应用源码变更、旧产品文档误删/误移、P0.1/P0.2 被继续当作 feature slug、或绕过 increment gate 的新问题。

## 已修复问题

### P1：Product Manager 未接入新对象模型
Status: fixed

修复内容：
- `codex/agents/product_manager.md` 已加入 feature registry、baselines、stages、increments 输入输出。
- User Intake Protocol 已要求 product object classification、registry/stage/increment 检查和 increment definition。
- Rules 已禁止用 MVP、P0.1、P0.2、Now、Next、Later 作为 feature slug。

### P1：Development Orchestrator 和 PM brief 未接入新门禁
Status: fixed

修复内容：
- `codex/agents/development_orchestrator.md` 已要求确认 classification、active stage、primary feature、affected features、increment id、scope、non-goals 和 upstream evidence。
- Orchestrator 已禁止绕过 increment definition gate。
- `codex/templates/pm_orchestrator_brief.template.md` 已增加 Product Classification、Product Object Check、Primary feature、Affected features、Increment id 和 Required Downstream Artifacts。

### P2：未跟踪文件导致无法精确审查
Status: fixed by staging

修复内容：
- 治理、产品、agent、skill、report 和 validator 资产将通过 `git add .agents codex docs scripts/validate_agent_skills.py` staged。
- 后续审查可以使用 `git diff --cached` 和 `git status --short` 精确确认变更集合。

## 产品一致性判断
- `docs/product/features/mvp-learning-loop-requirements.md` 的定位已降级为 legacy baseline source。
- `docs/product/features/mvp-learning-loop-spec.md` 的定位已降级为 legacy P0.1 spec source。
- 当前 APP 基础需求已进入 `docs/product/baselines/current-mvp.md`。
- 稳定产品能力已进入 `docs/product/feature_registry.md`。
- P0.1/P0.2 已作为 stage scope 管理。
- P0.1 active increment 已进入 `docs/product/increments/p0-1-expression-automation-training/definition.md`。
- P0.1 requirements/spec/acceptance/traceability 已进入 `docs/product/increments/p0-1-expression-automation-training/`。

## 非预期变更检查
- Flutter 应用源码目录无变更：`lib/`, `test/`, `android/`, `ios/`, `web/`, `windows/`, `macos/`, `linux/`。
- 既有 `mvp-learning-loop-requirements.md` 和 `mvp-learning-loop-spec.md` 仍存在。
- 未新增第三个官方场景承诺。
- 未把 P0.2 的跨 session/跨天调度或完整 L0-L5 写入 P0.1。
- 未把笔记本、完整评分体系、完整 A1-C2 或任意场景生成写入 P0.1 阻塞范围。
- P0.1 traceability 将 code/test evidence 标为 pre-implementation planned，没有误报实现完成。

## 验证
- `python scripts\validate_agent_skills.py`：passed。
- `rg` 检查确认 PM、Orchestrator、PM brief、feature registry、baseline、stage、increment 文档包含对象化门禁字段。
- `rg` 检查确认 P0.1 requirements、spec、acceptance、traceability 互相引用并覆盖 P01-FR / AC-P01 链路。
- `git status --short lib test android ios web windows macos linux`：无输出。

## 剩余风险
- P0.1 的 increment requirements/spec/acceptance/traceability 已迁移生成，但 downstream contracts 仍需补齐：domain model、AI runtime prompt/schema、UX screen spec、architecture/module boundary 和测试用例。
- 现有 legacy flat docs 仍保留兼容路径，后续需要迁移计划和引用更新。
- 本次仍是文档、agent、skill 和流程治理变更，未运行 Flutter 应用测试。
