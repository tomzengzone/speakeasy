package com.speakeasy.api;

import com.speakeasy.common.SchemaResponse;
import com.speakeasy.content.OnboardingContentService;
import com.speakeasy.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import java.time.Instant;
import java.util.List;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class OnboardingContentController {
  private final OnboardingContentService service;

  public OnboardingContentController(OnboardingContentService service) {
    this.service = service;
  }

  @PostMapping("/onboarding/assessment")
  public OnboardingAssessmentResponse submitAssessment(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody OnboardingAssessmentRequest request) {
    return OnboardingAssessmentResponse.from(service.submitAssessment(
        currentUser.userId(),
        request.goalDirection(),
        request.painPoints(),
        request.outputLevel(),
        request.dailyMinutes()));
  }

  @GetMapping("/scenarios")
  public ScenarioListResponse listScenarios(@AuthenticationPrincipal CurrentUser currentUser) {
    return new ScenarioListResponse(1, service.listScenarios(currentUser.userId()).stream().map(ScenarioSummaryDto::from).toList());
  }

  @GetMapping("/scenarios/{scenarioId}")
  public ScenarioResponse getScenario(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable String scenarioId) {
    return new ScenarioResponse(1, ScenarioDetailDto.from(service.getScenario(currentUser.userId(), scenarioId)));
  }

  @GetMapping("/scenarios/{scenarioId}/levels/{levelCode}")
  public ScenarioLevelResponse getScenarioLevel(
      @AuthenticationPrincipal CurrentUser currentUser, @PathVariable String scenarioId, @PathVariable String levelCode) {
    return ScenarioLevelResponse.from(service.getScenarioLevel(currentUser.userId(), scenarioId, levelCode));
  }

  @PutMapping("/user/scenarios/{scenarioId}")
  public UserScenarioStateResponse joinScenario(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable String scenarioId,
      @Valid @RequestBody UserScenarioStateRequest request) {
    return UserScenarioStateResponse.from(
        service.joinScenario(currentUser.userId(), scenarioId, request.targetLevel(), request.setCurrent()));
  }

  @DeleteMapping("/user/scenarios/{scenarioId}")
  public UserScenarioStateResponse removeScenario(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable String scenarioId) {
    return UserScenarioStateResponse.from(service.removeScenario(currentUser.userId(), scenarioId));
  }

  @PatchMapping("/user/scenarios/current")
  public UserScenarioStateResponse setCurrentScenario(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody CurrentScenarioRequest request) {
    return UserScenarioStateResponse.from(
        service.setCurrentScenario(currentUser.userId(), request.scenarioId(), request.targetLevel()));
  }

  @GetMapping("/home/summary")
  public HomeSummaryResponse getHomeSummary(@AuthenticationPrincipal CurrentUser currentUser) {
    return new HomeSummaryResponse(1, HomeSummaryDto.from(service.homeSummary(currentUser.userId())));
  }

  public record OnboardingAssessmentRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank @Pattern(regexp = "job_interview|onboarding_introduction|work_communication|daily_service") String goalDirection,
      @NotNull @Size(min = 1) List<@NotBlank String> painPoints,
      @NotBlank @Pattern(regexp = "L1|L2|L3") String outputLevel,
      @NotNull @Min(1) Integer dailyMinutes) {}

  public record UserScenarioStateRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @Pattern(regexp = "L1|L2|L3") String targetLevel,
      Boolean setCurrent) {}

  public record CurrentScenarioRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank @Pattern(regexp = "job_interview|onboarding_introduction") String scenarioId,
      @Pattern(regexp = "L1|L2|L3") String targetLevel) {}

  public record OnboardingAssessmentResponse(int schemaVersion, LearningRouteDto route) implements SchemaResponse {
    static OnboardingAssessmentResponse from(OnboardingContentService.AssessmentResult result) {
      return new OnboardingAssessmentResponse(1, LearningRouteDto.from(result.route()));
    }
  }

  public record LearningRouteDto(String currentScenarioId, String targetLevel, List<String> scenarioIds) {
    static LearningRouteDto from(OnboardingContentService.RouteView route) {
      return new LearningRouteDto(route.currentScenarioId(), route.targetLevel(), route.scenarioIds());
    }
  }

  public record ScenarioListResponse(int schemaVersion, List<ScenarioSummaryDto> scenarios) implements SchemaResponse {}

  public record ScenarioResponse(int schemaVersion, ScenarioDetailDto scenario) implements SchemaResponse {}

  public record ScenarioSummaryDto(
      String scenarioId, String title, String summary, List<String> tags, List<String> levels, String status, AccessStateDto access) {
    static ScenarioSummaryDto from(OnboardingContentService.ScenarioSummaryView scenario) {
      return new ScenarioSummaryDto(
          scenario.scenarioId(),
          scenario.title(),
          scenario.summary(),
          scenario.tags(),
          scenario.levels(),
          scenario.status(),
          new AccessStateDto(scenario.accessAllowed(), scenario.accessReasonCode()));
    }
  }

  public record ScenarioDetailDto(
      String scenarioId,
      String title,
      String summary,
      List<String> tags,
      List<String> levels,
      String status,
      AccessStateDto access,
      String version,
      int expressionCount,
      boolean joined) {
    static ScenarioDetailDto from(OnboardingContentService.ScenarioSummaryView scenario) {
      return new ScenarioDetailDto(
          scenario.scenarioId(),
          scenario.title(),
          scenario.summary(),
          scenario.tags(),
          scenario.levels(),
          scenario.status(),
          new AccessStateDto(scenario.accessAllowed(), scenario.accessReasonCode()),
          scenario.version(),
          scenario.expressionCount(),
          scenario.joined());
    }
  }

  public record AccessStateDto(boolean allowed, String reasonCode) {}

  public record ScenarioLevelResponse(
      int schemaVersion,
      String scenarioId,
      String levelCode,
      List<DialogueAssetDto> dialogueAssets,
      List<TargetExpressionDto> targetExpressions,
      List<ActionChainStepDto> actionChainSteps)
      implements SchemaResponse {
    static ScenarioLevelResponse from(OnboardingContentService.LevelContentView content) {
      return new ScenarioLevelResponse(
          1,
          content.scenarioId(),
          content.levelCode(),
          List.of(),
          content.targetExpressions().stream().map(TargetExpressionDto::from).toList(),
          List.of());
    }
  }

  public record DialogueAssetDto(String dialogueAssetId, String role, String text, String audioRef, int orderIndex) {}

  public record TargetExpressionDto(String targetExpressionId, String text, String meaningCn, List<String> tags) {
    static TargetExpressionDto from(OnboardingContentService.TargetExpressionView expression) {
      return new TargetExpressionDto(
          expression.targetExpressionId(), expression.text(), expression.meaningCn(), expression.tags());
    }
  }

  public record ActionChainStepDto(String actionChainStepId, String stepKey, String learnerTask, String successCondition, int orderIndex) {}

  public record UserScenarioStateResponse(int schemaVersion, UserScenarioStateDto state, HomeSummaryDto homeSummary)
      implements SchemaResponse {
    static UserScenarioStateResponse from(OnboardingContentService.UserScenarioStateResult result) {
      return new UserScenarioStateResponse(1, UserScenarioStateDto.from(result.state()), HomeSummaryDto.from(result.homeSummary()));
    }
  }

  public record UserScenarioStateDto(String scenarioId, String state, boolean current, String targetLevel, Instant updatedAt) {
    static UserScenarioStateDto from(OnboardingContentService.UserScenarioStateView state) {
      return new UserScenarioStateDto(state.scenarioId(), state.state(), state.current(), state.targetLevel(), state.updatedAt());
    }
  }

  public record HomeSummaryResponse(int schemaVersion, HomeSummaryDto summary) implements SchemaResponse {}

  public record HomeSummaryDto(
      String onboardingStatus,
      HomeScenarioDto currentScenario,
      List<HomeScenarioDto> joinedScenarios,
      String reviewStatus,
      String weaknessStatus,
      String unfinishedSessionStatus,
      HomeNextActionDto nextAction) {
    static HomeSummaryDto from(OnboardingContentService.HomeSummaryView summary) {
      return new HomeSummaryDto(
          summary.onboardingStatus(),
          summary.currentScenario() == null ? null : HomeScenarioDto.from(summary.currentScenario()),
          summary.joinedScenarios().stream().map(HomeScenarioDto::from).toList(),
          summary.reviewStatus(),
          summary.weaknessStatus(),
          summary.unfinishedSessionStatus(),
          HomeNextActionDto.from(summary.nextAction()));
    }
  }

  public record HomeScenarioDto(String scenarioId, String title, String targetLevel, boolean current, String version) {
    static HomeScenarioDto from(OnboardingContentService.HomeScenarioView scenario) {
      return new HomeScenarioDto(
          scenario.scenarioId(), scenario.title(), scenario.targetLevel(), scenario.current(), scenario.version());
    }
  }

  public record HomeNextActionDto(String actionType, String scenarioId, String levelCode, String label) {
    static HomeNextActionDto from(OnboardingContentService.HomeNextActionView action) {
      return new HomeNextActionDto(action.actionType(), action.scenarioId(), action.levelCode(), action.label());
    }
  }
}
