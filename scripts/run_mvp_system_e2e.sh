#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SUITE="smoke"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --suite)
      SUITE="${2:-}"
      shift 2
      ;;
    *)
      echo "[e2e] unknown argument: $1" >&2
      exit 2
      ;;
  esac
done

case "$SUITE" in
  smoke)
    FLUTTER_TEST_FILE="integration_test/mvp_system_smoke_test.dart"
    ;;
  scene-catalog)
    FLUTTER_TEST_FILE="integration_test/mvp_system_scene_catalog_test.dart"
    ;;
  learning-memory)
    FLUTTER_TEST_FILE="integration_test/mvp_system_learning_memory_test.dart"
    ;;
  practice-feedback)
    FLUTTER_TEST_FILE="integration_test/mvp_system_practice_feedback_test.dart"
    ;;
  profile-settings)
    FLUTTER_TEST_FILE="integration_test/mvp_system_profile_settings_test.dart"
    ;;
  membership-boundary)
    FLUTTER_TEST_FILE="integration_test/mvp_system_membership_boundary_test.dart"
    ;;
  commercial-boundary)
    FLUTTER_TEST_FILE="integration_test/commercial_boundary_test.dart"
    ;;
  p0-1-training-loop)
    FLUTTER_TEST_FILE="integration_test/p0_1_training_loop_test.dart"
    ;;
  *)
    echo "[e2e] unsupported suite: $SUITE" >&2
    exit 2
    ;;
esac

need_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "[e2e] missing required command: $1" >&2
    exit 127
  fi
}

pick_free_port() {
  python3 -c 'import socket; s=socket.socket(); s.bind(("127.0.0.1", 0)); print(s.getsockname()[1]); s.close()'
}

need_cmd postgres
need_cmd initdb
need_cmd pg_ctl
need_cmd psql
need_cmd mvn
need_cmd flutter
need_cmd curl
need_cmd python3

if [[ ! -f "$ROOT_DIR/$FLUTTER_TEST_FILE" ]]; then
  echo "[e2e] suite '$SUITE' is planned but not implemented: $FLUTTER_TEST_FILE" >&2
  exit 3
fi

if [[ -z "${JAVA_HOME:-}" ]]; then
  if [[ -x /usr/libexec/java_home ]]; then
    JAVA_HOME="$(/usr/libexec/java_home -v 17 2>/dev/null || true)"
  fi
  if [[ -z "${JAVA_HOME:-}" && -d /opt/homebrew/opt/openjdk@17 ]]; then
    JAVA_HOME="/opt/homebrew/opt/openjdk@17"
  fi
  export JAVA_HOME
fi

if [[ -z "${JAVA_HOME:-}" ]]; then
  echo "[e2e] JAVA_HOME is not set and Java 17 could not be resolved" >&2
  exit 127
fi

PG_PORT="${SPEAKEASY_E2E_PG_PORT:-$(pick_free_port)}"
BACKEND_PORT="${SPEAKEASY_E2E_BACKEND_PORT:-$(pick_free_port)}"
OPS_BEARER_TOKEN="${SPEAKEASY_E2E_OPS_BEARER_TOKEN:-ops-e2e-token}"
AI_PROVIDER="${SPEAKEASY_E2E_AI_PROVIDER:-deterministic}"
E2E_ROOT="${TMPDIR:-/tmp}/speakeasy-mvp-system-e2e-$$"
PGDATA="$E2E_ROOT/postgres"
E2E_HOME="$E2E_ROOT/home"
E2E_HIVE_NAMESPACE="mvp_system_e2e_$$"
POSTGRES_LOG="$E2E_ROOT/postgres.log"
BACKEND_LOG="$E2E_ROOT/backend.log"
FLUTTER_LOG="$E2E_ROOT/flutter.log"
BACKEND_PID=""

