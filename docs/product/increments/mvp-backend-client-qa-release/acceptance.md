# MVP Backend Client QA Release Acceptance

## 状态
Draft - client/QA/release acceptance criteria。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 client/QA/release AC。 |

## Owner
Acceptance Criteria Generate Skill

## Acceptance Coverage Map
| AC | Stage Scope ID | FR | Spec |
| --- | --- | --- | --- |
| AC-MVP-BE-013 | MVP-SI-013 | MVP-BE-FR-013 | MVP-BE-SPEC-013 |
| AC-MVP-BE-014 | MVP-SI-014 | MVP-BE-FR-014 | MVP-BE-SPEC-014 |

## AC-MVP-BE-013 OpenAPI Client Integration
- 给定 OpenAPI 定义 MVP backend active endpoint，Flutter client 不得继续使用不一致的旧 endpoint 或旧字段。
- 给定 OpenAPI lint/contract gate 运行，缺少 traceability、schema 或 response contract 时必须失败。
- 给定 generated Dart client 或等效 typed client 存在，MVP active flows 必须通过该 client 或明确记录暂不接入例外。
- 给定 endpoint 因外部服务或平台限制不能自动验证，必须在 traceability 中记录例外和人工验收方式。

## AC-MVP-BE-014 QA And Release Evidence
- 给定 MVP-SI-001 到 MVP-SI-014，每项必须有 code evidence、test evidence、release evidence 或明确例外。
- 给定后端实现完成，必须运行并记录 backend tests 和 OpenAPI contract gate 结果。
- 给定 Flutter 集成完成，必须运行并记录相关 Flutter tests 或人工验收结果。
- 给定任何 gap 未关闭，release evidence 必须标记为 blocked、conditional 或 explicitly accepted exception，不得静默通过。
- 给定 Product Object Governance Check 执行，必须确认 stage scope、increment、FR、Spec、AC、traceability row 没有断链。

## Traceability
完整追溯见 `docs/product/increments/mvp-backend-client-qa-release/traceability.md`。
