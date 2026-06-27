package com.speakeasy.api;

import com.speakeasy.common.SchemaResponse;
import com.speakeasy.security.CurrentUser;
import com.speakeasy.training.TrainingService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class TrainingController {
  private final TrainingService service;

  public TrainingController(TrainingService service) {
    this.service = service;
  }

  @PostMapping("/training/sessions")
  public TrainingSessionResponse startSession(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody StartTrainingSessionRequest request) {
    return TrainingSessionResponse.from(service.startOrResume(
        currentUser.userId(),
        request.scenarioId(),
        request.levelCode(),
        request.resumeExisting() == null || request.resumeExisting()));
  }

  @GetMapping("/training/sessions/{session_id}")
  public TrainingSessionResponse getSession(
      @AuthenticationPrincipal CurrentUser currentUser, @PathVariable("session_id") UUID sessionId) {
    return TrainingSessionResponse.from(service.getSession(currentUser.userId(), sessionId));
  }

  @PostMapping("/training/sessions/{session_id}/turns")
  public TrainingTurnResponse submitTurn(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable("session_id") UUID sessionId,
      @RequestHeader(name = "Idempotency-Key") String idempotencyKey,
      @Valid @RequestBody SubmitTrainingTurnRequest request) {
    return TrainingTurnResponse.from(service.submitTurn(
        currentUser.userId(),
        sessionId,
        idempotencyKey,
        request.transcript(),
        request.audioRef(),
        request.selectedOptionId(),
        request.clientStateVersion()));
  }

  @PostMapping("/training/sessions/{session_id}/planner/next")
  public PlannerDecisionResponse plannerNext(
      @AuthenticationPrincipal CurrentUser currentUser, @PathVariable("session_id") UUID sessionId) {
    return PlannerDecisionResponse.from(service.plannerNext(currentUser.userId(), sessionId));
  }

  @PostMapping("/training/sessions/{session_id}/hints")
  public HintResponse hint(
      @AuthenticationPrincipal CurrentUser currentUser, @PathVariable("session_id") UUID sessionId) {
    return HintResponse.from(service.hint(currentUser.userId(), sessionId));
  }

  @PostMapping("/training/sessions/{session_id}/pressure-check")
  public PlannerDecisionResponse pressureCheck(
      @AuthenticationPrincipal CurrentUser currentUser, @PathVariable("session_id") UUID sessionId) {
    return PlannerDecisionResponse.from(service.pressureCheck(currentUser.userId(), sessionId));
  }

  @PostMapping("/training/sessions/{session_id}/complete")
  public TrainingRecapResponse complete(
      @AuthenticationPrincipal CurrentUser currentUser, @PathVariable("session_id") UUID sessionId) {
    return TrainingRecapResponse.from(service.complete(currentUser.userId(), sessionId));
  }

  public record StartTrainingSessionRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String scenarioId,
      @NotBlank String levelCode,
      Boolean resumeExisting) {}

  public record SubmitTrainingTurnRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      String transcript,
      String audioRef,
      String selectedOptionId,
      Integer clientStateVersion) {}

  public record TrainingSessionResponse(int schemaVersion, TrainingSessionDto session) implements SchemaResponse {
    static TrainingSessionResponse from(TrainingService.TrainingSessionView session) {
      return new TrainingSessionResponse(1, TrainingSessionDto.from(session));
    }
  }

  public record TrainingTurnResponse(
      int schemaVersion,
      TrainingSessionDto session,
      TrainingTurnDto turn,
      TrainingFeedbackDto feedback,
      PlannerDecisionDto plannerDecision,
      List<LearningEvidenceCandidateDto> learningEvidenceCandidates,
      RecoverableProviderErrorDto recoverableError)
      implements SchemaResponse {
    static TrainingTurnResponse from(TrainingService.TrainingTurnResult result) {
      return new TrainingTurnResponse(
          1,
          TrainingSessionDto.from(result.session()),
          TrainingTurnDto.from(result.turn()),
          result.feedback() == null ? null : TrainingFeedbackDto.from(result.feedback()),
          result.plannerDecision() == null ? null : PlannerDecisionDto.from(result.plannerDecision()),
          result.learningEvidenceCandidates().stream().map(LearningEvidenceCandidateDto::from).toList(),
          result.recoverableError() == null ? null : RecoverableProviderErrorDto.from(result.recoverableError()));
    }
  }

  public record PlannerDecisionResponse(int schemaVersion, PlannerDecisionDto plannerDecision) implements SchemaResponse {
    static PlannerDecisionResponse from(TrainingService.PlannerDecisionView decision) {
      return new PlannerDecisionResponse(1, PlannerDecisionDto.from(decision));
    }
  }

  public record HintResponse(
      int schemaVersion, TrainingSessionDto session, PlannerDecisionDto plannerDecision, String prompt)
      implements SchemaResponse {
    static HintResponse from(TrainingService.HintResult result) {
      return new HintResponse(1, TrainingSessionDto.from(result.session()), PlannerDecisionDto.from(result.plannerDecision()), result.prompt());
    }
  }

  public record TrainingRecapResponse(int schemaVersion, TrainingRecapDto recap) implements SchemaResponse {
    static TrainingRecapResponse from(TrainingService.TrainingRecapView recap) {
      return new TrainingRecapResponse(1, TrainingRecapDto.from(recap));
    }
  }

  public record TrainingSessionDto(
      UUID sessionId,
      UUID userId,
      String scenarioId,
      UUID scenarioVersionId,
      String levelCode,
      String status,
      int currentTurnIndex,
      String currentStepKey,
      String currentMicroAction,
      String hintLevel,
      int failureCount,
      int successCount,
      String evidenceWriteStatus,
      String syncStatus,
      String mappingVersion,
      String actionChainVersion,
      String lastReasonCode,
      List<ActionChainStepDto> actionChain,
      PlannerDecisionDto lastDecision,
      TrainingRecapDto recap) {
    static TrainingSessionDto from(TrainingService.TrainingSessionView session) {
      return new TrainingSessionDto(
          session.sessionId(),
          session.userId(),
          session.scenarioId(),
          session.scenarioVersionId(),
          session.levelCode(),
          session.status(),
          session.currentTurnIndex(),
          session.currentStepKey(),
          session.currentMicroAction(),
          session.hintLevel(),
          session.failureCount(),
          session.successCount(),
          session.evidenceWriteStatus(),
          session.syncStatus(),
          session.mappingVersion(),
          session.actionChainVersion(),
          session.lastReasonCode(),
          session.actionChain().stream().map(ActionChainStepDto::from).toList(),
          session.lastDecision() == null ? null : PlannerDecisionDto.from(session.lastDecision()),
          session.recap() == null ? null : TrainingRecapDto.from(session.recap()));
    }
  }

  public record ActionChainStepDto(
      String stepKey,
      String label,
      String microAction,
      int orderIndex,
      String targetExpressionId,
      String promptText,
      String mappingVersion,
      String reviewStatus) {
    static ActionChainStepDto from(TrainingService.ActionChainStepView step) {
      return new ActionChainStepDto(
          step.stepKey(),
          step.label(),
          step.microAction(),
          step.orderIndex(),
          step.targetExpressionId(),
          step.promptText(),
          step.mappingVersion(),
          step.reviewStatus());
    }
  }

  public record TrainingTurnDto(
      UUID turnId,
      int turnIndex,
      String stepKey,
      String microAction,
      String transcript,
      String audioRef,
      String selectedOptionId,
      String result,
      String providerStatus,
      Instant createdAt) {
    static TrainingTurnDto from(TrainingService.TrainingTurnView turn) {
      return new TrainingTurnDto(
          turn.turnId(),
          turn.turnIndex(),
          turn.stepKey(),
          turn.microAction(),
          turn.transcript(),
          turn.audioRef(),
          turn.selectedOptionId(),
          turn.result(),
          turn.providerStatus(),
          turn.createdAt());
    }
  }

  public record TrainingFeedbackDto(
      String summary,
      String mainIssueType,
      String betterExpression,
      String nextPrompt,
      boolean pronunciationAvailable,
      String completionStatus,
      String taskStatus,
      String validationStatus,
      String providerStatus) {
    static TrainingFeedbackDto from(TrainingService.FeedbackView feedback) {
      return new TrainingFeedbackDto(
          feedback.summary(),
          feedback.mainIssueType(),
          feedback.betterExpression(),
          feedback.nextPrompt(),
          feedback.pronunciationAvailable(),
          feedback.completionStatus(),
          feedback.taskStatus(),
          feedback.validationStatus(),
          feedback.providerStatus());
    }
  }

  public record PlannerDecisionDto(
      UUID decisionId,
      String type,
      String nextStatus,
      String nextStepKey,
      String nextMicroAction,
      String nextHintLevel,
      String reasonCode,
      String plannerVersion,
      Instant createdAt) {
    static PlannerDecisionDto from(TrainingService.PlannerDecisionView decision) {
      return new PlannerDecisionDto(
          decision.decisionId(),
          decision.type(),
          decision.nextStatus(),
          decision.nextStepKey(),
          decision.nextMicroAction(),
          decision.nextHintLevel(),
          decision.reasonCode(),
          decision.plannerVersion(),
          decision.createdAt());
    }
  }

  public record LearningEvidenceCandidateDto(
      UUID candidateId,
      UUID learningEvidenceId,
      String evidenceType,
      UUID targetExpressionId,
      double confidence,
      String status,
      String ruleName,
      String reasonCode,
      int schemaVersion) {
    static LearningEvidenceCandidateDto from(TrainingService.EvidenceCandidateView candidate) {
      return new LearningEvidenceCandidateDto(
          candidate.candidateId(),
          candidate.learningEvidenceId(),
          candidate.evidenceType(),
          candidate.targetExpressionId(),
          candidate.confidence(),
          candidate.status(),
          candidate.ruleName(),
          candidate.reasonCode(),
          candidate.schemaVersion());
    }
  }

  public record RecoverableProviderErrorDto(String code, String message, boolean retryable) {
    static RecoverableProviderErrorDto from(TrainingService.RecoverableErrorView error) {
      return new RecoverableProviderErrorDto(error.code(), error.message(), error.retryable());
    }
  }

  public record TrainingRecapDto(
      UUID recapId,
      UUID sessionId,
      List<String> learnedItems,
      List<String> weakPoints,
      String nextFocus,
      List<String> acceptedEvidenceIds,
      Instant createdAt) {
    static TrainingRecapDto from(TrainingService.TrainingRecapView recap) {
      return new TrainingRecapDto(
          recap.recapId(),
          recap.sessionId(),
          recap.learnedItems(),
          recap.weakPoints(),
          recap.nextFocus(),
          recap.acceptedEvidenceIds(),
          recap.createdAt());
    }
  }
}
