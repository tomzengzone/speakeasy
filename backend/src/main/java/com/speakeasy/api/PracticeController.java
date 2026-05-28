package com.speakeasy.api;

import com.speakeasy.common.SchemaResponse;
import com.speakeasy.practice.PracticeService;
import com.speakeasy.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpHeaders;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PracticeController {
  private final PracticeService service;

  public PracticeController(PracticeService service) {
    this.service = service;
  }

  @PostMapping("/practice/sessions")
  public PracticeSessionResponse startSession(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody StartSessionRequest request) {
    return PracticeSessionResponse.from(service.startOrResume(
        currentUser.userId(),
        request.scenarioId(),
        request.levelCode(),
        request.resumeExisting() == null || request.resumeExisting()));
  }

  @GetMapping("/practice/sessions/{sessionId}")
  public PracticeSessionResponse getSession(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID sessionId) {
    return PracticeSessionResponse.from(service.getSession(currentUser.userId(), sessionId));
  }

  @PostMapping("/practice/sessions/{sessionId}/turns")
  public PracticeTurnResponse submitTurn(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable UUID sessionId,
      @RequestHeader(name = "Idempotency-Key") String idempotencyKey,
      @Valid @RequestBody SubmitTurnRequest request) {
    return PracticeTurnResponse.from(service.submitTurn(
        currentUser.userId(),
        sessionId,
        idempotencyKey,
        request.transcript(),
        request.audioRef(),
        request.clientStateVersion()));
  }

  @PostMapping("/practice/sessions/{sessionId}/complete")
  public SessionSummaryResponse complete(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID sessionId) {
    return SessionSummaryResponse.from(service.complete(currentUser.userId(), sessionId));
  }

  public record StartSessionRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank @Pattern(regexp = "job_interview|onboarding_introduction") String scenarioId,
      @NotBlank @Pattern(regexp = "L1|L2|L3") String levelCode,
      Boolean resumeExisting) {}

  public record SubmitTurnRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      String transcript,
      String audioRef,
      Integer clientStateVersion) {}

  public record PracticeSessionResponse(int schemaVersion, PracticeSessionDto session) implements SchemaResponse {
    static PracticeSessionResponse from(PracticeService.PracticeSessionView session) {
      return new PracticeSessionResponse(1, PracticeSessionDto.from(session));
    }
  }

  public record PracticeSessionDto(
      UUID sessionId,
      String scenarioId,
      String levelCode,
      String status,
      int currentTurnIndex,
      List<ConversationMessageDto> messages) {
    static PracticeSessionDto from(PracticeService.PracticeSessionView session) {
      return new PracticeSessionDto(
          session.sessionId(),
          session.scenarioId(),
          session.levelCode(),
          session.status(),
          session.currentTurnIndex(),
          session.messages().stream().map(ConversationMessageDto::from).toList());
    }
  }

  public record PracticeTurnResponse(
      int schemaVersion,
      UUID sessionId,
      String sessionStatus,
      ConversationMessageDto userMessage,
      CoachFeedbackDto coachFeedback,
      List<LearningEvidenceCandidateDto> learningEvidenceCandidates,
      RecoverableProviderErrorDto recoverableError)
      implements SchemaResponse {
    static PracticeTurnResponse from(PracticeService.PracticeTurnResult result) {
      return new PracticeTurnResponse(
          1,
          result.sessionId(),
          result.sessionStatus(),
          ConversationMessageDto.from(result.userMessage()),
          result.coachFeedback() == null ? null : CoachFeedbackDto.from(result.coachFeedback()),
          result.learningEvidenceCandidates().stream().map(LearningEvidenceCandidateDto::from).toList(),
          result.recoverableError() == null ? null : RecoverableProviderErrorDto.from(result.recoverableError()));
    }
  }

  public record ConversationMessageDto(String messageId, String role, String text, String audioRef, Instant createdAt) {
    static ConversationMessageDto from(PracticeService.MessageView message) {
      return new ConversationMessageDto(
          message.messageId(), message.role(), message.text(), message.audioRef(), message.createdAt());
    }
  }

  public record CoachFeedbackDto(
      String summary,
      String feedbackType,
      String mainIssueType,
      String suggestedExpression,
      String nextPrompt,
      ScoreSignalDto scoreSignal,
      String validationStatus,
      String providerStatus) {
    static CoachFeedbackDto from(PracticeService.FeedbackView feedback) {
      return new CoachFeedbackDto(
          feedback.summary(),
          feedback.feedbackType(),
          feedback.mainIssueType(),
          feedback.suggestedExpression(),
          feedback.nextPrompt(),
          ScoreSignalDto.from(feedback.scoreSignal()),
          feedback.validationStatus(),
          feedback.providerStatus());
    }
  }

  public record ScoreSignalDto(String scoreKind, Double value, Double confidence, String status, String source) {
    static ScoreSignalDto from(PracticeService.ScoreSignalView score) {
      return new ScoreSignalDto(score.scoreKind(), score.value(), score.confidence(), score.status(), "server_side_adapter");
    }
  }

  public record LearningEvidenceCandidateDto(
      String candidateId,
      String evidenceType,
      String targetExpressionId,
      String text,
      double confidence,
      String status) {
    static LearningEvidenceCandidateDto from(PracticeService.LearningEvidenceCandidateView candidate) {
      return new LearningEvidenceCandidateDto(
          candidate.candidateId(),
          candidate.evidenceType(),
          candidate.targetExpressionId(),
          candidate.text(),
          candidate.confidence(),
          candidate.status());
    }
  }

  public record RecoverableProviderErrorDto(String code, String message, boolean retryable) {
    static RecoverableProviderErrorDto from(PracticeService.RecoverableErrorView error) {
      return new RecoverableProviderErrorDto(error.code(), error.message(), error.retryable());
    }
  }

  public record SessionSummaryResponse(int schemaVersion, SessionSummaryDto summary) implements SchemaResponse {
    static SessionSummaryResponse from(PracticeService.SessionSummaryView summary) {
      return new SessionSummaryResponse(1, new SessionSummaryDto(
          summary.sessionId(), summary.learnedItems(), summary.weakPoints(), summary.nextFocus()));
    }
  }

  public record SessionSummaryDto(UUID sessionId, List<String> learnedItems, List<String> weakPoints, String nextFocus) {}
}
