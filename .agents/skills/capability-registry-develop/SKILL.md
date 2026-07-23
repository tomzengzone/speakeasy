---
name: capability-registry-develop
description: Use when Product Manager needs to create, change, split, merge, deprecate, map, or ready-gate Capability and Sub-capability entries in docs/product/feature_registry.md; Do not use to define Story/Slice behavior, delivery stage scope, requirements, specifications, acceptance criteria, tests, architecture, or implementation.
---

# Capability Registry Develop

## Overview

Propose and quality-gate PM-owned V2 Capability/Sub-capability facts. This skill supplies the method and findings; Product Manager owns product truth and approval.

## When to Use

Use for candidate destination, Capability/Sub-capability add or boundary change, split/merge/deprecate proposals, V1-to-V2 mapping, format checks, and ready-gate review of `CAPABILITY_REGISTRY`.

## When NOT to Use

Do not use for Story/Slice behavior, delivery planning, FR/Spec/AC/TC, technical contracts, implementation, tests, or registry path/source-of-truth changes. Route those to their owning workflow.

## Contract

- Method skill for `CAPABILITY_REGISTRY`; resolve path and ownership through the governance index.
- Drafts and findings are ephemeral until PM approval. Persistent semantic edits require `python scripts/validate_capability_registry.py`; Product Object Governance Check runs only when `G-INDEPENDENT-CHECK` applies.
- `docs/process/governance/index.json` is authoritative for path, lifecycle, write scope, and checker. No downstream artifact is created or rewritten by this skill.

## Inputs

PM-authorized outcome, responsibility, observable behavior, boundaries, non-goals, rationale, target/parent IDs, change mode, relevant registry rows, and affected downstream references. Read only the relevant sections; repository-wide inventory is reserved for identity, split, merge, or deprecation impact.

For add, boundary change, split, merge, deprecate, or unresolved destination work, read [structural change gates](references/structural-change-gates.md) before drafting. Do not load it for editorial or format-only checks.

## Outputs

Gate A destination finding, Gate B granularity finding, current-format draft, identity/boundary impact, omitted scope, migration direction when applicable, ready-gate result, and PM/checker handoff. Never emit an approved product fact.

## 文档路径约定

Persist only to `docs/product/feature_registry.md`; use conditionally selected references and assets as method support, not product sources.

## Registry format

```text
## CAP-<PREFIX> - <Capability name>
### Capability
Capability ID | Capability slug | Capability name | Business type | Owner | Lifecycle status | Owns | Does not own | Primary outcome | Adjacent capabilities | Downstream prefix | Legacy mapping
### Level-1 Sub-capabilities
Capability ID | Sub-capability ID | Sub-capability name | Owns | Does not own | Entry / precondition | Output / state | Related FR prefix | Status
## Legacy Mapping
V1 slug | V2 mapping | Migration note
```

Headings and row IDs must agree. IDs, slugs, and prefixes are unique and stable. Format/schema changes are separate governance work; no parallel flat schema is allowed.

## Gate A — destination

Classify as `new-capability`, `existing-capability-change`, `new-sub-capability`, `existing-sub-capability-change`, `story-slice`, `stage-increment`, `technical-support-object`, or `insufficient-information`. PM confirms object type, target/provisional ID, parent when applicable, and change mode. Missing confirmation blocks Gate B and persistence. Non-registry destinations stop and hand off.

Use durable user/business outcome, stable responsibility, observable behavior, owns/excludes, and non-goals. Names, screens, stages, domains, components, providers, or code labels are not evidence of Capability identity.

## Gate B — granularity

- Capability: independent long-lived outcome and complete boundary spanning more than one Story/Slice or delivery unit; compare the two nearest Capabilities by outcome, owns, excludes, and adjacency.
- Sub-capability: confirmed parent and stable first-level responsibility with explicit entry, output, and exclusions; compare nearest siblings and show value within the parent boundary.
- Too broad, too narrow, or already owned returns to Gate A. Gate B is `pass` or `fail`; it never changes PM’s destination.

## Process

1. Restate scope and source facts; read the relevant registry rows.
2. Run Gate A; stop for PM confirmation when unresolved.
3. Run Gate B and current-format/identity checks.
4. Produce the draft, impact inventory, omitted scope, and handoff.
5. For persistence, obtain PM approval, run the validator, and obtain independent checker evidence when `G-INDEPENDENT-CHECK` applies.

## Red Flags

Capability inferred from a label or code; CRUD/screen/stage treated as Capability; missing PM destination; provisional rows persisted; sibling/parent comparison absent; reused IDs; unexplained one-way adjacency; downstream artifacts auto-edited; or lifecycle changes accepted without schema support.

## Verification

Destination and gate applicability are explicit; format, IDs, parents, and adjacency validate; draft and approval are distinct; impact and omitted scope are concrete; no behavior or downstream scope is invented; persistence has PM approval and any Gate-required checker evidence.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The name proves it is a Capability.” | Identity depends on durable outcome, responsibility, boundary, and PM confirmation. |
| “Put V2 successors in Legacy Mapping.” | Unsupported lifecycle data requires schema governance, not free-text encoding. |
