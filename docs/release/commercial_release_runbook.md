# P0 商业化订阅发布运行手册

## 状态
准备中。本文只定义发布门禁、证据和回滚流程，不声明真实商店验证已通过。

## 适用范围
- Increment：`commercial-subscription-readiness`
- Stage：`p0-commercial-readiness`
- Release work package：`P0-COM-REL-001`
- 关联测试用例：TC-COM-011、TC-COM-012、TC-COM-015、TC-COM-016、TC-COM-019、TC-COM-021、TC-COM-022

## 发布前自动门禁
| Gate | 命令 | 阻断条件 | TC |
| --- | --- | --- | --- |
| Release configuration | `scripts/check_release_configuration.sh` | 生产 API 缺失或非 HTTPS、测试登录开启、订阅商品 ID 缺失、旧支付接口仍被客户端引用 | TC-COM-011 |
| Manual external evidence plan | `python3 scripts/check_manual_external_evidence_plan.py` | 剩余人工/外部 blocker 缺少逐步执行脚本、预期结果、实际结果字段或独立审查要求 | TC-COM-012、TC-COM-015、TC-COM-019、TC-COM-021、TC-COM-022 |
| Commercial copy contract | `python3 scripts/check_commercial_copy_contract.py --strict-external` | 会员页/应用内 upsell 承诺未映射到已实现权益、仍承诺未上线能力、商店/隐私/支持外部证据缺失 | TC-COM-015、TC-COM-016 |
| Provider sandbox evidence | `python3 scripts/check_provider_sandbox_evidence.py --strict-external` | Apple sandbox 或 Google Play internal test 证据引用缺失，或 TC-COM-019 场景矩阵不完整 | TC-COM-019 |
| Store submission evidence | `python3 scripts/check_store_submission_evidence.py --strict-external` | 商店元数据、订阅条款、隐私/Data safety、隐私/支持 URL 或审核账号证据缺失 | TC-COM-021 |
| Social login configuration | `scripts/check_social_login_release_config.sh` | WeChat AppID/Universal Link 仍为占位、iOS WeChat URL scheme 未替换、Apple Sign In entitlement 缺失、Android WXEntryActivity 缺失 | TC-COM-012 |
| Commercial readiness | `scripts/check_release_readiness.sh` | 任一前置 gate 失败、签名/符号/监控 secret 缺失、商店/隐私/审核账号证据缺失、provider sandbox/internal evidence 缺失 | TC-COM-021、TC-COM-022 |

## 必需环境与证据
| Key | 来源 | 要求 |
| --- | --- | --- |
| `APP_API_BASE_URL` / `API_BASE_URL` | release secret | HTTPS 生产 API，不得为 example/local 地址 |
| `ENV` | release env | 必须为 `production` |
| `ENABLE_TEST_PHONE_LOGIN` | release env | 必须为 `false` 或未启用 |
| `WECHAT_APP_ID` | release secret | 必须为真实微信开放平台 AppID |
| `WECHAT_UNIVERSAL_LINK` | release secret | 必须为 HTTPS 且已在微信开放平台和 Associated Domains 配置 |
| `SENTRY_DSN` | release secret | 必须存在，并完成 dSYM / ProGuard mapping 上传流程 |
| Android signing secrets | release secrets | `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、`ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD` 必须存在 |
| `APPLE_SANDBOX_EVIDENCE_REF` | release var | 指向 Apple sandbox 购买、恢复、退款、过期、宽限期和账号切换证据 |
| `GOOGLE_PLAY_INTERNAL_EVIDENCE_REF` | release var | 指向 Google Play internal test 购买、恢复、退款、过期、宽限期和账号切换证据 |
| `STORE_METADATA_EVIDENCE_REF` | release var | 指向商店截图、订阅条款、隐私标签/Data safety、审核说明证据 |
| `REVIEWER_ACCOUNT_REF` | release var | 指向可用审核账号和测试步骤 |
| `SYMBOL_UPLOAD_EVIDENCE_REF` | release var | 指向 dSYM / ProGuard mapping 上传或验证证据 |
| `ROLLBACK_REHEARSAL_REF` | release var | 指向回滚流程演练或审批记录 |
| `PRIVACY_URL` / `SUPPORT_URL` | release vars | HTTPS URL，必须与商店配置一致 |
| Manual external checklist | repo document | `tests/commercial/manual_external_evidence_checklist.md` 必须列出 TC-COM-012/015/019/021/022 的人工步骤、预期结果、实际结果字段和独立审查要求 |

## 手工/外部门禁
- TC-COM-015 必须由会员页、商店元数据、隐私/支持说明截图或等价证据关闭；本地脚本只能证明仓库内文案契约。
- TC-COM-019 必须由 Apple sandbox 和 Google Play internal test 证据关闭；本地脚本不能替代真实 provider 证据。
- TC-COM-021 必须由 App Store Connect / Play Console 元数据、订阅条款、隐私/支持 URL、审核账号证据关闭。
- TC-COM-012 和 TC-COM-022 必须由原生配置截图、真实登录 smoke、release secrets/signing/symbol/rollback 证据和 strict gate 输出关闭。
- 所有人工结果必须按 `tests/commercial/manual_external_evidence_checklist.md` 的模板记录 `Actual result`、`Evidence ref`、执行人、日期和 reviewer。
- 发布负责人必须在 `docs/reports/test_report.md` 记录外部证据引用和执行日期。

## 发布步骤
1. 确认 `docs/product/increments/commercial-subscription-readiness/test_cases.md` 中 TC-COM-011、TC-COM-012、TC-COM-015、TC-COM-016、TC-COM-019、TC-COM-021、TC-COM-022 均有执行证据或明确外部阻断记录。
2. 运行 `python3 scripts/check_manual_external_evidence_plan.py`，确认人工清单仍覆盖所有剩余 blocker。
3. 按 `tests/commercial/manual_external_evidence_checklist.md` 执行 TC-COM-012、TC-COM-015、TC-COM-019、TC-COM-021、TC-COM-022 的人工步骤，并回填 evidence refs。
4. 运行 `scripts/check_release_configuration.sh`。
5. 运行 `python3 scripts/check_commercial_copy_contract.py --strict-external`。
6. 运行 `python3 scripts/check_provider_sandbox_evidence.py --strict-external`。
7. 运行 `python3 scripts/check_store_submission_evidence.py --strict-external`。
8. 运行 `scripts/check_social_login_release_config.sh`。
9. 运行 `scripts/check_release_readiness.sh`。
10. 在 tag release 前确认 provider evidence、store metadata evidence、reviewer account、privacy/support URL 均已登记。
11. 触发 `.github/workflows/release.yml` tag workflow。
12. 上传或确认 dSYM / ProGuard mapping，记录 artifact、commit、tag、证据链接。
13. 完成 rollback rehearsal 或发布负责人审批，并记录 `ROLLBACK_REHEARSAL_REF`。

## 禁止事项
- 不得把 DashScope、OpenAI、Apple、Google、WeChat、Sentry 或签名密钥写入仓库。
- 不得用本地 deterministic provider 测试替代 TC-COM-019。
- 不得在 `ENABLE_TEST_PHONE_LOGIN=true` 或 `ENV!=production` 时发布商店版本。
- 不得在会员页或商店元数据中承诺尚未上线的离线包、专属报告或其他未交付权益。
