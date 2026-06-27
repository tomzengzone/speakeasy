#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]

FILES = {
    "migration": ROOT / "backend/src/main/resources/db/migration/V202606070001__p0_2_followup_d_goal_autopilot_telemetry.sql",
    "entity": ROOT / "backend/src/main/java/com/speakeasy/goal/GoalAutopilotMetricEvent.java",
    "repository": ROOT / "backend/src/main/java/com/speakeasy/goal/GoalAutopilotMetricEventRepository.java",
    "service": ROOT / "backend/src/main/java/com/speakeasy/goal/GoalAutopilotTelemetryService.java",
    "goal_service": ROOT / "backend/src/main/java/com/speakeasy/goal/GoalAutopilotService.java",
    "runtime_gate": ROOT / "backend/src/main/java/com/speakeasy/goal/GoalAutopilotRuntimeGate.java",
    "test": ROOT / "backend/src/test/java/com/speakeasy/goal/GoalAutopilotTelemetryTest.java",
}

FORBIDDEN_PERSISTED_TOKENS = (
    "user_id",
    "transcript",
    "audio_ref",
    "provider_payload",
    "prompt",
    "idempotency_key",
    "notification_payload",
)

REQUIRED_EVENTS = (
    "goal_intake",
    "diagnostic_assessment",
    "plan_generation",
    "control_update",
    "next_action",
    "action_complete",
    "checkpoint",
    "projection_read",
    "quota_error",
    "provider_fallback",
    "kill_switch_event",
)


def fail(message: str) -> None:
    raise SystemExit(f"FAIL: {message}")


def read(name: str) -> str:
    path = FILES[name]
    if not path.exists():
        fail(f"missing required file: {path.relative_to(ROOT)}")
    return path.read_text(encoding="utf-8")


def main() -> None:
    migration = read("migration").lower()
    entity = read("entity").lower()
    service = read("service").lower()
    goal_service = read("goal_service")
    runtime_gate = read("runtime_gate")
    test = read("test")
    read("repository")

    if "create table goal_autopilot_metric_events" not in migration:
        fail("telemetry migration must create goal_autopilot_metric_events")
    if "user_hash" not in migration or "metric_event_id" not in migration:
        fail("telemetry migration must persist metric id and redacted user_hash")
    for forbidden in FORBIDDEN_PERSISTED_TOKENS:
        if forbidden in migration:
            fail(f"telemetry migration must not persist sensitive column token: {forbidden}")
        if forbidden in entity:
            fail(f"telemetry entity must not persist sensitive field token: {forbidden}")

    required_service_tokens = (
        "redactedUserHash",
        "goal_autopilot_telemetry_write_failed",
        "force-write-failure",
        "Telemetry must never block the user path",
        "catch (RuntimeException",
    )
    for token in required_service_tokens:
        if token not in read("service"):
            fail(f"telemetry service missing required redaction/fallback token: {token}")

    for event in REQUIRED_EVENTS:
        if event not in goal_service and event not in runtime_gate:
            fail(f"missing metric event coverage token: {event}")

    required_test_tokens = (
        "tcP02Fud016RecordsRedactedFunnelHealthAndBlockedReasonMetrics",
        "tcP02Fud016TelemetryWriteFailureFallsBackToAuditWithoutBlockingUserPath",
        "doesNotContain(RAW_DIAGNOSTIC)",
        "doesNotContain(RAW_CHECKPOINT)",
        "doesNotContain(RAW_AUDIO_REF)",
        "quota_exhausted",
        "kill_switch_active",
        "goal_autopilot_telemetry_write_failed",
    )
    for token in required_test_tokens:
        if token not in test:
            fail(f"telemetry test missing required assertion token: {token}")

    print("PASS: P0.2 Followup-D S009 telemetry redaction contract holds")


if __name__ == "__main__":
    main()
