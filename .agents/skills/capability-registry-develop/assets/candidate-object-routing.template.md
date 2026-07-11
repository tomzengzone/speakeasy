# Candidate Object Destination 模板

用于 Gate A。在任何新增、重新分类或重设父级的 Capability / Sub-capability row proposal 之前，先判断候选对象归宿。该模板输出 finding，不批准产品事实。

```text
Candidate Object Facts:
- candidate name:
- proposed user/business outcome:
- stable responsibilities:
- observable user behavior:
- delivery-specific characteristics:
- technical/operational characteristics:
- boundaries and non-goals:
- missing information:

Destination Finding:
- result: ready-for-pm-confirmation | route-out | insufficient-information
- recommended destination:
  new-capability |
  existing-capability-change |
  new-sub-capability |
  existing-sub-capability-change |
  story-slice |
  stage-increment |
  technical-support-object |
  insufficient-information
- target object type: Capability | Sub-capability | Story/Slice | Stage/Increment | Technical Support | unresolved
- existing target ID or proposed provisional ID:
- parent Capability ID, when applicable:
- proposed change mode:
- classification rationale:
- why not the nearest alternative object types:
- next owning agent/skill/workflow:

PM Destination Confirmation:
- status: pending | confirmed | rejected | revision-required
- confirmed destination:
- confirmed target object type:
- confirmed existing target ID or proposed provisional ID:
- confirmed parent Capability ID, when applicable:
- confirmed change mode:
- decision note:
```

执行规则：

- PM 未确认 destination、target object type、现有目标 ID 或拟新增 provisional ID、适用的父 ID 和 change mode 前，不得进入 Gate B。
- `story-slice`、`stage-increment`、`technical-support-object` 在 handoff 后结束本 skill，不得生成 Registry row。
- `insufficient-information` 必须列出缺失信息并停止。
- 纯 `editorial` 使用 `N/A - confirmed existing registry object, no semantic scope change`。
- 纯 Legacy Mapping 使用 `N/A - legacy-mapping-only`。
- Gate A 的跨类型排除理由不得复制到 Gate B 充当颗粒度证据。
