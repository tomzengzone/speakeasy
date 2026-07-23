---
name: document-path-governance
description: Use when project documentation needs a canonical path, source-of-truth decision, owner/lifecycle audit, or Agent/Skill path-reference review.
---

# Document Path Governance

## Overview

Audit or propose document routing while keeping canonical path, owner, lifecycle, inputs and scope in the Governance Contract.

## When to Use

Use for new/moved/renamed categories, duplicate locations, source conflicts, or Agent/Skill operational pointer audits.

## When NOT to Use

Do not use for document content completeness, traceability semantics, ordinary generation or application code.

## Contract

Resolve all path/owner/lifecycle/input/contributor facts by Artifact ID from `GOVERNANCE_INDEX`; do not make this Skill another registry.

## Inputs

Relevant Artifact IDs/records, current tree, affected Agent/Skill definitions, referenced resources and requested routing decision.

## Outputs

Proposed contract change or audit finding identifying duplicates, stale refs and operational pointers. Only the owning Governance Contract edit can establish a path.

## Process

1. Classify the artifact and resolve its current contract record.
2. Check source collisions and active versus historical references.
3. Verify Agent/Skill references use Artifact IDs; allow exact path/command only when explicitly marked `Derived operational pointer` and contract-aligned.
4. Route content or traceability changes to their methods.
5. Validate the owning contract and active definitions.

## Red Flags

Path established only in a Skill/Agent; duplicate canonical locations; legacy fallback; copied owner/lifecycle/dependencies; unregistered template treated as authority.

## Verification

Each active Artifact resolves uniquely; operational pointers match the contract; historical paths are not active sources; no non-owning layer claims governance authority.
