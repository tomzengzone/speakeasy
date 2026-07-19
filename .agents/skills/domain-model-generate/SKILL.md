---
name: domain-model-generate
description: Use when approved product behavior needs entities, relationships, lifecycle states, or persistence boundaries defined. Do not use when the change only affects presentation copy or layout.
---

# Domain Model Generate

## Overview

Stabilize domain concepts before database, API, AI-runtime, or UI work depends on them.

## When to Use

Use when approved behavior introduces shared/persisted entities, state transitions, lifecycle rules, or unclear data ownership.

## When NOT to Use

Do not use for no-data changes, an existing entity’s label-only edit, or isolated UI polish.

## Contract

- Method skill for `DOMAIN_SCHEMA` and `DOMAIN_MODEL`; `ENTITY_RELATIONSHIP` is the related relationship Artifact. Resolve accountable ownership from `docs/process/governance/index.json`.
- Direct upstream is `INCREMENT_SPEC` (or approved Product Base spec for stable behavior); `INCREMENT_ACCEPTANCE`, architecture boundaries, and API contract are context.
- Paths, lifecycle, and write scopes are governed by `docs/process/governance/index.json`.

## Inputs

Approved spec/acceptance, existing domain artifacts, system/module boundaries, API contract, and approved Capability classification only as boundary context. Missing or conflicting classification blocks and routes to Product Manager.

## Outputs

Entities, fields, IDs/invariants, relationships, lifecycle/state transitions, persistence/API boundary recommendations, migration/seed needs, and traceability to the owning Product Base/increment spec.

## 文档路径约定

Write the governed domain artifacts only: `docs/domain/domain_schema.md`, `docs/domain/entity_relationship.md`, or `docs/domain/{domain}_model.md`; do not duplicate contracts in feature specs.

## Process

1. Derive nouns, actions, and states from the approved spec.
2. Separate domain concepts from DTOs and UI view models.
3. Define ownership, uniqueness, timestamps/audit, lifecycle transitions, archival/deletion, and migration needs.
4. Update the appropriate domain artifact before implementation.

## Red Flags

Database fields before meaning, inconsistent names, unconstrained backward transitions, AI output treated as durable truth, missing owner/upstream, or registry facts changed from this skill.

## Verification

Every entity has an owner and lifecycle; relationships and duplicate/deletion rules are unambiguous; API/database work can proceed without guessing; approved upstream and classification context are cited.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The table already exists.” | Existing storage does not define domain ownership or lifecycle semantics. |
| “The UI state is enough.” | Shared truth needs explicit domain boundaries before implementation. |
