# User Flow

## MVP Flow
```text
open app -> onboarding -> scenario list -> scenario detail -> practice -> correction -> save expression -> summary -> review queue
```

## Practice Flow
```text
read prompt -> answer -> receive feedback -> retry or continue -> complete scenario -> review summary
```

## P0.1 Expression Automation Training Flow
```text
official scene detail / resume entry
  -> load P0.1 training session for job_interview or onboarding_introduction
  -> show one action chain step and one micro-action
  -> learner completes listen / choose / say / shadow / fill / continue-under-prompt
  -> voice-first submit
  -> ASR / scoring / AI candidate feedback
  -> deterministic planner decides retry, hint change, continue, pressure check or recap
  -> learner retries or continues
  -> recap remains visible
  -> learning evidence candidate is written or marked retryable
```

## P0.1 Fallback Flow
```text
micro-action active
  -> mic denied / ASR failed / TTS failed / AI schema failed / scoring unavailable
  -> preserve current session and learner input where possible
  -> show recoverable error with retry, re-record, text fallback, exit, or recap
  -> deterministic planner resumes from previous valid state
```

## P0.1 Pressure Check Flow
```text
consecutive pass
  -> planner lowers hint or starts session-only pressure check
  -> learner answers a short follow-up or near-scene prompt
  -> pass: continue next action step or recap
  -> fail: return to higher hint retry
```

## UX Rules
- The learner should always know the next action.
- Feedback should be short and specific.
- Empty states should tell the learner what to do next.
- Error states should keep work recoverable.
- P0.1 training should show one primary micro-action at a time.
- P0.1 text answer is a fallback path, not the default speaking path.
- P0.1 pressure check stays inside the current session and must not imply cross-day scheduling or full L0-L5 mastery.

- 学习者应始终知道下一步动作。
- 反馈应简短且具体。
- 空状态应告诉学习者接下来做什么。
- 错误状态应让已完成内容保持可恢复。
- P0.1 训练一次只展示一个主要微动作。
- P0.1 文本回答是兜底路径，不是默认口语路径。
- P0.1 pressure check 只存在于当前 session 内，不得暗示跨天排期或完整 L0-L5 掌握。

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
