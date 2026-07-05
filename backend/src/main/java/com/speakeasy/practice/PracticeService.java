package com.speakeasy.practice;

import com.speakeasy.ai.AiGatewayService;
import com.speakeasy.commerce.EntitlementGateService;
import com.speakeasy.common.ApiException;
import com.speakeasy.content.ScenarioLevelRepository;
import com.speakeasy.content.ScenarioRepository;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.identity.UserAccountRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class PracticeService {
  private static final Collection<String> RECOVERABLE_STATUSES = List.of("active", "feedback", "recoverable_error");

  private final UserAccountRepository users;
  private final ScenarioRepository scenarios;
  private final ScenarioLevelRepository levels;
  private final PracticeSessionRepository sessions;
  private final PracticeTurnRepository turns;
  private final CoachFeedbackRepository feedbacks;
  private final SessionSummaryRepository summaries;
  private final AiGatewayService aiGateway;
  private final EntitlementGateService entitlementGateService;
  private final Clock clock;

  public PracticeService(
      UserAccountRepository users,
      ScenarioRepository scenarios,
      ScenarioLevelRepository levels,
      PracticeSessionRepository sessions,
      PracticeTurnRepository turns,
      CoachFeedbackRepository feedbacks,
      SessionSummaryRepository summaries,
      AiGatewayService aiGateway,
      EntitlementGateService entitlementGateService,
      Clock clock) {
    this.users = users;
    this.scenarios = scenarios;
    this.levels = levels;
    this.sessions = sessions;
    this.turns = turns;
    this.feedbacks = feedbacks;
    this.summaries = summaries;
    this.aiGateway = aiGateway;
    this.entitlementGateService = entitlementGateService;
    this.clock = clock;
  }

  @Transactional
  public PracticeSessionView startOrResume(UUID userId, String scenarioId, String levelCode, boolean resumeExisting) {
    requireUser(userId);
    requireOfficialScenarioLevel(scenarioId, levelCode);
    entitlementGateService.requireScenarioLevel(userId, scenarioId, levelCode);
    if (resumeExisting) {
      var existing = sessions.findFirstByUserIdAndScenarioIdAndLevelCodeAndStatusInOrderByUpdatedAtDesc(
          userId, scenarioId, levelCode, RECOVERABLE_STATUSES);
      if (existing.isPresent()) {
        return sessionView(existing.get());
      }
    }
    PracticeSession session = sessions.save(new PracticeSession(UUID.randomUUID(), userId, scenarioId, levelCode, Instant.now(clock)));
    return sessionView(session);
  }

  @Transactional(readOnly = true)
  public PracticeSessionView getSession(UUID userId, UUID sessionId) {
    PracticeSession session = requireSession(userId, sessionId);
    return sessionView(session);
  }

  @Transactional
  public PracticeTurnResult submitTurn(
      UUID userId, UUID sessionId, String idempotencyKey, String transcript, String audioRef, Integer clientStateVersion) {
    PracticeSession session = requireSession(userId, sessionId);
    if ("completed".equals(session.getStatus())) {
      throw new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Completed practice sessions cannot accept new turns.");
    }
    String normalizedTranscript = normalize(transcript);
    String normalizedAudioRef = normalize(audioRef);
    if (idempotencyKey == null || idempotencyKey.isBlank()) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", "Idempotency-Key is required.");
    }
    if (normalizedTranscript == null && normalizedAudioRef == null) {
      throw new ApiException(
          HttpStatus.UNPROCESSABLE_ENTITY,
          "SCHEMA_VALIDATION_FAILED",
          "Either transcript or audio_ref is required.");
    }
    if (normalizedAudioRef != null) {
      aiGateway.validateTrustedAudioRef(userId, "practice", normalizedAudioRef);
    }

    var existing = turns.findBySessionIdAndIdempotencyKey(sessionId, idempotencyKey);
    if (existing.isPresent()) {
      PracticeTurn turn = existing.get();
      if (!turn.samePayload(normalizedTranscript, normalizedAudioRef)) {
        throw new ApiException(HttpStatus.CONFLICT, "IDEMPOTENCY_CONFLICT", "Idempotency key reused with different payload.");
      }
      return turnResult(session, turn);
    }

    Instant now = Instant.now(clock);
    AiGatewayService.TranscribeResult transcribeResult = null;
    if (normalizedTranscript == null) {
      transcribeResult = aiGateway.transcribe(userId, normalizedAudioRef, "en-US");
      if (!"available".equals(transcribeResult.status())) {
        return saveRecoverableTurn(
            session,
            userId,
            idempotencyKey,
            "",
            normalizedAudioRef,
            transcribeResult.status(),
            "asr_unavailable",
            "Transcription is temporarily unavailable. Please retry or type your answer.",
            now);
      }
      normalizedTranscript = transcribeResult.transcript();
    }

    AiGatewayService.CoachResult coachResult = aiGateway.coach(userId, sessionId, normalizedTranscript, List.of());
    int turnIndex = session.getCurrentTurnIndex() + 1;
    PracticeTurn turn = turns.save(new PracticeTurn(
        UUID.randomUUID(),
        sessionId,
        userId,
        turnIndex,
        "learner",
        normalizedTranscript,
        normalizedAudioRef,
        coachResult.recoverable() ? "feedback_ready" : "feedback_ready",
        idempotencyKey,
        coachResult.providerStatus(),
        now));
    CoachFeedback feedback = saveFeedback(sessionId, turn.getPracticeTurnId(), coachResult, now);
    if (coachResult.recoverable()) {
      session.markRecoverableError(turnIndex, now);
    } else {
      session.markFeedbackReady(turnIndex, now);
    }
    sessions.save(session);
    return turnResult(session, turn, feedback);
  }

  @Transactional
  public SessionSummaryView complete(UUID userId, UUID sessionId) {
    PracticeSession session = requireSession(userId, sessionId);
    var existing = summaries.findBySessionId(sessionId);
    if (existing.isPresent()) {
      return summaryView(existing.get());
    }
    Instant now = Instant.now(clock);
    List<CoachFeedback> sessionFeedbacks = feedbacks.findBySessionIdOrderByCreatedAtAsc(sessionId);
    List<String> learnedItems = sessionFeedbacks.stream()
        .map(CoachFeedback::getSuggestedExpression)
        .filter(value -> value != null && !value.isBlank())
        .distinct()
        .toList();
    List<String> weakPoints = sessionFeedbacks.stream()
        .map(CoachFeedback::getMainIssueType)
        .filter(value -> value != null && !value.isBlank() && !"none".equals(value))
        .distinct()
        .toList();
    String nextFocus = sessionFeedbacks.isEmpty()
        ? "Complete one practice turn before reviewing."
        : sessionFeedbacks.get(sessionFeedbacks.size() - 1).getNextPrompt();
    SessionSummary summary = summaries.save(new SessionSummary(
        UUID.randomUUID(),
        sessionId,
        userId,
        learnedItems.isEmpty() ? List.of("practice_session_completed") : learnedItems,
        weakPoints.isEmpty() ? List.of("none") : weakPoints,
        nextFocus == null || nextFocus.isBlank() ? "Review one useful expression." : nextFocus,
        "candidate_only:practice_session:" + sessionId,
        now));
    session.complete(now);
    sessions.save(session);
    return summaryView(summary);
  }

  @Transactional(readOnly = true)
  public UnfinishedSessionView latestUnfinished(UUID userId) {
    return sessions.findFirstByUserIdAndStatusInOrderByUpdatedAtDesc(userId, RECOVERABLE_STATUSES)
        .map(session -> new UnfinishedSessionView(session.getPracticeSessionId(), session.getScenarioId(), session.getLevelCode(), session.getStatus()))
        .orElse(null);
  }

  private PracticeTurnResult saveRecoverableTurn(
      PracticeSession session,
      UUID userId,
      String idempotencyKey,
      String transcript,
      String audioRef,
      String providerStatus,
      String recoverableErrorCode,
      String summary,
      Instant now) {
    int turnIndex = session.getCurrentTurnIndex() + 1;
    PracticeTurn turn = turns.save(new PracticeTurn(
        UUID.randomUUID(),
        session.getPracticeSessionId(),
        userId,
        turnIndex,
        "learner",
        transcript,
        audioRef,
        "rejected",
        idempotencyKey,
        providerStatus,
        now));
    AiGatewayService.CoachResult fallback = new AiGatewayService.CoachResult(
        "recoverable_error",
        summary,
        "none",
        null,
        "Please retry this turn.",
        new AiGatewayService.ScoreResult("pronunciation", null, null, "unavailable"),
        "fallback",
        providerStatus,
        recoverableErrorCode);
    CoachFeedback feedback = saveFeedback(session.getPracticeSessionId(), turn.getPracticeTurnId(), fallback, now);
    session.markRecoverableError(turnIndex, now);
    sessions.save(session);
    return turnResult(session, turn, feedback);
  }

  private CoachFeedback saveFeedback(UUID sessionId, UUID sourceTurnId, AiGatewayService.CoachResult result, Instant now) {
    return feedbacks.save(new CoachFeedback(
        UUID.randomUUID(),
        sessionId,
        sourceTurnId,
        result.feedbackType(),
        result.summary(),
        result.mainIssueType(),
        result.suggestedExpression(),
        result.nextPrompt(),
        result.scoreSignal().scoreKind(),
        result.scoreSignal().value(),
        result.scoreSignal().confidence(),
        result.scoreSignal().status(),
        result.validationStatus(),
        result.providerStatus(),
        result.recoverableErrorCode(),
        now));
  }

  private PracticeTurnResult turnResult(PracticeSession session, PracticeTurn turn) {
    CoachFeedback feedback = feedbacks.findBySourceTurnId(turn.getPracticeTurnId()).orElse(null);
    return turnResult(session, turn, feedback);
  }

  private PracticeTurnResult turnResult(PracticeSession session, PracticeTurn turn, CoachFeedback feedback) {
    List<LearningEvidenceCandidateView> candidates = new ArrayList<>();
    if (feedback != null && !feedback.recoverable() && feedback.getSuggestedExpression() != null) {
      candidates.add(new LearningEvidenceCandidateView(
          "candidate-" + turn.getPracticeTurnId(),
          "expression_suggestion",
          null,
          feedback.getSuggestedExpression(),
          0.72,
          "candidate"));
    }
    return new PracticeTurnResult(
        session.getPracticeSessionId(),
        session.getStatus(),
        messageView(turn),
        feedback == null ? null : feedbackView(feedback),
        candidates,
        feedback != null && feedback.recoverable()
            ? new RecoverableErrorView(feedback.getRecoverableErrorCode(), feedback.getSummary(), true)
            : null);
  }

  private PracticeSessionView sessionView(PracticeSession session) {
    List<MessageView> messages = new ArrayList<>();
    for (PracticeTurn turn : turns.findBySessionIdOrderByTurnIndexAsc(session.getPracticeSessionId())) {
      messages.add(messageView(turn));
      feedbacks.findBySourceTurnId(turn.getPracticeTurnId())
          .filter(feedback -> !feedback.recoverable())
          .ifPresent(feedback -> messages.add(new MessageView(
              feedback.getFeedbackId().toString(), "coach", feedback.getSummary(), null, feedback.getCreatedAt())));
    }
    return new PracticeSessionView(
        session.getPracticeSessionId(),
        session.getScenarioId(),
        session.getLevelCode(),
        session.getStatus(),
        session.getCurrentTurnIndex(),
        messages);
  }

  private MessageView messageView(PracticeTurn turn) {
    return new MessageView(turn.getPracticeTurnId().toString(), turn.getRole(), turn.getTranscript(), turn.getAudioRef(), turn.getCreatedAt());
  }

  private FeedbackView feedbackView(CoachFeedback feedback) {
    return new FeedbackView(
        feedback.getSummary(),
        feedback.getFeedbackType(),
        feedback.getMainIssueType(),
        feedback.getSuggestedExpression(),
        feedback.getNextPrompt(),
        new ScoreSignalView(
            feedback.getScoreKind(),
            feedback.getScoreValue(),
            feedback.getScoreConfidence(),
            feedback.getScoreStatus()),
        feedback.getValidationStatus(),
        feedback.getProviderStatus());
  }

  private SessionSummaryView summaryView(SessionSummary summary) {
    return new SessionSummaryView(summary.getSessionId(), summary.getLearnedItems(), summary.getWeakPoints(), summary.getNextFocus());
  }

  private PracticeSession requireSession(UUID userId, UUID sessionId) {
    return sessions.findByPracticeSessionIdAndUserId(sessionId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Practice session was not found."));
  }

  private void requireOfficialScenarioLevel(String scenarioId, String levelCode) {
    scenarios.findById(scenarioId)
        .filter(scenario -> "available".equals(scenario.getStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Official scenario was not found."));
    levels.findByScenarioIdAndLevelCode(scenarioId, levelCode)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Scenario level was not found."));
  }

  private UserAccount requireUser(UUID userId) {
    return users.findById(userId)
        .filter(user -> !"deleted".equals(user.getAccountStatus()) && !"disabled".equals(user.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));
  }

  private String normalize(String value) {
    return value == null || value.isBlank() ? null : value.trim();
  }

  public record PracticeSessionView(
      UUID sessionId,
      String scenarioId,
      String levelCode,
      String status,
      int currentTurnIndex,
      List<MessageView> messages) {}

  public record PracticeTurnResult(
      UUID sessionId,
      String sessionStatus,
      MessageView userMessage,
      FeedbackView coachFeedback,
      List<LearningEvidenceCandidateView> learningEvidenceCandidates,
      RecoverableErrorView recoverableError) {}

  public record MessageView(String messageId, String role, String text, String audioRef, Instant createdAt) {}

  public record FeedbackView(
      String summary,
      String feedbackType,
      String mainIssueType,
      String suggestedExpression,
      String nextPrompt,
      ScoreSignalView scoreSignal,
      String validationStatus,
      String providerStatus) {}

  public record ScoreSignalView(String scoreKind, Double value, Double confidence, String status) {}

  public record LearningEvidenceCandidateView(
      String candidateId,
      String evidenceType,
      String targetExpressionId,
      String text,
      double confidence,
      String status) {}

  public record RecoverableErrorView(String code, String message, boolean retryable) {}

  public record SessionSummaryView(UUID sessionId, List<String> learnedItems, List<String> weakPoints, String nextFocus) {}

  public record UnfinishedSessionView(UUID sessionId, String scenarioId, String levelCode, String status) {}
}
