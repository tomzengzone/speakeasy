---
name: requirement-refine
description: Use when a user idea, feature request, or change request must be turned into scoped, testable product requirements. Do not use when implementation is already specified and only coding is needed.
---

# Requirement Refine

## Overview

Convert product intent into constrained, testable requirements before design or code. Broad modules use a two-step method—first stable first-level subfunctions and product boundaries, then atomic requirement items—but the final document must not expose those execution headings.

## When to Use

Use for ambiguous/new features, possible scope expansion, approved Story/Slice refinement, accepted Product Base consolidation, or broad-module decomposition.

## When NOT to Use

Do not use for a mechanical edit with clear acceptance, an exact-reproduction bugfix, or implementation already fully specified (unless the user explicitly requests requirement governance).

## Contract

- Method skill for `PRODUCT_BASE_REQUIREMENTS` and `INCREMENT_REQUIREMENTS`; resolve ownership through the governance index.
- Direct upstream for new increment requirements is approved `STORY_MAP` (User Story + Vertical Slice). Stage, Increment, Capability, and Stage Scope IDs are scope/classification guards only. `CHANGE_REQUEST` may be an explicit PM-approved exception.
- Canonical paths, lifecycle, direct inputs, and write scopes are governed by `docs/process/governance/index.json`; default durable project documents to Chinese unless explicitly requested otherwise.

## Inputs

User/change request, PM product-object classification, approved Story/Slice IDs, Product Base requirements for stable behavior, active stage/increment definition and covered scope IDs, approved Capability context, existing product docs, target users, constraints, and approved delivery boundary. Missing Story/Slice blocks new increment requirements.

When the target spans a broad product module or multiple first-level subfunctions, read [broad-module requirements](references/broad-module-requirements.md) before decomposition. Do not load it for a single bounded requirement.

## Outputs

Classified Product Base or increment requirements artifact, module boundary, first-level subfunctions, atomic requirement items, direct Story/Slice and Capability references, measurable success criteria, assumptions, non-goals, open questions, downstream handoff, and separate traceability references. Baseline references are used only for approved implemented-behavior consolidation.

## 文档路径约定

Stable accepted requirements go to `docs/product/base/requirements.md`; stage-bound requirements go to `docs/product/increments/{increment_id}/requirements.md`; scope expansion goes to `docs/process/change_request.md`. This skill does not create or edit Story Map, Registry, Spec, AC, TC, or traceability artifacts.

## Product-object rules

Classify as `product-base-consolidation`, `baseline-consolidation`, `new-feature`, `feature-increment`, `bugfix`, `refactor`, `experiment`, or `scope-change`. Capability is long-lived PM-owned V2 identity; Stage/Increment are delivery structures; Baseline is frozen evidence; legacy V1 slugs are historical mappings only. Delivery-priority labels, stage horizons, and increment IDs are not Capability IDs/slugs, requirement IDs, or module titles. Do not invent behavior from Stage Scope, roadmap, or registry prose.

## Process

1. State assumptions and classify product object/source mode before selecting the output path.
2. For new increment work, verify approved Story/Slice IDs and Stage Scope/covered items as guards.
3. Split mixed feature/stage/increment/baseline requests; split multi-module scope before drafting.
4. Decompose broad scope into non-overlapping first-level subfunctions and boundary statements.
5. Draft atomic, independently testable items; map each to direct Story/Slice and applicable Capability IDs.
6. Add measurable success criteria, non-goals, assumptions, open questions, backlog/change-request notes, and downstream handoff without writing AC/spec content.
7. State whether the result is Product Base, baseline consolidation, or increment requirements; route unresolved priority/scope to PM.

## Red Flags

Vague adjectives without thresholds, unrelated screens/data, implementation details in requirements/AC, missing non-goals, premature “100% coverage,” bypassed Spec, invalid Capability/requirement IDs, baseline facts rewritten as future requirements, untraceable IDs, oversized FR rows, subfunctions without product boundaries, multi-behavior items, extra table columns, or `Step 1`/`Step 2` headings in the final artifact.

## Verification

Every success criterion is testable; user/action/outcome are clear; assumptions are separate; scope additions are backlog/change request; output path matches object; V2 Capability context is preserved; every increment requirement ID traces to Story + Slice or approved exception; broad modules have subfunctions and boundaries; each item belongs to one subfunction; the three-column table is respected; downstream spec can consume direct upstream; complete traceability is separate.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The story is enough.” | Requirement IDs need direct Story/Slice lineage and measurable boundaries. |
| “We can split the module while coding.” | Product subfunctions and exclusions must constrain downstream scope first. |
| “Add traceability fields to the item table for safety.” | The owning matrix is the single complete join; duplicated fields drift. |
