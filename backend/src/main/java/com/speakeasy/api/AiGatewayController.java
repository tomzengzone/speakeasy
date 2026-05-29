package com.speakeasy.api;

import com.speakeasy.ai.AiGatewayService;
import com.speakeasy.ai.AiProviderGateway;
import com.speakeasy.common.SchemaResponse;
import com.speakeasy.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.util.List;
import java.util.UUID;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AiGatewayController {
  private final AiGatewayService service;

  public AiGatewayController(AiGatewayService service) {
    this.service = service;
  }

  @PostMapping("/ai/transcribe")
  public TranscribeResponse transcribe(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody TranscribeRequest request) {
    AiProviderGateway.TranscribeResult result = service.transcribe(currentUser.userId(), request.audioRef(), request.languageHint());
    return new TranscribeResponse(1, result.transcript(), result.confidence(), result.status());
  }

  @PostMapping("/ai/tts")
  public TtsResponse synthesize(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody TtsRequest request) {
    AiProviderGateway.TtsResult result = service.synthesize(currentUser.userId(), request.text(), request.voice());
    return new TtsResponse(1, result.audioRef(), result.status());
  }

  @PostMapping("/ai/pronunciation")
  public PronunciationResponse scorePronunciation(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody PronunciationRequest request) {
    return new PronunciationResponse(
        1,
        ScoreSignalDto.from(service.scorePronunciation(currentUser.userId(), request.audioRef(), request.referenceText())));
  }

  @PostMapping({"/ai/coach-turn", "/ai/feedback"})
  public CoachTurnResponse coach(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody CoachTurnRequest request) {
    AiProviderGateway.CoachResult result =
        service.coach(currentUser.userId(), request.sessionId(), request.transcript(), request.targetExpressionIds());
    return new CoachTurnResponse(
        1,
        CoachFeedbackDto.from(result),
        result.validationStatus());
  }

  public record TranscribeRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String audioRef,
      String languageHint) {}

  public record TranscribeResponse(int schemaVersion, String transcript, double confidence, String status) implements SchemaResponse {}

  public record TtsRequest(@NotNull @Min(1) @Max(1) Integer schemaVersion, @NotBlank String text, String voice) {}

  public record TtsResponse(int schemaVersion, String audioRef, String status) implements SchemaResponse {}

  public record PronunciationRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String audioRef,
      String referenceText) {}

  public record PronunciationResponse(int schemaVersion, ScoreSignalDto scoreSignal) implements SchemaResponse {}

  public record CoachTurnRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotNull UUID sessionId,
      @NotBlank String transcript,
      List<String> targetExpressionIds) {}

  public record CoachTurnResponse(int schemaVersion, CoachFeedbackDto feedback, String validationStatus) implements SchemaResponse {}

  public record CoachFeedbackDto(
      String summary,
      String feedbackType,
      String mainIssueType,
      String suggestedExpression,
      String nextPrompt,
      ScoreSignalDto scoreSignal,
      String validationStatus,
      String providerStatus) {
    static CoachFeedbackDto from(AiProviderGateway.CoachResult feedback) {
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
    static ScoreSignalDto from(AiProviderGateway.ScoreResult score) {
      return new ScoreSignalDto(score.scoreKind(), score.value(), score.confidence(), score.status(), "server_side_adapter");
    }
  }
}
