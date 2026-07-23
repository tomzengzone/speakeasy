# Legacy Mapping 行模板

用于 `docs/product/feature_registry.md` 的 `Legacy Mapping` 表。保持当前三列，不承载 V2 Capability / Sub-capability successor。

```md
| V1 slug | V2 mapping | Migration note |
| --- | --- | --- |
| `<legacy-v1-slug>` | `CAP-<PREFIX>` | <迁移边界、拆分去向或技术支撑说明> |
```

检查：

- V1 slug 唯一且符合小写 kebab-case。
- V2 mapping 只引用已存在的 Capability ID，或使用当前 registry 已支持的 architecture / AI runtime support 格式。
- Migration note 解释旧边界如何迁入 V2，不生成新增产品行为。
- 本表只映射 V1 slug；不得用于持久化 V2 split、merge、deprecate successor。
