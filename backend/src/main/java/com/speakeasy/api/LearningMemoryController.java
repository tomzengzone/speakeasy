package com.speakeasy.api;

import com.speakeasy.common.SchemaResponse;
import com.speakeasy.learning.FavoriteExpression;
import com.speakeasy.learning.LearningEvidence;
import com.speakeasy.learning.LearningHistoryEntry;
import com.speakeasy.learning.LearningMemoryService;
import com.speakeasy.learning.MasteryRecord;
import com.speakeasy.learning.ReviewItem;
import com.speakeasy.learning.SavedExpression;
import com.speakeasy.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.Instant;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class LearningMemoryController {
  private final LearningMemoryService service;

  public LearningMemoryController(LearningMemoryService service) {
    this.service = service;
  }

  @GetMapping("/expressions/queue")
  public ExpressionQueueResponse expressionQueue(@AuthenticationPrincipal CurrentUser currentUser) {
    return ExpressionQueueResponse.from(service.expressionQueue(currentUser.userId()));
  }

  @PostMapping("/expressions/tasks/{queueItemId}/complete")
  public ExpressionTaskProgressResponse completeTask(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable UUID queueItemId,
      @Valid @RequestBody CompleteExpressionTaskRequest request) {
    return ExpressionTaskProgressResponse.from(service.completeTask(
        currentUser.userId(), queueItemId, request.result(), request.score(), request.answerText(), request.transcriptRef()));
  }

  @GetMapping("/favorites/expressions")
  public FavoriteExpressionListResponse favorites(@AuthenticationPrincipal CurrentUser currentUser) {
    return new FavoriteExpressionListResponse(1, service.favorites(currentUser.userId()).stream().map(FavoriteExpressionDto::from).toList());
  }

  @PostMapping("/favorites/expressions")
  public FavoriteExpressionResponse favorite(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody FavoriteExpressionRequest request) {
    return new FavoriteExpressionResponse(1, FavoriteExpressionDto.from(service.favorite(
        currentUser.userId(), request.targetExpressionId(), request.expressionText(), request.sourceType(), request.sourceId())));
  }

  @DeleteMapping("/favorites/expressions/{favoriteId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteFavorite(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID favoriteId) {
    service.deleteFavorite(currentUser.userId(), favoriteId);
  }

  @GetMapping("/learning/evidence")
  public LearningEvidenceListResponse evidence(@AuthenticationPrincipal CurrentUser currentUser) {
    return new LearningEvidenceListResponse(1, service.acceptedEvidence(currentUser.userId()).stream().map(LearningEvidenceDto::from).toList());
  }

  @PostMapping("/learning/evidence")
  @ResponseStatus(HttpStatus.CREATED)
  public LearningEvidenceResponse createEvidence(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody CreateLearningEvidenceRequest request) {
    return new LearningEvidenceResponse(1, LearningEvidenceDto.from(service.createEvidence(
        currentUser.userId(),
        request.sourceType(),
        request.sourceId(),
        request.evidenceType(),
        request.targetExpressionId(),
        request.confidence())));
  }

  @GetMapping("/learning/mastery")
  public MasteryListResponse mastery(@AuthenticationPrincipal CurrentUser currentUser) {
    return new MasteryListResponse(1, service.mastery(currentUser.userId()).stream().map(MasteryRecordDto::from).toList());
  }

  @GetMapping("/review/items")
  public ReviewItemListResponse reviewItems(@AuthenticationPrincipal CurrentUser currentUser) {
    return new ReviewItemListResponse(1, service.dueReview(currentUser.userId()).stream().map(ReviewItemDto::from).toList());
  }

  @PostMapping("/review/items/{reviewItemId}/result")
  public ReviewItemResponse submitReview(
      @AuthenticationPrincipal CurrentUser currentUser,
      @PathVariable UUID reviewItemId,
      @Valid @RequestBody ReviewResultRequest request) {
    return new ReviewItemResponse(1, ReviewItemDto.from(service.submitReview(currentUser.userId(), reviewItemId, request.result())));
  }

  @GetMapping("/learning/wiki")
  public PersonalWikiResponse wiki(@AuthenticationPrincipal CurrentUser currentUser) {
    return new PersonalWikiResponse(1, service.wiki(currentUser.userId()).stream().map(SavedExpressionDto::from).toList());
  }

  @GetMapping("/learning/history")
  public LearningHistoryResponse history(@AuthenticationPrincipal CurrentUser currentUser) {
    return new LearningHistoryResponse(1, service.history(currentUser.userId()).stream().map(LearningHistoryDto::from).toList());
  }

  @DeleteMapping("/learning/history/{historyEntryId}")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void deleteHistory(@AuthenticationPrincipal CurrentUser currentUser, @PathVariable UUID historyEntryId) {
    service.deleteHistory(currentUser.userId(), historyEntryId);
  }

  public record CompleteExpressionTaskRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String result,
      Double score,
      String answerText,
      String transcriptRef) {}

  public record FavoriteExpressionRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotNull UUID targetExpressionId,
      @NotBlank String expressionText,
      String sourceType,
      String sourceId) {}

  public record CreateLearningEvidenceRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String sourceType,
      @NotBlank String sourceId,
      @NotBlank String evidenceType,
      UUID targetExpressionId,
      Double confidence) {}

  public record ReviewResultRequest(@NotNull @Min(1) @Max(1) Integer schemaVersion, @NotBlank String result, String answerText) {}

  public record ExpressionQueueResponse(int schemaVersion, String state, List<ExpressionQueueItemDto> queueItems)
      implements SchemaResponse {
    static ExpressionQueueResponse from(LearningMemoryService.ExpressionQueueView queue) {
      return new ExpressionQueueResponse(1, queue.state(), queue.items().stream().map(ExpressionQueueItemDto::from).toList());
    }
  }

  public record ExpressionQueueItemDto(
      UUID queueItemId,
      String sourceType,
      UUID targetExpressionId,
      String expressionText,
      String meaningCn,
      String taskType,
      int priority,
      String status,
      Instant dueAt) {
    static ExpressionQueueItemDto from(LearningMemoryService.ExpressionQueueItemView item) {
      return new ExpressionQueueItemDto(
          item.queueItemId(), item.sourceType(), item.targetExpressionId(), item.expressionText(), item.meaningCn(),
          item.taskType(), item.priority(), item.status(), item.dueAt());
    }
  }

  public record ExpressionTaskProgressResponse(int schemaVersion, ExpressionTaskProgressDto progress) implements SchemaResponse {
    static ExpressionTaskProgressResponse from(LearningMemoryService.ExpressionTaskProgressView progress) {
      return new ExpressionTaskProgressResponse(1, new ExpressionTaskProgressDto(
          progress.attemptId(), progress.queueItemId(), progress.targetExpressionId(), progress.result(), progress.bestScore(), progress.evidenceId()));
    }
  }

  public record ExpressionTaskProgressDto(
      UUID attemptId, UUID queueItemId, UUID targetExpressionId, String result, Double bestScore, UUID evidenceId) {}

  public record FavoriteExpressionListResponse(int schemaVersion, List<FavoriteExpressionDto> favorites) implements SchemaResponse {}

  public record FavoriteExpressionResponse(int schemaVersion, FavoriteExpressionDto favorite) implements SchemaResponse {}

  public record FavoriteExpressionDto(UUID favoriteId, UUID targetExpressionId, String expressionText, String status) {
    static FavoriteExpressionDto from(FavoriteExpression favorite) {
      return new FavoriteExpressionDto(
          favorite.getFavoriteId(), favorite.getTargetExpressionId(), favorite.getExpressionText(), favorite.getStatus());
    }
  }

  public record LearningEvidenceListResponse(int schemaVersion, List<LearningEvidenceDto> evidence) implements SchemaResponse {}

  public record LearningEvidenceResponse(int schemaVersion, LearningEvidenceDto evidence) implements SchemaResponse {}

  public record LearningEvidenceDto(UUID evidenceId, String evidenceType, UUID targetExpressionId, Double confidence, String acceptedStatus, Instant createdAt) {
    static LearningEvidenceDto from(LearningEvidence evidence) {
      return new LearningEvidenceDto(
          evidence.getEvidenceId(), evidence.getEvidenceType(), evidence.getTargetExpressionId(), evidence.getConfidence(),
          evidence.getAcceptedStatus(), evidence.getCreatedAt());
    }
  }

  public record MasteryListResponse(int schemaVersion, List<MasteryRecordDto> masteryRecords) implements SchemaResponse {}

  public record MasteryRecordDto(UUID targetExpressionId, String masteryStatus, Double score, Instant updatedAt) {
    static MasteryRecordDto from(MasteryRecord mastery) {
      return new MasteryRecordDto(mastery.getTargetExpressionId(), mastery.getMasteryStatus(), mastery.getScore(), mastery.getUpdatedAt());
    }
  }

  public record ReviewItemListResponse(int schemaVersion, List<ReviewItemDto> reviewItems) implements SchemaResponse {}

  public record ReviewItemResponse(int schemaVersion, ReviewItemDto reviewItem) implements SchemaResponse {}

  public record ReviewItemDto(UUID reviewItemId, String promptType, UUID targetExpressionId, Instant dueAt, String status) {
    static ReviewItemDto from(ReviewItem reviewItem) {
      return new ReviewItemDto(
          reviewItem.getReviewItemId(), reviewItem.getPromptType(), reviewItem.getTargetExpressionId(),
          reviewItem.getDueAt(), reviewItem.getStatus());
    }
  }

  public record PersonalWikiResponse(int schemaVersion, List<SavedExpressionDto> entries) implements SchemaResponse {}

  public record SavedExpressionDto(UUID savedExpressionId, UUID targetExpressionId, String expressionText, String meaningCn, String example, String status) {
    static SavedExpressionDto from(SavedExpression expression) {
      return new SavedExpressionDto(
          expression.getSavedExpressionId(), expression.getTargetExpressionId(), expression.getExpressionText(),
          expression.getMeaningCn(), expression.getExample(), expression.getStatus());
    }
  }

  public record LearningHistoryResponse(int schemaVersion, List<LearningHistoryDto> entries) implements SchemaResponse {}

  public record LearningHistoryDto(UUID historyEntryId, UUID sourceSessionId, String title, String status, Instant createdAt) {
    static LearningHistoryDto from(LearningHistoryEntry entry) {
      return new LearningHistoryDto(entry.getHistoryEntryId(), entry.getSourceSessionId(), entry.getTitle(), entry.getStatus(), entry.getCreatedAt());
    }
  }
}
