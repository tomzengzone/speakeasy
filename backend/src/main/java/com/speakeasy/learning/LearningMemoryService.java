package com.speakeasy.learning;

import com.speakeasy.common.ApiException;
import com.speakeasy.content.ScenarioVersion;
import com.speakeasy.content.ScenarioVersionRepository;
import com.speakeasy.content.TargetExpression;
import com.speakeasy.content.TargetExpressionRepository;
import com.speakeasy.content.UserScenarioState;
import com.speakeasy.content.UserScenarioStateRepository;
import com.speakeasy.identity.UserAccountRepository;
import java.time.Clock;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class LearningMemoryService {
  private final UserAccountRepository users;
  private final UserScenarioStateRepository userScenarios;
  private final ScenarioVersionRepository versions;
  private final TargetExpressionRepository expressions;
  private final PracticeQueueItemRepository queueItems;
  private final ExpressionPracticeAttemptRepository attempts;
  private final FavoriteExpressionRepository favorites;
  private final LearningEvidenceRepository evidences;
  private final MasteryRecordRepository masteryRecords;
  private final ReviewItemRepository reviewItems;
  private final SavedExpressionRepository savedExpressions;
  private final LearningHistoryEntryRepository historyEntries;
  private final Clock clock;

  public LearningMemoryService(
      UserAccountRepository users,
      UserScenarioStateRepository userScenarios,
      ScenarioVersionRepository versions,
      TargetExpressionRepository expressions,
      PracticeQueueItemRepository queueItems,
      ExpressionPracticeAttemptRepository attempts,
      FavoriteExpressionRepository favorites,
      LearningEvidenceRepository evidences,
      MasteryRecordRepository masteryRecords,
      ReviewItemRepository reviewItems,
      SavedExpressionRepository savedExpressions,
      LearningHistoryEntryRepository historyEntries,
      Clock clock) {
    this.users = users;
    this.userScenarios = userScenarios;
    this.versions = versions;
    this.expressions = expressions;
    this.queueItems = queueItems;
    this.attempts = attempts;
    this.favorites = favorites;
    this.evidences = evidences;
    this.masteryRecords = masteryRecords;
    this.reviewItems = reviewItems;
    this.savedExpressions = savedExpressions;
    this.historyEntries = historyEntries;
    this.clock = clock;
  }

  @Transactional
  public ExpressionQueueView expressionQueue(UUID userId) {
    requireUser(userId);
    List<UserScenarioState> joined = userScenarios.findByUserIdAndState(userId, "joined");
    if (joined.isEmpty()) {
      return new ExpressionQueueView("empty_no_scene", List.of());
    }
    ensureScenarioQueue(userId, joined);
    List<PracticeQueueItem> ready = queueItems.findByUserIdAndStatus(userId, "ready");
    List<ExpressionQueueItemView> items = dedupeAndOrder(ready).stream().map(this::queueItemView).toList();
    return new ExpressionQueueView(items.isEmpty() ? "empty_no_due_items" : "ready", items);
  }

  @Transactional
  public ExpressionTaskProgressView completeTask(
      UUID userId, UUID queueItemId, String result, Double score, String answerText, String transcriptRef) {
    requireUser(userId);
    PracticeQueueItem item = queueItems.findByQueueItemIdAndUserId(queueItemId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Queue item was not found."));
    Instant now = Instant.now(clock);
    ExpressionPracticeAttempt attempt = attempts.save(new ExpressionPracticeAttempt(
        UUID.randomUUID(),
        queueItemId,
        userId,
        item.getTaskType(),
        answerText,
        transcriptRef,
        result,
        score,
        now));
    item.complete(now);
    queueItems.save(item);
    LearningEvidence evidence = createEvidenceInternal(
        userId,
        "review_result",
        attempt.getAttemptId().toString(),
        score != null && score >= 0.8 ? "mastered_expression" : "weak_expression",
        item.getTargetExpressionId(),
        score == null ? 0.7 : score,
        null,
        null,
        null,
        now);
    return new ExpressionTaskProgressView(
        attempt.getAttemptId(), item.getQueueItemId(), item.getTargetExpressionId(), result, score, evidence.getEvidenceId());
  }

  @Transactional
  public FavoriteExpression favorite(UUID userId, UUID targetExpressionId, String expressionText, String sourceType, String sourceId) {
    requireUser(userId);
    TargetExpression target = requireExpression(targetExpressionId);
    Instant now = Instant.now(clock);
    FavoriteExpression favorite = favorites.findByUserIdAndTargetExpressionId(userId, targetExpressionId)
        .orElseGet(() -> new FavoriteExpression(
            UUID.randomUUID(), userId, targetExpressionId, expressionTextOrDefault(expressionText, target), sourceType, sourceId, now));
    favorite.reactivate(expressionTextOrDefault(expressionText, target), sourceType, sourceId, now);
    return favorites.save(favorite);
  }

  @Transactional(readOnly = true)
  public List<FavoriteExpression> favorites(UUID userId) {
    requireUser(userId);
    return favorites.findByUserIdAndStatus(userId, "active");
  }

  @Transactional
  public void deleteFavorite(UUID userId, UUID favoriteId) {
    FavoriteExpression favorite = favorites.findByFavoriteIdAndUserId(favoriteId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Favorite was not found."));
    favorite.remove(Instant.now(clock));
    favorites.save(favorite);
  }

  @Transactional
  public LearningEvidence createEvidence(
      UUID userId, String sourceType, String sourceId, String evidenceType, UUID targetExpressionId, Double confidence) {
    requireUser(userId);
    return createEvidenceInternal(
        userId, sourceType, sourceId, evidenceType, targetExpressionId, confidence, null, null, null, Instant.now(clock));
  }

  @Transactional
  public LearningEvidence createEvidenceWithRuleTrace(
      UUID userId,
      String sourceType,
      String sourceId,
      String evidenceType,
      UUID targetExpressionId,
      Double confidence,
      String ruleName,
      String reasonCode,
      Integer schemaVersion) {
    requireUser(userId);
    return createEvidenceInternal(
        userId,
        sourceType,
        sourceId,
        evidenceType,
        targetExpressionId,
        confidence,
        clean(ruleName),
        clean(reasonCode),
        schemaVersion,
        Instant.now(clock));
  }

  @Transactional(readOnly = true)
  public List<LearningEvidence> acceptedEvidence(UUID userId) {
    requireUser(userId);
    return evidences.findByUserIdAndAcceptedStatusOrderByCreatedAtDesc(userId, "accepted");
  }

  @Transactional(readOnly = true)
  public List<MasteryRecord> mastery(UUID userId) {
    requireUser(userId);
    return masteryRecords.findByUserId(userId);
  }

  @Transactional(readOnly = true)
  public List<ReviewItem> dueReview(UUID userId) {
    requireUser(userId);
    return reviewItems.findByUserIdAndStatusAndDueAtLessThanEqualOrderByDueAtAsc(userId, "due", Instant.now(clock));
  }

  @Transactional
  public ReviewItem submitReview(UUID userId, UUID reviewItemId, String result) {
    ReviewItem item = reviewItems.findByReviewItemIdAndUserId(reviewItemId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Review item was not found."));
    item.submit(result, Instant.now(clock));
    return reviewItems.save(item);
  }

  @Transactional(readOnly = true)
  public List<SavedExpression> wiki(UUID userId) {
    requireUser(userId);
    return savedExpressions.findByUserIdAndStatus(userId, "active");
  }

  @Transactional(readOnly = true)
  public List<LearningHistoryEntry> history(UUID userId) {
    requireUser(userId);
    return historyEntries.findByUserIdAndStatusOrderByCreatedAtDesc(userId, "recorded");
  }

  @Transactional
  public void deleteHistory(UUID userId, UUID historyEntryId) {
    LearningHistoryEntry history = historyEntries.findByHistoryEntryIdAndUserId(historyEntryId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "History entry was not found."));
    history.delete(Instant.now(clock));
    historyEntries.save(history);
  }

  private LearningEvidence createEvidenceInternal(
      UUID userId,
      String sourceType,
      String sourceId,
      String evidenceType,
      UUID targetExpressionId,
      Double confidence,
      String ruleName,
      String reasonCode,
      Integer schemaVersion,
      Instant now) {
    boolean accepted = targetExpressionId != null && confidence != null && confidence >= 0.6;
    LearningEvidence evidence = evidences.save(new LearningEvidence(
        UUID.randomUUID(),
        userId,
        sourceType,
        sourceId,
        evidenceType,
        targetExpressionId,
        confidence,
        accepted ? "accepted" : "rejected",
        accepted ? null : "low_confidence_or_missing_target",
        ruleName,
        reasonCode,
        schemaVersion,
        now));
    if (accepted) {
      applyAcceptedEvidence(userId, evidence, now);
    }
    return evidence;
  }

  private void applyAcceptedEvidence(UUID userId, LearningEvidence evidence, Instant now) {
    TargetExpression target = requireExpression(evidence.getTargetExpressionId());
    String masteryStatus = "weak_expression".equals(evidence.getEvidenceType()) ? "weak" : "mastered";
    MasteryRecord mastery = masteryRecords.findByUserIdAndTargetExpressionId(userId, evidence.getTargetExpressionId())
        .orElseGet(() -> new MasteryRecord(
            UUID.randomUUID(), userId, evidence.getTargetExpressionId(), "new", 0.0, evidence.getEvidenceId(), now));
    mastery.update(masteryStatus, evidence.getConfidence(), evidence.getEvidenceId(), now);
    masteryRecords.save(mastery);
    reviewItems.save(new ReviewItem(
        UUID.randomUUID(), userId, evidence.getTargetExpressionId(), evidence.getEvidenceId(), "expression_recall", now, 1, now));
    savedExpressions.save(new SavedExpression(
        UUID.randomUUID(),
        userId,
        evidence.getTargetExpressionId(),
        target.getText(),
        target.getMeaningCn(),
        target.getUsageNote(),
        evidence.getEvidenceId(),
        now));
    historyEntries.save(new LearningHistoryEntry(
        UUID.randomUUID(), userId, null, "已掌握表达：" + target.getText(), now));
    int priority = "weak_expression".equals(evidence.getEvidenceType()) ? 200 : 100;
    queueItems.save(new PracticeQueueItem(
        UUID.randomUUID(), userId, evidence.getEvidenceType(), evidence.getTargetExpressionId(), "review_expression", priority, now, now));
  }

  private void ensureScenarioQueue(UUID userId, List<UserScenarioState> joined) {
    Instant now = Instant.now(clock);
    for (UserScenarioState state : joined) {
      ScenarioVersion version = versions.findFirstByScenarioIdAndContentStatusOrderByPublishedAtDesc(state.getScenarioId(), "published")
          .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Published scenario version was not found."));
      for (TargetExpression expression : expressions.findByScenarioVersionIdAndLevelCodeOrderByTextAsc(
          version.getScenarioVersionId(), state.getTargetLevel())) {
        queueItems.findFirstByUserIdAndTargetExpressionIdAndStatusIn(
                userId, expression.getTargetExpressionId(), List.of("ready", "in_progress"))
            .orElseGet(() -> queueItems.save(new PracticeQueueItem(
                UUID.randomUUID(), userId, "variant", expression.getTargetExpressionId(), "practice_expression", 300, null, now)));
      }
    }
  }

  private List<PracticeQueueItem> dedupeAndOrder(List<PracticeQueueItem> items) {
    Map<UUID, PracticeQueueItem> deduped = new LinkedHashMap<>();
    items.stream()
        .sorted(Comparator
            .comparingInt(PracticeQueueItem::getPriority)
            .thenComparing(item -> item.getDueAt() == null ? Instant.MAX : item.getDueAt()))
        .forEach(item -> deduped.putIfAbsent(item.getTargetExpressionId(), item));
    return new ArrayList<>(deduped.values());
  }

  private ExpressionQueueItemView queueItemView(PracticeQueueItem item) {
    TargetExpression expression = requireExpression(item.getTargetExpressionId());
    return new ExpressionQueueItemView(
        item.getQueueItemId(),
        item.getSourceType(),
        item.getTargetExpressionId(),
        expression.getText(),
        expression.getMeaningCn(),
        item.getTaskType(),
        item.getPriority(),
        item.getStatus(),
        item.getDueAt());
  }

  private TargetExpression requireExpression(UUID targetExpressionId) {
    return expressions.findById(targetExpressionId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Target expression was not found."));
  }

  private String expressionTextOrDefault(String expressionText, TargetExpression target) {
    return expressionText == null || expressionText.isBlank() ? target.getText() : expressionText;
  }

  private String clean(String value) {
    String cleaned = value == null ? "" : value.trim();
    return cleaned.isBlank() ? null : cleaned;
  }

  private void requireUser(UUID userId) {
    users.findById(userId)
        .filter(user -> !"deleted".equals(user.getAccountStatus()) && !"disabled".equals(user.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));
  }

  public record ExpressionQueueView(String state, List<ExpressionQueueItemView> items) {}

  public record ExpressionQueueItemView(
      UUID queueItemId,
      String sourceType,
      UUID targetExpressionId,
      String expressionText,
      String meaningCn,
      String taskType,
      int priority,
      String status,
      Instant dueAt) {}

  public record ExpressionTaskProgressView(
      UUID attemptId,
      UUID queueItemId,
      UUID targetExpressionId,
      String result,
      Double bestScore,
      UUID evidenceId) {}
}
