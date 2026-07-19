---
name: story-map-develop
description: Use when Product Manager needs to create, split, rewrite, review, or ready-gate business-specific User Stories and Child Vertical Slices in docs/product/story_map.md, including rejecting formulaic or low-information narratives; Do not use to generate FR, spec, AC, TC, contracts, implementation plans, code, roadmap, priority, or release decisions.
---

# Story Map Develop

## Overview

Propose and quality-gate PM-owned User Stories and Child Vertical Slices as the direct product source for requirements. Product Manager owns product facts, priority, and approval.

## When to Use

Use for new or revised Story/Slice rows, split/merge review, ambiguity or low-information review, current-format validation, and ready-gate findings.

## When NOT to Use

Do not generate downstream requirements, specifications, acceptance criteria, tests, technical contracts, implementation, reports, roadmap/stage/increment decisions, or Capability registry changes.

## Contract

- Method for `STORY_MAP`; resolve path and ownership through the governance index.
- Drafts and findings are ephemeral until PM approval. `CAPABILITY_REGISTRY` supplies approved ownership boundaries, never Story/Slice behavior.
- `docs/process/governance/index.json` is authoritative for path, lifecycle, write scope, and checker. Write only Story Map rows after approval; never edit downstream artifacts to fill a narrative gap.

## Inputs

PM/user-authorized behavior, actors, business objects, decisions, state meaning, cross-Capability handoffs, meaningful exceptions, non-goals, scope mode, source inventory, relevant Story Map/registry sections, and existing IDs. Read only the target scope.

For row creation, semantic rewrite, split/merge, or approval-readiness work, read [Story/Slice ready gates](references/ready-gates.md). Do not load it for path lookup or an unchanged-format inspection.

## Outputs

Paste-ready rows, boundary notes, split/ambiguity/ready findings, row-level source coverage, omitted scope, and an explicit PM-approval requirement.

## 文档路径约定

Persist only to `docs/product/story_map.md`; use the registry as boundary reference and conditionally selected references/assets as method support.

## Current format

Organize by Capability. A Story is `### US-... - <title>`, followed by one five-column table and nested `Child Vertical Slices` rows:

```text
Id | description | Status | Primary Capability ID | Affected Capability IDs
```

The description owns row semantics. Do not add Actor/Scenario/Success/Parent columns; nesting owns the parent link. Status is `draft` or `approved`, and only PM approves. Put shared assumptions, source notes, and non-goals in a nearby boundary note.

## Process

1. State scope, target rows, sources, assumptions, and unknowns.
2. Read relevant Story Map rows and registry boundaries; never infer behavior from labels.
3. Build a compact behavior inventory and apply Story, Slice, information, source, structure, and approval gates.
4. Produce current-format rows or findings; stop rather than invent missing facts.
5. Obtain PM approval before persistence and run the touched-scope validator plus independent checker when required.

## Red Flags

Stories that are modules/pages/roadmap items; alternate schemas; duplicate parent columns; one row containing independent loops; CRUD/loading boilerplate; state lists without user decision/value; behavior inferred from Capability; missing source/omitted scope; or downstream artifacts edited to manufacture completeness.

## Verification

Rows fit the current map; nesting, IDs, columns, and status validate; each Slice has concrete facts and differs from siblings; description is the sole row semantics source; authority, adjacency, omitted scope, and PM approval are explicit; no downstream or release decision is emitted.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “Every field or UI state is a Slice.” | A Slice needs independent user value, state meaning, or verification. |
| “Capability already defines behavior.” | Capability defines ownership; PM must provide concrete behavior. |
