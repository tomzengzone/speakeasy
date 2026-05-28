package com.speakeasy.api;

import com.speakeasy.commerce.CommercialFoundationService;
import com.speakeasy.common.SchemaResponse;
import com.speakeasy.security.CurrentUser;
import java.util.List;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class MembershipBoundaryController {
  private final CommercialFoundationService commercialService;

  public MembershipBoundaryController(CommercialFoundationService commercialService) {
    this.commercialService = commercialService;
  }

  @GetMapping("/membership/boundary")
  public MembershipBoundaryResponse membershipBoundary(@AuthenticationPrincipal CurrentUser currentUser) {
    String plan = commercialService.latestEntitlement(currentUser.userId())
        .map(entitlement -> entitlement.getPlan())
        .orElse("free");
    return new MembershipBoundaryResponse(
        1,
        new MembershipBoundaryDto(
            "entry-only",
            "commercial-not-ready",
            plan,
            List.of(new PlatformLimitDto("android", "purchase", "platform-limited", "ANDROID_BILLING_NOT_CONNECTED")),
            List.of(
                new CapabilityBoundaryDto("membership_entry", "available-entry", "MVP entry is available."),
                new CapabilityBoundaryDto("full_entitlement_gating", "future-scope", "Owned by commercial-subscription-readiness."))));
  }

  @PostMapping("/membership/android/purchase")
  public PlatformLimitResponse androidPurchase(@AuthenticationPrincipal CurrentUser currentUser) {
    return platformLimited("purchase");
  }

  @PostMapping("/membership/android/restore")
  public PlatformLimitResponse androidRestore(@AuthenticationPrincipal CurrentUser currentUser) {
    return platformLimited("restore");
  }

  @GetMapping("/learning/report/summary")
  public LearningReportBoundaryResponse learningReport(@AuthenticationPrincipal CurrentUser currentUser) {
    return new LearningReportBoundaryResponse(
        1,
        "empty",
        List.of(),
        new PlaceholderDto("learning_report", "not-implemented", "REPORT_NOT_IMPLEMENTED"));
  }

  @GetMapping("/offline-content/status")
  public PlaceholderResponse offlineContent(@AuthenticationPrincipal CurrentUser currentUser) {
    return new PlaceholderResponse(1, new PlaceholderDto("offline_content", "not-implemented", "OFFLINE_CONTENT_NOT_IMPLEMENTED"));
  }

  @GetMapping("/achievements/status")
  public PlaceholderResponse achievements(@AuthenticationPrincipal CurrentUser currentUser) {
    return new PlaceholderResponse(1, new PlaceholderDto("achievements", "not-implemented", "ACHIEVEMENTS_NOT_IMPLEMENTED"));
  }

  private PlatformLimitResponse platformLimited(String action) {
    return new PlatformLimitResponse(
        1,
        new PlatformLimitDto("android", action, "platform-limited", "ANDROID_BILLING_NOT_CONNECTED"));
  }

  public record MembershipBoundaryResponse(int schemaVersion, MembershipBoundaryDto membership) implements SchemaResponse {}

  public record MembershipBoundaryDto(
      String state,
      String commercialStatus,
      String currentPlan,
      List<PlatformLimitDto> platformLimits,
      List<CapabilityBoundaryDto> capabilities) {}

  public record PlatformLimitResponse(int schemaVersion, PlatformLimitDto platformLimit) implements SchemaResponse {}

  public record PlatformLimitDto(String platform, String action, String status, String reasonCode) {}

  public record CapabilityBoundaryDto(String capability, String status, String message) {}

  public record LearningReportBoundaryResponse(
      int schemaVersion, String reportStatus, List<String> sections, PlaceholderDto placeholder) implements SchemaResponse {}

  public record PlaceholderResponse(int schemaVersion, PlaceholderDto placeholder) implements SchemaResponse {}

  public record PlaceholderDto(String surface, String status, String reasonCode) {}
}
