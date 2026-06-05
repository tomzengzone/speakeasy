package com.speakeasy.api;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.speakeasy.common.SchemaResponse;
import com.speakeasy.goal.GoalAutopilotService;
import com.speakeasy.goal.NotificationOutboxService;
import com.speakeasy.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.time.LocalDate;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GoalAutopilotController {
  private final GoalAutopilotService service;

  public GoalAutopilotController(GoalAutopilotService service) {
    this.service = service;
  }

  @PostMapping("/goal-autopilot/goals")
  public GoalAutopilotSummaryResponse createGoal(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @Valid @RequestBody CreateGoalRequest request) {
    return GoalAutopilotSummaryResponse.from(service.createGoal(
        currentUser.userId(),
        new GoalAutopilotService.GoalInput(
            request.goalType(),
            request.targetScore(),
            request.targetAbility(),
            request.deadline(),
            request.dailyMinutes(),
            request.intensityPreference(),
            request.diagnosticSamples() == null
                ? List.of()
                : request.diagnosticSamples().stream()
                    .map(sample -> new GoalAutopilotService.DiagnosticSampleInput(
                        sample.sampleRef(), sample.transcript(), sample.audioRef(), sample.durationSeconds()))
                    .toList(),
            request.autopilotControl() == null ? null : request.autopilotControl().quietHoursStart(),
            request.autopilotControl() == null ? null : request.autopilotControl().quietHoursEnd(),
            request.autopilotControl() != null && Boolean.TRUE.equals(request.autopilotControl().notificationConsent())),
        requestId));
  }

  @GetMapping("/goal-autopilot/summary")
  public GoalAutopilotSummaryResponse summary(@AuthenticationPrincipal CurrentUser currentUser) {
    return GoalAutopilotSummaryResponse.from(service.summary(currentUser.userId()));
  }

  @GetMapping("/goal-autopilot/control")
  public AutopilotControlResponse control(@AuthenticationPrincipal CurrentUser currentUser) {
    return AutopilotControlResponse.from(service.control(currentUser.userId()));
  }

  @PatchMapping("/goal-autopilot/control")
  public AutopilotControlResponse updateControl(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @RequestHeader(name = "Idempotency-Key") String idempotencyKey,
      @Valid @RequestBody UpdateAutopilotControlRequest request) {
    return AutopilotControlResponse.from(service.updateControl(
        currentUser.userId(),
        new GoalAutopilotService.ControlSettingsInput(
            request.quietHoursStart(),
            request.quietHoursEnd(),
            request.timezone(),
            request.notificationConsent(),
            request.intensityOverride(),
            request.missedDayPolicy()),
        requestId,
        idempotencyKey));
  }

  @PostMapping("/goal-autopilot/control/pause")
  public AutopilotControlResponse pauseControl(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @RequestHeader(name = "Idempotency-Key") String idempotencyKey,
      @Valid @RequestBody PauseAutopilotControlRequest request) {
    return AutopilotControlResponse.from(service.pauseControl(currentUser.userId(), request.pauseReason(), requestId, idempotencyKey));
  }

  @PostMapping("/goal-autopilot/control/resume")
  public AutopilotControlResponse resumeControl(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @RequestHeader(name = "Idempotency-Key") String idempotencyKey,
      @Valid @RequestBody ResumeAutopilotControlRequest request) {
    return AutopilotControlResponse.from(service.resumeControl(currentUser.userId(), request.sourceEvent(), requestId, idempotencyKey));
  }

  @GetMapping("/goal-autopilot/reminders/outbox")
  public NotificationOutboxListResponse reminderOutbox(@AuthenticationPrincipal CurrentUser currentUser) {
    return NotificationOutboxListResponse.from(service.reminderOutbox(currentUser.userId()));
  }

  @GetMapping("/goal-autopilot/replay-audits")
  public PlannerReplayAuditListResponse replayAudits(@AuthenticationPrincipal CurrentUser currentUser) {
    return PlannerReplayAuditListResponse.from(service.replayAudits(currentUser.userId()));
  }

  @PostMapping("/goal-autopilot/plans/generate")
  public GoalPlanResponse generatePlan(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @Valid @RequestBody GeneratePlanRequest request) {
    return GoalPlanResponse.from(service.generatePlan(
        currentUser.userId(),
        Boolean.TRUE.equals(request.forceReplan()),
        request.reasonCode(),
        requestId));
  }

  @GetMapping("/goal-autopilot/daily-plan")
  public DailyPlanResponse dailyPlan(@AuthenticationPrincipal CurrentUser currentUser) {
    return DailyPlanResponse.from(service.dailyPlan(currentUser.userId()));
  }

  @GetMapping("/goal-autopilot/actions/next")
  public AutopilotActionResponse nextAction(@AuthenticationPrincipal CurrentUser currentUser) {
    return AutopilotActionResponse.from(service.nextAction(currentUser.userId()));
  }

  @PostMapping("/goal-autopilot/actions/{plan_item_id}/complete")
  public AutopilotActionResponse completeAction(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable("plan_item_id") UUID planItemId,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @Valid @RequestBody CompletePlanItemRequest request) {
    return AutopilotActionResponse.from(service.completeAction(currentUser.userId(), planItemId, request.outcome(), requestId));
  }

  @GetMapping("/goal-autopilot/forecast")
  public GoalForecastResponse forecast(@AuthenticationPrincipal CurrentUser currentUser) {
    return GoalForecastResponse.from(service.forecast(currentUser.userId()));
  }

  @PostMapping("/goal-autopilot/checkpoints")
  public CheckpointResponse checkpoint(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @Valid @RequestBody SubmitCheckpointRequest request) {
    return CheckpointResponse.from(service.submitCheckpoint(
        currentUser.userId(),
        new GoalAutopilotService.CheckpointInput(
            request.checkpointType(), request.transcript(), request.audioRef(), request.scoreHint()),
        requestId));
  }

  public record CreateGoalRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String goalType,
      Double targetScore,
      String targetAbility,
      @NotNull LocalDate deadline,
      @NotNull @Min(5) @Max(240) Integer dailyMinutes,
      @NotBlank String intensityPreference,
      List<DiagnosticSampleRequest> diagnosticSamples,
      AutopilotControlRequest autopilotControl) {}

  public record DiagnosticSampleRequest(String sampleRef, String transcript, String audioRef, Integer durationSeconds) {}

  public record AutopilotControlRequest(
      Boolean paused,
      String quietHoursStart,
      String quietHoursEnd,
      Boolean notificationConsent,
      String intensityOverride) {}

  public record UpdateAutopilotControlRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      String quietHoursStart,
      String quietHoursEnd,
      String timezone,
      Boolean notificationConsent,
      String intensityOverride,
      String missedDayPolicy) {}

  public record PauseAutopilotControlRequest(@NotNull @Min(1) @Max(1) Integer schemaVersion, String pauseReason) {}

  public record ResumeAutopilotControlRequest(@NotNull @Min(1) @Max(1) Integer schemaVersion, String sourceEvent) {}

  public record GeneratePlanRequest(@NotNull @Min(1) @Max(1) Integer schemaVersion, Boolean forceReplan, String reasonCode) {}

  public record CompletePlanItemRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion, @NotBlank String outcome, String evidenceRef, String learnerNote) {}

  public record SubmitCheckpointRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String checkpointType,
      String transcript,
      String audioRef,
      Double scoreHint) {}

  @JsonInclude(JsonInclude.Include.NON_NULL)
  public record GoalAutopilotSummaryResponse(
      int schemaVersion,
      GoalProfileDto goalProfile,
      SupportedGoalMatrixDecisionDto supportDecision,
      DiagnosticAssessmentDto diagnostic,
      WeeklyBackplanDto weeklyBackplan,
      DailyTrainingPlanDto dailyPlan,
      AutopilotActionDto nextAction,
      ProgressForecastDto forecast,
      OutcomeCheckpointDto latestCheckpoint)
      implements SchemaResponse {
    static GoalAutopilotSummaryResponse from(GoalAutopilotService.SummaryView view) {
      return new GoalAutopilotSummaryResponse(
          1,
          GoalProfileDto.from(view.goalProfile()),
          SupportedGoalMatrixDecisionDto.from(view.supportDecision()),
          DiagnosticAssessmentDto.from(view.diagnostic()),
          view.weeklyBackplan() == null ? null : WeeklyBackplanDto.from(view.weeklyBackplan()),
          view.dailyPlan() == null ? null : DailyTrainingPlanDto.from(view.dailyPlan()),
          view.nextAction() == null ? null : AutopilotActionDto.from(view.nextAction()),
          ProgressForecastDto.from(view.forecast()),
          view.latestCheckpoint() == null ? null : OutcomeCheckpointDto.from(view.latestCheckpoint()));
    }
  }

  public record GoalPlanResponse(
      int schemaVersion, WeeklyBackplanDto weeklyBackplan, DailyTrainingPlanDto dailyPlan, AutopilotActionDto nextAction)
      implements SchemaResponse {
    static GoalPlanResponse from(GoalAutopilotService.PlanResult result) {
      return new GoalPlanResponse(
          1,
          WeeklyBackplanDto.from(result.weeklyBackplan()),
          DailyTrainingPlanDto.from(result.dailyPlan()),
          AutopilotActionDto.from(result.nextAction()));
    }
  }

  public record DailyPlanResponse(int schemaVersion, DailyTrainingPlanDto dailyPlan) implements SchemaResponse {
    static DailyPlanResponse from(GoalAutopilotService.DailyPlanView plan) {
      return new DailyPlanResponse(1, DailyTrainingPlanDto.from(plan));
    }
  }

  @JsonInclude(JsonInclude.Include.NON_NULL)
  public record AutopilotActionResponse(
      int schemaVersion, AutopilotActionDto action, ProgressForecastDto forecast, PlanUpdateSignalDto planUpdateSignal)
      implements SchemaResponse {
    static AutopilotActionResponse from(GoalAutopilotService.ActionResult result) {
      return new AutopilotActionResponse(
          1,
          AutopilotActionDto.from(result.action()),
          ProgressForecastDto.from(result.forecast()),
          result.planUpdateSignal() == null ? null : PlanUpdateSignalDto.from(result.planUpdateSignal()));
    }
  }

  public record GoalForecastResponse(int schemaVersion, ProgressForecastDto forecast) implements SchemaResponse {
    static GoalForecastResponse from(GoalAutopilotService.ForecastView forecast) {
      return new GoalForecastResponse(1, ProgressForecastDto.from(forecast));
    }
  }

  @JsonInclude(JsonInclude.Include.NON_NULL)
  public record AutopilotControlResponse(
      int schemaVersion,
      UserAutopilotControlDto control,
      boolean nextActionChanged,
      boolean reminderEligibilityChanged,
      boolean replanRequired,
      String reasonCode,
      NotificationEligibilityDecisionDto reminderEligibility,
      PlanUpdateSignalDto planUpdateSignal)
      implements SchemaResponse {
    static AutopilotControlResponse from(GoalAutopilotService.ControlResult result) {
      return new AutopilotControlResponse(
          1,
          UserAutopilotControlDto.from(result.control()),
          result.nextActionChanged(),
          result.reminderEligibilityChanged(),
          result.replanRequired(),
          result.reasonCode(),
          NotificationEligibilityDecisionDto.from(result.reminderEligibility()),
          PlanUpdateSignalDto.from(result.planUpdateSignal()));
    }
  }

  public record UserAutopilotControlDto(
      UUID controlId,
      UUID userId,
      UUID goalProfileId,
      String controlStatus,
      Instant pausedAt,
      String pauseReason,
      Instant resumedAt,
      String quietHoursStart,
      String quietHoursEnd,
      String timezone,
      boolean notificationConsent,
      String intensityOverride,
      String missedDayPolicy,
      Instant updatedAt,
      String ruleVersion) {
    static UserAutopilotControlDto from(GoalAutopilotService.ControlView view) {
      return new UserAutopilotControlDto(
          view.controlId(),
          view.userId(),
          view.goalProfileId(),
          view.controlStatus(),
          view.pausedAt(),
          view.pauseReason(),
          view.resumedAt(),
          view.quietHoursStart(),
          view.quietHoursEnd(),
          view.timezone(),
          view.notificationConsent(),
          view.intensityOverride(),
          view.missedDayPolicy(),
          view.updatedAt(),
          view.ruleVersion());
    }
  }

  public record NotificationEligibilityDecisionDto(
      String decisionId,
      UUID controlId,
      UUID userId,
      UUID goalProfileId,
      UUID planItemId,
      boolean eligible,
      String reasonCode,
      Instant nextAllowedAt,
      String explanationKey,
      Instant evaluatedAt,
      String ruleVersion) {
    static NotificationEligibilityDecisionDto from(GoalAutopilotService.NotificationEligibilityDecisionView view) {
      return new NotificationEligibilityDecisionDto(
          view.decisionId(),
          view.controlId(),
          view.userId(),
          view.goalProfileId(),
          view.planItemId(),
          view.eligible(),
          view.reasonCode(),
          view.nextAllowedAt(),
          view.explanationKey(),
          view.evaluatedAt(),
          view.ruleVersion());
    }
  }

  public record NotificationOutboxListResponse(int schemaVersion, List<NotificationOutboxRecordDto> records)
      implements SchemaResponse {
    static NotificationOutboxListResponse from(List<NotificationOutboxService.OutboxRecordView> records) {
      return new NotificationOutboxListResponse(1, records.stream().map(NotificationOutboxRecordDto::from).toList());
    }
  }

  public record NotificationOutboxRecordDto(
      UUID outboxId,
      UUID userId,
      UUID goalProfileId,
      int goalRevision,
      UUID planItemId,
      String reminderSlot,
      String lifecycleStatus,
      String dedupeKey,
      String inputSnapshotHash,
      String payloadHash,
      String reasonCode,
      String processingStatus,
      Instant nextAttemptAt,
      String failureReason,
      int retryCount,
      Instant sentAt,
      String ruleVersion,
      Instant createdAt,
      Instant updatedAt) {
    static NotificationOutboxRecordDto from(NotificationOutboxService.OutboxRecordView view) {
      return new NotificationOutboxRecordDto(
          view.outboxId(),
          view.userId(),
          view.goalProfileId(),
          view.goalRevision(),
          view.planItemId(),
          view.reminderSlot(),
          view.lifecycleStatus(),
          view.dedupeKey(),
          view.inputSnapshotHash(),
          view.payloadHash(),
          view.reasonCode(),
          view.processingStatus(),
          view.nextAttemptAt(),
          view.failureReason(),
          view.retryCount(),
          view.sentAt(),
          view.ruleVersion(),
          view.createdAt(),
          view.updatedAt());
    }
  }

  public record PlannerReplayAuditListResponse(int schemaVersion, List<PlannerReplayAuditDto> audits)
      implements SchemaResponse {
    static PlannerReplayAuditListResponse from(List<NotificationOutboxService.PlannerReplayAuditView> audits) {
      return new PlannerReplayAuditListResponse(1, audits.stream().map(PlannerReplayAuditDto::from).toList());
    }
  }

  public record PlannerReplayAuditDto(
      UUID replayAuditId,
      String decisionFamily,
      String sourceEntityRef,
      String inputSnapshotHash,
      String outputSnapshotHash,
      String expectedDecision,
      String reasonCode,
      String ruleVersion,
      String replayHash,
      Instant createdAt) {
    static PlannerReplayAuditDto from(NotificationOutboxService.PlannerReplayAuditView view) {
      return new PlannerReplayAuditDto(
          view.replayAuditId(),
          view.decisionFamily(),
          view.sourceEntityRef(),
          view.inputSnapshotHash(),
          view.outputSnapshotHash(),
          view.expectedDecision(),
          view.reasonCode(),
          view.ruleVersion(),
          view.replayHash(),
          view.createdAt());
    }
  }

  public record CheckpointResponse(
      int schemaVersion, OutcomeCheckpointDto checkpoint, ProgressForecastDto forecast, PlanUpdateSignalDto planUpdateSignal)
      implements SchemaResponse {
    static CheckpointResponse from(GoalAutopilotService.CheckpointResult result) {
      return new CheckpointResponse(
          1,
          OutcomeCheckpointDto.from(result.checkpoint()),
          ProgressForecastDto.from(result.forecast()),
          PlanUpdateSignalDto.from(result.planUpdateSignal()));
    }
  }

  public record GoalProfileDto(
      UUID goalProfileId,
      String goalType,
      Double targetScore,
      String targetAbility,
      LocalDate deadline,
      int dailyMinutes,
      String intensityPreference,
      String supportStatus,
      String status,
      int revision) {
    static GoalProfileDto from(GoalAutopilotService.GoalProfileView view) {
      return new GoalProfileDto(
          view.goalProfileId(),
          view.goalType(),
          view.targetScore(),
          view.targetAbility(),
          view.deadline(),
          view.dailyMinutes(),
          view.intensityPreference(),
          view.supportStatus(),
          view.status(),
          view.revision());
    }
  }

  public record SupportedGoalMatrixDecisionDto(
      String decisionId,
      String supportStatus,
      String reasonCode,
      String limitationMessage,
      boolean rubricAvailable,
      String contentCoverage) {
    static SupportedGoalMatrixDecisionDto from(GoalAutopilotService.SupportDecision view) {
      return new SupportedGoalMatrixDecisionDto(
          view.decisionId(),
          view.supportStatus(),
          view.reasonCode(),
          view.limitationMessage(),
          view.rubricAvailable(),
          view.contentCoverage());
    }
  }

  public record DiagnosticAssessmentDto(
      UUID diagnosticAssessmentId,
      String status,
      String confidenceBand,
      int sampleCount,
      List<RubricScoreDto> rubricScores,
      List<WeaknessTagDto> weaknessTags,
      GoalClaimGuardDto claimGuard) {
    static DiagnosticAssessmentDto from(GoalAutopilotService.DiagnosticView view) {
      return new DiagnosticAssessmentDto(
          view.diagnosticAssessmentId(),
          view.status(),
          view.confidenceBand(),
          view.sampleCount(),
          view.rubricScores().stream().map(RubricScoreDto::from).toList(),
          view.weaknessTags().stream().map(WeaknessTagDto::from).toList(),
          GoalClaimGuardDto.from(view.claimGuard()));
    }
  }

  public record RubricScoreDto(String dimension, double score, double confidence, String evidenceRef) {
    static RubricScoreDto from(GoalAutopilotService.RubricScoreView view) {
      return new RubricScoreDto(view.dimension(), view.score(), view.confidence(), view.evidenceRef());
    }
  }

  public record WeaknessTagDto(
      String tag, String severity, String dimension, String recommendedTrainingDirection, String evidenceRef) {
    static WeaknessTagDto from(GoalAutopilotService.WeaknessTagView view) {
      return new WeaknessTagDto(
          view.tag(), view.severity(), view.dimension(), view.recommendedTrainingDirection(), view.evidenceRef());
    }
  }

  public record GoalClaimGuardDto(boolean officialScoreEquivalence, boolean goalCompletionClaimAllowed, String allowedClaim) {
    static GoalClaimGuardDto from(GoalAutopilotService.ClaimGuardView view) {
      return new GoalClaimGuardDto(view.officialScoreEquivalence(), view.goalCompletionClaimAllowed(), view.allowedClaim());
    }
  }

  public record WeeklyBackplanDto(
      UUID weeklyBackplanId,
      String planVersion,
      LocalDate startDate,
      LocalDate endDate,
      String milestone,
      int sessionCount,
      List<String> reviewWindows,
      LocalDate checkpointDueDate,
      String status) {
    static WeeklyBackplanDto from(GoalAutopilotService.WeeklyBackplanView view) {
      return new WeeklyBackplanDto(
          view.weeklyBackplanId(),
          view.planVersion(),
          view.startDate(),
          view.endDate(),
          view.milestone(),
          view.sessionCount(),
          view.reviewWindows(),
          view.checkpointDueDate(),
          view.status());
    }
  }

  public record DailyTrainingPlanDto(
      UUID dailyPlanId,
      LocalDate planDate,
      int totalMinutes,
      String status,
      String limitationMessage,
      List<PlanItemDto> items,
      MemoryCurvePolicyDto memoryPolicy) {
    static DailyTrainingPlanDto from(GoalAutopilotService.DailyPlanView view) {
      return new DailyTrainingPlanDto(
          view.dailyPlanId(),
          view.planDate(),
          view.totalMinutes(),
          view.status(),
          view.limitationMessage(),
          view.items().stream().map(PlanItemDto::from).toList(),
          MemoryCurvePolicyDto.from(view.memoryPolicy()));
    }
  }

  public record PlanItemDto(
      UUID planItemId,
      String itemType,
      String title,
      String reasonCode,
      int durationMinutes,
      String status,
      String memoryRisk,
      String pressureLevel) {
    static PlanItemDto from(GoalAutopilotService.PlanItemView view) {
      return new PlanItemDto(
          view.planItemId(),
          view.itemType(),
          view.title(),
          view.reasonCode(),
          view.durationMinutes(),
          view.status(),
          view.memoryRisk(),
          view.pressureLevel());
    }
  }

  public record MemoryCurvePolicyDto(
      String policyVersion, String forgettingRisk, int nextReviewIntervalDays, int overlearningCap, String interleavingRule) {
    static MemoryCurvePolicyDto from(GoalAutopilotService.MemoryCurvePolicyView view) {
      return new MemoryCurvePolicyDto(
          view.policyVersion(),
          view.forgettingRisk(),
          view.nextReviewIntervalDays(),
          view.overlearningCap(),
          view.interleavingRule());
    }
  }

  public record AutopilotActionDto(
      String actionId,
      UUID planItemId,
      String actionType,
      String title,
      String reasonCode,
      int expectedDurationMinutes,
      String status,
      String explanation) {
    static AutopilotActionDto from(GoalAutopilotService.AutopilotActionView view) {
      return new AutopilotActionDto(
          view.actionId(),
          view.planItemId(),
          view.actionType(),
          view.title(),
          view.reasonCode(),
          view.expectedDurationMinutes(),
          view.status(),
          view.explanation());
    }
  }

  public record ProgressForecastDto(
      UUID forecastId,
      String gapSummary,
      LocalDate etaDate,
      String etaWindow,
      String confidenceBand,
      String riskLevel,
      String riskReason,
      LocalDate nextCheckpointDate,
      GoalClaimGuardDto claimGuard) {
    static ProgressForecastDto from(GoalAutopilotService.ForecastView view) {
      return new ProgressForecastDto(
          view.forecastId(),
          view.gapSummary(),
          view.etaDate(),
          view.etaWindow(),
          view.confidenceBand(),
          view.riskLevel(),
          view.riskReason(),
          view.nextCheckpointDate(),
          GoalClaimGuardDto.from(view.claimGuard()));
    }
  }

  public record OutcomeCheckpointDto(
      UUID checkpointId, String checkpointType, String cadence, String resultStatus, String confidenceBand, String summary) {
    static OutcomeCheckpointDto from(GoalAutopilotService.CheckpointView view) {
      return new OutcomeCheckpointDto(
          view.checkpointId(), view.checkpointType(), view.cadence(), view.resultStatus(), view.confidenceBand(), view.summary());
    }
  }

  public record PlanUpdateSignalDto(String signalType, String reasonCode) {
    static PlanUpdateSignalDto from(GoalAutopilotService.PlanUpdateSignalView view) {
      return new PlanUpdateSignalDto(view.signalType(), view.reasonCode());
    }
  }
}
