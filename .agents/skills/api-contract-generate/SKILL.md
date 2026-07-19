---
name: api-contract-generate
description: Use when frontend, backend, or AI runtime work needs a contract-first API boundary with request, response, errors, and compatibility rules. Do not use for private helpers or local-only state.
---

# API Contract Generate

## Overview

Define a stable API boundary before implementation so clients, servers, tests, and AI runtimes share one source of truth.

## When to Use

Use for cross frontend/backend, external API, endpoint/DTO, error, or compatibility changes.

## When NOT to Use

Do not use for client-only/internal changes or throw-away spikes.

## Contract

- Method skill for `API_CONTRACT`; `OPENAPI` remains a separate machine-readable Artifact. Resolve both ownership routes from `docs/process/governance/index.json`.
- Direct upstream is the approved `INCREMENT_SPEC` (or approved Product Base spec for accepted stable behavior); `DOMAIN_SCHEMA` is conditional context.
- Keep contract prose in `docs/architecture/api_contract.md` and machine schemas in `docs/architecture/openapi/speakeasy-api.yaml`; do not duplicate responsibilities. Routes and write scopes come from `docs/process/governance/index.json`.

## Inputs

Inputs: approved spec, applicable domain model, existing API/OpenAPI source, security and compatibility constraints. Output: capability purpose, method/path/auth, request/response schemas, stable errors and recovery hints, version/migration notes, success/failure examples, tests, and owning-increment traceability.

## Outputs

Capability purpose, method/path/auth, request/response schemas, stable errors and recovery hints, version/migration notes, examples, tests, and owning-increment traceability.

## 文档路径约定

Keep prose in `docs/architecture/api_contract.md` and machine schemas in `docs/architecture/openapi/speakeasy-api.yaml`; the governance contract is the path/write-scope authority.

## Process

1. Define the user/system capability and boundary before route shape.
2. Specify required/optional fields, validation, auth, error codes/status/recovery, and compatibility/migration behavior.
3. Keep storage, provider, ORM, and framework details out of the contract.
4. Update the prose contract and, when approved, the OpenAPI source; map cases to API tests.
5. Copy the owning increment’s approved Primary/Affected Capability classification and compatibility risk without changing registry facts. Missing/conflicting classification blocks and routes to Product Manager.

## Red Flags

Table-mirroring, generic-only 500s, provider/ORM leakage, breaking changes without migration, missing upstream, or duplicated prose/OpenAPI schemas.

## Verification

Client and server can implement independently; each error has stable semantics; examples cover success and failure; compatibility tests are possible; the contract traces to the approved Product Base/increment spec. Flag table-mirroring, generic-only 500s, provider/ORM leakage, breaking changes without migration, missing upstream, and duplicated prose/OpenAPI schemas.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The endpoint is obvious.” | Explicit request, response, error, and compatibility rules prevent client/server drift. |
| “OpenAPI alone is enough.” | Prose boundary and machine schema have distinct source-of-truth responsibilities. |
