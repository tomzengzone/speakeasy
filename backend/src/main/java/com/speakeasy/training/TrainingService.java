package com.speakeasy.training;

import com.speakeasy.ai.AiGatewayService;
import com.speakeasy.commerce.EntitlementGateService;
import com.speakeasy.common.ApiException;
import com.speakeasy.content.ScenarioLevelRepository;
import com.speakeasy.content.ScenarioRepository;
import com.speakeasy.content.ScenarioVersion;
import com.speakeasy.content.ScenarioVersionRepository;
import com.speakeasy.content.TargetExpression;
import com.speakeasy.content.TargetExpressionRepository;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.learning.LearningEvidence;
import com.speakeasy.learning.LearningMemoryService;
import com.speakeasy.usage.UsageReservation;
import com.speakeasy.usage.UsageService;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HexFormat;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class TrainingService {
  private static final Collection<String> RESUMABLE_STATUSES =
      List.of("ready", "retry", "feedback", "pressure_check", "recoverable_error", "recap");

  private final UserAccountRepository users;
  private final ScenarioRepository scenarios;
  private final ScenarioVersionRepository versions;
  private final ScenarioLevelRepository levels;
  private final TargetExpressionRepository expressions;
  private final TrainingContentMappingRepository mappings;
  private final TrainingSessionRepository sessions;
  private final TrainingTurnRepository turns;
  private final TrainingPlannerDecisionRepository plannerDecisions;
  private final TrainingEvidenceCandidateRepository evidenceCandidates;
  private final TrainingRecapRepository recaps;
  private final TrainingMetricEventRepository metrics;
  private final TrainingPlannerService planner;
  private final AiGatewayService aiGateway;
  private final LearningMemoryService learningMemory;
  private final EntitlementGateService entitlementGate;
  private final UsageService usageService;
  private final Clock clock;

  public TrainingService(
      UserAccountRepository users,
      ScenarioRepository scenarios,
      ScenarioVersionRepository versions,
      ScenarioLevelRepository levels,
      TargetExpressionRepository expressions,
      TrainingContentMappingRepository mappings,
      TrainingSessionRepository sessions,
      TrainingTurnRepository turns,
      TrainingPlannerDecisionRepository plannerDecisions,
      TrainingEvidenceCandidateRepository evidenceCandidates,
      TrainingRecapRepository recaps,
      TrainingMetricEventRepository metrics,
      TrainingPlannerService planner,
      AiGatewayService aiGateway,
      LearningMemoryService learningMemory,
      EntitlementGateService entitlementGate,
      UsageService usageService,
      Clock clock) {
    this.users = users;
    this.scenarios = scenarios;
    this.versions = versions;
    this.levels = levels;
    this.expressions = expressions;
    this.mappings = mappings;
    this.sessions = sessions;
    this.turns = turns;
    this.plannerDecisions = plannerDecisions;
    this.evidenceCandidates = evidenceCandidates;
    this.recaps = recaps;
    this.metrics = metrics;
    this.planner = planner;
    this.aiGateway = aiGateway;
    this.learningMemory = learningMemory;
    this.entitlementGate = entitlementGate;
    this.usageService = usageService;
    this.clock = clock;
  }

  @Transactional
  public TrainingSessionView startOrResume(UUID userId, String scenarioId, String levelCode, boolean resumeExisting) {
    requireUser(userId);
    String canonicalScenarioId = cleanRequired(scenarioId, "scenario_id");
    String canonicalLevelCode = canonicalLevelCode(levelCode);
    ScenarioVersion version = requireTrainingContent(canonicalScenarioId, canonicalLevelCode);
    entitlementGate.requireScenarioLevel(userId, canonicalScenarioId, canonicalLevelCode);
    if (resumeExisting) {
      var existing = sessions.findFirstByUserIdAndScenarioIdAndLevelCodeAndStatusInOrderByUpdatedAtDesc(
          userId, canonicalScenarioId, canonicalLevelCode, RESUMABLE_STATUSES);
      if (existing.isPresent()) {
        saveMetric(userId, existing.get().getTrainingSessionId(), "training_session_resume", "success", null, null);
        return sessionView(existing.get());
      }
    }
    Instant now = Instant.now(clock);
    TrainingSession session = new TrainingSession(
        UUID.randomUUID(),
        userId,
        canonicalScenarioId,
        version.getScenarioVersionId(),
        canonicalLevelCode,
        mappingVersion(version),
        TrainingPlannerService.ACTION_CHAIN_VERSION,
        now);
    UsageReservation reservation =
        usageService.reserveProviderCall(userId, "training", "training_session:" + session.getTrainingSessionId());
    usageService.commit(userId, reservation.getReservationId(), "training_session_start:" + session.getTrainingSessionId());
    TrainingSession saved = sessions.save(session);
    saveMetric(userId, saved.getTrainingSessionId(), "training_session_start", "success", null, null);
    return sessionView(saved);
  }

  @Transactional(readOnly = true)
  public TrainingSessionView getSession(UUID userId, UUID sessionId) {
    return sessionView(requireSession(userId, sessionId));
  }

  @Transactional
  public TrainingTurnResult submitTurn(
      UUID userId,
      UUID sessionId,
      String idempotencyKey,
      String transcript,
      String audioRef,
      String selectedOptionId,
      Integer clientStateVersion) {
    TrainingSession session = requireSession(userId, sessionId);
    if (session.terminal()) {
      throw new ApiException(HttpStatus.CONFLICT, "CONFLICT", "Completed training sessions cannot accept new turns.");
    }
    if (idempotencyKey == null || idempotencyKey.isBlank()) {
      throw new ApiException(HttpStatus.BAD_REQUEST, "SCHEMA_VALIDATION_FAILED", "Idempotency-Key is required.");
    }
    TrainingContentMapping currentMapping = currentMapping(session);
    String normalizedTranscript = clean(transcript);
    String normalizedAudioRef = clean(audioRef);
    String normalizedOption = clean(selectedOptionId);
    if (normalizedTranscript == null && normalizedAudioRef == null && normalizedOption == null) {
      throw new ApiException(
          HttpStatus.UNPROCESSABLE_ENTITY,
          "SCHEMA_VALIDATION_FAILED",
          "transcript, audio_ref or selected_option_id is required.");
    }
    String inputHash = inputHash(session, normalizedTranscript, normalizedAudioRef, normalizedOption, clientStateVersion);
    var existing = turns.findByTrainingSessionIdAndIdempotencyKey(sessionId, idempotencyKey);
    if (existing.isPresent()) {
      TrainingTurn turn = existing.get();
      if (!turn.samePayload(inputHash)) {
        throw new ApiException(HttpStatus.CONFLICT, "IDEMPOTENCY_CONFLICT", "Idempotency key reused with different payload.");
      }
      saveMetric(userId, sessionId, "training_turn_replay", "success", null, null);
      return turnResult(session, turn, null);
    }

    Instant now = Instant.now(clock);
    String providerStatus = "success";
    AiGatewayService.ScoreResult score = null;
    if (normalizedTranscript == null && normalizedAudioRef != null) {
      AiGatewayService.TranscribeResult transcribe = aiGateway.transcribe(userId, normalizedAudioRef, "en-US");
      providerStatus = transcribe.status();
      if (!"available".equals(transcribe.status())) {
        return saveRecoverableTurn(
            session,
            idempotencyKey,
            inputHash,
            normalizedAudioRef,
            normalizedOption,
            transcribe.status(),
            "asr_unavailable_text_fallback",
            "Transcription is temporarily unavailable. Please retry or type your answer.",
            now);
      }
      normalizedTranscript = transcribe.transcript();
    }
    if (normalizedTranscript == null && normalizedOption != null) {
      normalizedTranscript = "selected_option:" + normalizedOption;
    }
    if (normalizedAudioRef != null) {
      score = aiGateway.scorePronunciation(userId, normalizedAudioRef, currentMapping.getPromptText());
    }

    AiGatewayService.CoachResult coach =
        aiGateway.coachTraining(userId, sessionId, normalizedTranscript, targetExpressionIds(session));
    providerStatus = coach.providerStatus();
    if (coach.recoverable()) {
      return saveRecoverableTurn(
          session,
          idempotencyKey,
          inputHash,
          normalizedAudioRef,
          normalizedOption,
          providerStatus,
          coach.recoverableErrorCode(),
          coach.summary(),
          now);
    }

    int turnIndex = session.getCurrentTurnIndex() + 1;
    boolean success = !"off_topic".equals(coach.mainIssueType());
    String outcome = success ? ("pressure_check".equals(session.getStatus()) ? "pressure_passed" : "success") : "failure";
    String reasonCode = success ? "target_and_task_met" : "off_topic_or_task_not_met";
    TrainingPlannerService.PlannerDraft draft =
        planner.decide(session, new TrainingPlannerService.AttemptSignal(outcome, reasonCode));
    TrainingTurn turn = turns.save(new TrainingTurn(
        UUID.randomUUID(),
        sessionId,
        userId,
        turnIndex,
        session.getCurrentStepKey(),
        session.getCurrentMicroAction(),
        normalizedTranscript,
        normalizedAudioRef,
        normalizedOption,
        success ? "accepted" : "rejected",
        idempotencyKey,
        inputHash,
        providerStatus,
        now));
    TrainingEvidenceCandidate candidate = saveEvidenceCandidate(
        session, turn, currentMapping, success, score, reasonCode, normalizedTranscript, now);
    TrainingPlannerDecision decision = saveDecision(session, turn.getTrainingTurnId(), draft, inputSnapshot(session, turn), now);
    if (success) {
      session.recordSuccess();
    } else {
      session.recordFailure();
    }
    session.applyPlannerDecision(decision, turnIndex, now);
    session.markEvidenceWritten("accepted".equals(candidate.getStatus()), now);
    sessions.save(session);
    saveMetric(userId, sessionId, "training_turn_submit", success ? "success" : "rejected", "ai", null);
    return turnResult(session, turn, feedbackView(session, coach, success, score, draft), decision, List.of(candidate), null);
  }

  @Transactional
  public PlannerDecisionView plannerNext(UUID userId, UUID sessionId) {
    TrainingSession session = requireSession(userId, sessionId);
    var existing = plannerDecisions.findFirstByTrainingSessionIdOrderByCreatedAtDesc(sessionId);
    if (existing.isPresent()) {
      return decisionView(existing.get());
    }
    Instant now = Instant.now(clock);
    TrainingPlannerDecision decision =
        saveDecision(session, null, planner.currentStatePreview(session), inputSnapshot(session, null), now);
    saveMetric(userId, sessionId, "training_planner_preview", "success", null, null);
    return decisionView(decision);
  }

  @Transactional
  public HintResult hint(UUID userId, UUID sessionId) {
    TrainingSession session = requireSession(userId, sessionId);
    Instant now = Instant.now(clock);
    TrainingPlannerService.PlannerDraft draft = planner.hint(session);
    TrainingPlannerDecision decision = saveDecision(session, null, draft, inputSnapshot(session, null), now);
    session.applyPlannerDecision(decision, session.getCurrentTurnIndex(), now);
    sessions.save(session);
    saveMetric(userId, sessionId, "training_hint_request", "success", null, null);
    return new HintResult(sessionView(session), decisionView(decision), hintPrompt(session));
  }

  @Transactional
  public PlannerDecisionView pressureCheck(UUID userId, UUID sessionId) {
    TrainingSession session = requireSession(userId, sessionId);
    Instant now = Instant.now(clock);
    TrainingPlannerService.PlannerDraft draft = planner.pressureCheck(session);
    TrainingPlannerDecision decision = saveDecision(session, null, draft, inputSnapshot(session, null), now);
    session.applyPlannerDecision(decision, session.getCurrentTurnIndex(), now);
    sessions.save(session);
    saveMetric(userId, sessionId, "training_pressure_check_start", "success", null, null);
    return decisionView(decision);
  }

  @Transactional
  public TrainingRecapView complete(UUID userId, UUID sessionId) {
    TrainingSession session = requireSession(userId, sessionId);
    var existing = recaps.findByTrainingSessionId(sessionId);
    if (existing.isPresent()) {
      return recapView(existing.get());
    }
    Instant now = Instant.now(clock);
    List<TrainingEvidenceCandidate> candidates = evidenceCandidates.findByTrainingSessionIdOrderByCreatedAtAsc(sessionId);
    List<String> acceptedIds = candidates.stream()
        .filter(candidate -> "accepted".equals(candidate.getStatus()))
        .map(candidate -> candidate.getLearningEvidenceId() == null ? "" : candidate.getLearningEvidenceId().toString())
        .filter(value -> !value.isBlank())
        .toList();
    List<String> learnedItems = candidates.stream()
        .filter(candidate -> "accepted".equals(candidate.getStatus()))
        .map(candidate -> candidate.getTargetExpressionId() == null ? "training_step_completed" : candidate.getTargetExpressionId().toString())
        .distinct()
        .toList();
    List<String> weakPoints = candidates.stream()
        .filter(candidate -> !"accepted".equals(candidate.getStatus()))
        .map(TrainingEvidenceCandidate::getReasonCode)
        .distinct()
        .toList();
    TrainingRecap recap = recaps.save(new TrainingRecap(
        UUID.randomUUID(),
        sessionId,
        userId,
        "Training recap for " + session.getScenarioId() + " " + session.getLevelCode() + ".",
        joinList(learnedItems.isEmpty() ? List.of("practice_one_target_expression") : learnedItems),
        joinList(weakPoints.isEmpty() ? List.of("none") : weakPoints),
        learnedItems.isEmpty() ? "Repeat one useful expression from this session." : "Review " + learnedItems.get(0) + ".",
        joinList(acceptedIds),
        now));
    session.complete(now);
    sessions.save(session);
    saveMetric(userId, sessionId, "training_session_complete", "success", null, null);
    return recapView(recap);
  }

  private TrainingTurnResult saveRecoverableTurn(
      TrainingSession session,
      String idempotencyKey,
      String inputHash,
      String audioRef,
      String selectedOptionId,
      String providerStatus,
      String reasonCode,
      String summary,
      Instant now) {
    int turnIndex = session.getCurrentTurnIndex() + 1;
    TrainingTurn turn = turns.save(new TrainingTurn(
        UUID.randomUUID(),
        session.getTrainingSessionId(),
        session.getUserId(),
        turnIndex,
        session.getCurrentStepKey(),
        session.getCurrentMicroAction(),
        "",
        audioRef,
        selectedOptionId,
        "recoverable_error",
        idempotencyKey,
        inputHash,
        providerStatus,
        now));
    TrainingPlannerService.PlannerDraft draft =
        planner.decide(session, new TrainingPlannerService.AttemptSignal("recoverable", reasonCode));
    TrainingPlannerDecision decision = saveDecision(session, turn.getTrainingTurnId(), draft, inputSnapshot(session, turn), now);
    session.applyPlannerDecision(decision, turnIndex, now);
    sessions.save(session);
    saveMetric(session.getUserId(), session.getTrainingSessionId(), "training_turn_submit", "recoverable_error", "ai", reasonCode);
    saveMetric(session.getUserId(), session.getTrainingSessionId(), "training_provider_fallback", "recoverable_error", "ai", reasonCode);
    return turnResult(
        session,
        turn,
        new FeedbackView(
            summary,
            "none",
            "",
            "Please retry this turn when the service is available.",
            false,
            "unknown",
            "unknown",
            "fallback",
            providerStatus),
        decision,
        List.of(),
        new RecoverableErrorView(reasonCode, summary, true));
  }

  private TrainingEvidenceCandidate saveEvidenceCandidate(
      TrainingSession session,
      TrainingTurn turn,
      TrainingContentMapping mapping,
      boolean success,
      AiGatewayService.ScoreResult score,
      String reasonCode,
      String transcript,
      Instant now) {
    double confidence = score != null && score.confidence() != null ? score.confidence() : (success ? 0.82 : 0.45);
    UUID learningEvidenceId = null;
    String status = "rejected";
    if (success && confidence >= 0.7) {
      LearningEvidence evidence = learningMemory.createEvidenceWithRuleTrace(
          session.getUserId(),
          "training_turn",
          turn.getTrainingTurnId().toString(),
          "mastered_expression",
          mapping.getTargetExpressionId(),
          confidence,
          "training_signal_v1",
          reasonCode,
          1);
      learningEvidenceId = evidence.getEvidenceId();
      status = "accepted";
    }
    TrainingEvidenceCandidate candidate = evidenceCandidates.save(new TrainingEvidenceCandidate(
        UUID.randomUUID(),
        session.getTrainingSessionId(),
        turn.getTrainingTurnId(),
        learningEvidenceId,
        session.getUserId(),
        success ? "mastered_expression" : "weak_expression",
        mapping.getTargetExpressionId(),
        confidence,
        status,
        "training_signal_v1",
        success ? reasonCode : "task_not_met",
        1,
        "step=" + turn.getStepKey() + ";micro_action=" + turn.getMicroAction() + ";input_ref=" + sha256(transcript),
        now));
    saveMetric(
        session.getUserId(),
        session.getTrainingSessionId(),
        "training_evidence_candidate",
        candidate.getStatus(),
        null,
        "accepted".equals(candidate.getStatus()) ? null : candidate.getReasonCode());
    return candidate;
  }

  private TrainingPlannerDecision saveDecision(
      TrainingSession session,
      UUID sourceTurnId,
      TrainingPlannerService.PlannerDraft draft,
      String inputSnapshot,
      Instant now) {
    TrainingPlannerDecision decision = plannerDecisions.save(new TrainingPlannerDecision(
        UUID.randomUUID(),
        session.getTrainingSessionId(),
        sourceTurnId,
        session.getUserId(),
        draft.decisionType(),
        draft.nextStatus(),
        draft.nextStepKey(),
        draft.nextMicroAction(),
        draft.nextHintLevel(),
        draft.reasonCode(),
        TrainingPlannerService.PLANNER_VERSION,
        inputSnapshot,
        outputSnapshot(draft),
        now));
    saveMetric(session.getUserId(), session.getTrainingSessionId(), "training_planner_decision", "success", null, null);
    return decision;
  }

  private ScenarioVersion requireTrainingContent(String scenarioId, String levelCode) {
    scenarios.findById(scenarioId)
        .filter(scenario -> "available".equals(scenario.getStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Official scenario was not found."));
    levels.findByScenarioIdAndLevelCode(scenarioId, levelCode)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Scenario level was not found."));
    ScenarioVersion version = versions.findFirstByScenarioIdAndContentStatusOrderByPublishedAtDesc(scenarioId, "published")
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Published scenario version was not found."));
    List<TargetExpression> targets =
        expressions.findByScenarioVersionIdAndLevelCodeOrderByTextAsc(version.getScenarioVersionId(), levelCode);
    if (targets.isEmpty()) {
      throw new ApiException(
          HttpStatus.UNPROCESSABLE_ENTITY,
          "SCHEMA_VALIDATION_FAILED",
          "Training content mapping requires target expressions for this scenario level.");
    }
    ensureMappings(version, levelCode, targets);
    return version;
  }

  private void ensureMappings(ScenarioVersion version, String levelCode, List<TargetExpression> targets) {
    if (mappings.existsByScenarioVersionIdAndLevelCodeAndReviewStatus(
        version.getScenarioVersionId(), levelCode, "reviewed")) {
      return;
    }
    Instant now = Instant.now(clock);
    List<TrainingContentMapping> generated = new ArrayList<>();
    List<TrainingPlannerService.StepDefinition> steps = planner.actionChain();
    for (int i = 0; i < steps.size(); i++) {
      TrainingPlannerService.StepDefinition step = steps.get(i);
      TargetExpression target = targets.get(i % targets.size());
      generated.add(new TrainingContentMapping(
          UUID.randomUUID(),
          version.getScenarioId(),
          version.getScenarioVersionId(),
          levelCode,
          mappingVersion(version),
          TrainingPlannerService.ACTION_CHAIN_VERSION,
          step.stepKey(),
          step.microAction(),
          i,
          target.getTargetExpressionId(),
          "Use this target expression for " + step.label() + ": " + target.getText(),
          "reviewed",
          now));
    }
    mappings.saveAll(generated);
  }

  private TrainingSession requireSession(UUID userId, UUID sessionId) {
    return sessions.findByTrainingSessionIdAndUserId(sessionId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Training session was not found."));
  }

  private void requireUser(UUID userId) {
    users.findById(userId)
        .filter(user -> !"deleted".equals(user.getAccountStatus()) && !"disabled".equals(user.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));
  }

  private TrainingContentMapping currentMapping(TrainingSession session) {
    return contentMappings(session).stream()
        .filter(mapping -> mapping.getStepKey().equals(session.getCurrentStepKey()))
        .findFirst()
        .orElseThrow(() -> new ApiException(
            HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Reviewed training mapping is missing."));
  }

  private List<TrainingContentMapping> contentMappings(TrainingSession session) {
    List<TrainingContentMapping> reviewed = mappings
        .findByScenarioVersionIdAndLevelCodeAndReviewStatusOrderByOrderIndexAsc(
            session.getScenarioVersionId(), session.getLevelCode(), "reviewed");
    if (reviewed.isEmpty()) {
      throw new ApiException(
          HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Reviewed training mapping is missing.");
    }
    return reviewed;
  }

  private List<String> targetExpressionIds(TrainingSession session) {
    return contentMappings(session).stream()
        .map(mapping -> mapping.getTargetExpressionId().toString())
        .distinct()
        .toList();
  }

  private TrainingSessionView sessionView(TrainingSession session) {
    TrainingRecapView recap = recaps.findByTrainingSessionId(session.getTrainingSessionId()).map(this::recapView).orElse(null);
    PlannerDecisionView latestDecision =
        plannerDecisions.findFirstByTrainingSessionIdOrderByCreatedAtDesc(session.getTrainingSessionId())
            .map(this::decisionView)
            .orElse(null);
    return new TrainingSessionView(
        session.getTrainingSessionId(),
        session.getUserId(),
        session.getScenarioId(),
        session.getScenarioVersionId(),
        session.getLevelCode(),
        session.getStatus(),
        session.getCurrentTurnIndex(),
        session.getCurrentStepKey(),
        session.getCurrentMicroAction(),
        session.getHintLevel(),
        session.getFailureCount(),
        session.getSuccessCount(),
        session.getEvidenceWriteStatus(),
        session.getSyncStatus(),
        session.getMappingVersion(),
        session.getActionChainVersion(),
        session.getLastReasonCode(),
        actionChainView(session),
        latestDecision,
        recap);
  }

  private List<ActionChainStepView> actionChainView(TrainingSession session) {
    return contentMappings(session).stream()
        .map(mapping -> new ActionChainStepView(
            mapping.getStepKey(),
            planner.stepByKey(mapping.getStepKey()).label(),
            mapping.getMicroAction(),
            mapping.getOrderIndex(),
            mapping.getTargetExpressionId().toString(),
            mapping.getPromptText(),
            mapping.getMappingVersion(),
            mapping.getReviewStatus()))
        .toList();
  }

  private TrainingTurnResult turnResult(TrainingSession session, TrainingTurn turn, FeedbackView feedback) {
    TrainingPlannerDecision decision = plannerDecisions.findBySourceTurnId(turn.getTrainingTurnId()).orElse(null);
    List<TrainingEvidenceCandidate> candidates = evidenceCandidates.findBySourceTurnIdOrderByCreatedAtAsc(turn.getTrainingTurnId());
    RecoverableErrorView recoverable = "recoverable_error".equals(turn.getResult()) && decision != null
        ? new RecoverableErrorView(decision.getReasonCode(), "Please retry or use text fallback.", true)
        : null;
    return turnResult(session, turn, feedback, decision, candidates, recoverable);
  }

  private TrainingTurnResult turnResult(
      TrainingSession session,
      TrainingTurn turn,
      FeedbackView feedback,
      TrainingPlannerDecision decision,
      List<TrainingEvidenceCandidate> candidates,
      RecoverableErrorView recoverable) {
    FeedbackView effectiveFeedback = feedback;
    if (effectiveFeedback == null && decision != null) {
      effectiveFeedback = new FeedbackView(
          "Planner decision: " + decision.getReasonCode(),
          "none",
          "",
          "Continue with the server-owned training flow.",
          false,
          "unknown",
          "unknown",
          "valid",
          turn.getProviderStatus());
    }
    return new TrainingTurnResult(
        sessionView(session),
        turnView(turn),
        effectiveFeedback,
        decision == null ? null : decisionView(decision),
        candidates.stream().map(this::candidateView).toList(),
        recoverable);
  }

  private FeedbackView feedbackView(
      TrainingSession session,
      AiGatewayService.CoachResult coach,
      boolean success,
      AiGatewayService.ScoreResult score,
      TrainingPlannerService.PlannerDraft draft) {
    return new FeedbackView(
        coach.summary(),
        coach.mainIssueType(),
        coach.suggestedExpression() == null ? "" : coach.suggestedExpression(),
        coach.nextPrompt() == null ? "" : coach.nextPrompt(),
        score != null && "available".equals(score.status()),
        success ? "met" : "not_met",
        success ? "met" : "not_met",
        coach.validationStatus(),
        coach.providerStatus());
  }

  private TrainingTurnView turnView(TrainingTurn turn) {
    return new TrainingTurnView(
        turn.getTrainingTurnId(),
        turn.getTurnIndex(),
        turn.getStepKey(),
        turn.getMicroAction(),
        turn.getTranscript(),
        turn.getAudioRef(),
        turn.getSelectedOptionId(),
        turn.getResult(),
        turn.getProviderStatus(),
        turn.getCreatedAt());
  }

  private PlannerDecisionView decisionView(TrainingPlannerDecision decision) {
    return new PlannerDecisionView(
        decision.getPlannerDecisionId(),
        decision.getDecisionType(),
        decision.getNextStatus(),
        decision.getNextStepKey(),
        decision.getNextMicroAction(),
        decision.getNextHintLevel(),
        decision.getReasonCode(),
        decision.getPlannerVersion(),
        decision.getCreatedAt());
  }

  private EvidenceCandidateView candidateView(TrainingEvidenceCandidate candidate) {
    return new EvidenceCandidateView(
        candidate.getCandidateId(),
        candidate.getLearningEvidenceId(),
        candidate.getEvidenceType(),
        candidate.getTargetExpressionId(),
        candidate.getConfidence(),
        candidate.getStatus(),
        candidate.getRuleName(),
        candidate.getReasonCode(),
        candidate.getSchemaVersion());
  }

  private TrainingRecapView recapView(TrainingRecap recap) {
    return new TrainingRecapView(
        recap.getRecapId(),
        recap.getTrainingSessionId(),
        splitList(recap.getLearnedItems()),
        splitList(recap.getWeakPoints()),
        recap.getNextFocus(),
        splitList(recap.getAcceptedEvidenceIds()),
        recap.getCreatedAt());
  }

  private void saveMetric(
      UUID userId, UUID sessionId, String eventType, String status, String providerFamily, String fallbackReason) {
    metrics.save(new TrainingMetricEvent(
        UUID.randomUUID(),
        sessionId,
        userId,
        eventType,
        status,
        providerFamily,
        "lt_2s",
        fallbackReason,
        1,
        "training:" + (sessionId == null ? "none" : sessionId.toString().replace("-", "").substring(0, 12)),
        Instant.now(clock)));
  }

  private String canonicalLevelCode(String levelCode) {
    String cleaned = cleanRequired(levelCode, "level_code");
    return switch (cleaned) {
      case "beginner" -> "L1";
      case "intermediate" -> "L2";
      case "advanced" -> "L3";
      default -> {
        if (!List.of("L1", "L2", "L3").contains(cleaned)) {
          throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Unsupported level_code.");
        }
        yield cleaned;
      }
    };
  }

  private String mappingVersion(ScenarioVersion version) {
    return "training-map:" + version.getVersion();
  }

  private String hintPrompt(TrainingSession session) {
    return "sentence_frame".equals(session.getHintLevel())
        ? "Try starting with one complete sentence."
        : "Use the current hint level: " + session.getHintLevel() + ".";
  }

  private String inputHash(
      TrainingSession session, String transcript, String audioRef, String selectedOptionId, Integer clientStateVersion) {
    return sha256(session.getTrainingSessionId()
        + "|"
        + value(transcript)
        + "|"
        + value(audioRef)
        + "|"
        + value(selectedOptionId)
        + "|"
        + (clientStateVersion == null ? "" : clientStateVersion));
  }

  private String inputSnapshot(TrainingSession session, TrainingTurn turn) {
    return "{"
        + "\"session_id\":\""
        + session.getTrainingSessionId()
        + "\",\"status\":\""
        + json(session.getStatus())
        + "\",\"step\":\""
        + json(session.getCurrentStepKey())
        + "\",\"micro_action\":\""
        + json(session.getCurrentMicroAction())
        + "\",\"turn_id\":\""
        + (turn == null ? "" : turn.getTrainingTurnId())
        + "\"}";
  }

  private String outputSnapshot(TrainingPlannerService.PlannerDraft draft) {
    return "{"
        + "\"decision_type\":\""
        + json(draft.decisionType())
        + "\",\"next_status\":\""
        + json(draft.nextStatus())
        + "\",\"next_step\":\""
        + json(draft.nextStepKey())
        + "\",\"next_micro_action\":\""
        + json(draft.nextMicroAction())
        + "\",\"reason_code\":\""
        + json(draft.reasonCode())
        + "\"}";
  }

  private String cleanRequired(String value, String fieldName) {
    String cleaned = clean(value);
    if (cleaned == null) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", fieldName + " is required.");
    }
    return cleaned;
  }

  private String clean(String value) {
    String cleaned = value == null ? "" : value.trim();
    return cleaned.isBlank() ? null : cleaned;
  }

  private String value(String value) {
    return value == null ? "" : value;
  }

  private String joinList(List<String> values) {
    return String.join("\n", values);
  }

  private List<String> splitList(String value) {
    String cleaned = value == null ? "" : value.trim();
    return cleaned.isBlank() ? List.of() : List.of(cleaned.split("\\n"));
  }

  private String json(String value) {
    return value == null ? "" : value.replace("\\", "\\\\").replace("\"", "\\\"");
  }

  private String sha256(String value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value(value).getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException("sha256 unavailable", e);
    }
  }

  public record TrainingSessionView(
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
      List<ActionChainStepView> actionChain,
      PlannerDecisionView lastDecision,
      TrainingRecapView recap) {}

  public record ActionChainStepView(
      String stepKey,
      String label,
      String microAction,
      int orderIndex,
      String targetExpressionId,
      String promptText,
      String mappingVersion,
      String reviewStatus) {}

  public record TrainingTurnResult(
      TrainingSessionView session,
      TrainingTurnView turn,
      FeedbackView feedback,
      PlannerDecisionView plannerDecision,
      List<EvidenceCandidateView> learningEvidenceCandidates,
      RecoverableErrorView recoverableError) {}

  public record TrainingTurnView(
      UUID turnId,
      int turnIndex,
      String stepKey,
      String microAction,
      String transcript,
      String audioRef,
      String selectedOptionId,
      String result,
      String providerStatus,
      Instant createdAt) {}

  public record FeedbackView(
      String summary,
      String mainIssueType,
      String betterExpression,
      String nextPrompt,
      boolean pronunciationAvailable,
      String completionStatus,
      String taskStatus,
      String validationStatus,
      String providerStatus) {}

  public record PlannerDecisionView(
      UUID decisionId,
      String type,
      String nextStatus,
      String nextStepKey,
      String nextMicroAction,
      String nextHintLevel,
      String reasonCode,
      String plannerVersion,
      Instant createdAt) {}

  public record EvidenceCandidateView(
      UUID candidateId,
      UUID learningEvidenceId,
      String evidenceType,
      UUID targetExpressionId,
      double confidence,
      String status,
      String ruleName,
      String reasonCode,
      int schemaVersion) {}

  public record RecoverableErrorView(String code, String message, boolean retryable) {}

  public record HintResult(TrainingSessionView session, PlannerDecisionView plannerDecision, String prompt) {}

  public record TrainingRecapView(
      UUID recapId,
      UUID sessionId,
      List<String> learnedItems,
      List<String> weakPoints,
      String nextFocus,
      List<String> acceptedEvidenceIds,
      Instant createdAt) {}
}
