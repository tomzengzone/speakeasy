# User Story 表格模板

用于 `docs/product/story_map.md` 的 capability 章节。保持与当前文件一致，不新增 metadata 列。

```md
### US-<CAP>-<NNN> - <title>

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-<CAP>-<NNN>` | <用自然叙事说明 actor、具体场景、业务对象、用户目标及可见价值；可使用“作为……我希望……”检查语义，但不要求固定句式。> | `draft` | `CAP-<PRIMARY>` | `CAP-<AFFECTED-1>`, `CAP-<AFFECTED-2>` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-<CAP>-<NNN>` | <one user-perceivable delivery loop> | `draft` | `CAP-<PRIMARY>` | `CAP-<AFFECTED>` |
```

检查：

- `description` 是唯一产品语义源。
- 标题命名用户要完成的业务目标，不以页面、模块或字段集合代替价值。
- Child Slices 应共同兑现 Story 的价值，不引入 Story 未承诺的新旅程。
- 没有 affected capability 时写 `none`。
- Non-goals、source、共享 assumption 或边界冲突写在文档级说明或就近 `Boundary note`。
- 不增加 Actor、Scenario、Outcome、Parent Story 等重复列。
