---
name: domain-model-generate
description: Use when approved Functional Requirements change entities, relationships, lifecycle states, invariants, or persistence ownership. Do not use for presentation-only changes.
---

# Domain Model Generate

## Overview

Stabilize domain and persistence facts before API, backend, AI or UI work depends on them.

## When to Use

Use for shared/persisted entities, relationships, lifecycle transitions, invariants, ownership or migration facts.

## When NOT to Use

Do not use for label/layout changes, unchanged data facts or unapproved product behavior.

## Contract

Method skill for `DOMAIN_SCHEMA` and `DOMAIN_MODEL`; `ENTITY_RELATIONSHIP` is a related Artifact. Resolve governance facts by Artifact ID. Mandatory FR is the product upstream; architecture/API are engineering context.

## Inputs

Applicable approved FR IDs, current domain/relationship/model artifacts, system and API boundaries, persistence constraints and relevant Contract-TC needs.

## Outputs

Entities, fields, identities, invariants, relationships, lifecycle transitions, persistence ownership, migration needs and testable contract changes.

## Process

1. Confirm applicable FR and actual domain fact change.
2. Separate domain concepts from DTOs, database mechanics and UI view models.
3. Define ownership, uniqueness, audit, deletion and valid transitions.
4. Update only the affected owning Domain Artifact.
5. Add/update Contract-TC and run resolved validation.

## Red Flags

Storage fields before meaning; inconsistent naming; unconstrained transitions; AI candidate treated as durable truth; product behavior invented in the model; missing Contract-TC.

## Verification

Every changed concept has explicit ownership/lifecycle; relationships and deletion rules are unambiguous; applicable FR resolves through traceability; Contract-TC proves each changed fact.
