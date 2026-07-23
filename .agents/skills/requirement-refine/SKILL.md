---
name: requirement-refine
description: Use when approved Vertical Slice behavior must be distilled into mandatory, atomic, testable Functional Requirements. Do not use for coding-only work or unapproved product behavior.
---

# Requirement Refine

## Overview

Turn approved Child Vertical Slices into mandatory atomic FRs without adding product behavior or delivery metadata.

## When to Use

Use when an approved VS enters implementation, an existing FR must change, or a product fact needs atomic requirement wording.

## When NOT to Use

Do not use for draft/unapproved VS, code-only fixes with no product fact change, Capability classification, tests, or Engineering Contract design.

## Contract

Method skill for `FUNCTIONAL_REQUIREMENT_CATALOG`. Resolve path, owner, lifecycle, inputs, contributor scope and validation through `GOVERNANCE_INDEX`. Story Map is the only product source; Capability/Sub-capability is classification only.

## Inputs

Selected approved VS, its nested Story lineage, approved Capability classification, existing FRs, constraints, and explicit PM decisions. Missing or conflicting behavior blocks and returns to Product Manager.

## Outputs

Approved/draft atomic FR rows with stable ID, `source_vs_ids`, primary and affected classification, one rule, one boundary/failure condition when applicable, and approval status.

## Process

1. Confirm each source VS exists, is approved, and has one unambiguous Story parent.
2. Separate reusable rules, invariants, boundaries and failures into atomic FRs.
3. Record only `source_vs_ids` as direct lineage; do not duplicate Story ID or treat classification as lineage.
4. Keep Stage, Increment, Work Package, PR, implementation and execution status out.
5. Obtain PM approval and run the validation command resolved for `FUNCTIONAL_REQUIREMENT_CATALOG`.

## Red Flags

Behavior inferred from Capability text; optional FR for an implementing VS; multiple independent rules in one row; Story/Stage/Increment as direct upstream; test or implementation detail in FR; unapproved source VS.

## Verification

Every implementing approved VS has at least one approved FR; each FR references only approved VS through `source_vs_ids`; IDs/classification are valid; rules are atomic and independently testable; no second lineage exists.
