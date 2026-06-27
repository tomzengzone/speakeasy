package com.speakeasy.commerce;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ApiException;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class EntitlementGateService {
  private static final TypeReference<Map<String, Object>> OBJECT_MAP = new TypeReference<>() {};

  private final CommercialFoundationService foundationService;
  private final ObjectMapper objectMapper;

  public EntitlementGateService(CommercialFoundationService foundationService, ObjectMapper objectMapper) {
    this.foundationService = foundationService;
    this.objectMapper = objectMapper;
  }

  @Transactional(readOnly = true)
  public EntitlementSnapshot currentEntitlement(UUID userId) {
    EntitlementSnapshot entitlement =
        foundationService.latestEntitlement(userId).orElseGet(() -> foundationService.defaultFreeEntitlement(userId));
    if (!isUsable(entitlement)) {
      throw new ApiException(
          HttpStatus.FORBIDDEN,
          "ENTITLEMENT_REQUIRED",
          "Current entitlement does not allow this feature.",
          Map.of("entitlement_status", entitlement.getStatus(), "plan", entitlement.getPlan()));
    }
    return entitlement;
  }

  @Transactional(readOnly = true)
  public void requireScenarioLevel(UUID userId, String scenarioId, String levelCode) {
    if (!"L3".equals(levelCode)) {
      return;
    }
    EntitlementSnapshot entitlement = currentEntitlement(userId);
    Map<String, Object> features = parse(entitlement.getFeatureFlags());
    if (!Boolean.TRUE.equals(features.get("advanced_scenarios"))) {
      throw new ApiException(
          HttpStatus.FORBIDDEN,
          "ENTITLEMENT_REQUIRED",
          "This scenario level requires an active paid entitlement.",
          Map.of("scenario_id", scenarioId, "level_code", levelCode, "required_feature", "advanced_scenarios"));
    }
  }

  @Transactional(readOnly = true)
  public int limitFor(UUID userId, String usageFamily) {
    EntitlementSnapshot entitlement =
        foundationService.latestEntitlement(userId).orElseGet(() -> foundationService.defaultFreeEntitlement(userId));
    if (!isUsable(entitlement)) {
      entitlement = foundationService.defaultFreeEntitlement(userId);
    }
    Map<String, Object> quotas = parse(entitlement.getQuotaLimits());
    Object value = quotas.get(usageFamily);
    if (value instanceof Number number) {
      return Math.max(0, number.intValue());
    }
    return switch (usageFamily) {
      case "training" -> 3;
      case "ai", "asr", "tts", "scoring" -> 10;
      default -> 0;
    };
  }

  @Transactional(readOnly = true)
  public String planFor(UUID userId) {
    EntitlementSnapshot entitlement =
        foundationService.latestEntitlement(userId).orElseGet(() -> foundationService.defaultFreeEntitlement(userId));
    if (!isUsable(entitlement)) {
      entitlement = foundationService.defaultFreeEntitlement(userId);
    }
    String plan = entitlement.getPlan();
    return plan == null || plan.isBlank() ? "free" : plan.trim();
  }

  private boolean isUsable(EntitlementSnapshot entitlement) {
    if (!"active".equals(entitlement.getStatus())) {
      return false;
    }
    Instant validUntil = entitlement.getValidUntil();
    return validUntil == null || validUntil.isAfter(Instant.now());
  }

  private Map<String, Object> parse(String json) {
    try {
      return objectMapper.readValue(json, OBJECT_MAP);
    } catch (Exception e) {
      return Map.of();
    }
  }
}
