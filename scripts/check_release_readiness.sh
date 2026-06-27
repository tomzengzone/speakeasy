#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-strict}"
ERRORS=()

fail() {
  ERRORS+=("$1")
}

run_gate() {
  local label="$1"
  shift
  if ! "$@"; then
    fail "$label failed"
  fi
}

run_gate "release configuration" "$ROOT_DIR/scripts/check_release_configuration.sh"
run_gate "identity production trust guard" python3 "$ROOT_DIR/scripts/check_identity_release_guard.py"
run_gate "manual external evidence plan" python3 "$ROOT_DIR/scripts/check_manual_external_evidence_plan.py"
run_gate "commercial copy contract" python3 "$ROOT_DIR/scripts/check_commercial_copy_contract.py" --strict-external
run_gate "provider sandbox evidence" python3 "$ROOT_DIR/scripts/check_provider_sandbox_evidence.py" --strict-external
run_gate "AI provider sandbox evidence" python3 "$ROOT_DIR/scripts/check_ai_provider_sandbox_evidence.py" --strict-external
run_gate "paid AI external evidence" python3 "$ROOT_DIR/scripts/check_ai_external_release_evidence.py" --strict-external
run_gate "store submission evidence" python3 "$ROOT_DIR/scripts/check_store_submission_evidence.py" --strict-external

if [[ "$MODE" == "--env-only" ]]; then
  run_gate "social login release config" "$ROOT_DIR/scripts/check_social_login_release_config.sh" --env-only
else
  run_gate "social login release config" "$ROOT_DIR/scripts/check_social_login_release_config.sh"
fi

for required_secret in \
  SENTRY_DSN \
  ANDROID_KEYSTORE_BASE64 \
  ANDROID_KEYSTORE_PASSWORD \
  ANDROID_KEY_ALIAS \
  ANDROID_KEY_PASSWORD; do
  if [[ -z "${!required_secret:-}" ]]; then
    fail "$required_secret is required for release readiness"
  fi
done

for evidence_ref in \
  APPLE_SANDBOX_EVIDENCE_REF \
  GOOGLE_PLAY_INTERNAL_EVIDENCE_REF \
  DASHSCOPE_AI_SANDBOX_EVIDENCE_REF \
  AI_MEDIA_STORAGE_EVIDENCE_REF \
  AI_COST_DASHBOARD_EVIDENCE_REF \
  AI_RETENTION_POLICY_EVIDENCE_REF \
  STORE_METADATA_EVIDENCE_REF \
  REVIEWER_ACCOUNT_REF \
  SYMBOL_UPLOAD_EVIDENCE_REF \
  ROLLBACK_REHEARSAL_REF; do
  if [[ -z "${!evidence_ref:-}" ]]; then
    fail "$evidence_ref is required before commercial release"
  fi
done

for public_url in PRIVACY_URL SUPPORT_URL; do
  value="${!public_url:-}"
  if [[ -z "$value" ]]; then
    fail "$public_url is required before commercial release"
  elif [[ ! "$value" =~ ^https:// ]]; then
    fail "$public_url must use https"
  fi
done

for doc in \
  "docs/release/release_checklist.md" \
  "docs/release/rollback_plan.md" \
  "docs/release/version_log.md" \
  "docs/release/commercial_release_runbook.md" \
  "tests/commercial/manual_external_evidence_checklist.md"; do
  if [[ ! -f "$ROOT_DIR/$doc" ]]; then
    fail "missing release document: $doc"
  fi
done

if [[ -f "$ROOT_DIR/docs/release/commercial_release_runbook.md" ]] &&
  ! grep -q "TC-COM-019" "$ROOT_DIR/docs/release/commercial_release_runbook.md"; then
  fail "commercial release runbook must preserve the TC-COM-019 external provider gate"
fi

if ((${#ERRORS[@]} > 0)); then
  printf 'release readiness check failed:\n' >&2
  for error in "${ERRORS[@]}"; do
    printf -- '- %s\n' "$error" >&2
  done
  exit 1
fi

printf 'release readiness check passed\n'