cleanup() {
  local code=$?
  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
    wait "$BACKEND_PID" >/dev/null 2>&1 || true
  fi
  if [[ -d "$PGDATA" ]]; then
    pg_ctl -D "$PGDATA" stop -m fast >/dev/null 2>&1 || true
  fi
  echo "[e2e] logs preserved at $E2E_ROOT"
  exit "$code"
}
trap cleanup EXIT INT TERM

mkdir -p "$E2E_ROOT" "$E2E_HOME"

echo "[e2e] initializing PostgreSQL in $PGDATA"
initdb -D "$PGDATA" -A trust -U speakeasy >"$E2E_ROOT/initdb.log" 2>&1
pg_ctl -D "$PGDATA" -l "$POSTGRES_LOG" -o "-p $PG_PORT -h 127.0.0.1" start >/dev/null

for _ in {1..40}; do
  if psql "postgresql://speakeasy@127.0.0.1:$PG_PORT/postgres" -c "select 1" >/dev/null 2>&1; then
    break
  fi
  sleep 0.25
done

psql "postgresql://speakeasy@127.0.0.1:$PG_PORT/postgres" -c "select 1" >/dev/null
echo "[e2e] PostgreSQL ready on 127.0.0.1:$PG_PORT"

echo "[e2e] starting backend on 127.0.0.1:$BACKEND_PORT"
(
  cd "$ROOT_DIR/backend"
  SPEAKEASY_DB_URL="jdbc:postgresql://127.0.0.1:$PG_PORT/postgres" \
  SPEAKEASY_DB_USERNAME="speakeasy" \
  SPEAKEASY_DB_PASSWORD="" \
  SPEAKEASY_OPS_BEARER_TOKEN="$OPS_BEARER_TOKEN" \
  SPEAKEASY_AI_PROVIDER="$AI_PROVIDER" \
  SERVER_PORT="$BACKEND_PORT" \
  JAVA_HOME="$JAVA_HOME" \
  mvn -Dmaven.repo.local="$ROOT_DIR/.m2/repository" -DskipTests spring-boot:run
) >"$BACKEND_LOG" 2>&1 &
BACKEND_PID=$!

BACKEND_READY=0
for _ in {1..360}; do
  if curl -fsS -H "Authorization: Bearer $OPS_BEARER_TOKEN" "http://127.0.0.1:$BACKEND_PORT/v1/admin/release-health" >/dev/null 2>&1; then
    BACKEND_READY=1
    break
  fi
  if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    echo "[e2e] backend exited before readiness" >&2
    tail -120 "$BACKEND_LOG" >&2 || true
    exit 1
  fi
  sleep 0.5
done

if [[ "$BACKEND_READY" != "1" ]]; then
  echo "[e2e] backend readiness timed out" >&2
  tail -120 "$BACKEND_LOG" >&2 || true
  exit 1
fi

curl -fsS -H "Authorization: Bearer $OPS_BEARER_TOKEN" "http://127.0.0.1:$BACKEND_PORT/v1/admin/release-health" >/dev/null
echo "[e2e] backend ready with /v1 context path"

echo "[e2e] running Flutter suite '$SUITE' on macOS"
(
  cd "$ROOT_DIR"
  HOME="$E2E_HOME" \
  flutter test -d macos "$FLUTTER_TEST_FILE" \
    --dart-define=ENV=e2e \
    --dart-define=API_BASE_URL="http://127.0.0.1:$BACKEND_PORT/v1" \
    --dart-define=ENABLE_TEST_PHONE_LOGIN=true \
    --dart-define=SPEAKEASY_HIVE_NAMESPACE="$E2E_HIVE_NAMESPACE" \
    --dart-define=SPEAKEASY_DISABLE_SHARED_PREFS_MIGRATION=true \
    --dart-define=SPEAKEASY_DISABLE_GLOBAL_ERROR_HOOKS=true
) 2>&1 | tee "$FLUTTER_LOG"

echo "[e2e] suite '$SUITE' passed"
