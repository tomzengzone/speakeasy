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

  @GetMapping("/goal-autopilot/progress-projection")
  public GoalProgressProjectionResponse progressProjection(@AuthenticationPrincipal CurrentUser currentUser) {
    return GoalProgressProjectionResponse.from(service.progressProjection(currentUser.userId()));
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

  @GetMapping("/goal-autopilot/mastery-transitions")
  public MasteryTransitionListResponse masteryTransitions(@AuthenticationPrincipal CurrentUser currentUser) {
    return MasteryTransitionListResponse.from(service.masteryTransitions(currentUser.userId()));
  }

  @PostMapping("/goal-autopilot/recovery/replan")
  public RecoveryPlanResponse replanRecovery(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @RequestHeader(name = "Idempotency-Key") String idempotencyKey,
      @Valid @RequestBody RecoveryReplanRequest request) {
    return RecoveryPlanResponse.from(service.replanRecovery(
        currentUser.userId(),
        new GoalAutopilotService.RecoveryReplanInput(
            request.sourceEvent(), request.planItemId(), request.preferredPolicy()),
        requestId,
        idempotencyKey));
  }

  @PostMapping("/goal-autopilot/item-policy/decisions")
  public ItemPolicyDecisionResponse itemPolicyDecisions(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @Valid @RequestBody ItemPolicyDecisionRequest request) {
    return ItemPolicyDecisionResponse.from(service.itemPolicyDecisions(
        currentUser.userId(),
        new GoalAutopilotService.ItemPolicyDecisionInput(
            request.policyVersion(),
            request.itemRefs(),
            request.dailyTimeBudgetMinutes(),
            request.items() == null
                ? List.of()
                : request.items().stream()
                    .map(item -> new GoalAutopilotService.MemoryItemPolicyInput(
                        item.itemType(),
                        item.itemRef(),
                        item.interleavingGroup(),
                        item.currentMasteryLevel(),
                        item.evidenceRefs(),
                        item.lastReviewedAt(),
                        item.exposureCount(),
                        item.overlearningCount(),
                        item.forgettingRisk(),
                        item.retrievalSuccess(),
                        item.recentFailures(),
                        item.pressureLevel(),
                        item.estimatedMinutes()))
                    .toList()),
        requestId));
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

  @GetMapping("/goal-autopilot/checkpoints/task")
  public CheckpointTaskResponse checkpointTask(@AuthenticationPrincipal CurrentUser currentUser) {
    return CheckpointTaskResponse.from(service.checkpointTask(currentUser.userId()));
  }

  @PostMapping("/goal-autopilot/checkpoints")
  public CheckpointResponse checkpoint(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(name = "X-Request-Id", required = false) String requestId,
      @Valid @RequestBody SubmitCheckpointRequest request) {
    return CheckpointResponse.from(service.submitCheckpoint(
        currentUser.userId(),
        new GoalAutopilotService.CheckpointInput(
            request.checkpointType(), request.transcript(), request.audioRef(), request.scoreHint(), request.resultStatus()),
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

  public record RecoveryReplanRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String sourceEvent,
      UUID planItemId,
      String preferredPolicy) {}

  public record ItemPolicyDecisionRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String policyVersion,
      List<String> itemRefs,
      @Min(0) @Max(240) Integer dailyTimeBudgetMinutes,
      List<MemoryItemPolicyInputRequest> items) {}

  public record MemoryItemPolicyInputRequest(
      String itemType,
      String itemRef,
      String interleavingGroup,
      String currentMasteryLevel,
      List<String> evidenceRefs,
      Instant lastReviewedAt,
      Integer exposureCount,
      Integer overlearningCount,
      Double forgettingRisk,
      Boolean retrievalSuccess,
      Integer recentFailures,
      String pressureLevel,
      Integer estimatedMinutes) {}

  public record CompletePlanItemRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion, @NotBlank String outcome, String evidenceRef, String learnerNote) {}

  public record SubmitCheckpointRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String checkpointType,
      String transcript,
      String audioRef,
      Double scoreHint,
      String resultStatus) {}

  @JsonInclude(JsonInclude.Include.NON_NULL)
  public record GoalAutopilotSummaryResponse(
      int schemaVersion,
      GoalProfileDto goalProfile,
      SupportedGoalMatrixDecisionDto supportDecision,
      DiagnosticAssessmentDto diagnostic,
      GoalEntitlementDepthDto entitlementDepth,
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
          GoalEntitlementDepthDto.from(view.entitlementDepth()),
          view.weeklyBackplan() == null ? null : WeeklyBackplanDto.from(view.weeklyBackplan()),
          view.dailyPlan() == null ? null : DailyTrainingPlanDto.from(view.dailyPlan()),
          view.nextAction() == null ? null : AutopilotActionDto.from(view.nextAction()),
          ProgressForecastDto.from(view.forecast()),
          view.latestCheckpoint() == null ? null : OutcomeCheckpointDto.from(view.latestCheckpoint()));
    }
  }

  @JsonInclude(JsonInclude.Include.NON_NULL)
  public record GoalProgressProjectionResponse(int schemaVersion, GoalProgressProjectionDto projection)
      implements SchemaResponse {
    static GoalProgressProjectionResponse from(GoalAutopilotService.GoalProgressProjectionView view) {
      return new GoalProgressProjectionResponse(1, GoalProgressProjectionDto.from(view));
    }
  }

  @JsonInclude(JsonInclude.Include.NON_NULL)
  public record GoalProgressProjectionDto(
      String projectionId,
      String projectionState,
      String downgradeReason,
      GoalProgressGoalFragmentDto goal,
      GoalProgressNextActionFragmentDto nextAction,
      GoalProgressForecastFragmentDto progress,
      GoalProgressCheckpointFragmentDto latestCheckpoint,
      List<GoalProgressSurfaceFragmentDto> surfaceFragments,
      List<String> sourceRefs,
      String ruleVersion,
      Instant updatedAt) {
    static GoalProgressProjectionDto from(GoalAutopilotService.GoalProgressProjectionView view) {
      return new GoalProgressProjectionDto(
          view.projectionId(),
          view.projectionState(),
          view.downgradeReason(),
          view.goal() == null ? null : GoalProgressGoalFragmentDto.from(view.goal()),
          view.nextAction() == null ? null : GoalProgressNextActionFragmentDto.from(view.nextAction()),
          view.progress() == null ? null : GoalProgressForecastFragmentDto.from(view.progress()),
          view.latestCheckpoint() == null ? null : GoalProgressCheckpointFragmentDto.from(view.latestCheckpoint()),
          view.surfaceFragments().stream().map(GoalProgressSurfaceFragmentDto::from).toList(),
          view.sourceRefs(),
          view.ruleVersion(),
          view.updatedAt());
    }
  }

  public record GoalProgressGoalFragmentDto(
      UUID goalProfileId,
      String goalType,
      String supportStatus,
      String status,
      int revision) {
    static GoalProgressGoalFragmentDto from(GoalAutopilotService.GoalProgressGoalFragmentView view) {
      return new GoalProgressGoalFragmentDto(
          view.goalProfileId(), view.goalType(), view.supportStatus(), view.status(), view.revision());
    }
  }

  public record GoalProgressNextActionFragmentDto(
      String actionId,
      UUID planItemId,
      String actionType,
      String title,
      String reasonCode,
      int expectedDurationMinutes,
      String status) {
    static GoalProgressNextActionFragmentDto from(GoalAutopilotService.GoalProgressNextActionFragmentView view) {
      return new GoalProgressNextActionFragmentDto(
          view.actionId(),
          view.planItemId(),
          view.actionType(),
          view.title(),
          view.reasonCode(),
          view.expectedDurationMinutes(),
          view.status());
    }
  }

  public record GoalProgressForecastFragmentDto(
      UUID forecastId,
      String forecastState,
      String gapSummary,
      LocalDate etaDate,
      ProgressForecastEtaRangeDto etaRange,
      String etaUnavailableReason,
      String confidenceBand,
      String riskLevel,
      String riskReasonCode,
      LocalDate nextCheckpointDate,
      GoalClaimGuardDto claimGuard,
      Instant updatedAt) {
    static GoalProgressForecastFragmentDto from(GoalAutopilotService.GoalProgressForecastFragmentView view) {
      return new GoalProgressForecastFragmentDto(
          view.forecastId(),
          view.forecastState(),
          view.gapSummary(),
          view.etaDate(),
          view.etaRange() == null ? null : ProgressForecastEtaRangeDto.from(view.etaRange()),
          view.etaUnavailableReason(),
          view.confidenceBand(),
          view.riskLevel(),
          view.riskReasonCode(),
          view.nextCheckpointDate(),
          GoalClaimGuardDto.from(view.claimGuard()),
          view.updatedAt());
    }
  }

  public record GoalProgressCheckpointFragmentDto(
      UUID checkpointId,
      String resultStatus,
      String confidenceBand,
      String summary,
      String planUpdateSignal,
      String reasonCode) {
    static GoalProgressCheckpointFragmentDto from(GoalAutopilotService.GoalProgressCheckpointFragmentView view) {
      return new GoalProgressCheckpointFragmentDto(
          view.checkpointId(),
          view.resultStatus(),
          view.confidenceBand(),
          view.summary(),
          view.planUpdateSignal(),
          view.reasonCode());
    }
  }

  public record GoalProgressSurfaceFragmentDto(
      String surface,
      String displayState,
      boolean eligible,
      String downgradeReason,
      String nextActionRef,
      String forecastRef,
      String checkpointRef,
      List<String> safeFields) {
    static GoalProgressSurfaceFragmentDto from(GoalAutopilotService.GoalProgressSurfaceFragmentView view) {
      return new GoalProgressSurfaceFragmentDto(
          view.surface(),
          view.displayState(),
          view.eligible(),
          view.downgradeReason(),
          view.nextActionRef(),
          view.forecastRef(),
          view.checkpointRef(),
          view.safeFields());
    }
  }

  public record GoalPlanResponse(
      int schemaVersion,
      WeeklyBackplanDto weeklyBackplan,
      DailyTrainingPlanDto dailyPlan,
      AutopilotActionDto nextAction,
      GoalEntitlementDepthDto entitlementDepth)
      implements SchemaResponse {
    static GoalPlanResponse from(GoalAutopilotService.PlanResult result) {
      return new GoalPlanResponse(
          1,
          WeeklyBackplanDto.from(result.weeklyBackplan()),
          DailyTrainingPlanDto.from(result.dailyPlan()),
          AutopilotActionDto.from(result.nextAction()),
          GoalEntitlementDepthDto.from(result.entitlementDepth()));
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

  public record GoalForecastResponse(
      int schemaVersion, ProgressForecastDto forecast, GoalEntitlementDepthDto entitlementDepth)
      implements SchemaResponse {
    static GoalForecastResponse from(GoalAutopilotService.ForecastResult result) {
      return new GoalForecastResponse(
          1,
          ProgressForecastDto.from(result.forecast()),
          GoalEntitlementDepthDto.from(result.entitlementDepth()));
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

  public record RecoveryPlanResponse(
      int schemaVersion,
      RecoveryPlanDecisionDto recoveryDecision,
      DailyTrainingPlanDto dailyPlan,
      PlanUpdateSignalDto planUpdateSignal)
      implements SchemaResponse {
    static RecoveryPlanResponse from(GoalAutopilotService.RecoveryPlanResult result) {
      return new RecoveryPlanResponse(
          1,
          RecoveryPlanDecisionDto.from(result.recoveryDecision()),
          DailyTrainingPlanDto.from(result.dailyPlan()),
          PlanUpdateSignalDto.from(result.planUpdateSignal()));
    }
  }

  public record RecoveryPlanDecisionDto(
      UUID decisionId,
      UUID goalProfileId,
      UUID dailyPlanId,
      String sourceEvent,
      String recoveryMode,
      List<String> affectedPlanItemRefs,
      String inputSnapshotHash,
      String reasonCode,
      String ruleVersion,
      Instant createdAt) {
    static RecoveryPlanDecisionDto from(GoalAutopilotService.RecoveryPlanDecisionView view) {
      return new RecoveryPlanDecisionDto(
          view.decisionId(),
          view.goalProfileId(),
          view.dailyPlanId(),
          view.sourceEvent(),
          view.recoveryMode(),
          view.affectedPlanItemRefs(),
          view.inputSnapshotHash(),
          view.reasonCode(),
          view.ruleVersion(),
          view.createdAt());
    }
  }

  public record ItemPolicyDecisionResponse(
      int schemaVersion,
      List<MemoryItemPolicyStateDto> decisions,
      PlannerReplayAuditDto replayAudit)
      implements SchemaResponse {
    static ItemPolicyDecisionResponse from(GoalAutopilotService.ItemPolicyDecisionResult result) {
      return new ItemPolicyDecisionResponse(
          1,
          result.decisions().stream().map(MemoryItemPolicyStateDto::from).toList(),
          PlannerReplayAuditDto.from(result.replayAudit()));
    }
  }

  public record MemoryItemPolicyStateDto(
      String memoryItemStateId,
      UUID userId,
      String itemType,
      String itemRef,
      String interleavingGroup,
      String currentMasteryLevel,
      List<String> evidenceRefs,
      Instant lastReviewedAt,
      int exposureCount,
      int overlearningCount,
      String forgettingRisk,
      String dueDecision,
      Instant nextDueAt,
      String reasonCode,
      String ruleVersion) {
    static MemoryItemPolicyStateDto from(GoalAutopilotService.MemoryItemPolicyStateView view) {
      return new MemoryItemPolicyStateDto(
          view.memoryItemStateId(),
          view.userId(),
          view.itemType(),
          view.itemRef(),
          view.interleavingGroup(),
          view.currentMasteryLevel(),
          view.evidenceRefs(),
          view.lastReviewedAt(),
          view.exposureCount(),
          view.overlearningCount(),
          view.forgettingRisk(),
          view.dueDecision(),
          view.nextDueAt(),
          view.reasonCode(),
          view.ruleVersion());
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

  public record MasteryTransitionListResponse(int schemaVersion, List<MasteryTransitionDecisionDto> transitions)
      implements SchemaResponse {
    static MasteryTransitionListResponse from(List<GoalAutopilotService.MasteryTransitionDecisionView> transitions) {
      return new MasteryTransitionListResponse(
          1, transitions.stream().map(MasteryTransitionDecisionDto::from).toList());
    }
  }

  public record MasteryTransitionDecisionDto(
      UUID transitionId,
      UUID userId,
      String memoryItemStateId,
      String previousLevel,
      String proposedLevel,
      String acceptedLevel,
      String direction,
      List<String> evidenceRefs,
      double confidence,
      String reasonCode,
      String ruleVersion,
      Instant createdAt) {
    static MasteryTransitionDecisionDto from(GoalAutopilotService.MasteryTransitionDecisionView view) {
      return new MasteryTransitionDecisionDto(
          view.transitionId(),
          view.userId(),
          view.memoryItemStateId(),
          view.previousLevel(),
          view.proposedLevel(),
          view.acceptedLevel(),
          view.direction(),
          view.evidenceRefs(),
          view.confidence(),
          view.reasonCode(),
          view.ruleVersion(),
          view.createdAt());
    }
  }

  public record CheckpointResponse(
      int schemaVersion,
      OutcomeCheckpointDto checkpoint,
      ProgressForecastDto forecast,
      GoalEntitlementDepthDto entitlementDepth,
      PlanUpdateSignalDto planUpdateSignal)
      implements SchemaResponse {
    static CheckpointResponse from(GoalAutopilotService.CheckpointResult result) {
      return new CheckpointResponse(
          1,
          OutcomeCheckpointDto.from(result.checkpoint()),
          ProgressForecastDto.from(result.forecast()),
          GoalEntitlementDepthDto.from(result.entitlementDepth()),
          PlanUpdateSignalDto.from(result.planUpdateSignal()));
    }
  }

  public record CheckpointTaskResponse(
      int schemaVersion, CheckpointTaskDecisionDto checkpointTask, GoalEntitlementDepthDto entitlementDepth)
      implements SchemaResponse {
    static CheckpointTaskResponse from(GoalAutopilotService.CheckpointTaskDecisionView view) {
      return new CheckpointTaskResponse(
          1, CheckpointTaskDecisionDto.from(view), GoalEntitlementDepthDto.from(view.entitlementDepth()));
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

  public record GoalEntitlementDepthDto(
      String depthState,
      String allowedDepth,
      String diagnosticDepth,
      int diagnosticSampleLimit,
      String plannerDepth,
      int plannerHorizonDays,
      int plannerSessionLimit,
      String checkpointDepth,
      String checkpointCadence,
      String explanationDepth,
      boolean providerCandidateAllowed,
      boolean preciseEtaAllowed,
      String limitationReason,
      String sourceEntitlementRef,
      String ruleVersion) {
    static GoalEntitlementDepthDto from(GoalAutopilotService.EntitlementDepthView view) {
      return new GoalEntitlementDepthDto(
          view.depthState(),
          view.allowedDepth(),
          view.diagnosticDepth(),
          view.diagnosticSampleLimit(),
          view.plannerDepth(),
          view.plannerHorizonDays(),
          view.plannerSessionLimit(),
          view.checkpointDepth(),
          view.checkpointCadence(),
          view.explanationDepth(),
          view.providerCandidateAllowed(),
          view.preciseEtaAllowed(),
          view.limitationReason(),
          view.sourceEntitlementRef(),
          view.ruleVersion());
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
      int sourceGoalRevision,
      String forecastState,
      String gapSummary,
      LocalDate etaDate,
      ProgressForecastEtaRangeDto etaRange,
      String etaWindow,
      String etaUnavailableReason,
      String confidenceBand,
      String riskLevel,
      String riskReason,
      String riskReasonCode,
      LocalDate nextCheckpointDate,
      GoalClaimGuardDto claimGuard,
      ProgressForecastExplanationDto explanation,
      Instant updatedAt) {
    static ProgressForecastDto from(GoalAutopilotService.ForecastView view) {
      return new ProgressForecastDto(
          view.forecastId(),
          view.sourceGoalRevision(),
          view.forecastState(),
          view.gapSummary(),
          view.etaDate(),
          view.etaRange() == null ? null : ProgressForecastEtaRangeDto.from(view.etaRange()),
          view.etaWindow(),
          view.etaUnavailableReason(),
          view.confidenceBand(),
          view.riskLevel(),
          view.riskReason(),
          view.riskReasonCode(),
          view.nextCheckpointDate(),
          GoalClaimGuardDto.from(view.claimGuard()),
          ProgressForecastExplanationDto.from(view.explanation()),
          view.updatedAt());
    }
  }

  public record ProgressForecastEtaRangeDto(LocalDate startDate, LocalDate endDate) {
    static ProgressForecastEtaRangeDto from(GoalAutopilotService.ForecastEtaRangeView view) {
      return new ProgressForecastEtaRangeDto(view.startDate(), view.endDate());
    }
  }

  public record ProgressForecastExplanationDto(String key, String source, String fallbackReason, boolean candidateOnly) {
    static ProgressForecastExplanationDto from(GoalAutopilotService.ForecastExplanationView view) {
      return new ProgressForecastExplanationDto(view.key(), view.source(), view.fallbackReason(), view.candidateOnly());
    }
  }

  public record OutcomeCheckpointDto(
      UUID checkpointId,
      String checkpointType,
      String cadence,
      String resultStatus,
      String confidenceBand,
      String summary,
      String planUpdateSignal,
      String reasonCode) {
    static OutcomeCheckpointDto from(GoalAutopilotService.CheckpointView view) {
      return new OutcomeCheckpointDto(
          view.checkpointId(),
          view.checkpointType(),
          view.cadence(),
          view.resultStatus(),
          view.confidenceBand(),
          view.summary(),
          view.planUpdateSignal(),
          view.reasonCode());
    }
  }

  @JsonInclude(JsonInclude.Include.NON_NULL)
  public record CheckpointTaskDecisionDto(
      String checkpointState,
      String dueStatus,
      LocalDate dueDate,
      LocalDate nextDueDate,
      String cadence,
      String limitationReason,
      String supportStatus,
      String contentCoverage,
      CheckpointTaskDefinitionDto task,
      String ruleVersion) {
    static CheckpointTaskDecisionDto from(GoalAutopilotService.CheckpointTaskDecisionView view) {
      return new CheckpointTaskDecisionDto(
          view.checkpointState(),
          view.dueStatus(),
          view.dueDate(),
          view.nextDueDate(),
          view.cadence(),
          view.limitationReason(),
          view.supportStatus(),
          view.contentCoverage(),
          view.task() == null ? null : CheckpointTaskDefinitionDto.from(view.task()),
          view.ruleVersion());
    }
  }

  public record CheckpointTaskDefinitionDto(
      String taskId,
      String taskType,
      String cadence,
      String goalType,
      String promptRef,
      int estimatedDurationMinutes,
      List<String> requiredEvidence,
      String rubricRef,
      String supportStatus,
      String limitationReason,
      String aiDepth,
      String scoringBoundary) {
    static CheckpointTaskDefinitionDto from(GoalAutopilotService.CheckpointTaskDefinitionView view) {
      return new CheckpointTaskDefinitionDto(
          view.taskId(),
          view.taskType(),
          view.cadence(),
          view.goalType(),
          view.promptRef(),
          view.estimatedDurationMinutes(),
          view.requiredEvidence(),
          view.rubricRef(),
          view.supportStatus(),
          view.limitationReason(),
          view.aiDepth(),
          view.scoringBoundary());
    }
  }

  @JsonInclude(JsonInclude.Include.NON_NULL)
  public record PlanUpdateSignalDto(
      String signalType,
      String reasonCode,
      UUID sourceCheckpointId,
      String ruleVersion,
      String inputSnapshotHash,
      UUID replayAuditId) {
    static PlanUpdateSignalDto from(GoalAutopilotService.PlanUpdateSignalView view) {
      return new PlanUpdateSignalDto(
          view.signalType(),
          view.reasonCode(),
          view.sourceCheckpointId(),
          view.ruleVersion(),
          view.inputSnapshotHash(),
          view.replayAuditId());
    }
  }
}
