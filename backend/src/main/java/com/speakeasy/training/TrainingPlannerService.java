package com.speakeasy.training;

import java.util.List;
import org.springframework.stereotype.Service;

@Service
public class TrainingPlannerService {
  public static final String PLANNER_VERSION = "p01-training-planner-v1";
  public static final String ACTION_CHAIN_VERSION = "p01-action-chain-v1";

  private static final List<StepDefinition> STEPS = List.of(
      new StepDefinition("opening", "Opening", "SayOne"),
      new StepDefinition("explain_purpose", "Explain purpose", "FillOne"),
      new StepDefinition("express_view", "Express view", "SayOne"),
      new StepDefinition("respond_follow_up", "Respond to follow-up", "ContinueUnderPrompt"),
      new StepDefinition("confirm_next_step", "Confirm next step", "ChooseOne"),
      new StepDefinition("closing", "Closing", "SayOne"));

  public PlannerDraft decide(TrainingSession session, AttemptSignal signal) {
    return switch (signal.outcome()) {
      case "recoverable" -> new PlannerDraft(
          "recoverable_error",
          "recoverable_error",
          session.getCurrentStepKey(),
          session.getCurrentMicroAction(),
          session.getHintLevel(),
          cleanReason(signal.reasonCode(), "recoverable_failure"));
      case "failure" -> failureDecision(session, signal);
      case "pressure_passed" -> advanceOrRecap(session, cleanReason(signal.reasonCode(), "pressure_check_passed"));
      default -> successDecision(session, signal);
    };
  }

  public PlannerDraft hint(TrainingSession session) {
    String raised = raiseHint(session.getHintLevel());
    return new PlannerDraft(
        "raise_hint",
        "ready",
        session.getCurrentStepKey(),
        session.getCurrentMicroAction(),
        raised,
        "hint_requested_raise_support");
  }

  public PlannerDraft pressureCheck(TrainingSession session) {
    return new PlannerDraft(
        "pressure_check",
        "pressure_check",
        session.getCurrentStepKey(),
        "ContinueUnderPrompt",
        lowerHint(session.getHintLevel()),
        "manual_pressure_check_requested");
  }

  public PlannerDraft currentStatePreview(TrainingSession session) {
    return new PlannerDraft(
        "continue",
        session.getStatus(),
        session.getCurrentStepKey(),
        session.getCurrentMicroAction(),
        session.getHintLevel(),
        "planner_preview_current_state");
  }

  public List<StepDefinition> actionChain() {
    return STEPS;
  }

  public StepDefinition stepByKey(String stepKey) {
    return STEPS.stream()
        .filter(step -> step.stepKey().equals(stepKey))
        .findFirst()
        .orElse(STEPS.get(0));
  }

  private PlannerDraft successDecision(TrainingSession session, AttemptSignal signal) {
    if (session.getSuccessCount() + 1 >= 2 && !"pressure_check".equals(session.getStatus())) {
      return new PlannerDraft(
          "pressure_check",
          "pressure_check",
          session.getCurrentStepKey(),
          "ContinueUnderPrompt",
          lowerHint(session.getHintLevel()),
          "consecutive_success_pressure_check");
    }
    return advanceOrRecap(session, cleanReason(signal.reasonCode(), "target_and_task_met"));
  }

  private PlannerDraft failureDecision(TrainingSession session, AttemptSignal signal) {
    String raised = raiseHint(session.getHintLevel());
    boolean maxSupport = "model_then_retry".equals(session.getHintLevel()) || "model_then_retry".equals(raised);
    return new PlannerDraft(
        maxSupport ? "model_then_retry" : "raise_hint",
        "retry",
        session.getCurrentStepKey(),
        session.getCurrentMicroAction(),
        raised,
        maxSupport ? "repeated_failure_model_then_retry" : cleanReason(signal.reasonCode(), "failure_raise_hint"));
  }

  private PlannerDraft advanceOrRecap(TrainingSession session, String reasonCode) {
    StepDefinition next = nextStep(session.getCurrentStepKey());
    if (next == null) {
      return new PlannerDraft(
          "recap",
          "recap",
          session.getCurrentStepKey(),
          session.getCurrentMicroAction(),
          session.getHintLevel(),
          "action_chain_completed");
    }
    return new PlannerDraft(
        "advance_step",
        "ready",
        next.stepKey(),
        next.microAction(),
        lowerHint(session.getHintLevel()),
        reasonCode);
  }

  private StepDefinition nextStep(String currentStepKey) {
    for (int i = 0; i < STEPS.size(); i++) {
      if (STEPS.get(i).stepKey().equals(currentStepKey)) {
        return i + 1 >= STEPS.size() ? null : STEPS.get(i + 1);
      }
    }
    return STEPS.get(0);
  }

  private String raiseHint(String current) {
    return switch (current == null ? "none" : current) {
      case "none" -> "sentence_frame";
      case "sentence_frame" -> "options";
      case "options" -> "chunk_shadowing";
      default -> "model_then_retry";
    };
  }

  private String lowerHint(String current) {
    return switch (current == null ? "none" : current) {
      case "model_then_retry" -> "chunk_shadowing";
      case "chunk_shadowing" -> "options";
      case "options" -> "sentence_frame";
      default -> "none";
    };
  }

  private String cleanReason(String value, String fallback) {
    String cleaned = value == null ? "" : value.trim();
    return cleaned.isBlank() ? fallback : cleaned;
  }

  public record StepDefinition(String stepKey, String label, String microAction) {}

  public record AttemptSignal(String outcome, String reasonCode) {}

  public record PlannerDraft(
      String decisionType,
      String nextStatus,
      String nextStepKey,
      String nextMicroAction,
      String nextHintLevel,
      String reasonCode) {}
}
