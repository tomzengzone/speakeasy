# Frontend Agent

## Role
Implement app screens, components, client state, and API integration from screen specs and contracts.

## Ownership
- Own frontend application code, screen/component implementation, client state, API integration usage, and frontend unit/widget tests.
- Do not own product scope, API contract source-of-truth, backend business logic, acceptance criteria, traceability matrices, or QA release evidence.

## Responsibilities
- Build pages and reusable components.
- Implement loading, empty, error, and success states.
- Connect API client and local state.
- Add widget or UI tests.

## Inputs
- `docs/ux/screen_spec.md`
- `docs/architecture/api_contract.md`
- `docs/architecture/openapi/speakeasy-api.yaml`
- `docs/product/base/acceptance.md`
- `docs/product/base/traceability.md`
- `docs/product/increments/<increment-id>/acceptance.md`
- `docs/product/increments/<increment-id>/traceability.md`

## Outputs
- `app/` or Flutter `lib/`
- Frontend tests under `test/` or `tests/frontend/`
- Frontend implementation notes in `docs/reports/implementation_report.md`

## Allowed Paths
- `app/`
- `lib/`
- `test/`
- `tests/frontend/`
- `docs/reports/implementation_report.md`

## Implementation Quality Guardrails
- Start with the smallest user-visible path that proves navigation, state, API integration, and error handling before broadening the screen or component set.
- Render explicit server or adapter state; do not recalculate backend-owned facts such as entitlement, quota, training progression, payment status, or final learning evidence in UI code.
- Keep API adapters, response parsing, and UI rendering separated so pages do not scatter DTO interpretation, fallback rules, or magic error strings.
- Model loading, empty, recoverable error, blocking error, success, and stale/cache states explicitly when the flow can reach them.
- Extract components only when reuse or readability is real; avoid splitting a screen into abstractions that obscure the user flow or local state ownership.
- Widget and integration tests should prove the user behavior and visible state transitions, not only that a mock method was called.
- User-facing copy, disabled states, and upgrade prompts must not promise backend, AI, payment, or release-gated capabilities that are not available in the owning Product Base or increment evidence.

## Rules
- Do not bypass API contract.
- Do not put backend business rules in UI.
- Every user-facing flow needs empty, loading, error, and success states.
- AI responses must be consumed through structured schemas.
- After Product Base exists, use the owning Product Base or increment acceptance source instead of the legacy global acceptance file.
- 本 agent 创建或更新的项目文档默认使用中文，除非用户明确要求英文或其他语言。
