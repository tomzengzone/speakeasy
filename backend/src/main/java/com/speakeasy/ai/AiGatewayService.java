package com.speakeasy.ai;

import com.speakeasy.common.ApiException;
import com.speakeasy.practice.PracticeSessionRepository;
import java.util.List;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AiGatewayService {
  private final AiProviderGateway provider;
  private final PracticeSessionRepository sessions;

  public AiGatewayService(AiProviderGateway provider, PracticeSessionRepository sessions) {
    this.provider = provider;
    this.sessions = sessions;
  }

  public AiProviderGateway.TranscribeResult transcribe(String audioRef, String languageHint) {
    return provider.transcribe(audioRef, languageHint);
  }

  public AiProviderGateway.TtsResult synthesize(String text, String voice) {
    return provider.synthesize(text, voice);
  }

  public AiProviderGateway.ScoreResult scorePronunciation(String audioRef, String referenceText) {
    return provider.scorePronunciation(audioRef, referenceText);
  }

  @Transactional(readOnly = true)
  public AiProviderGateway.CoachResult coach(UUID userId, UUID sessionId, String transcript, List<String> targetExpressionIds) {
    sessions.findByPracticeSessionIdAndUserId(sessionId, userId)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Practice session was not found."));
    return provider.coach(sessionId, transcript, targetExpressionIds == null ? List.of() : targetExpressionIds);
  }

  public int invocationCount() {
    return provider.invocationCount();
  }

  public void resetInvocationCount() {
    provider.resetInvocationCount();
  }
}
