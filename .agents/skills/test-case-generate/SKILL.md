---
name: test-case-generate
description: Use when acceptance criteria or bug fixes need concrete unit, integration, E2E, or AI eval test cases. Do not use when tests already cover the changed behavior and only need to be run.
---

# Test Case Generate

## Overview

Turn approved acceptance criteria into balanced, executable test cases before or during implementation.

## When to Use

Use when Product Base/increment acceptance needs QA planning, a bug needs regression coverage, or API/UI/data/AI contracts change.

## When NOT to Use

Do not use when only running existing tests, for documentation-only work, or for a discarded spike.

## Contract

- Method skill for `INCREMENT_TEST_CASES`; resolve its accountable ownership and the separate evidence/report/traceability ownership routes from `docs/process/governance/index.json`.
- Direct upstream is `INCREMENT_ACCEPTANCE` plus `INCREMENT_SPEC` (or Product Base equivalents); API, screen, and prompt contracts are conditional context.
- Stable IDs live in `docs/product/increments/{increment_id}/test_cases.md`; evidence uses governed traceability/report paths from `docs/process/governance/index.json`.

## Inputs

Approved AC/spec/traceability, increment definition/WP/Traceability Row IDs, applicable API/screen/prompt contracts, existing test conventions, and classification only as boundary context. Missing AC routes to `acceptance-criteria-generate`.

## Outputs

Layered test cases with fixtures/assertions, regression tests, coverage gaps/manual notes, stable AC-to-TC mappings, and a handoff for QA to record Test Evidence through its declared report/traceability scope. Never invent requirements or expand scope.

## 文档路径约定

Persist only the test library at `docs/product/increments/{increment_id}/test_cases.md`. Return report, traceability, executable-test, and eval handoffs to the owners resolved through the governance contract.

## Required Test Case Fields

Every case is non-empty (use `N/A - <reason>` only when genuinely inapplicable) and includes: `TC ID`, `Traceability Row ID`, `Increment ID`, `WP ID`, `Spec ID`, `AC ID`, test layer, automation status, test script path, execution command, result status, evidence report, and `Gap / Exception`.

Allowed values: layer `unit|integration|contract|widget|e2e|ai-eval|release-check|manual`; automation `automated|manual-verification|external-dependency|not-automatable-yet|planned`; result `planned|implemented|passed|failed|blocked|skipped|retired`. IDs use stable `TC-<scope-prefix>-<NNN>`; retired IDs remain retired with reason.

## Process

1. Confirm AC and traceability exist when coverage is in scope.
2. Map every AC to one or more tests or an explicit exception (`manual acceptance`, external dependency, or not automatable yet).
3. Record the AC-to-TC gate before implementation routing.
4. Prefer the lowest-cost proving layer; use integration/E2E for boundaries, regression tests for bugs, and explicit reusable data.
5. Apply Red-Green-Refactor when practical and hand uncovered ACs to QA for `TEST_REPORT`; do not mark implementation ready/completed while mappings or evidence are missing.

## Red Flags

Happy-path/snapshot-only coverage, live third-party dependence without fixtures, bug fixes without a failing regression test, redundant E2E, tests redefining FR/AC, unstable IDs, empty evidence, or generation from roadmap/stage text.

## Verification

Every criterion is covered or explicitly deferred; implementation readiness is blocked without stable TC IDs/allowed exceptions; the test pyramid is balanced; failures identify an owner; AI tests cover valid/invalid outputs; evidence maps to the owning Product Base/increment and preserves classification.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “A passing smoke test is enough.” | Each approved AC needs a stable case or explicit exception and evidence. |
| “We can renumber later.” | Stable IDs are the traceability join and must not be reused. |
