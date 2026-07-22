---
name: skill-quality-check
description: Use when project-local Skill definitions or linked resources change and need structural and semantic governance validation. Do not use for application code review.
---

# Skill Quality Check

## Overview

Review active Skills for reusable current-state methods, clear triggers and separation from Governance Contract authority.

## When to Use

Use after changing `SKILL.md`, a directly linked Skill resource, the skill quality standard or the skill validator.

## When NOT to Use

Do not use for application behavior/code quality, ordinary documentation or retired/historical packages outside the active graph.

## Contract

Method skill for `SKILL_DEFINITION`, `SKILL_RESOURCE` and `SKILL_QUALITY_STANDARD`. Resolve governance facts by Artifact ID; findings are ephemeral unless a governed report is explicitly requested.

## Inputs

Changed active Skill definitions, their directly linked existing resources, current quality standard, relevant Artifact/Gate records and validator output.

## Outputs

Pass/block findings with exact file refs, authority-separation corrections and validator evidence.

## Process

1. Build scope from active method Skills and directly linked resources, not the entire skills directory.
2. Run `python3 scripts/validate_agent_skills.py`.
3. Check triggers/non-triggers, required method sections, bounded inputs/outputs, red flags and executable verification.
4. Reject copied canonical path/owner/lifecycle/dependency/Gate authority; allow only contract-aligned pointers explicitly marked `Derived operational pointer`.
5. Confirm retired Skills are absent from discovery and historical instructions are not active fallback.

## Red Flags

Always-use triggers; procedure history in active instructions; second governance registry; unlinked resources; tombstone Skill; duplicated behavior or output authority; validator ignored.

## Verification

Validator exits zero; active definitions contain reusable current-state obligations only; all method targets resolve; operational pointers align; retired packages are undiscoverable.
