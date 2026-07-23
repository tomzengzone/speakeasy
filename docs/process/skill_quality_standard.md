# Skill 质量标准

本标准约束 active project-local Skill 的方法质量。Governance Contract 独占 Artifact/Gate 治理事实；Skill 只保存可复用的当前方法、内容规则和验证方法。

## Active scope

Active Skill 集合只包含由 routed Artifact 的 `method_skill` 引用的 package，以及其 `SKILL.md` 直接链接且实际存在的 resource。整个 `.agents/skills/` 目录不能被一概视为 active。已退役、未登记、migration-only 或仅有历史用途的 package/resource 不进入默认上下文。

## 目录结构

```text
.agents/skills/<skill-name>/
  SKILL.md
  references/   # 仅在 SKILL 直接链接并说明读取条件时使用
  scripts/      # 可选确定性 helper
  assets/       # 可选输出资源，不是运行规则
```

`SKILL.md` 是唯一必需的运行时指令文件。不得添加平行 README、规范、迁移说明或 tombstone Skill 继续触发已退役方法。

## Authority separation

- Canonical path、accountable owner、contributor scope、lifecycle、Artifact direct/conditional inputs 和 Gate routing 只能由 Governance Contract 定义。
- Skill 通过 Artifact/Gate ID 解析 contract，不复制上述字段或维护第二张 registry。
- 执行所必需的精确路径/命令只有在标记为 `Derived operational pointer` 且能与 contract 校验一致时才允许出现；它不是 authority。
- Agent 只定义角色、权限、专业边界和 handoff；Workflow 只定义顺序与决策点；Template 只定义字段/版式。
- Governance Contract 以外的冲突副本必须删除，而不是建立兼容层。

## SKILL.md contract

每个 Skill 以 YAML frontmatter 开始：

```yaml
---
name: skill-name
description: Use when ... Do not use ...
---
```

目录名使用 lowercase kebab-case，frontmatter `name` 与目录名一致。`description` 必须包含正向与反向触发边界。运行时正文至少包含：

- `## Overview`
- `## When to Use`
- `## When NOT to Use`
- `## Contract`
- `## Inputs`
- `## Outputs`
- `## Process`
- `## Red Flags`
- `## Verification`

内容必须面向可重复使用的 current state。一次性事件、已完成迁移、旧方案过程、兼容 fallback 和整改编号不得保留在 active instructions 中。

## Method quality

- Inputs 只包含执行方法需要的当前事实；缺失产品行为时回到 owning Story/VS/FR，不在 Skill 中推断。
- Outputs 明确语义边界，但不自行建立 path、owner 或 lifecycle。
- Process 应小而可验证，区分适用与不适用步骤，避免把每个任务都扩展为全流程。
- Verification 给出确定性结构检查、测试或审查方法；测试证据不能替代适用独立 checker。
- Red Flags 必须覆盖最可能的 scope creep、重复 authority、错误 source 和不可验证输出。
- 只加载任务命中的 Skill 和其条件命中的直接 resource；不递归加载未引用材料。

## Story/Slice delivery methods

- `story-map-develop` 维护 Story 与嵌套 Child VS；Capability 只分类。
- `requirement-refine` 把 approved VS 提炼成 mandatory atomic FR；FR 只通过 `source_vs_ids` 直接引用 VS。
- `test-case-generate` 维护 FR-TC、Contract-TC、VS-TC；三类 case 分别只直接引用 FR、Contract、VS。
- `document-traceability-check` 只从 owning sources 重建完整 projection 和 coverage join，不能拥有 direct edge 或执行状态。
- API/Domain/AI/UX 方法以 applicable mandatory FR 为产品上游；事实变化必须有对应 Contract-TC。

普通编码的最小上下文为 selected approved VS、mandatory FR、受影响 Engineering Contract、typed TCs、相邻代码/测试和验证命令。Stage/Increment/Work Package 只作 planning metadata，不是产品/Contract/TC lineage。

## Bundled resources

- `references/` 只保存非总是适用的领域细节；SKILL 必须以 Markdown link 直接链接并写明选择条件。
- Reference 只允许一层，不得继续路由另一份 reference，也不得覆盖核心 trigger、permission、I/O、process 或 verification。
- `scripts/` 用于确定性重复操作；`assets/` 仅供输出，不作为规则来源。
- 未被 active SKILL 直接链接的资源不进入 authority graph 或默认上下文。

## Native Agent quality

- 每个 registered TOML 包含唯一 `name`、具体 `description`、精简 `developer_instructions` 和与职责相称的 sandbox mode。
- Producer 只能在用户批准和 contract contributor scope 内写入；独立 Checker 必须 read-only。
- Agent 不复制 Skill 方法、Artifact 路径表或 Gate 正文，也不维护静态永久 Skill 附件。
- 普通单 owner 工作由根会话走最短安全路径；只有专业边界、并行收益或独立审查确有必要时委派。

## Verification

Skill/Agent/governance definition 变化后至少运行：

```bash
python3 scripts/validate_agent_skills.py
python3 scripts/validate_governance_contracts.py
python3 scripts/validate_story_slice_cutover.py
```

验证必须覆盖 trigger/non-trigger、必需章节、active method route、直接 resource、retired Skill discovery、authority separation、legacy active reference 和 derived operational pointer 对齐。对合法的 contract-aligned pointer 不得误报。
