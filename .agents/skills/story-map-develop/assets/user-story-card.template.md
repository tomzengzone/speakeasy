# User Story 表格模板

用于 `docs/product/story_map.md` 的 capability 章节。保持与当前文件一致，不新增 metadata 列。

```md
### US-<CAP>-<NNN> - <title>

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `US-<CAP>-<NNN>` | 作为 <Actor>，当/在 <Scenario> 时，我希望 <Action / Goal>，以便 <Outcome / Value>。 | `draft` | `CAP-<PRIMARY>` | `CAP-<AFFECTED-1>`, `CAP-<AFFECTED-2>` |

Child Vertical Slices:

| Id | description | Status | Primary Capability ID | Affected Capability IDs |
| --- | --- | --- | --- | --- |
| `VS-<CAP>-<NNN>` | <one user-perceivable delivery loop> | `draft` | `CAP-<PRIMARY>` | `CAP-<AFFECTED>` |
```

检查：

- `description` 是唯一产品语义源。
- 没有 affected capability 时写 `none`。
- Non-goals、source、共享 assumption 或边界冲突写在文档级说明或就近 `Boundary note`。
- 不增加 Actor、Scenario、Outcome、Parent Story 等重复列。
