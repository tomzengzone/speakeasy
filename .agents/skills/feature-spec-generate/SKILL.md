---
name: feature-spec-generate
description: Use when a feature needs an executable specification before architecture, UI, backend, or AI runtime work. Do not use when the requested change is smaller than a feature and already has clear tests.
---

# Feature Spec Generate

## Overview

Create the feature-level contract connecting approved requirements to behavior, architecture impact, tests, and non-goals.

## When to Use

Use for a new user-visible feature, a multi-module behavior change, or coordinated API/UI/data/AI work.

## When NOT to Use

Do not use for one-line copy/config edits, a bug regression test only, or an already-approved spec with no behavior change.

## Contract

- Method skill for `PRODUCT_BASE_SPEC` and `INCREMENT_SPEC`; resolve accountable ownership from `docs/process/governance/index.json`.
- Direct upstream is approved refined FRs plus the increment requirements/definition (or Product Base requirements for stable behavior). Story/Slice and Stage are scope/provenance context only; registry is boundary/classification context only.
- Downstream API, domain, AI, UX, and acceptance artifacts are requested by reference, not inlined.
- Paths and write scopes are governed by `docs/process/governance/index.json`; default durable project documents to Chinese unless explicitly requested otherwise.

## Inputs

Approved FRs, increment definition/requirements, applicable Product Base requirements, scope guards, architecture/domain docs, current approved delivery constraints, and Definition of Done. Missing approved FR blocks generation.

## Outputs

Goal/user flow, inputs/outputs/states/dependencies, impacted ownership areas, API/data/UI/AI/test impact, non-goals/rollout risks, source-FR references for each flow/state/dependency, and readiness for `acceptance-criteria-generate`.

## 文档路径约定

Write `docs/product/increments/{increment_id}/spec.md` for delivery work or `docs/product/base/spec.md` for accepted stable behavior; do not treat a baseline snapshot as the living spec.

## Process

1. Confirm product object and output path.
2. List approved FR IDs; map every major flow/state/dependency to its source FR and add Slice only as scope guard.
3. Define observable success/failure/empty/loading behavior and non-goals before implementation details.
4. List impacted ownership areas; split if more than five files are expected.
5. Map success to expected acceptance coverage, record ADR/change-request risks, and state approval readiness.

## Red Flags

Unrelated features, oversized increments, missing failure/empty/loading states, optional tests, untraceable behavior, premature AC, stable Capability identity derived from stage/roadmap/baseline/increment IDs, inlined downstream contracts, or behavior without approved FR/change request.

## Verification

The feature can be accepted/rejected from the spec; every impact has an owner; non-goals prevent scope creep; the spec is the direct upstream for new-feature AC; references bind to one increment definition/requirements set and do not claim code-coverage completeness.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The user story is enough.” | Approved FRs and an executable spec prevent untraceable behavior. |
| “We can define states while coding.” | Loading, failure, and non-goals must constrain implementation first. |
