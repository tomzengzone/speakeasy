# Usability Checklist

- [ ] User can identify the next action within 3 seconds.
- [ ] Primary action is visually clear.
- [ ] Loading state explains what is happening.
- [ ] Error state preserves user input.
- [ ] Feedback is no longer than needed.
- [ ] Correction tone is supportive and specific.
- [ ] Mobile layout avoids dense text blocks.
- [ ] Saved or completed state is visible immediately.
- [ ] Empty state includes a useful next step.
- [ ] MVP scope does not introduce hidden workflows.

## P0 Commercial

- [ ] Membership page shows server entitlement state and does not rely on local `memberPlan` as final truth.
- [ ] Purchase, restore, empty restore, invalid receipt, and provider unavailable states each have a clear next action.
- [ ] Paywall and protected feature entry use the same gating result for scenario list, scenario detail, training entry, AI feedback, and reports.
- [ ] Expired, refunded, revoked, grace-period, and quota-exhausted states are visually distinct.
- [ ] Account deletion confirmation explains cloud deletion/anonymization and local cleanup before the destructive action.
- [ ] Commercial copy matches store metadata, privacy copy, and actual implemented entitlement rules.

## P0.1 Expression Automation Training

- [ ] The learner sees exactly one primary micro-action in the active training panel.
- [ ] The current action chain step is visible but does not crowd the main action.
- [ ] Voice answer controls include record, cancel, submit and re-record states.
- [ ] Text fallback appears only after mic denial, ASR failure or debug mode.
- [ ] Hint level changes are visible through concrete support: sentence frame, options, chunk shadowing or model-then-retry.
- [ ] Feedback names one main issue and one next action.
- [ ] Pronunciation unavailable state does not block progress.
- [ ] Pressure check is visually distinct from normal retry and stays session-only.
- [ ] Recoverable error preserves user input or recap where possible.
- [ ] Recap stays available even when learning evidence write-back is retryable.
- [ ] P0.1 screens do not show third-scene creation, arbitrary scene generation, cross-day schedule, full L0-L5 mastery or commercial gating as completion conditions.
