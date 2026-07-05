#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-strict}"
ERRORS=()

fail() {
  ERRORS+=("$1")
}

wechat_app_id="${WECHAT_APP_ID:-}"
wechat_universal_link="${WECHAT_UNIVERSAL_LINK:-}"

if [[ -z "$wechat_app_id" || "$wechat_app_id" == "wx0000000000000000" ]]; then
  fail "WECHAT_APP_ID must be a real WeChat app id"
elif [[ ! "$wechat_app_id" =~ ^wx[0-9A-Za-z]{8,}$ ]]; then
  fail "WECHAT_APP_ID must look like a WeChat app id"
fi

if [[ -z "$wechat_universal_link" || "$wechat_universal_link" == "https://your-domain.com/app/" ]]; then
  fail "WECHAT_UNIVERSAL_LINK must be configured"
elif [[ ! "$wechat_universal_link" =~ ^https:// ]]; then
  fail "WECHAT_UNIVERSAL_LINK must use https"
fi

if [[ "$MODE" != "--env-only" ]]; then
  if grep -q "wx0000000000000000" "$ROOT_DIR/ios/Runner/Info.plist"; then
    fail "iOS Info.plist still contains the placeholder WeChat URL scheme"
  fi

  if ! grep -R -q "com.apple.developer.applesignin" "$ROOT_DIR/ios" 2>/dev/null; then
    fail "iOS Sign in with Apple entitlement is not present"
  fi

  if [[ ! -f "$ROOT_DIR/android/app/src/main/kotlin/com/speakeasy/app/wxapi/WXEntryActivity.kt" ]]; then
    fail "Android WeChat WXEntryActivity is missing"
  fi
fi

if ((${#ERRORS[@]} > 0)); then
  printf 'social login release config check failed:\n' >&2
  for error in "${ERRORS[@]}"; do
    printf -- '- %s\n' "$error" >&2
  done
  exit 1
fi

printf 'social login release config check passed\n'
