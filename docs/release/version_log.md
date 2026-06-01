# Version Log

| Version | Date | Summary | Risk | Rollback |
| --- | --- | --- | --- | --- |
| 0.0.0 | TBD | Sprint 0 process baseline | Low | Revert documentation-only commit |
| 0.1.0-mvp-backend-stage | 2026-05-29 | MVP backend/database foundation through client QA release: backend persistence/API increments, generated OpenAPI Dart boundary, full backend/Flutter/contract evidence | Medium | Revert the stage increment commits together, restore the prior OpenAPI/Dart drift manifest, rerun backend/Flutter/contract gates, and keep audit/deletion records preserved |
| 0.2.0-p0-commercial-readiness | TBD | P0 commercial readiness: subscription/payment boundary, Flutter subscription integration, release preflight scripts, provider/store evidence gates, and AI provider production hardening for media upload, persistent TTS cache, DashScope evidence, cost dashboard and AI data strategy | High | Pause store/paid AI rollout, preserve payment/audit/media records, revert commercial client/backend changes together, disable real provider config, rerun release readiness, payment provider gates and AI provider hardening gates |
