# Commercial Launch TODO

## P0 - Must Ship Before Store Submission

- Backend-owned AI credentials: keep DashScope, OpenAI, OSS, and provider keys only on the server. The app should receive only public runtime values through `--dart-define`, such as `API_BASE_URL`.
- Subscription entitlement service: implement `/payments/apple/verify-receipt` with App Store Server API verification, persist entitlement state on the backend, and handle renewals, refunds, grace periods, expiration, and restore flows.
- Android subscription service: implement Google Play Billing purchase, restore, and backend purchase-token verification before enabling paid Android plans.
- Account lifecycle: implement `DELETE /user/me` on the backend, delete or anonymize learning data according to the privacy policy, and return a clear success/error response to the app.
- Production auth: replace demo email/member flows with backend-backed login and user state. Disable `ENABLE_TEST_PHONE_LOGIN` in every release build.
- WeChat login: replace placeholder App ID, URL scheme, and universal link in Dart config, iOS project settings, Android manifest, and store backend callback settings.
- Apple login: enable the Sign in with Apple capability in the Apple Developer account and Xcode signing profile before App Store submission.

## P1 - Release Quality

- Store privacy: keep `ios/Runner/PrivacyInfo.xcprivacy`, App Store privacy labels, Google Play Data safety, and in-app privacy policy aligned with real providers and retained data.
- Observability: set `SENTRY_DSN` only through release secrets, upload dSYM/ProGuard mapping files, and verify crash grouping on TestFlight/internal testing.
- CI release hardening: release workflows must fail when signing or production API secrets are missing. Never generate temporary production signing keys.
- Placeholder features: either complete offline content and achievements, or hide routes and store copy until those experiences are production-ready.
- Dependency maintenance: replace discontinued packages, review major updates, and keep a tested lockfile for each release.
- Asset hygiene: keep source icon assets, remove generated desktop metadata such as `.DS_Store`, and avoid bundling non-product files.

## P2 - Store Operations

- Prepare App Store Connect and Play Console metadata: screenshots, support URL, privacy URL, review notes, subscription terms, and test reviewer account.
- Test commercial edge cases: first install, upgrade from old local storage, SMS login, Apple/WeChat login, microphone denial, speech recognition denial, offline network, purchase, restore, refund, expiration, account deletion, and crash recovery.
- Add backend rate limiting, AI cost controls, abuse detection, audit logs, and data deletion logs before opening paid traffic.
