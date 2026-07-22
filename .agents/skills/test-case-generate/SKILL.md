---
name: test-case-generate
description: Use when approved FR, changed Engineering Contract, or implementing Vertical Slice needs stable FR-TC, Contract-TC, or VS-TC design. Do not use when tests only need execution.
---

# Test Case Generate

## Overview

Design layered executable test cases with one typed direct upstream per case and reusable, self-contained oracles.

## When to Use

Use for mandatory FR coverage, Engineering Contract fact changes, selected VS full-chain coverage, or a bug requiring a stable regression oracle.

## When NOT to Use

Do not use to run existing tests, store CI results, invent behavior, or compensate for an incomplete/unapproved VS or FR.

## Contract

Method skill for `TEST_CASE_CATALOG`. Resolve governance facts by Artifact ID. TC execution results belong to exact-commit test/CI evidence, not this catalog.

## Inputs

Approved FRs, selected approved VS, changed Engineering Contract IDs, existing test conventions/code, stable selectors, fixtures, failure boundaries and target commands.

## Outputs

FR-TC, Contract-TC and VS-TC entries containing one typed direct edge, self-contained Given/When/Then, oracle, boundary/negative case, layer, scope, selector, script path and command.

## Process

1. Choose exactly one type: FR-TC uses only `source_fr_id`; Contract-TC uses only `source_contract_id`; VS-TC uses only `source_vs_id`.
2. For FR-TC, choose the lowest-cost layer that proves the atomic rule.
3. For Contract-TC, select contract/integration/migration/AI-eval or another layer that proves the changed engineering fact.
4. For VS-TC, cover the user-visible integration/E2E loop on all actually affected layers and its key degradation path.
5. Add stable selector, script and command; leave runtime result status out.
6. Run the validation command resolved for `TEST_CASE_CATALOG`.

## Red Flags

More than one direct upstream type; copied cross-layer coverage joins; passing status in the catalog; happy path only; unstable selector; release smoke used as first defect feedback; tests redefining product behavior.

## Verification

Every FR has an FR-TC or time-bounded explicit exception; every implementing VS has a VS-TC; every changed Contract has a Contract-TC; all entries have executable fields and exactly one allowed direct edge.
