---
name: issue-management
description: Use when creating, triaging, updating, or linking repository issues for this project's product and development workflow. Do not use to decide product scope, replace Product Manager classification, bypass requirements/spec/AC/TC gates, or mark implementation complete without local workflow evidence.
---

# Issue Management

## Overview
Structure repository issues as tracking containers for the local product and development workflow. Keep Product Manager classification, Product Base, increment artifacts, acceptance criteria, test cases, traceability, and reports as the source of truth.

## When to Use
- A user asks to create, clean up, triage, label, or link an issue for project work.
- A bug, follow-up, release blocker, workflow task, or implementation slice needs an issue title/body before execution starts.
- A pull request, branch, test result, or report needs to be linked back to an existing issue.
- Product Manager has classified a request and wants optional issue tracking for coordination.

## When NOT to Use
- Product scope, priority, stage placement, or increment acceptance has not been classified by Product Manager.
- The task is to write requirements, specs, acceptance criteria, test cases, architecture, code, QA evidence, or release evidence.
- The issue would become the only source of truth for a requirement, decision, or completion claim.
- The request only needs a local code edit and no issue tracking.
- The user explicitly asks not to use the repository issue tracker.

## Inputs
- User issue request, bug report, follow-up, or status update.
- Product Manager classification when available.
- `docs/process/workflow.md`
- `docs/product/development_status.md`
- `docs/product/feature_registry.md`
- `docs/product/stages/<stage-id>.md`
- `docs/product/increments/<increment-id>/definition.md`
- `docs/product/increments/<increment-id>/requirements.md`
- `docs/product/increments/<increment-id>/spec.md`
- `docs/product/increments/<increment-id>/acceptance.md`
- `docs/product/increments/<increment-id>/test_cases.md`
- `docs/product/increments/<increment-id>/traceability.md`
- `docs/reports/implementation_report.md`
- `docs/reports/test_report.md`
- `docs/reports/quality_report.md`
- Existing issue, branch, pull request, CI, or release evidence links when provided.

## Outputs
- Issue title and body draft, or issue update/comment draft.
- Suggested labels, status, milestone, and owner/checker references.
- Explicit links to the local workflow artifacts that remain source of truth.
- Branch and pull request linking text such as `Refs #<id>` or `Closes #<id>`.
- A blocked finding when the request lacks Product Manager classification or would bypass workflow gates.

## 文档路径约定
- This skill does not create new product source-of-truth paths.
- Product decisions remain in `docs/product/development_status.md`, `docs/product/feature_registry.md`, `docs/product/stages/`, `docs/product/base/`, and `docs/product/increments/`.
- Execution and validation evidence remain in `docs/reports/implementation_report.md`, `docs/reports/test_report.md`, and `docs/reports/quality_report.md`.
- Issue templates, if added later, belong under `.github/ISSUE_TEMPLATE/` and require a separate workflow/governance change.
- Persistent updates to workflow rules belong in `docs/process/workflow.md`; do not update workflow rules from this skill unless the user explicitly asks for a governance change.

## Process
1. Confirm whether Product Manager has classified the request as `product-base-consolidation`, `baseline-consolidation`, `new-feature`, `feature-increment`, `bugfix`, `refactor`, `experiment`, or `scope-change`.
2. If classification is missing and the issue would imply product scope or priority, return a blocked finding and route back to Product Manager.
3. Identify the linked product object: feature, stage, Stage Scope Item ID, increment, FR, AC, TC, owner agent, and checker agent when available.
4. Draft the issue as a tracking artifact with these sections: Summary, Classification, Source-of-truth links, Scope, Non-goals, Acceptance/Test links, Owner/Checker, Current status, Evidence links, PR/branch links.
5. Suggest labels using the local taxonomy below. Mark priority as `suggested` unless Product Manager has confirmed it.
6. Use lifecycle language conservatively: `Refs #<id>` for planning, partial implementation, governance, or follow-up work; `Closes #<id>` only when Definition of Done evidence is complete.
7. When updating an existing issue, preserve manual decisions and only add traceability, status, evidence, or stale-field corrections supported by current artifacts.
8. If using a CLI or connector, inspect existing labels, milestones, and issue state before proposing changes. Do not invent destructive issue edits.

Recommended label taxonomy:
- `type:bug`, `type:feature`, `type:enhancement`, `type:docs`, `type:chore`, `type:workflow`, `type:research`
- `priority:critical`, `priority:high`, `priority:medium`, `priority:low`
- `status:needs-triage`, `status:needs-info`, `status:accepted`, `status:blocked`, `status:in-progress`, `status:ready-for-review`, `status:done`
- `area:backend`, `area:frontend`, `area:ai-runtime`, `area:api-contract`, `area:domain`, `area:ux`, `area:qa`, `area:devops`, `area:product`, `area:docs`, `area:workflow`, `area:release`
- `gate:needs-classification`, `gate:needs-requirements`, `gate:needs-spec`, `gate:needs-ac-tc`, `gate:needs-contract`, `gate:ready-for-implementation`, `gate:release-blocked`

## Red Flags
- The issue body defines requirements that do not exist in local product artifacts.
- The issue claims accepted scope, priority, completion, release readiness, or Product Base merge without PM/workflow evidence.
- The issue skips AC-to-TC mapping for committed implementation work.
- A PR uses `Closes` for planning, partial slices, or blocked external evidence.
- Labels or milestones imply a different Capability, stage, increment, or priority than the Product Manager decision.
- The issue links to generated code, tests, or reports but omits the owning increment or source-of-truth artifact.

## Verification
- The skill name and directory do not include external issue tracker branding.
- The issue draft clearly says local product and workflow artifacts are the source of truth.
- Every suggested issue links to V2 Capability/stage/increment artifacts when they exist.
- Missing Product Manager classification is treated as blocked, not inferred silently.
- Priority is only final when Product Manager has confirmed it.
- `Refs` versus `Closes` matches the actual workflow state and evidence.
- No product requirements, specs, ACs, tests, code, or release claims are created by this skill.

## Common Rationalizations
| Rationalization | Reality |
| --- | --- |
| "The issue explains the requirement well enough." | The issue tracks work; requirements and acceptance live in local product artifacts. |
| "We can close the issue because the PR merged." | Close only when Definition of Done evidence and required reports support completion. |
| "Priority is obvious from the bug description." | Product Manager owns priority; the issue may only suggest it unless confirmed. |
| "A tracker label is harmless." | Labels shape execution routing and must not conflict with stage, increment, or gate state. |
