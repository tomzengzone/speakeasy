package com.speakeasy.ai;

import java.util.List;
import java.util.UUID;

public interface AiProviderGateway {
  TranscribeResult transcribe(String audioRef, String languageHint);

  TtsResult synthesize(String text, String voice);

  ScoreResult scorePronunciation(String audioRef, String referenceText);

  CoachResult coach(UUID sessionId, String transcript, List<String> targetExpressionIds);

  int invocationCount();

  void resetInvocationCount();

  record TranscribeResult(String transcript, double confidence, String status) {}

  record TtsResult(String audioRef, String status) {}

  record ScoreResult(String scoreKind, Double value, Double confidence, String status) {}

  record CoachResult(
      String feedbackType,
      String summary,
      String mainIssueType,
      String suggestedExpression,
      String nextPrompt,
      ScoreResult scoreSignal,
      String validationStatus,
      String providerStatus,
      String recoverableErrorCode) {
    public boolean recoverable() {
      return recoverableErrorCode != null && !recoverableErrorCode.isBlank();
    }
  }
}
