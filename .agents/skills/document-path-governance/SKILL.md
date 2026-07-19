---
name: document-path-governance
description: Use when project documentation needs a canonical path, document owner, source-of-truth decision, path template, or skill/agent input-output path audit. Do not use for judging whether the content inside an already correctly placed document is complete or well scoped.
---

# Document Path Governance

## Overview

Decide canonical documentation location, accountable owner, source of truth, I/O path, lifecycle, and contributor scope so artifacts do not drift or collide.

## When to Use

Use for a new/moved/renamed document category, duplicate locations, source-of-truth conflict, skill `Inputs`/`Outputs`/path audit, or agent `Allowed Paths` audit.

## When NOT to Use

Do not use for content completeness (`document-content-contract`), cross-stage chain checks (`document-traceability-check`), ordinary document generation, application code, or Capability semantic operations (`capability-registry-develop`).

## Contract

- `docs/process/governance/index.json` and its Artifact shards are the authority for canonical path templates, owner, lifecycle, direct inputs, stable ephemeral outputs, checker candidate, and contributor mutable scope. The canonical path is the persistent self-output.
- Long legacy path lists are migration evidence only; do not create a second registry. `skill` is a method, not an accountable owner unless the Artifact contract says otherwise.
- Persistent path-review findings use declared `QUALITY_REPORT` contributor scope; default durable project documents to Chinese unless explicitly requested otherwise.

## Inputs

Contract index and relevant shards, current `docs/` tree, changed/target `SKILL.md` and bundled resources, `.codex/agents/*.toml`, workflow/DoD/quality standard, and the requested new path or conflict.

## Outputs

Canonical path/owner/source-of-truth decision, I/O and lifecycle mapping, duplicate/legacy migration plan, agent Allowed Paths coverage finding, and scoped quality evidence when requested. Do not author the target document’s content.

## 文档路径约定

Use Artifact IDs and `canonical_path` from the contract. Product Base, increments, architecture/domain/AI/UX, reports, release, skills, native agents, and governance files must be resolved through the index; historical paths are evidence only, not active routing sources.

## Product-object boundaries

Capability is a stable PM-owned classification in `CAPABILITY_REGISTRY`; Story/Slice is the product source; Stage/Increment organize delivery; Base is living stable behavior; Baseline is a frozen snapshot; Change Request records scope changes. Do not substitute one object’s path for another or change registry fields/IDs/migrations here.

## Process

1. Classify the target object and read its Artifact contract.
2. Resolve existing source of truth before proposing a new path; check duplicates and owner/lifecycle collisions.
3. Verify skill inputs/outputs and agent outputs are covered by allowed paths and contributor scopes.
4. For moves, record old path, new path, reference updates, rollback/compatibility window, and archive status.
5. Require a separate content-contract review when content boundaries change and a traceability review when links/evidence change.
6. Run `python scripts/validate_agent_skills.py`, contract validation, language, and write-scope gates after edits.

## Red Flags

Duplicate canonical locations, outputs described only as “updated docs,” agent outputs outside Allowed Paths, ad-hoc directories, path rules that collide with API/OpenAPI or SWC source-of-truth, or a baseline treated as living input.

## Verification

Every target has one canonical path template, accountable owner, lifecycle, direct I/O, and an explicit checker candidate or `null`; all related skills/agents point to it; contributor writes are scoped; legacy references and rollback are explicit; no Capability procedure is copied.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “Put it somewhere convenient and fix paths later.” | Every reference hardens a path and makes migration costlier. |
| “The skill knows where it writes.” | Explicit contract paths are required for repeatable routing and scope checks. |
