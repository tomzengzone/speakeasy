---
name: screen-spec-generate
description: Use when approved Functional Requirements change a Flutter/mobile screen’s behavior, states, interaction, or API/AI dependencies. Do not use for trivial visual-only edits.
---

# Screen Spec Generate

## Overview

Define user-visible screen behavior and state transitions before implementation.

## When to Use

Use for a new/changed screen flow, user-visible state, or API/AI contract consumption.

## When NOT to Use

Do not use for copy/icon/spacing-only work, unchanged screen behavior or unapproved product behavior.

## Contract

Method skill for `SCREEN_SPEC`; User Flow and Usability Checklist retain their own Artifact ownership. Resolve governance facts by Artifact ID. Mandatory FR is the product upstream; API/LLM contracts are conditional engineering inputs.

## Inputs

Applicable approved FR IDs, current UX/API/AI contracts, navigation/state conventions, accessibility constraints and relevant Contract-TC needs.

## Outputs

Goal/entry, components/data, named states/transitions, visible feedback, loading/empty/error/offline/duplicate/retry behavior and testable selector needs.

## Process

1. Confirm applicable FR and actual UX fact change.
2. Start from the user’s next action; define stable components and data boundaries.
3. Cover success, slow, offline, empty, duplicate, error and retry states.
4. Map changed UX facts to Contract-TC and selected VS to VS-TC without duplicating their direct edges.
5. Run resolved validation and applicable UX review.

## Red Flags

No failure/empty state; free-form AI output treated as truth; component-owned data outside boundary; extra scope; product behavior invented in screen prose; missing stable selectors.

## Verification

A developer can implement without inventing states; every action has visible feedback; API/AI failures are handled; Contract-TC and VS-TC prove their respective boundaries.
