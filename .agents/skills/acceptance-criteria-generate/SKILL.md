---
name: acceptance-criteria-generate
description: Use when approved product behavior needs pass/fail acceptance criteria before implementation or QA planning. Do not use when current criteria only need execution.
---

# Acceptance Criteria Generate

## Overview

Convert approved behavior into observable, binary checks that implementation, QA, and traceability can use.

## When to Use

Use for new/accepted behavior, Product Base or approved baseline consolidation, or an accepted change that needs a done-ness gate.

## When NOT to Use

Do not use for design exploration, pure internal refactoring, or criteria that are already specific and only need execution.

## Contract

- Method skill for `PRODUCT_BASE_ACCEPTANCE` and `INCREMENT_ACCEPTANCE`; resolve accountable ownership from `docs/process/governance/index.json`.
- Direct upstream is the approved `PRODUCT_BASE_SPEC` or `INCREMENT_SPEC`. Story, Stage, Capability, roadmap, registry, code, and test plans are scope/evidence context, not parallel behavior sources.
- Write only the canonical acceptance artifact. Return an ephemeral AC-to-traceability handoff to `traceability-authority`; paths and contributor scopes are governed by `docs/process/governance/index.json`.

## Inputs

Approved spec, applicable FRs, constraints/non-goals, platform limits, and (only for explicitly approved baseline consolidation) implementation evidence. Missing approved spec blocks generation.

## Outputs

Numbered acceptance criteria, edge/error coverage, approved Spec/FR references, and an ephemeral handoff containing pending AC-to-TC and traceability mappings. Canonical persistent paths are only `PRODUCT_BASE_ACCEPTANCE` or `INCREMENT_ACCEPTANCE`.

## 文档路径约定

Persist only to the contract-selected acceptance location; return all traceability work as a handoff to its owning authority.

## Process

1. Select mode: Product Base, approved baseline snapshot, or increment.
2. Write observable, binary criteria grouped by workflow step; cover success, failure, empty/loading, permission, duplicate, and edge states when applicable.
3. Keep implementation details out unless reverse-freezing approved code evidence.
4. Record approved Spec/FR references in the acceptance artifact; hand off the join update to `traceability-authority`.
5. Emit pending test mappings; `test-case-generate` assigns stable Test Case IDs before implementation or records an explicit exception (`manual acceptance`, external dependency, or not automatable).
6. Require Code Evidence and Test Evidence (or a documented exception) before completion.

## Product-object boundaries

- Do not declare or change Capability classification; route missing or conflicting classification to Product Manager and `capability-registry-develop`.
- Never generate increment criteria without its approved increment spec.
- Do not use stage names, priority windows, increment IDs, or registry rows as Capability IDs/slugs or as behavior sources.

## Red Flags

Vague thresholds, happy-path-only coverage, missing approved upstream, scope conflicts, duplicated full Story/Slice chains, empty evidence fields without pending/exception status, or unsupported “100% coverage” claims.

## Verification

Every FR has at least one AC, every AC references one or more FRs, criteria are locally/test verifiable, and the handoff contains the mappings required for the owning traceability matrix. Flag vague thresholds, happy-path-only coverage, scope conflicts, missing upstreams, duplicated full traceability chains, and unsupported “100% coverage” claims.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The behavior is obvious.” | The approved spec is still the direct upstream and the smallest useful criterion prevents scope drift. |
| “Tests can define done-ness later.” | Acceptance criteria must exist before implementation is called complete. |
