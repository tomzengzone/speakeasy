# MVP Backend Client QA Release Requirements

## 状态
Draft - derived from MVP backend stage。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 client/QA/release requirement IDs。 |

## Owner
Requirement Development Agent

## Requirement Coverage
| Requirement ID | Stage Scope ID | Requirement |
| --- | --- | --- |
| MVP-BE-FR-013 | MVP-SI-013 | Flutter client 必须与 OpenAPI source of truth 对齐，通过 generated Dart client 或等效 contract gate 消除旧 endpoint、旧字段和手写漂移。 |
| MVP-BE-FR-014 | MVP-SI-014 | MVP backend stage 必须具备后端单元/集成测试、OpenAPI contract 测试、Flutter integration/e2e 或明确例外，并形成 implementation、quality、test 和 release evidence。 |

## Success Criteria
- SC-MVP-BE-026：OpenAPI lint 和 contract gate 通过。
- SC-MVP-BE-027：Flutter API client 不再调用与 OpenAPI 不一致的 MVP backend active endpoints。
- SC-MVP-BE-028：MVP-SI-001 到 MVP-SI-014 每一项都有 code evidence、test evidence、release evidence 或明确例外。
- SC-MVP-BE-029：test report 和 quality report 能反向引用 owning increment traceability rows。
- SC-MVP-BE-030：Product Object Governance Check 确认没有 P0/P0.1/P0.2/P1/P2 scope 混入 MVP backend Done 口径。

## Non-goals
- 不代替后端实现。
- 不把手工验收当成默认豁免；只有外部服务、平台或 release 条件限制时才允许明确例外。

## Downstream Artifacts
- `docs/product/increments/mvp-backend-client-qa-release/spec.md`
- `docs/product/increments/mvp-backend-client-qa-release/acceptance.md`
- `docs/product/increments/mvp-backend-client-qa-release/traceability.md`
