#!/usr/bin/env python3
"""Validate P0.2 Followup-D S002 Flutter runtime source-of-truth guards."""

from __future__ import annotations

from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

ADAPTER = ROOT / "lib/features/goal_autopilot/goal_autopilot_adapter.dart"
MODELS = ROOT / "lib/features/goal_autopilot/goal_autopilot_models.dart"
PANEL = ROOT / "lib/features/goal_autopilot/goal_autopilot_panel.dart"
SURFACE = ROOT / "lib/features/goal_autopilot/goal_progress_surface.dart"
HOME = ROOT / "lib/pages/home_page.dart"
QUEUE = ROOT / "lib/features/interview/interview_expression_learning_page.dart"
WIDGET_TEST = (
    ROOT
    / "test/features/goal_autopilot/goal_autopilot_runtime_gate_widget_test.dart"
)


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def section(text: str, start: str, end: str) -> str:
    start_index = text.find(start)
    if start_index < 0:
        return ""
    end_index = text.find(end, start_index + len(start))
    if end_index < 0:
        return text[start_index:]
    return text[start_index:end_index]


def require_contains(
    errors: list[str],
    label: str,
    text: str,
    needle: str,
    reason: str,
) -> None:
    if needle not in text:
        errors.append(f"{label}: missing {needle!r} - {reason}")


def require_absent(
    errors: list[str],
    label: str,
    text: str,
    needle: str,
    reason: str,
) -> None:
    if needle in text:
        errors.append(f"{label}: found {needle!r} - {reason}")


def main() -> int:
    errors: list[str] = []
    for path in (ADAPTER, MODELS, PANEL, SURFACE, HOME, QUEUE, WIDGET_TEST):
        if not path.exists():
            errors.append(f"missing required S002 file: {path.relative_to(ROOT)}")
    if errors:
        return fail(errors)

    adapter = read(ADAPTER)
    models = read(MODELS)
    panel = read(PANEL)
    surface = read(SURFACE)
    home = read(HOME)
    queue = read(QUEUE)
    widget_test = read(WIDGET_TEST)

    require_contains(
        errors,
        "adapter",
        adapter,
        "loadRuntimeGateProjection",
        "Flutter must read runtime/projection state through the S002 gate",
    )
    require_contains(
        errors,
        "adapter",
        adapter,
        "GoalAutopilotView.runtimeUnavailable",
        "disabled backend must produce an unavailable view, not no-goal fallback",
    )
    require_contains(
        errors,
        "adapter",
        adapter,
        "GoalAutopilotRuntimeDisabledException",
        "runtime disabled errors need a typed local test hook",
    )
    require_contains(
        errors,
        "adapter",
        adapter,
        "请求失败（503",
        "generated ApiClient 503 fallback must map to backend_unavailable",
    )

    require_contains(
        errors,
        "models",
        models,
        "GoalProgressProjection.unavailable",
        "backend unavailable must render an unavailable projection shell",
    )
    unavailable_factory = section(
        models,
        "factory GoalProgressProjection.unavailable",
        "factory GoalProgressProjection.fromJson",
    )
    for needle, reason in {
        "goal: null": "unavailable projection must not synthesize a goal",
        "nextAction: null": "unavailable projection must not synthesize a plan action",
        "progress: null": "unavailable projection must not synthesize forecast facts",
        "latestCheckpoint: null": "unavailable projection must not synthesize checkpoint facts",
        "sourceRefs: const <String>[]": "unavailable projection must not fake backend source refs",
    }.items():
        require_contains(errors, "models unavailable projection", unavailable_factory, needle, reason)
    runtime_fragment_factory = section(
        models,
        "factory GoalProgressSurfaceFragment.runtimeUnavailable",
        "factory GoalProgressSurfaceFragment.fromJson",
    )
    require_contains(
        errors,
        "models unavailable fragment",
        runtime_fragment_factory,
        "safeFields: const <String>[]",
        "unavailable fragments must expose no progress fields",
    )

    require_contains(
        errors,
        "panel",
        panel,
        "value.isRuntimeUnavailable",
        "runtime disabled view must preempt edit/create/explore branches",
    )
    require_contains(
        errors,
        "panel",
        panel,
        "_GoalRuntimeUnavailable",
        "panel must render a dedicated unavailable entry state",
    )
    require_contains(
        errors,
        "panel",
        panel,
        "onRuntimeUnavailableProjection?.call(view.progressProjection)",
        "panel must hand unavailable projection to parent cache replacement",
    )
    runtime_panel = section(panel, "class _GoalRuntimeUnavailable", "class _NoActiveGoal")
    for forbidden in (
        "Set a goal",
        "Explore practice",
        "Try a sample drill",
        "Start autopilot",
        "Edit goal",
        "Generate plan",
        "Regenerate plan",
        "Checkpoint",
        "Done",
        "Turn reminders",
        "Pause autopilot",
        "Resume autopilot",
    ):
        require_absent(
            errors,
            "runtime unavailable panel",
            runtime_panel,
            forbidden,
            "disabled runtime must not expose entry or mutation controls",
        )

    home_projection_method = section(
        home,
        "Future<GoalProgressProjection?> _goalProjectionFuture()",
        "_InterviewSceneHomeStatus?",
    )
    require_contains(
        errors,
        "home projection future",
        home_projection_method,
        "loadRuntimeGateProjection()",
        "Home/Queue/Wiki surfaces must consume the S002 runtime gate projection",
    )
    require_absent(
        errors,
        "home projection future",
        home_projection_method,
        "loadOptionalProgressProjection()",
        "Home projection cache must not bypass the runtime gate",
    )
    require_contains(
        errors,
        "home projection cache replacement",
        home,
        "_replaceGoalProjectionWithRuntimeGate",
        "Home must replace cached ready projection after runtime disabled state",
    )
    require_contains(
        errors,
        "home projection cache replacement",
        home,
        "Future<GoalProgressProjection?>.value",
        "Home cache replacement must use the backend-provided unavailable projection",
    )
    require_contains(
        errors,
        "queue surface",
        queue,
        "GoalProgressQueueSurface",
        "Queue must continue rendering backend projection fragments",
    )
    require_contains(
        errors,
        "home/wiki surface",
        home,
        "GoalProgressWikiSurface",
        "Wiki must continue rendering backend projection fragments",
    )

    for forbidden in (
        "targetScore",
        "targetAbility",
        "goalCompletionClaimAllowed",
        "officialScoreEquivalence",
        "etaDate",
        "quotaRemaining",
        "releaseReady",
    ):
        require_absent(
            errors,
            "goal progress surface",
            surface,
            forbidden,
            "surfaces must not locally infer backend-owned facts",
        )

    for needle in (
        "disabled projection closes goal entry",
        "runtime backend failure does not fall back to no-goal entry",
        "unavailable projection replacement clears stale surface copy",
        "sourceRefs, isEmpty",
    ):
        require_contains(
            errors,
            "S002 widget test",
            widget_test,
            needle,
            "TC-P02-FUD-003 must cover disabled entry, backend unavailable, cache cleanup and no local refs",
        )

    if errors:
        return fail(errors)

    print("P0.2 Followup-D S002 Flutter source-of-truth check passed.")
    return 0


def fail(errors: list[str]) -> int:
    print("P0.2 Followup-D S002 Flutter source-of-truth check failed:")
    for error in errors:
        print(f"- {error}")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
