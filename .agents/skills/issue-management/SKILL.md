---
name: issue-management
description: Use when creating, triaging, updating, or linking repository issues for this project's product and development workflow. Do not use to decide product scope, replace Product Manager classification, bypass requirements/spec/AC/TC gates, or mark implementation complete without local workflow evidence.
---

# Issue Management

## Overview

Use repository issues as tracking containers while local product, workflow, acceptance, evidence, and release artifacts remain the source of truth.

## When to Use

Use for an issue title/body or update draft, bug/follow-up/release-blocker triage, linking a branch/PR/test/report, or optional coordination after Product Manager classification.

## When NOT to Use

Do not use when scope/priority/stage/increment is unclassified, when the request is to author requirements/spec/AC/TC/architecture/evidence/release artifacts, for local edits with no issue need, when the user rejects the tracker, or when the issue would become the sole source of truth.

## Contract

- This is an ephemeral tracking method; it does not own a product/workflow artifact or create new source-of-truth paths.
- Product decisions remain in Product Base, registry, stages, increments, and `DEVELOPMENT_STATUS`; execution evidence remains in `IMPLEMENTATION_REPORT`, `TEST_REPORT`, and `QUALITY_REPORT`.
- Issue templates under `.github/ISSUE_TEMPLATE/` require a separate governance change. Persistent workflow changes route to `WORKFLOW`/Documentation Governance.
- Paths, owners, and write scopes are governed by `docs/process/governance/index.json`; default durable project documents to Chinese unless explicitly requested otherwise.

## Inputs

User issue request or update, PM classification, applicable workflow/product/increment artifacts, current reports, and existing issue/branch/PR/CI/release links.

## Outputs

Issue title/body or update draft with Summary, Classification, source-of-truth links, Scope, Non-goals, Acceptance/Test links, Owner/Checker, status, evidence, and branch/PR links; suggested labels/status/milestone/owner with priority marked suggested unless PM confirmed; blocked finding when classification or required gates are missing.

## 文档路径约定

Do not create product source-of-truth paths. Use existing workflow/product/report paths for links; issue templates are only proposed under `.github/ISSUE_TEMPLATE/` through a separate change.

## Process

1. Confirm PM classification (`product-base-consolidation`, `baseline-consolidation`, `new-feature`, `feature-increment`, `bugfix`, `refactor`, `experiment`, or `scope-change`).
2. Block and route to PM when scope/priority would be inferred.
3. Link the product object, stage/scope item, increment, FR/AC/TC, owner, and checker as available.
4. Draft the tracking sections and conservative labels; use `Refs #<id>` for planning/partial/governance work and `Closes #<id>` only with DoD evidence.
5. Preserve manual issue decisions; inspect tracker state before proposing CLI/connector updates and avoid destructive edits.

## Label taxonomy

Use the local `type:*`, `priority:*`, `status:*`, `area:*`, and `gate:*` labels only when they match current workflow evidence; priority is suggested until PM confirms it.

## Red Flags

Issue text invents requirements, scope, priority, completion, release readiness, or Capability/stage/increment; skips AC-to-TC; uses `Closes` for partial work; labels conflict with PM decisions; or links code/reports without the owning artifact.

## Verification

The issue clearly says local artifacts are authoritative; missing classification blocks; links cover applicable product scope and evidence; `Refs`/`Closes` matches DoD; no product requirements, tests, code, or release claims are created by this skill.

## Common Rationalizations

| Rationalization | Reality |
| --- | --- |
| “The issue body can define the requirement.” | Issues track work; Product Base/spec/AC remain authoritative. |
| “A merged PR closes everything.” | Close only after DoD evidence and required reports support completion. |
| “Priority is obvious.” | PM owns priority; the issue may only suggest it until confirmed. |
