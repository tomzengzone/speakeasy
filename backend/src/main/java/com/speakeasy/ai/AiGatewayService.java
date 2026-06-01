package com.speakeasy.ai;

import com.speakeasy.common.ApiException;
import com.speakeasy.practice.PracticeSessionRepository;
import com.speakeasy.usage.UsageReservation;
import com.speakeasy.usage.UsageService;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AiGatewayService {
  private final AiProviderGateway provider;
  private final PracticeSessionRepository sessions;
  private final UsageService usageService;
  private final AiProviderPolicyService policyService;
  private final AiMediaReferenceService mediaReferenceService;
  private final AiCostMetricsService costMetricsService;
  private final AiRetentionService retentionService;

  public AiGatewayService(
      AiProviderGateway provider,
      PracticeSessionRepository sessions,
      UsageService usageService,
      AiProviderPolicyService policyService,
      AiMediaReferenceService mediaReferenceService,
      AiCostMetricsService costMetricsService,
      AiRetentionService retentionService) {
    this.provider = provider;
    this.sessions = sessions;
    this.usageService = usageService;
    this.policyService = policyService;
    this.mediaReferenceService = mediaReferenceService;
    this.costMetricsService = costMetricsService;
    this.retentionService = retentionService;
  }

  public AiProviderGateway.TranscribeResult transcribe(UUID userId, String audioRef, String languageHint) {
    policyService.validateAudioRef(userId, "asr", audioRef);
    UsageReservation reservation = usageService.reserveProviderCall(userId, "asr", mediaReferenceService.auditRef(audioRef));
    try {
      AiProviderGateway.TranscribeResult result = provider.transcribe(audioRef, languageHint);
      costMetricsService.recordInvocation(
          userId, "asr", result.status(), false, null, audioDuration(audioRef), "");
      closeProviderReservation(userId, reservation, "available".equals(result.status()));
      return result;
    } catch (RuntimeException e) {
      usageService.release(userId, reservation.getReservationId(), "provider_exception:asr");
      throw e;
    }
  }

  public AiProviderGateway.TtsResult synthesize(UUID userId, String text, String voice) {
    policyService.validateText(userId, "tts", text);
    UsageReservation reservation = usageService.reserveProviderCall(userId, "tts", "tts");
    try {
      AiProviderGateway.TtsResult result = provider.synthesize(text, voice);
      retentionService.attachTtsCacheOwner(result.mediaId(), userId);
      costMetricsService.recordInvocation(
          userId,
          "tts",
          result.status(),
          "hit".equals(result.cacheStatus()),
          tokenEstimate(text),
          null,
          "provider_unavailable".equals(result.status()) ? result.status() : "");
      closeProviderReservation(userId, reservation, "available".equals(result.status()));
      return result;
    } catch (RuntimeException e) {
      usageService.release(userId, reservation.getReservationId(), "provider_exception:tts");
      throw e;
    }
  }

  public AiProviderGateway.ScoreResult scorePronunciation(UUID userId, String audioRef, String referenceText) {
    policyService.validateAudioRef(userId, "scoring", audioRef);
    UsageReservation reservation = usageService.reserveProviderCall(userId, "scoring", mediaReferenceService.auditRef(audioRef));
    try {
      AiProviderGateway.ScoreResult result = provider.scorePronunciation(audioRef, referenceText);
      costMetricsService.recordInvocation(
          userId, "scoring", result.status(), false, tokenEstimate(referenceText), audioDuration(audioRef), "");
      closeProviderReservation(userId, reservation, "available".equals(result.status()));
      return result;
    } catch (RuntimeException e) {
      usageService.release(userId, reservation.getReservationId(), "provider_exception:scoring");
      throw e;
    }
  }

  @Transactional
  public AiProviderGateway.CoachResult coach(UUID userId, UUID sessionId, String transcript, List<String> targetExpressionIds) {
    sessions.findByPracticeSessionIdAndUserId(sessionId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Practice session was not found."));
    policyService.validateText(userId, "ai", transcript);
    UsageReservation reservation = usageService.reserveProviderCall(userId, "ai", sessionId.toString());
    try {
      AiProviderGateway.CoachResult result = provider.coach(sessionId, transcript, targetExpressionIds == null ? List.of() : targetExpressionIds);
      costMetricsService.recordInvocation(
          userId,
          "ai",
          result.providerStatus(),
          false,
          tokenEstimate(transcript),
          null,
          result.recoverableErrorCode());
      closeProviderReservation(userId, reservation, !result.recoverable());
      return result;
    } catch (RuntimeException e) {
      usageService.release(userId, reservation.getReservationId(), "provider_exception:ai");
      throw e;
    }
  }

  private void closeProviderReservation(UUID userId, UsageReservation reservation, boolean success) {
    if (success) {
      usageService.commit(userId, reservation.getReservationId(), "provider:" + reservation.getUsageFamily());
    } else {
      usageService.release(userId, reservation.getReservationId(), "provider:" + reservation.getUsageFamily());
    }
  }

  public int invocationCount() {
    return provider.invocationCount();
  }

  public void resetInvocationCount() {
    provider.resetInvocationCount();
  }

  private Integer audioDuration(String audioRef) {
    AiMediaReferenceService.TrustedAudioRef media = mediaReferenceService.inspectAudioRef(audioRef, false);
    return media.durationSeconds();
  }

  private Integer tokenEstimate(String text) {
    String cleaned = text == null ? "" : text.trim();
    return cleaned.isBlank() ? 0 : Math.max(1, cleaned.length() / 4);
  }
}
