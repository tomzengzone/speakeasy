# Capability Registry Granularity Evaluation 模板

用于 Gate B。只有 Product Manager 已确认 Registry destination、target object type、目标/provisional ID、父 ID（适用时）和 change mode 后才能使用。

```text
Confirmed Classification:
- destination:
- target object type: Capability | Sub-capability
- existing target ID or proposed provisional ID:
- parent Capability ID, when applicable:
- change mode:
- PM destination confirmation reference:

Comparison Selection:
- comparison basis: outcome | Owns | Does not own | adjacency | parent/sibling boundary
- selected peer/sibling IDs:
- unavailable comparison and gap:

Capability Granularity, when target object type is Capability:
- primary user/business outcome:
- peer 1 outcome / ownership / boundary comparison:
- peer 2 outcome / ownership / boundary comparison:
- evidence of a long-lived independent business boundary:
- evidence the object spans multiple behaviors or delivery slices:
- stable first-level responsibilities it could contain:
- evidence it cannot naturally fit an existing Capability:
- too-broad risk:
- too-narrow risk:

Sub-capability Granularity, when target object type is Sub-capability:
- parent-fit evidence:
- sibling 1 outcome / ownership / entry / output comparison:
- sibling 2 outcome / ownership / entry / output comparison, or comparison gap:
- stable first-level responsibility:
- evidence it is not a page, action, Story/Slice, API, table, or code module:
- evidence it remains inside the parent boundary:
- sibling overlap risk:
- too-broad risk:
- too-narrow risk:

Granularity Finding:
- result: pass | fail | N/A
- evaluated rule set: Capability | Sub-capability | N/A
- required correction or Gate A return reason:
- comparison evidence summary:
```

执行规则：

- Capability 和 Sub-capability 只填写匹配 target object type 的区块，另一类型标记 `N/A - not selected`。
- Capability 默认比较两个最接近的现有顶层 Capability；不得任意选择无关对象。
- Sub-capability 优先比较两个同父级 sibling；不足两个时记录实际比较对象和 comparison gap。
- `fail` 不得生成可持久化 Registry row，也不得自行改变 PM 已确认的 destination。
- 纯 `editorial` 或 `legacy-mapping-only` 可以按 SKILL Gate applicability 标记规定的 `N/A`。
