# 就绪审查输出模板

用于用户明确要求 User Story 或 Child Vertical Slice 就绪审查结果时的可选输出版式。

```text
Target:
- User Story: <Id or proposed Id>
- Child Vertical Slices: <Ids or proposed Ids>

Result:
- pass | fail

Blocking Findings:
- none | <最小阻塞项及受影响记录>

Non-blocking Findings:
- none | <不阻塞批准的改进项>

Proposed Story Map Rows:
- none | <使用三列表格输出可直接持久化的记录>

Unresolved Decisions:
- none | <仍需 Product Manager 决定的产品行为>

Approval Status:
- draft | approved
```

该模板只组织审查结果，不增加 Story Map 字段或建立新的 Gate。
