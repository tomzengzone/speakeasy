#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=()

fail() {
  ERRORS+=("$1")
}

require_file() {
  local path="$1"
  if [[ ! -f "$ROOT_DIR/$path" ]]; then
    fail "missing required file: $path"
  fi
}

api_base_url="${APP_API_BASE_URL:-${API_BASE_URL:-}}"
env_name="${ENV:-}"
test_phone_login="${ENABLE_TEST_PHONE_LOGIN:-false}"
test_phone_login_normalized="$(printf '%s' "$test_phone_login" | tr '[:upper:]' '[:lower:]')"

if [[ -z "$api_base_url" ]]; then
  fail "APP_API_BASE_URL or API_BASE_URL is required"
elif [[ ! "$api_base_url" =~ ^https:// ]]; then
  fail "API base URL must use https"
elif [[ "$api_base_url" =~ (example\.com|localhost|127\.0\.0\.1|0\.0\.0\.0) ]]; then
  fail "API base URL must not use placeholder or local hosts"
fi

if [[ "$env_name" != "production" ]]; then
  fail "ENV must be production"
fi

if [[ "$test_phone_login_normalized" == "true" ]]; then
  fail "ENABLE_TEST_PHONE_LOGIN must not be true for release"
fi

require_file "lib/config/payment_config.dart"
require_file "lib/services/api_client.dart"
require_file "lib/generated/api/speakeasy_api.dart"

for product_id in \
  "com.speakeasy.plan.weekly" \
  "com.speakeasy.plan.monthly" \
  "com.speakeasy.plan.yearly"; do
  if ! grep -q "$product_id" "$ROOT_DIR/lib/config/payment_config.dart"; then
    fail "missing configured subscription product id: $product_id"
  fi
done

if grep -q "/payments/apple/verify-receipt" "$ROOT_DIR/lib/services/api_client.dart"; then
  fail "legacy Apple receipt endpoint must not be used in release client"
fi

for generated_constant in \
  "subscriptionsAppleVerify" \
  "subscriptionsGoogleVerify" \
  "subscriptionsRestore" \
  "entitlementsRefresh"; do
  if ! grep -q "$generated_constant" "$ROOT_DIR/lib/generated/api/speakeasy_api.dart"; then
    fail "generated API boundary missing $generated_constant"
  fi
done

if ((${#ERRORS[@]} > 0)); then
  printf 'release configuration check failed:\n' >&2
  for error in "${ERRORS[@]}"; do
    printf -- '- %s\n' "$error" >&2
  done
  exit 1
fi

printf 'release configuration check passed\n'
