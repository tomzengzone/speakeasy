# User Flow

## MVP Flow
```text
open app -> onboarding -> scenario list -> scenario detail -> practice -> correction -> save expression -> summary -> review queue
```

## Practice Flow
```text
read prompt -> answer -> receive feedback -> retry or continue -> complete scenario -> review summary
```

## Content 001/002 目录与精确版本详情流程

```text
content_asset_entry
  -> GET /scenarios without query/category
  -> content_theme_catalog shows every published+visible theme in API order
  -> learner selects theme_card
  -> GET /scenarios/{scenario_id}/courses
  -> selected_theme_course_summaries shows every current published+visible summary in API order
  -> learner compares title_en / summary_zh / one CEFR on course_summary_card
  -> card carries exact course_id + course_version_id
  -> GET /courses/{course_id}/versions/{course_version_id}
  -> course_detail_header shows the same version title / summary / CEFR / positive duration and unit
  -> learner reads and judges fit/time
  -> back restores the same selected theme, course list scroll position and focused card
```

## Content 真实空、失败与恢复流程

```text
GET /scenarios returns 200 scenarios: []
  -> show true catalog empty state

published+visible theme returns 200 courses: []
  -> retain theme_card in catalog
  -> show true course-list empty state
  -> return to the same theme catalog context

catalog or course read returns CONTENT_READ_UNAVAILABLE / 503
  -> do not show empty or partial success
  -> retain known selection/list context only for the same learner/auth context
  -> show retry
  -> retry the same request
  -> success replaces the state; repeated failure keeps recovery available

any content read returns 401
  -> clear learner-specific body
  -> re-authenticate
  -> retry in the new authenticated context
```

## Content 精确版本不可用与返回流程

```text
course_summary_card provides exact course_id + course_version_id
  -> exact detail request only; no latest/other-course/adjacent-CEFR fallback
  -> 200: show loaded detail, including neutral decorative background when background_asset_ref is null
  -> CONTENT_READ_UNAVAILABLE / 503: retain source theme/list/scroll return context and offer retry
  -> privacy-safe 404: clear old detail body and show "内容暂不可用" without probing why
  -> back restores the same course list context

logout / learner switch / authentication-context change
  -> clear prior learner-specific catalog, list and detail bodies
  -> cached body or ETag never becomes visibility truth
```

Content 001/002 只覆盖浏览与阅读判断；不增加开始学习动作、学习阶段、训练、AI、media、scoring、CMS workflow 或 authored inventory 行为，其他 Course 入口只保留未来兼容 seam。

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
