# Child Vertical Slice 表格模板

用于 Parent User Story 的 `Child Vertical Slices:` 表。Parent 关系由所在 Story 章节表达，不增加 Parent ID 列。

```md
Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-<CAP>-<NNN>` | <以适合该业务的自然句式，说明入口或触发、具体业务对象、用户选择或状态变化、可见结果，以及必要的作用范围或跨 capability 交接。> | `draft` | `CAP-<PRIMARY>` | `CAP-<AFFECTED-1>`, `CAP-<AFFECTED-2>` |
```

检查：

- 一行只表达一个 primary user-perceivable delivery loop。
- 同一动作的异常分支留在同一行；独立触发、结果和验证路径拆成 sibling row。
- 每行至少承载两类具体产品事实，例如可选方案、状态含义、作用范围、责任域交接或有业务意义的例外。
- 删除业务名词后若只剩“进入、查看、保存、失败重试”，说明信息密度不足，必须重写。
- 不强制写 success / failure / empty state；只有它们改变用户决策、业务事实或恢复路径时才写入。
- Sibling rows 必须能分别说明独立用户价值，不按查看/编辑/保存或正常/失败机械拆分。
- 没有 affected capability 时写 `none`。
- 不增加 Parent User Story ID、Entry Point、Success State、E2E Intent 等重复列。
