# Ready Gate 输出模板

用于输出可直接落到当前 story map 的 proposal 或 finding。

```text
Assumptions:
- product behavior source
- capability boundary source
- inherited non-goals / boundary notes

Target:
- capability section
- User Story ID or proposed ID
- affected Child Vertical Slice IDs

Story Map Rows:
- 使用 user-story-card.template.md 或 vertical-slice-card.template.md 的五列表格结构。

Boundary Note:
- none | 需要写入 story map 的就近边界说明

Ready Gate Finding:
- result: pass | fail
- gate: draft structural | approval semantic
- narrative finding
- split / ambiguity / boundary finding
- capability mapping finding
- missing information, if any

PM Approval Required:
- yes；只有 Product Manager 可以把 `draft` 改为 `approved` 或承诺下游消费。
```

输出规则：

- 不输出 expanded metadata card。
- 不输出 FR、spec、pass/fail AC、TC、contract、implementation plan、code、priority、roadmap 或 release decision。
- Story map 级结构 pass 不代表所有 `draft` 行通过 approval semantic gate。
