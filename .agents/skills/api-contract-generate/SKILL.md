---
name: api-contract-generate
description: Use when approved Functional Requirements change a frontend/backend or external API boundary. Do not use for private helpers or local-only state.
---

# API Contract Generate

## Overview

Define stable API behavior so clients, servers and tests can implement independently.

## When to Use

Use for route, request, response, auth, stable error, compatibility or machine-schema fact changes.

## When NOT to Use

Do not use for implementation-only internals, unchanged API facts or unapproved product behavior.

## Contract

Method skill for `API_CONTRACT`; `OPENAPI` is the machine-readable companion Artifact. Resolve all governance facts by Artifact ID. Mandatory FR is the product upstream; Domain Schema is conditional engineering context.

## Inputs

Applicable approved FR IDs, current API/OpenAPI and Domain facts, security/compatibility constraints, affected clients and relevant Contract-TC needs.

## Outputs

Purpose, method/path/auth, request/response, validation, stable errors/recovery, compatibility/migration rules, examples and testable contract changes.

## Process

1. Confirm applicable FR and actual API fact change.
2. Define boundary semantics before route shape; keep storage/provider/framework details out.
3. Update prose and OpenAPI in their distinct ownership boundaries.
4. Add or update Contract-TC with `source_contract_id` only.
5. Run validation commands resolved for affected Artifact IDs.

## Red Flags

Table mirroring; generic-only errors; provider leakage; breaking change without migration; product behavior added in API prose; duplicated prose/machine schema ownership.

## Verification

Client/server can implement independently; errors and compatibility are explicit; applicable FR lineage is resolvable through governance/traceability; Contract-TC proves each changed fact.
