# MVP Backend Client QA Release Spec

## 状态
Draft - client/QA/release executable product spec。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 client/QA/release spec IDs。 |

## Owner
Feature Spec Generate Skill

## Spec Coverage
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| MVP-BE-SPEC-013 | MVP-SI-013 | MVP-BE-FR-013 | Flow-MVP-BE-013 OpenAPI client integration |
| MVP-BE-SPEC-014 | MVP-SI-014 | MVP-BE-FR-014 | Flow-MVP-BE-014 QA and release evidence |

## Flow-MVP-BE-013 OpenAPI Client Integration
1. OpenAPI source is updated or confirmed for all MVP backend implemented endpoints.
2. Contract/lint gate runs and fails on missing traceability or schema drift.
3. Dart client is generated or an equivalent typed client is checked against OpenAPI.
4. Flutter app migrates active MVP backend calls away from old paths/fields.
5. Endpoint drift is recorded as closed, deferred, or explicit exception.

## Flow-MVP-BE-014 QA And Release Evidence
1. QA maps each MVP-SI row to test coverage or exception.
2. Backend unit/integration tests validate persistence, controller responses and error states.
3. Contract tests validate OpenAPI-compatible request/response behavior.
4. Flutter integration/e2e tests validate active user paths where feasible.
5. Reports record commands, results, gaps, residual risks and release readiness.
6. Product Object Governance Check independently reviews stage/increment traceability.

## Required States
| State domain | States |
| --- | --- |
| API contract | draft, lint-passed, drift-detected, accepted |
| Client integration | not-started, generated, migrated, exception-recorded |
| Test evidence | missing, automated, manual, external-dependency, accepted-exception |
| Release evidence | not-ready, conditionally-ready, ready |

## Non-goals
- 不扩大产品范围。
- 不替代 source increment 的 requirements/spec/acceptance。
