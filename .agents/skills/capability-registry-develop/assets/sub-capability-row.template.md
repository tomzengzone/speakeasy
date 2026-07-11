# Sub-capability 行模板

用于 `docs/product/feature_registry.md` 某个 Capability 章节内的 `### Level-1 Sub-capabilities` 表。保持当前九列，不新增并行字段；只放当前父 Capability 的直属一级子能力。

```md
| Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-<PREFIX>` | `CAP-<PREFIX>-<NN>` | <稳定一级子能力名称> | <拥有的职责> | <不拥有的职责> | <业务入口或前置条件> | <可观察结果或产品状态> | `FR-<PREFIX>` | Active v2 |
```

检查：

- 父 Capability 存在，ID 前缀与父级一致。
- 行内 `Capability ID` 与当前 Capability 章节 ID 一致，子行不得放入其他父章节。
- Sub-capability ID 唯一且已发布后不复用。
- 子能力边界位于父能力范围内。
- Entry / precondition 和 Output / state 不写实现方案。
- Related FR prefix 只提供命名 namespace，不是 FR 行为来源。
- 当前表没有 successor 字段；`split`、`merge`、`deprecate` proposal 不得把替代关系塞入 `Status` 或其他自由文本，必须先完成 schema governance change。
