# User Flow

## MVP Flow
```text
open app -> onboarding -> scenario list -> scenario detail -> practice -> correction -> save expression -> summary -> review queue
```

## Practice Flow
```text
read prompt -> answer -> receive feedback -> retry or continue -> complete scenario -> review summary
```

## UX Rules
- The learner should always know the next action.
- Feedback should be short and specific.
- Empty states should tell the learner what to do next.
- Error states should keep work recoverable.

## P0 Commercial Subscription Flow
```text
profile / paid feature
  -> membership or paywall
  -> load server entitlement and saleable plans
  -> start Apple or Google Play purchase
  -> submit transaction token to backend verify endpoint
  -> refresh entitlement snapshot
  -> unlock paid feature or show recoverable failure
```

## P0 Restore / Downgrade Flow
```text
membership screen
  -> restore purchase
  -> backend verifies provider record
  -> restored entitlement or empty restore state
  -> later provider refund / expiry / revocation
  -> backend updates entitlement
  -> app refresh shows downgrade and next action
```

## P0 Gating Flow
```text
user opens protected feature
  -> app refreshes or reads fresh entitlement snapshot
  -> allowed: continue
  -> entitlement missing: show paywall
  -> quota exhausted: show upgrade or cooldown
  -> expired/refunded: show manage subscription or resubscribe
```

## P0 Account Deletion Flow
```text
profile settings
  -> account deletion confirmation
  -> DELETE /user/me
  -> backend deletion job accepted/completed
  -> app clears local session, learning cache, favorites, wiki, practice drafts
  -> user returns to logged-out state
```
