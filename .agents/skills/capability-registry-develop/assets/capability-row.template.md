# Capability 行模板

用于 `docs/product/feature_registry.md` 某个 Capability 章节内的 `### Capability` 单行表。保持当前十二列，不新增并行字段；章节外壳使用 `capability-section.template.md`。

```md
| Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary user/business outcome | Adjacent capabilities | Downstream document prefix | Legacy mapping |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `CAP-<PREFIX>` | `<stable-capability-slug>` | <稳定业务能力名称> | <业务类型> | Product Manager | Active v2 | <长期拥有的业务职责> | <明确不拥有的相邻职责> | <用户或商业结果> | `CAP-<ADJACENT>` | `<PREFIX>` | <V1 映射或“无直接旧顶层 slug”> |
```

检查：

- ID、slug 和 prefix 唯一，已发布后不复用。
- 章节标题中的 ID 和名称与本行一致，且本表只有一条 Capability 数据行。
- `Owner` 是产品决策 owner，不是软件组件 owner。
- `Owns`、`Does not own` 和主要结果能明确区分相邻能力。
- 本次新增或触碰的相邻 Capability 存在；单向关系有明确说明并由 PM 批准。未触碰的历史不对称关系只记录 baseline finding。
- downstream prefix 只提供命名 namespace，不生成产品行为。
- 当前 schema 不支持 V2 successor；`split`、`merge`、`deprecate` proposal 不得直接套用本模板持久化，必须先完成 schema governance change。
