# MVP System E2E Validation Spec

## 状态
Validated for local MVP system E2E gate - executable system validation spec。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-29 | Draft | 建立系统 E2E spec IDs 和验证流。 |
| v1.0 | 2026-05-29 | Validated | Flow-MVP-E2E-001 到 004 的 smoke gate/coverage audit 路径已实现并通过。 |
| v1.1 | 2026-05-29 | Validated | 深度系统回归覆盖场景目录、学习记忆、练习反馈、Profile/settings/session 和会员边界 UI。 |

## Owner
Feature Spec Generate Skill

## Spec Coverage
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| MVP-E2E-SPEC-001 | MVP-SI-014 | MVP-E2E-FR-001 | Local real-stack orchestration |
| MVP-E2E-SPEC-002 | MVP-SI-014 | MVP-E2E-FR-002 | Flutter-driven critical user journey |
| MVP-E2E-SPEC-003 | MVP-SI-014 | MVP-E2E-FR-003 | Product Base AC system coverage matrix |
| MVP-E2E-SPEC-004 | MVP-SI-014 | MVP-E2E-FR-004 | Evidence, diagnostics and rerun protocol |

## Flow-MVP-E2E-001 Local Real-Stack Orchestration
1. Script verifies `postgres`, `initdb`, `psql`, Java 17, Maven and Flutter are available.
2. Script creates an isolated temporary PostgreSQL data directory.
3. Script starts PostgreSQL on localhost with a test port and creates the app database/user if needed.
4. Script starts Spring Boot with `SPEAKEASY_DB_URL`, `SPEAKEASY_DB_USERNAME`, `SPEAKEASY_DB_PASSWORD` and `SERVER_PORT`.
5. Script waits until a public backend endpoint responds.
6. Script runs Flutter integration test with `API_BASE_URL=http://127.0.0.1:<backend-port>/v1` and `ENABLE_TEST_PHONE_LOGIN=true`.
7. Script tears down child processes and records log locations.

## Flow-MVP-E2E-002 Flutter Critical Journey
1. App launches to login gate when there is no authenticated local session.
2. Test accepts terms and enters the phone login flow.
3. Test enters a deterministic test phone number and submits the test login action.
4. App receives backend-issued token, hydrates the user and routes to onboarding.
5. Test completes onboarding choices and saves learning route.
6. App routes to home and renders learning scene / expression modules from current state and backend hydration.

## Flow-MVP-E2E-003 Coverage Matrix
1. Product Base AC-001 to AC-013 are listed in the system E2E coverage summary.
2. Each AC maps to at least one executed system TC, accepted exception or external/manual gate.
3. Exceptions must name the blocking external dependency and the owning future gate.
4. A coverage audit fails if any Product Base AC is absent from the matrix.

## Flow-MVP-E2E-004 Evidence And Diagnostics
1. Every system TC records script path and exact command.
2. Every execution records result status and evidence report path.
3. Failure triage categories include env-missing, stack-boot-failed, db-migration-failed, backend-api-failed, flutter-ui-failed and external-dependency.
4. QA report distinguishes executed passing evidence from accepted external/provider gates.

## Required States
| State domain | States |
| --- | --- |
| Stack readiness | missing-tools, postgres-started, backend-started, flutter-running, teardown-complete |
| Test automation | planned, automated, manual-external, accepted-exception |
| Result status | planned, passed, failed, skipped-env, accepted-exception |
| Evidence | missing, local-log, test-report, quality-report |

## Non-goals
- 不把 integration test 作为所有 unit/widget/API contract 测试的替代品。
- 不在本地脚本中连接生产数据库或生产第三方账号。
