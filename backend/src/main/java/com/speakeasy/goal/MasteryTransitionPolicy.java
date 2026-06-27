package com.speakeasy.goal;

import java.util.List;
import java.util.Map;
import java.util.Set;

public class MasteryTransitionPolicy {
  public static final String RULE_VERSION = "fub-mastery-v1";
  private static final List<String> LEVELS = List.of("L0", "L1", "L2", "L3", "L4", "L5");
  private static final Set<String> BLOCKED_SUPPORT_STATUSES = Set.of("partial", "unsupported");
  private static final Map<String, Double> PROMOTION_THRESHOLDS = Map.of(
      "L0", 0.65,
      "L1", 0.70,
      "L2", 0.75,
      "L3", 0.80,
      "L4", 0.85);

  public Decision evaluate(Input input) {
    String previousLevel = requireLevel(input.previousLevel(), "previous_level");
    String targetLevel = input.targetLevel() == null ? nextLevel(previousLevel) : requireLevel(input.targetLevel(), "target_level");
    double confidence = clampConfidence(input.confidence());
    List<String> evidenceRefs = input.evidenceRefs() == null
        ? List.of()
        : input.evidenceRefs().stream().filter(ref -> ref != null && !ref.isBlank()).map(String::trim).toList();
    String supportStatus = input.supportStatus() == null ? "supported" : input.supportStatus().trim();

    if (BLOCKED_SUPPORT_STATUSES.contains(supportStatus)) {
      return hold(
          previousLevel,
          confidence,
          evidenceRefs,
          "partial".equals(supportStatus) ? "partial_goal_limited" : "unsupported_goal");
    }
    if (input.fatigueProtected()) {
      return hold(previousLevel, confidence, evidenceRefs, "fatigue_protected");
    }
    if (input.contradictoryEvidence()) {
      return hold(previousLevel, confidence, evidenceRefs, "contradictory_evidence");
    }
    if (input.checkpointRegression() && confidence >= 0.70) {
      return demote(previousLevel, confidence, evidenceRefs, "checkpoint_regression");
    }
    if (input.retrievalRegression() && input.recentFailures() >= 2 && confidence >= 0.70) {
      return demote(previousLevel, confidence, evidenceRefs, "retrieval_regression");
    }
    if (input.recentFailures() >= 2 && confidence >= 0.70) {
      return demote(previousLevel, confidence, evidenceRefs, "repeated_failure");
    }
    if (input.acceptedEvidenceCount() < 3 || evidenceRefs.size() < 2) {
      return hold(previousLevel, confidence, evidenceRefs, "insufficient_evidence");
    }
    if (!isAbove(previousLevel, targetLevel)) {
      return hold(previousLevel, confidence, evidenceRefs, "target_level_not_above_current");
    }
    double threshold = PROMOTION_THRESHOLDS.getOrDefault(previousLevel, Double.POSITIVE_INFINITY);
    if (confidence < threshold || input.lowConfidenceOverride()) {
      return hold(previousLevel, confidence, evidenceRefs, "low_confidence");
    }
    return new Decision(
        previousLevel,
        nextLevel(previousLevel),
        nextLevel(previousLevel),
        "promote",
        evidenceRefs,
        confidence,
        "evidence_promotion_confident_retrieval",
        RULE_VERSION);
  }

  private Decision demote(String previousLevel, double confidence, List<String> evidenceRefs, String reasonCode) {
    String acceptedLevel = previousLevel.equals("L0") ? "L0" : LEVELS.get(LEVELS.indexOf(previousLevel) - 1);
    return new Decision(previousLevel, acceptedLevel, acceptedLevel, "demote", evidenceRefs, confidence, reasonCode, RULE_VERSION);
  }

  private Decision hold(String previousLevel, double confidence, List<String> evidenceRefs, String reasonCode) {
    return new Decision(previousLevel, previousLevel, previousLevel, "hold", evidenceRefs, confidence, reasonCode, RULE_VERSION);
  }

  private boolean isAbove(String previousLevel, String targetLevel) {
    return LEVELS.indexOf(targetLevel) > LEVELS.indexOf(previousLevel);
  }

  private String nextLevel(String currentLevel) {
    int index = LEVELS.indexOf(currentLevel);
    return index >= LEVELS.size() - 1 ? currentLevel : LEVELS.get(index + 1);
  }

  private String requireLevel(String level, String field) {
    if (level == null || !LEVELS.contains(level)) {
      throw new IllegalArgumentException(field + " must be one of L0-L5.");
    }
    return level;
  }

  private double clampConfidence(double confidence) {
    if (confidence < 0 || confidence > 1) {
      throw new IllegalArgumentException("confidence must be between 0 and 1.");
    }
    return confidence;
  }

  public record Input(
      String previousLevel,
      String targetLevel,
      double confidence,
      List<String> evidenceRefs,
      int acceptedEvidenceCount,
      int recentFailures,
      boolean retrievalRegression,
      boolean checkpointRegression,
      boolean fatigueProtected,
      boolean contradictoryEvidence,
      String supportStatus,
      boolean lowConfidenceOverride) {}

  public record Decision(
      String previousLevel,
      String proposedLevel,
      String acceptedLevel,
      String direction,
      List<String> evidenceRefs,
      double confidence,
      String reasonCode,
      String ruleVersion) {}
}
