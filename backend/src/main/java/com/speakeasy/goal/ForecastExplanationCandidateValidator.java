package com.speakeasy.goal;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Set;

public class ForecastExplanationCandidateValidator {
  private static final ObjectMapper MAPPER = new ObjectMapper();
  private static final Set<String> REQUIRED_FIELDS = Set.of(
      "schema_version",
      "output_type",
      "source_goal_revision",
      "forecast_state",
      "risk_reason_code",
      "learner_visible_explanation",
      "guardrails");
  private static final Set<String> FORBIDDEN_PERSISTENT_FIELDS = Set.of(
      "goal_completed",
      "official_score",
      "certified",
      "guaranteed_eta",
      "eta_date",
      "eta_range_start",
      "eta_range_end",
      "entitlement",
      "quota_state",
      "billing_state",
      "final_mastery_level",
      "release_approval",
      "release_ready",
      "product_base_merge_approved",
      "checkpoint_status",
      "plan_state");

  public ValidationResult validate(ProgressForecastPolicy.Decision deterministicDecision, String candidateJson) {
    JsonNode root = parseCandidate(candidateJson);
    if (root == null || !root.isObject()) {
      return rejected("ai_schema_invalid", deterministicDecision);
    }
    if (!hasRequiredFields(root)) {
      return rejected("ai_schema_invalid", deterministicDecision);
    }
    if (!"followup_c_forecast_explanation_candidate".equals(root.path("output_type").asText())) {
      return rejected("ai_schema_invalid", deterministicDecision);
    }
    if (containsForbiddenPersistentField(root) || guardrailsForbidRendering(root.path("guardrails"))) {
      return rejected("ai_forbidden_persistent_field", deterministicDecision);
    }
    if (!echoesDeterministicDecision(root, deterministicDecision)) {
      return rejected("ai_candidate_mismatch", deterministicDecision);
    }
    if (containsUnsafeClaim(root.path("learner_visible_explanation").asText(""))) {
      return rejected("ai_forbidden_persistent_field", deterministicDecision);
    }
    return new ValidationResult(
        true,
        "candidate_explanation_valid",
        root.path("learner_visible_explanation").asText(),
        false);
  }

  private JsonNode parseCandidate(String candidateJson) {
    if (candidateJson == null || candidateJson.isBlank()) {
      return null;
    }
    String cleaned = candidateJson.trim();
    if (cleaned.startsWith("```")) {
      int firstNewline = cleaned.indexOf('\n');
      int lastFence = cleaned.lastIndexOf("```");
      if (firstNewline >= 0 && lastFence > firstNewline) {
        cleaned = cleaned.substring(firstNewline + 1, lastFence).trim();
      }
    }
    try {
      return MAPPER.readTree(cleaned);
    } catch (Exception ignored) {
      return null;
    }
  }

  private boolean hasRequiredFields(JsonNode root) {
    return REQUIRED_FIELDS.stream().allMatch(root::has);
  }

  private boolean guardrailsForbidRendering(JsonNode guardrails) {
    return guardrails.path("official_score_equivalence").asBoolean(true)
        || guardrails.path("goal_completion_claim_allowed").asBoolean(true)
        || guardrails.path("guaranteed_eta_claim_allowed").asBoolean(true)
        || guardrails.path("persistent_decision_fields_present").asBoolean(true)
        || guardrails.path("forbidden_fields_detected").size() > 0;
  }

  private boolean echoesDeterministicDecision(JsonNode root, ProgressForecastPolicy.Decision deterministicDecision) {
    return root.path("source_goal_revision").asInt() == deterministicDecision.sourceGoalRevision()
        && deterministicDecision.forecastState().equals(root.path("forecast_state").asText())
        && deterministicDecision.riskReasonCode().equals(root.path("risk_reason_code").asText());
  }

  private boolean containsForbiddenPersistentField(JsonNode root) {
    Set<String> found = new HashSet<>();
    collectForbiddenFields(root, found);
    return !found.isEmpty();
  }

  private void collectForbiddenFields(JsonNode node, Set<String> found) {
    if (node == null || node.isNull()) {
      return;
    }
    if (node.isObject()) {
      Iterator<String> names = node.fieldNames();
      while (names.hasNext()) {
        String name = names.next();
        if (FORBIDDEN_PERSISTENT_FIELDS.contains(name)) {
          found.add(name);
        }
        collectForbiddenFields(node.get(name), found);
      }
      return;
    }
    if (node.isArray()) {
      node.forEach(child -> collectForbiddenFields(child, found));
    }
  }

  private boolean containsUnsafeClaim(String explanation) {
    String lower = explanation.toLowerCase();
    return lower.contains("official")
        || lower.contains("certified")
        || lower.contains("guaranteed")
        || lower.contains("ielts 8")
        || lower.contains("toefl 30")
        || lower.contains("goal completed");
  }

  private ValidationResult rejected(String reasonCode, ProgressForecastPolicy.Decision deterministicDecision) {
    return new ValidationResult(false, reasonCode, fallbackExplanation(deterministicDecision), false);
  }

  private String fallbackExplanation(ProgressForecastPolicy.Decision decision) {
    return "This is an internal progress signal: "
        + decision.riskReasonCode()
        + " with forecast state "
        + decision.forecastState()
        + ". It is not an official exam score or guaranteed outcome.";
  }

  public record ValidationResult(
      boolean accepted,
      String reasonCode,
      String fallbackExplanation,
      boolean mutatesPersistentState) {}
}
