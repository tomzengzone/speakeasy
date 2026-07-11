# Capability 章节模板

用于在 `docs/product/feature_registry.md` 中表达一个 Capability 与其直属一级 Sub-capability 的父子关系。每个 active Capability 必须且只能有一个对应二级章节。

```md
## CAP-<PREFIX> - <Capability name>

### Capability

<使用 capability-row.template.md；只包含当前 Capability 一行>

### Level-1 Sub-capabilities

<使用 sub-capability-row.template.md；只包含当前 Capability 的直属一级 Sub-capability 行>
```

检查：

- 二级章节标题 ID 和名称与 `### Capability` 的唯一数据行一致。
- `### Capability` 与 `### Level-1 Sub-capabilities` 各出现一次，顺序固定。
- 每个 Sub-capability 行的 `Capability ID` 等于章节 ID，Sub-capability ID 以前缀 `CAP-<PREFIX>-` 开头。
- 新增 Sub-capability 写入既有父章节；新增 Capability 必须同时创建完整章节，不写入平铺总表。
- `## Legacy Mapping` 位于全部 Capability 章节之后，不嵌入任一 Capability 章节。
