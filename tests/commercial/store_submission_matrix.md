# Store Submission Matrix：商业化订阅上线准备

## 状态
External pending - 本矩阵定义 TC-COM-021 必需商店资料证据，不声明 App Store Connect 或 Play Console 已配置完成。

## 适用范围
- Increment：`commercial-subscription-readiness`
- Stage Scope：COM-SI-012
- Requirement：FR-COM-012
- Acceptance：AC-COM-014
- Test Case：TC-COM-021

## Evidence Contract
| Field | Requirement |
| --- | --- |
| Store metadata evidence ref | `STORE_METADATA_EVIDENCE_REF` must point to App Store Connect / Play Console metadata, screenshots, subscription product pages, and review notes. |
| Reviewer account ref | `REVIEWER_ACCOUNT_REF` must point to reviewer login credentials or a secure credential vault reference plus test steps. |
| Privacy URL | `PRIVACY_URL` must be HTTPS and match store configuration. |
| Support URL | `SUPPORT_URL` must be HTTPS and match store configuration. |
| Manual execution checklist | `tests/commercial/manual_external_evidence_checklist.md` defines step-by-step execution, expected results, actual result fields, and independent review requirements. |
| Local gate | `python3 scripts/check_store_submission_evidence.py` validates this matrix and reports missing external refs. |
| Strict release gate | `python3 scripts/check_store_submission_evidence.py --strict-external` fails until external refs and URLs are supplied. |

## Submission Matrix
| Area | Required evidence | Current status | Evidence ref |
| --- | --- | --- | --- |
| App Store metadata | App name, subtitle, description, keywords, age rating, category, localized screenshots | external-pending | `STORE_METADATA_EVIDENCE_REF` |
| Play Console metadata | App title, short/full description, category, content rating, graphics, screenshots | external-pending | `STORE_METADATA_EVIDENCE_REF` |
| Subscription products | Weekly/monthly/yearly product ids, localized names, prices, durations, renewal disclosure | external-pending | `STORE_METADATA_EVIDENCE_REF` |
| Subscription terms | Auto-renewal terms, cancellation path, billing disclosure, restore purchase instructions | external-pending | `STORE_METADATA_EVIDENCE_REF` |
| Privacy labels / Data safety | Data collection/use declarations aligned with production backend and analytics/crash reporting | external-pending | `STORE_METADATA_EVIDENCE_REF` |
| Privacy URL | Public HTTPS privacy policy URL configured in stores | external-pending | `PRIVACY_URL` |
| Support URL | Public HTTPS support/contact URL configured in stores | external-pending | `SUPPORT_URL` |
| Reviewer account | Secure reviewer account credentials/reference and step-by-step review notes | external-pending | `REVIEWER_ACCOUNT_REF` |

## External Blockers
- App Store Connect and Play Console access is required.
- Public privacy/support URLs must be deployed and configured in the stores.
- Reviewer credentials must be provided through a secure channel or credential vault; they must not be committed to the repository.
