# Architecture and SWC Traceability

Read this reference only for whole-app, architecture, cross-layer, or implementation-impacting SWC review.

## Architecture coverage

Declare scope mode: whole-app, stage, increment, capability, refactor, or experiment. Inventory applicable Product Base, baseline, Capability Registry, roadmap, stages, increments, future boundaries, non-goals, current code, contracts, release artifacts, and reports. Classify omissions as blocker, deferred, or not applicable.

For whole-app conclusions, require a coverage matrix across frontend, backend, data, API, AI/runtime, security, tests, release, and operations. Technology recommendations also require alternatives, constraints, trade-offs, operational fit, and rollback cost. An ADR does not turn incomplete exploration into an accepted source of truth.

## SWC evidence

Before implementation-impacting work, require the global SWC baseline, SWC catalog, increment `swc_allocation.md`, applicable stable Flow IDs, concrete code paths, and reuse/forbidden-duplicate decisions. Brownfield work also requires Existing Implementation Baseline and Delta From Existing Baseline.

Run `python scripts/check_swc_allocation.py --scope changed --include-worktree`, or record an evidence-backed no-impact decision when the Gate permits it. Unknown components, unallocated changed paths, missing baseline/delta, or incomplete coverage cannot Pass.
