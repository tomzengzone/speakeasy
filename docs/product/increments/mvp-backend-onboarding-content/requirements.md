# MVP Backend Onboarding Content Requirements

## 状态
Draft - derived from MVP backend stage。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 onboarding/content requirement IDs。 |

## Owner
Requirement Development Agent

## Capability Classification
- Primary Capability ID：`CAP-CONTENT`
- Primary Sub-capability ID：`CAP-CONTENT-01`
- Affected Capability IDs：`CAP-LEVEL`、`CAP-INTENT`、`CAP-PLAN`
- Affected Sub-capability IDs：`CAP-CONTENT-02`、`CAP-CONTENT-03`、`CAP-LEVEL-02`、`CAP-INTENT-01`、`CAP-INTENT-03`、`CAP-INTENT-04`、`CAP-PLAN-03`

## Requirement Coverage
| Requirement ID | Stage Scope ID | Requirement |
| --- | --- | --- |
| MVP-BE-FR-003 | MVP-SI-003 | 后端必须保存首评 assessment、每日分钟偏好、Product Base 场景映射和 learning route，且遵守英语面试、入职介绍、工作沟通映射和日常服务非真实场景边界。 |
| MVP-BE-FR-004 | MVP-SI-004 | 后端必须提供两个官方场景的目录、详情、版本、等级、目标表达和内容读取能力，且内容版本可追踪、可测试、可回滚。 |
| MVP-BE-FR-005 | MVP-SI-005 | 后端必须承接用户加入、移除、设为当前场景、切换目标等级、首页学习状态和下一步建议所需的状态读取/写入。 |

## Success Criteria
- SC-MVP-BE-006：首评完成后可从后端读取 learning route 和 current scenario。
- SC-MVP-BE-007：日常服务不会被后端写成可练官方场景。
- SC-MVP-BE-008：scenario list/detail/level API 只返回 Product Base 当前两个官方场景和 L1/L2/L3 内容。
- SC-MVP-BE-009：加入、移除、当前场景和目标等级变化能影响后续首页/练习入口数据。
- SC-MVP-BE-010：首页状态 API 能表达未加入场景、已加入场景、当前场景、未完成会话占位、复习/薄弱/下一步建议占位或数据。

## Non-goals
- 不承诺第三个官方场景。
- 不承诺完整 A1-C2。
- 不承诺任意场景生成。

## Downstream Artifacts
- `docs/product/increments/mvp-backend-onboarding-content/spec.md`
- `docs/product/increments/mvp-backend-onboarding-content/acceptance.md`
- `docs/product/increments/mvp-backend-onboarding-content/traceability.md`
