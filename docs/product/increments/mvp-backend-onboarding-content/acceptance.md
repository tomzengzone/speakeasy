# MVP Backend Onboarding Content Acceptance

## 状态
Draft - onboarding/content acceptance criteria。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 onboarding/content AC。 |

## Owner
Acceptance Criteria Generate Skill

## Acceptance Coverage Map
| AC | Stage Scope ID | FR | Spec |
| --- | --- | --- | --- |
| AC-MVP-BE-003 | MVP-SI-003 | MVP-BE-FR-003 | MVP-BE-SPEC-003 |
| AC-MVP-BE-004 | MVP-SI-004 | MVP-BE-FR-004 | MVP-BE-SPEC-004 |
| AC-MVP-BE-005 | MVP-SI-005 | MVP-BE-FR-005 | MVP-BE-SPEC-005 |

## AC-MVP-BE-003 Onboarding And Learning Route
- 给定用户提交缺少目标方向、表达卡点或输出水平的首评，后端必须拒绝完成并返回 validation error。
- 给定用户选择英语面试，后端必须写入 `job_interview`。
- 给定用户选择入职介绍或工作沟通，后端必须写入 `onboarding_introduction`。
- 给定用户选择日常服务，后端不得创建可练官方场景。
- 给定用户完成首评，后端必须能返回 assessment 和 learning route。

## AC-MVP-BE-004 Official Scenario Content
- 给定 scenario list 请求，后端只能返回英语面试和入职介绍两个 Product Base 官方场景。
- 给定 scenario detail 请求，后端必须返回标题、简介、标签、目标等级、表达数量和版本信息。
- 给定 level content 请求，后端必须返回 L1/L2/L3 中有效等级的内容；无效等级必须返回确定性错误。
- 给定内容 seed 或版本变更，必须能通过测试确认内容可读取且不会误新增 Product Base 外场景。

## AC-MVP-BE-005 User Scenario State And Home Summary
- 给定用户加入场景，后端 home summary 必须能反映已加入场景。
- 给定用户移除场景，后端不得继续把该场景作为 current scene。
- 给定用户设为当前场景或切换等级，后续 home summary 和练习入口必须使用新状态。
- 给定用户没有已加入场景，home summary 必须能返回可理解空状态。
- 给定复习、薄弱或未完成会话数据暂未实现，home summary 必须返回明确缺省状态，不得伪造完成数据。

## Traceability
完整追溯见 `docs/product/increments/mvp-backend-onboarding-content/traceability.md`。
