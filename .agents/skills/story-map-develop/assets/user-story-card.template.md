# User Story 输出模板

用于输出一个 User Story 及其嵌套的 Child Vertical Slice。路径通过 Governance Contract 解析。

```md
### US-0042 - <title>

| Id | description | Status |
| --- | --- | --- |
| `US-0042` | <用自然叙事说明用户、具体情境、业务对象、目标和可见价值。> | `draft` |

Child Vertical Slices:

| Id | description | Status |
| --- | --- | --- |
| `VS-0042-1` | <说明触发或入口、业务对象、用户选择或业务决策、状态影响和可见结果。> | `draft` |
```

父子关系由文档嵌套位置表达；模板不增加 Capability、Parent 或下游 Artifact 列。
