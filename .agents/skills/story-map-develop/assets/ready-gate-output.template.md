# Ready Gate 输出模板

用于输出可直接落到当前 story map 的 proposal 或 finding。

```text
Assumptions:
- scope mode: capability | story | slice-review | ready-gate
- source inventory: user-authorized draft proposal | PM-provided behavior | existing canonical facts | legacy evidence | registry boundary only
- capability boundary source
- inherited non-goals / boundary notes

Target:
- capability section
- User Story ID or proposed ID
- affected Child Vertical Slice IDs

Row-level Source Coverage:
- <Row ID> -> user-authorized draft proposal | PM-provided behavior | existing canonical fact | proposed ambiguity

Omitted Scope:
- provider / SLA / approval rule / governance conclusion / downstream artifact not decided in this run

Story Map Rows:
- 使用 user-story-card.template.md 或 vertical-slice-card.template.md 的五列表格结构。

Boundary Note:
- none | 需要写入 story map 的就近边界说明

Ready Gate Finding:
- result: pass | fail
- gate: draft structural | narrative quality | approval semantic | combined
- narrative finding
- business information density finding
- sibling differentiation finding
- source authority and row coverage finding
- split / ambiguity / boundary finding
- capability mapping finding
- registry adjacency finding
- omitted-scope finding
- missing information, if any

PM Approval Required:
- yes；只有 Product Manager 可以把 `draft` 改为 `approved` 或承诺下游消费。
```

输出规则：

- 不输出 expanded metadata card。
- 不输出 FR、spec、pass/fail AC、TC、contract、implementation plan、code、priority、roadmap 或 release decision。
- Story map 级结构 pass 不代表所有 `draft` 行通过 approval semantic gate。
- 输入不足时输出 ambiguity finding，不用通用成功/失败句式补齐未知产品行为。
