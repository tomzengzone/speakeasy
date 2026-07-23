---
name: story-map-develop
description: Use when Product Manager creates, splits, rewrites, reviews, or approves User Stories and nested Child Vertical Slices. Do not use for FR, TC, or implementation.
---

# Story Map Develop

## Overview

Maintain the unique current product source for User Stories and their nested Child Vertical Slices.

## When to Use

Use when Story/VS behavior, boundary, nesting, classification or approval status changes.

## When NOT to Use

Do not use for FR, TC, Contract, delivery planning, implementation or historical product-document maintenance.

## Contract

Method skill for `STORY_MAP`. Resolve governance facts through `GOVERNANCE_INDEX`; `CAPABILITY_REGISTRY` supplies classification boundaries, not behavior.

## Inputs

PM decision, relevant current Story Map rows, applicable Capability/Sub-capability boundary, user/scenario/goal, visible outcome, state change, failure path and explicit non-goals.

## Outputs

Story rows nested under Capability sections and Child VS rows nested under one Story. Story directly records Capability classification; nesting owns the VS-to-Story edge.

## Process

1. Confirm the product decision and classification without inferring behavior from labels.
2. Write a Story with user, situation, goal and value.
3. Split independently verifiable user loops into Child VS rows with trigger, prerequisites, user choice, state change, visible result and key failure/boundary.
4. Keep one parent through nesting; do not add duplicate parent columns.
5. Only Product Manager sets `approved`; validate touched rows.

## Red Flags

Pages/modules as stories; capability text treated as behavior; formulaic CRUD slices; one VS containing independent loops; Stage/Increment delivery metadata; FR/TC/Contract body copied into the map; downstream artifacts used to manufacture completeness.

## Verification

Each approved VS has a unique approved Story parent and complete user loop; classifications exist; descriptions own row semantics; no delivery chain or downstream content is duplicated.
