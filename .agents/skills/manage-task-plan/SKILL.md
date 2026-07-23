---
name: manage-task-plan
description: Use when the user explicitly asks Codex to create, approve, execute, inspect, resume, revise, or complete a persistent single-task plan split into sequential PR-sized units with user approval before each unit. Do not use for ordinary one-off changes, automatic background execution, parallel PR work, or as a replacement for product, governance, architecture, issue, or release sources of truth.
---

# Manage Task Plan

## Overview

把大型开发或治理任务拆成顺序 PR 单元，并把计划、批准、证据和续接入口保存在工作区。新会话只加载主计划和当前 PR 卡片。

## Contract

- 仅在用户明确要求创建、批准、执行、续接、修订或完成持久任务计划时运行；不要因任务很大而自动启用。
- 写入 `.codex/task-plans/<task-id>/plan.md` 和 `prs/PR-NNN.md`。它们只是执行状态，不替代正式 source of truth。
- 总计划批准前不实施；每个 PR 必须单独批准开始、提交证据并等待用户验收。未完成当前 PR，不启动下一个。
- 同一任务最多有一个 `in_progress` 或 `awaiting_acceptance` PR。
- 目标、范围、允许路径、验收或验证变化时，递增 `revision`、清空 `approved_revision` 并重新批准。
- 用户明确要求续接时，可继续 revision 未漂移的活动 PR；branch、HEAD、路径或计划漂移时先停止报告。
- 未获授权时不提交、推送、创建、合并或关闭远程 PR；保留无关工作树改动。

## Inputs

用户任务和审批指令、仓库说明、适用正式文档/Gate、工作树、现有任务计划，以及当前 PR 的范围、验收与证据。

## Outputs

- 新任务：主计划和顺序 PR 卡片。
- 查询/续接：任务状态、当前 PR、批准 revision、仓库漂移、最后证据、下一动作和审批门。
- 执行：仅当前 PR 的批准范围变更、验证证据和 `awaiting_acceptance` 状态；不自动进入下一 PR。

## Process

1. **创建。** 检查任务源、仓库和脏工作树；按可独立审查、验证且合并后仍有效的边界拆分 PR。使用 [主计划模板](assets/task-plan.template.md) 和 [PR 卡片模板](assets/pr-unit.template.md)，或运行 `init`。
2. **提交计划。** 填完目标、范围、依赖、允许路径、验收和验证；转为 `awaiting_approval`，运行 validate，展示计划并停止。
3. **批准计划。** 用户明确批准后运行 `approve-plan`。它只把 task 设为 `in_progress`、PR 设为 `planned`；继续等待首个 PR 批准。
4. **执行 PR。** 用户指定 PR 后运行 `approve-pr`，记录批准 revision、branch 和 HEAD。只执行卡片范围；在重要边界更新 Current State、Evidence、Blockers、Next Action 并运行 `checkpoint`。
5. **等待验收。** 完成适用验证/checker 后转为 `awaiting_acceptance`，报告证据并停止。用户接受后转为 `completed`；同范围修正回到 `in_progress`；边界变化运行 `revise-pr`。
6. **续接。** 运行 `resume`，只读取 `plan.md` 和唯一活动 PR；核对仓库、revision 和证据。没有活动 PR 时展示下一个 `planned` PR 并等待批准。
7. **完成。** 仅当全部 PR completed、Overall Evidence 完整且用户确认任务验收时，才完成 task。

```powershell
python <skill-dir>/scripts/task_plan.py init --title "<task>" --pr "<PR 1>" --pr "<PR 2>"
python <skill-dir>/scripts/task_plan.py transition <task-id> --target task --to awaiting_approval
python <skill-dir>/scripts/task_plan.py approve-plan <task-id>
python <skill-dir>/scripts/task_plan.py approve-pr <task-id> PR-001
python <skill-dir>/scripts/task_plan.py checkpoint <task-id> PR-001
python <skill-dir>/scripts/task_plan.py transition <task-id> --target PR-001 --to awaiting_acceptance
python <skill-dir>/scripts/task_plan.py transition <task-id> --target PR-001 --to completed
python <skill-dir>/scripts/task_plan.py resume <task-id>
```

状态只允许：task `draft -> awaiting_approval -> in_progress <-> blocked -> completed|cancelled`；PR `proposed -> planned -> in_progress -> awaiting_acceptance -> completed`，另可 blocked/cancelled/superseded。`planned -> in_progress` 只能经 `approve-pr`，`proposed -> planned` 只能经 `approve-plan`，验证通过不能代替用户验收。

## Red Flags

未批准就实施、一次批准覆盖全部 PR、并行活动 PR、修改边界后保留旧批准、用计划状态替代正式事实、用意图代替证据、无授权远程发布，或恢复时忽略仓库漂移。

## Verification

每次状态写入后运行 `python <skill-dir>/scripts/task_plan.py validate <task-id>`。开发或修改本 Skill 后运行：

```powershell
$env:PYTHONDONTWRITEBYTECODE='1'; python <skill-dir>/scripts/test_task_plan.py
python scripts/validate_agent_skills.py
$env:PYTHONUTF8='1'; python <skill-creator-dir>/scripts/quick_validate.py .agents/skills/manage-task-plan
```

必须证明显式触发、总计划与逐 PR 审批、单活动 PR 锁、revision 失效、依赖顺序、证据门、完成门、恢复和 source-of-truth 边界。
