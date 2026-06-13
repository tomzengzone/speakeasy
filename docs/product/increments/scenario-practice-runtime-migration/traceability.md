# 场景练习 Runtime 迁移追溯矩阵

## 状态
架构设计已就绪。本文件为后续 frontend-only 迁移实现提供追溯关系。

## 追溯矩阵
| Trace ID | Stage Scope ID | FR | Spec section | AC | SWC allocation | Planned TC | Status |
| --- | --- | --- | --- | --- | --- | --- | --- |
| MIG-TR-001 | P01-SI-001 | MIG-FR-001 | Current File Inventory; Target SWCs | MIG-AC-002 | `swc_allocation.md` Requirement Allocation Matrix row MIG-FR-001 | MIG-TC-001 | Architecture ready |
| MIG-TR-002 | P01-SI-001 | MIG-FR-002 | Architecture Decision; Migration Slices | MIG-AC-003 | `swc_allocation.md` row MIG-FR-002 | MIG-TC-002 | Architecture ready |
| MIG-TR-003 | P01-SI-007, P01-SI-011 | MIG-FR-003 | Target SWCs; Migration Slices | MIG-AC-004, MIG-AC-009 | `swc_allocation.md` row MIG-FR-003 and runtime flows | MIG-TC-003 | Architecture ready |
| MIG-TR-004 | P01-SI-005, P01-SI-008, P01-SI-009 | MIG-FR-004 | Target SWCs; Implementation Constraints | MIG-AC-008 | `swc_allocation.md` row MIG-FR-004 | MIG-TC-004 | Architecture ready |
| MIG-TR-005 | P01-SI-007, P01-SI-008, P01-SI-011 | MIG-FR-005 | Frontend-Only Decision; Implementation Constraints | MIG-AC-001 | `swc_allocation.md` row MIG-FR-005 | MIG-TC-005 | Architecture ready |
| MIG-TR-006 | P01-SI-001, P01-SI-007, P01-SI-008, P01-SI-009, P01-SI-011 | MIG-FR-006 | Current File Inventory | MIG-AC-005 | `swc_allocation.md` Old SWC/File Responsibility Inventory | MIG-TC-006 | Architecture ready |
| MIG-TR-007 | P01-SI-001, P01-SI-007, P01-SI-008, P01-SI-009, P01-SI-011 | MIG-FR-007 | Target SWCs | MIG-AC-006 | `swc_allocation.md` Target SWC Allocation | MIG-TC-007 | Architecture ready |
| MIG-TR-008 | P01-SI-005, P01-SI-007, P01-SI-008, P01-SI-009, P01-SI-011 | MIG-FR-008 | Data-Flow Summary | MIG-AC-007 | `swc_allocation.md` SWC Data Flows | MIG-TC-008 | Architecture ready |
| MIG-TR-009 | P01-SI-010, P01-SI-011 | MIG-FR-009 | Implementation Constraints | MIG-AC-009 | `swc_allocation.md` Reuse And Forbidden Boundaries | MIG-TC-009 | Architecture ready |
| MIG-TR-010 | P01-SI-001..011 refactor evidence only | MIG-FR-010 | Migration Slices | MIG-AC-010 | `swc_allocation.md` Verification | MIG-TC-010 | Pending checker |
| MIG-TR-011 | P01-SI-009, P01-SI-011 | MIG-FR-011 | Target SWCs; Data-Flow Summary | MIG-AC-011 | `swc_allocation.md` practice history rows and flow | MIG-TC-011 | Architecture ready |

## 下游关联
- 开发任务必须引用一个或多个 `MIG-TR-*` ID。
- 实现报告必须列出被修改或复用的具体 SWC flow ID。
- 测试报告必须把测试结果映射回 `MIG-TC-*`。
- 任何跨层漂移都必须创建新的 increment，或先更新对应 Domain Schema、OpenAPI、backend traceability，代码才可以被接受。
