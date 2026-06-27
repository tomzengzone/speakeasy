# MVP Backend Foundation Auth Spec

## 状态
Draft - foundation/auth executable product spec。

## Version / Status
| Version | Date | Status | Change |
| --- | --- | --- | --- |
| v0.1 | 2026-05-28 | Draft | 建立 foundation/auth spec IDs。 |

## Owner
Feature Spec Generate Skill

## Spec Coverage
| Spec ID | Stage Scope ID | Requirement ID | Spec area |
| --- | --- | --- | --- |
| MVP-BE-SPEC-001 | MVP-SI-001 | MVP-BE-FR-001 | Flow-MVP-BE-001 runtime/migration/error foundation |
| MVP-BE-SPEC-002 | MVP-SI-002 | MVP-BE-FR-002 | Flow-MVP-BE-002 auth/session/current user |

## Flow-MVP-BE-001 Runtime, DB, Migration, Error Foundation
1. Backend starts with explicit environment configuration for local/test/prod-like settings.
2. Flyway applies schema migrations in deterministic order.
3. Repository/service/controller layers expose implemented entities through DTOs, not raw persistence shapes.
4. API errors use the canonical response/error model and do not expose internal stack traces.
5. Test setup validates migration and basic persistence against PostgreSQL-compatible behavior.

## Flow-MVP-BE-002 Auth, Session, Current User
1. Client submits login through phone, Apple, or WeChat contract-compatible endpoints.
2. Backend creates or resolves user account/profile and issues access/refresh tokens.
3. Client can refresh a valid session and logout an active session.
4. Authenticated requests resolve current user from bearer token.
5. `/user/me` or equivalent current-user response returns Product Base profile/session state needed by the app.
6. Invalid, expired, missing, or revoked tokens return deterministic errors.

## Required States
| State domain | States |
| --- | --- |
| Runtime | starting, ready, migration-failed |
| Session | unauthenticated, authenticated, expired, revoked |
| User profile | created, active, incomplete-profile, deleted-or-disabled |
| Error | validation-error, unauthenticated, forbidden, conflict, provider-unavailable, internal-error |

## Non-goals
- 不定义 UI 布局。
- 不定义完整支付、权益或 P0 商业账号策略。
- 不承诺外部登录 provider 在所有环境真实可用。
