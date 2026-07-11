# Child Vertical Slice 表格模板

用于 Parent User Story 的 `Child Vertical Slices:` 表。Parent 关系由所在 Story 章节表达，不增加 Parent ID 列。

```md
Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-<CAP>-<NNN>` | 当 <Actor> 从 <entry point> 触发 <action or event> 时，系统给出 <primary user-visible result>；成功时 <success state>；失败、无内容或不可用时 <failure / empty state when applicable>；<data or product state effect when applicable>。 | `draft` | `CAP-<PRIMARY>` | `CAP-<AFFECTED-1>`, `CAP-<AFFECTED-2>` |
```

检查：

- 一行只表达一个 primary user-perceivable delivery loop。
- 同一动作的异常分支留在同一行；独立触发、结果和验证路径拆成 sibling row。
- 没有 affected capability 时写 `none`。
- 不增加 Parent User Story ID、Entry Point、Success State、E2E Intent 等重复列。
