package com.speakeasy.ai;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicInteger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

@Component
@ConditionalOnProperty(prefix = "speakeasy.ai", name = "provider", havingValue = "dashscope")
public class DashScopeAiProviderGateway implements AiProviderGateway {
  private static final Map<String, String> JSON_HEADERS =
      Map.of("Content-Type", "application/json");
  private static final List<String> BANNED_FIELDS =
      List.of(
          "mastered",
          "accepted",
          "review_scheduled",
          "entitled",
          "billing_state",
          "entitlement",
          "subscription_status");
  private static final List<String> ALLOWED_FEEDBACK_TYPES = List.of("next_question", "retry", "recoverable_error");
  private static final List<String> ALLOWED_ISSUES =
      List.of("none", "grammar", "vocabulary", "naturalness", "tone", "pronunciation", "fluency", "missing_intent", "off_topic");
  private static final List<String> ALLOWED_SCORE_KINDS = List.of("pronunciation", "fluency", "task_completion");
  private static final List<String> ALLOWED_SCORE_STATUS = List.of("available", "low_confidence", "unavailable");
  private static final Set<String> COACH_ROOT_FIELDS =
      Set.of("feedback_type", "summary", "main_issue_type", "suggested_expression", "next_prompt", "score_signal");
  private static final Set<String> SCORE_SIGNAL_FIELDS = Set.of("score_kind", "value", "confidence", "status");

  private final DashScopeAiProperties properties;
  private final DashScopeHttpTransport transport;
  private final ObjectMapper mapper;
  private final AiProviderTelemetry telemetry;
  private final AiMediaReferenceService mediaReferenceService;
  private final AiTtsCacheService ttsCacheService;
  private final AtomicInteger invocationCount = new AtomicInteger();
  private final ConcurrentMap<String, TtsResult> localFallbackTtsCache = new ConcurrentHashMap<>();

  @Autowired
  public DashScopeAiProviderGateway(
      DashScopeAiProperties properties,
      DashScopeHttpTransport transport,
      ObjectMapper mapper,
      AiProviderTelemetry telemetry,
      AiMediaReferenceService mediaReferenceService,
      AiTtsCacheService ttsCacheService) {
    this.properties = properties;
    this.transport = transport;
    this.mapper = mapper;
    this.telemetry = telemetry;
    this.mediaReferenceService = mediaReferenceService;
    this.ttsCacheService = ttsCacheService;
  }

  public DashScopeAiProviderGateway(
      DashScopeAiProperties properties,
      DashScopeHttpTransport transport,
      ObjectMapper mapper,
      AiProviderTelemetry telemetry,
      AiMediaReferenceService mediaReferenceService) {
    this(properties, transport, mapper, telemetry, mediaReferenceService, null);
  }

  @Override
  public TranscribeResult transcribe(String audioRef, String languageHint) {
    invocationCount.incrementAndGet();
    Instant started = Instant.now();
    AiMediaReferenceService.TrustedAudioRef media = mediaReferenceService.inspectAudioRef(audioRef, true);
    String fallback = validateAudioRef(media);
    if (!fallback.isBlank()) {
      record("asr", properties.getAsrModel(), fallback, started, fallback, null, media.durationSeconds());
      return new TranscribeResult("", 0, fallback.equals("provider_policy_rejected") ? "provider_unavailable" : "no_result");
    }
    try {
      ObjectNode body = mapper.createObjectNode();
      body.put("model", properties.getAsrModel());
      ObjectNode input = body.putObject("input");
      ArrayNode fileUrls = input.putArray("file_urls");
      fileUrls.add(media.providerRef().trim());
      ObjectNode parameters = body.putObject("parameters");
      ArrayNode hints = parameters.putArray("language_hints");
      addLanguageHints(hints, languageHint);
      parameters.put("file_format", audioFormat(media.providerRef()));

      JsonNode submit =
          transport.postJson(
              url(properties.getApiBaseUrl(), "/services/audio/asr/transcription"),
              body,
              authHeaders("X-DashScope-Async", "enable"),
              properties.getRequestTimeout());
      String taskId = textAt(submit, "/output/task_id");
      if (taskId.isBlank()) {
        record("asr", properties.getAsrModel(), "provider_unavailable", started, "missing_task_id", null, media.durationSeconds());
        return new TranscribeResult("", 0, "provider_unavailable");
      }
      for (int i = 0; i < properties.getAsrPollAttempts(); i++) {
        JsonNode poll =
            transport.postJson(
                url(properties.getApiBaseUrl(), "/tasks/" + taskId),
                mapper.createObjectNode(),
                authHeaders(),
                properties.getRequestTimeout());
        String status = textAt(poll, "/output/task_status");
        if ("SUCCEEDED".equals(status)) {
          String transcript = transcriptFrom(poll);
          if (transcript.isBlank()) {
            record("asr", properties.getAsrModel(), "no_result", started, "empty_transcript", null, media.durationSeconds());
            return new TranscribeResult("", 0, "no_result");
          }
          record("asr", properties.getAsrModel(), "available", started, "", null, media.durationSeconds());
          return new TranscribeResult(transcript, 0.86, "available");
        }
        if ("FAILED".equals(status)) {
          record("asr", properties.getAsrModel(), "no_result", started, "task_failed", null, media.durationSeconds());
          return new TranscribeResult("", 0, "no_result");
        }
      }
      record("asr", properties.getAsrModel(), "provider_unavailable", started, "poll_timeout", null, media.durationSeconds());
      return new TranscribeResult("", 0, "provider_unavailable");
    } catch (RuntimeException e) {
      record("asr", properties.getAsrModel(), "provider_unavailable", started, "transport_error", null, media.durationSeconds());
      return new TranscribeResult("", 0, "provider_unavailable");
    }
  }

  @Override
  public TtsResult synthesize(String text, String voice) {
    invocationCount.incrementAndGet();
    Instant started = Instant.now();
    String cleaned = text == null ? "" : text.trim();
    if (cleaned.isBlank() || cleaned.length() > properties.getMaxTextChars() || properties.getApiKey().isBlank()) {
      record("tts", properties.getTtsModel(), "provider_unavailable", started, "provider_policy_rejected", tokenEstimate(cleaned), null);
      return new TtsResult("", "provider_unavailable");
    }
    String resolvedVoice = voice == null || voice.isBlank() ? properties.getTtsVoice() : voice.trim();
    String languageType = inferLanguageType(cleaned);
    String cacheKey = ttsCacheService == null
        ? ttsCacheKey(cleaned, resolvedVoice, languageType)
        : ttsCacheService.cacheKey(cleaned, resolvedVoice, languageType);
    if (ttsCacheService != null) {
      var cached = ttsCacheService.lookup(cacheKey);
      if (cached.isPresent()) {
        AiTtsCacheEntry entry = cached.get();
        record("tts", properties.getTtsModel(), "available", started, "cache_hit", tokenEstimate(cleaned), null);
        return new TtsResult(
            entry.getAudioRef(),
            "available",
            entry.getCacheId().toString(),
            "hit",
            entry.getExpiresAt());
      }
    } else {
      TtsResult cached = localFallbackTtsCache.get(cacheKey);
      if (cached != null) {
        record("tts", properties.getTtsModel(), "available", started, "cache_hit", tokenEstimate(cleaned), null);
        return cached;
      }
    }
    try {
      ObjectNode body = mapper.createObjectNode();
      body.put("model", properties.getTtsModel());
      ObjectNode input = body.putObject("input");
      input.put("text", cleaned);
      input.put("voice", resolvedVoice);
      input.put("language_type", languageType);
      JsonNode response =
          transport.postJson(
              properties.getTtsUrl(),
              body,
              authHeaders(),
              properties.getRequestTimeout());
      String audioRef = textAt(response, "/output/audio/url");
      if (audioRef.isBlank()) {
        audioRef = textAt(response, "/output/audio_url");
      }
      if (audioRef.isBlank()) {
        record("tts", properties.getTtsModel(), "provider_unavailable", started, "missing_audio_ref", tokenEstimate(cleaned), null);
        return new TtsResult("", "provider_unavailable");
      }
      TtsResult result = cachedOrStoredResult(cleaned, resolvedVoice, languageType, cacheKey, audioRef);
      record("tts", properties.getTtsModel(), "available", started, "provider_call", tokenEstimate(cleaned), null);
      return result;
    } catch (RuntimeException e) {
      record("tts", properties.getTtsModel(), "provider_unavailable", started, "transport_error", tokenEstimate(cleaned), null);
      return new TtsResult("", "provider_unavailable");
    }
  }

  @Override
  public ScoreResult scorePronunciation(String audioRef, String referenceText) {
    invocationCount.incrementAndGet();
    Instant started = Instant.now();
    AiMediaReferenceService.TrustedAudioRef media = mediaReferenceService.inspectAudioRef(audioRef, false);
    record("scoring", "dashscope-unconfigured", "unavailable", started, "provider_not_selected", null, media.durationSeconds());
    return new ScoreResult("pronunciation", null, null, "unavailable");
  }

  @Override
  public CoachResult coach(UUID sessionId, String transcript, List<String> targetExpressionIds) {
    invocationCount.incrementAndGet();
    Instant started = Instant.now();
    String cleaned = transcript == null ? "" : transcript.trim();
    if (cleaned.isBlank() || cleaned.length() > properties.getMaxTextChars() || properties.getApiKey().isBlank()) {
      record("ai", properties.getLlmModel(), "provider_unavailable", started, "provider_policy_rejected", tokenEstimate(cleaned), null);
      return fallback("provider_unavailable", "Coach feedback is temporarily unavailable. Please retry.");
    }
    try {
      JsonNode response =
          transport.postJson(
              url(properties.getCompatibleBaseUrl(), "/chat/completions"),
              coachRequest(cleaned, targetExpressionIds),
              authHeaders(),
              properties.getRequestTimeout());
      String raw = textAt(response, "/choices/0/message/content");
      CoachResult result = parseCoach(raw);
      record("ai", properties.getLlmModel(), result.providerStatus(), started, "", tokenEstimate(cleaned), null);
      return result;
    } catch (RuntimeException e) {
      record("ai", properties.getLlmModel(), "provider_unavailable", started, "transport_error", tokenEstimate(cleaned), null);
      return fallback("provider_unavailable", "Coach feedback is temporarily unavailable. Please retry.");
    }
  }

  @Override
  public int invocationCount() {
    return invocationCount.get();
  }

  @Override
  public void resetInvocationCount() {
    invocationCount.set(0);
    localFallbackTtsCache.clear();
  }

  private TtsResult cachedOrStoredResult(String text, String voice, String language, String cacheKey, String audioRef) {
    if (ttsCacheService == null) {
      TtsResult result = new TtsResult(audioRef, "available");
      localFallbackTtsCache.putIfAbsent(cacheKey, result);
      return localFallbackTtsCache.get(cacheKey);
    }
    AiTtsCacheEntry entry = ttsCacheService.store(cacheKey, text, voice, language, audioRef);
    return new TtsResult(
        entry.getAudioRef(),
        "available",
        entry.getCacheId().toString(),
        "miss",
        entry.getExpiresAt());
  }

  private ObjectNode coachRequest(String transcript, List<String> targetExpressionIds) {
    ObjectNode body = mapper.createObjectNode();
    body.put("model", properties.getLlmModel());
    body.put("temperature", 0.1);
    body.put("max_tokens", 420);
    ArrayNode messages = body.putArray("messages");
    messages.addObject().put("role", "system").put("content", coachSystemPrompt());
    messages.addObject().put("role", "user").put("content", coachUserPrompt(transcript, targetExpressionIds));
    return body;
  }

  private String coachSystemPrompt() {
    return String.join(
        "\n",
        "You generate strict JSON for English speaking coach feedback.",
        "Do not use Markdown.",
        "Do not decide final mastery, entitlement, billing, or review schedule.",
        "Schema:",
        "{\"feedback_type\":\"next_question|retry|recoverable_error\",\"summary\":\"short Chinese feedback\",\"main_issue_type\":\"none|grammar|vocabulary|naturalness|tone|pronunciation|fluency|missing_intent|off_topic\",\"suggested_expression\":\"English suggestion or empty\",\"next_prompt\":\"one next prompt\",\"score_signal\":{\"score_kind\":\"pronunciation|fluency|task_completion\",\"value\":0.85,\"confidence\":0.85,\"status\":\"available|low_confidence|unavailable\"}}");
  }

  private String coachUserPrompt(String transcript, List<String> targetExpressionIds) {
    return "Learner transcript: "
        + transcript
        + "\nTarget expression ids: "
        + (targetExpressionIds == null ? List.of() : targetExpressionIds);
  }

  private CoachResult parseCoach(String raw) {
    try {
      JsonNode json = mapper.readTree(extractJson(raw));
      requireObject(json, "root");
      if (containsBannedField(json)) {
        return fallback("invalid_schema", "AI feedback schema validation failed. Please retry.");
      }
      requireOnlyFields(json, COACH_ROOT_FIELDS, "root");
      String feedbackType = requiredEnum(requiredText(json, "feedback_type", false), ALLOWED_FEEDBACK_TYPES);
      String summary = requiredText(json, "summary", false);
      String issue = requiredEnum(requiredText(json, "main_issue_type", false), ALLOWED_ISSUES);
      String suggestedExpression = requiredText(json, "suggested_expression", true);
      String nextPrompt = requiredText(json, "next_prompt", false);
      JsonNode scoreSignal = json.get("score_signal");
      requireObject(scoreSignal, "score_signal");
      requireOnlyFields(scoreSignal, SCORE_SIGNAL_FIELDS, "score_signal");
      ScoreResult score =
          new ScoreResult(
              requiredEnum(requiredText(scoreSignal, "score_kind", false), ALLOWED_SCORE_KINDS),
              requiredScore(scoreSignal, "value"),
              requiredScore(scoreSignal, "confidence"),
              requiredEnum(requiredText(scoreSignal, "status", false), ALLOWED_SCORE_STATUS));
      return new CoachResult(
          feedbackType,
          summary,
          issue,
          suggestedExpression,
          nextPrompt,
          score,
          "valid",
          "success",
          null);
    } catch (Exception e) {
      return fallback("invalid_schema", "AI feedback schema validation failed. Please retry.");
    }
  }

  private CoachResult fallback(String code, String summary) {
    return new CoachResult(
        "recoverable_error",
        summary,
        "none",
        null,
        "Please retry this turn when the service is available.",
        new ScoreResult("pronunciation", null, null, "unavailable"),
        "fallback",
        code,
        code);
  }

  private String validateAudioRef(AiMediaReferenceService.TrustedAudioRef media) {
    if (properties.getApiKey().isBlank()) {
      return "provider_policy_rejected";
    }
    if (!media.valid()) {
      return "no_result";
    }
    if (!media.trustedMetadata()) {
      return "provider_policy_rejected";
    }
    Integer duration = media.durationSeconds();
    if (duration != null && duration > properties.getMaxAsrDurationSeconds()) {
      return "provider_policy_rejected";
    }
    Long bytes = media.bytes();
    if (bytes != null && bytes > properties.getMaxAsrBytes()) {
      return "provider_policy_rejected";
    }
    return "";
  }

  private String transcriptFrom(JsonNode poll) {
    JsonNode results = poll.at("/output/results");
    if (results.isArray() && results.size() > 0) {
      JsonNode first = results.get(0);
      String text = textAt(first, "/text");
      if (!text.isBlank()) {
        return text;
      }
      String url = textAt(first, "/transcription_url");
      if (!url.isBlank()) {
        JsonNode transcription = transport.getJson(url, authHeaders(), properties.getRequestTimeout());
        return transcriptFromDownloaded(transcription);
      }
    }
    return "";
  }

  private String transcriptFromDownloaded(JsonNode transcription) {
    if (transcription.isArray()) {
      StringBuilder builder = new StringBuilder();
      for (JsonNode item : transcription) {
        builder.append(textAt(item, "/text"));
      }
      return builder.toString().trim();
    }
    JsonNode transcripts = transcription.at("/transcripts");
    if (transcripts.isArray()) {
      StringBuilder builder = new StringBuilder();
      for (JsonNode item : transcripts) {
        builder.append(textAt(item, "/text"));
      }
      return builder.toString().trim();
    }
    return textAt(transcription, "/text");
  }

  private Map<String, String> authHeaders(String... extra) {
    java.util.LinkedHashMap<String, String> headers = new java.util.LinkedHashMap<>(JSON_HEADERS);
    headers.put("Authorization", "Bearer " + properties.getApiKey());
    for (int i = 0; i + 1 < extra.length; i += 2) {
      headers.put(extra[i], extra[i + 1]);
    }
    return headers;
  }

  private void addLanguageHints(ArrayNode hints, String languageHint) {
    String value = languageHint == null ? "" : languageHint.trim();
    if (value.isBlank()) {
      hints.add("en");
      hints.add("zh");
      return;
    }
    for (String part : value.split(",")) {
      String cleaned = part.trim();
      if (!cleaned.isBlank()) {
        hints.add(cleaned);
      }
    }
  }

  private String audioFormat(String audioRef) {
    String path = URI.create(audioRef).getPath().toLowerCase(Locale.ROOT);
    if (path.endsWith(".mp3")) {
      return "mp3";
    }
    if (path.endsWith(".m4a") || path.endsWith(".mp4") || path.endsWith(".aac")) {
      return "mp4";
    }
    return "wav";
  }

  private String inferLanguageType(String text) {
    boolean hasChinese = text.codePoints().anyMatch(code -> code >= 0x4e00 && code <= 0x9fff);
    boolean hasLatin = text.codePoints().anyMatch(code -> (code >= 'A' && code <= 'Z') || (code >= 'a' && code <= 'z'));
    if (hasChinese && !hasLatin) {
      return "Chinese";
    }
    if (hasLatin && !hasChinese) {
      return "English";
    }
    return "Auto";
  }

  private String ttsCacheKey(String text, String voice, String language) {
    try {
      MessageDigest digest = MessageDigest.getInstance("SHA-256");
      byte[] bytes =
          digest.digest((properties.getTtsModel() + "\n" + voice + "\n" + language + "\n" + text).getBytes(StandardCharsets.UTF_8));
      return HexFormat.of().formatHex(bytes).substring(0, 32);
    } catch (Exception e) {
      throw new IllegalStateException("sha256 unavailable", e);
    }
  }

  private Integer tokenEstimate(String text) {
    if (text == null || text.isBlank()) {
      return 0;
    }
    return Math.max(1, text.length() / 4);
  }

  private String url(String base, String path) {
    String cleanedBase = base.endsWith("/") ? base.substring(0, base.length() - 1) : base;
    return cleanedBase + path;
  }

  private String textAt(JsonNode node, String pointer) {
    if (node == null) {
      return "";
    }
    JsonNode value = node.at(pointer);
    return value.isMissingNode() || value.isNull() ? "" : value.asText("").trim();
  }

  private String requiredEnum(String value, List<String> allowed) {
    if (!allowed.contains(value)) {
      throw new IllegalArgumentException("unsupported enum");
    }
    return value;
  }

  private void requireObject(JsonNode node, String fieldName) {
    if (node == null || !node.isObject()) {
      throw new IllegalArgumentException(fieldName + " must be object");
    }
  }

  private void requireOnlyFields(JsonNode node, Set<String> allowedFields, String objectName) {
    java.util.Iterator<String> names = node.fieldNames();
    while (names.hasNext()) {
      String name = names.next();
      if (!allowedFields.contains(name)) {
        throw new IllegalArgumentException(objectName + " has unsupported field");
      }
    }
  }

  private String requiredText(JsonNode node, String fieldName, boolean allowBlank) {
    JsonNode value = node.get(fieldName);
    if (value == null || value.isNull() || !value.isTextual()) {
      throw new IllegalArgumentException("missing text field " + fieldName);
    }
    String text = value.asText().trim();
    if (!allowBlank && text.isBlank()) {
      throw new IllegalArgumentException("blank text field " + fieldName);
    }
    return text;
  }

  private Double requiredScore(JsonNode node, String fieldName) {
    JsonNode value = node.get(fieldName);
    if (value == null || !value.isNumber()) {
      throw new IllegalArgumentException("missing score field " + fieldName);
    }
    double score = value.doubleValue();
    if (score < 0 || score > 1) {
      throw new IllegalArgumentException("score out of range " + fieldName);
    }
    return score;
  }

  private String extractJson(String raw) {
    String value = raw == null ? "" : raw.trim();
    int start = value.indexOf('{');
    int end = value.lastIndexOf('}');
    if (start < 0 || end <= start) {
      throw new IllegalArgumentException("json object missing");
    }
    return value.substring(start, end + 1);
  }

  private boolean containsBannedField(JsonNode node) {
    if (node == null || node.isNull()) {
      return false;
    }
    if (node.isObject()) {
      java.util.Iterator<Map.Entry<String, JsonNode>> fields = node.fields();
      while (fields.hasNext()) {
        Map.Entry<String, JsonNode> field = fields.next();
        if (BANNED_FIELDS.contains(field.getKey().trim())) {
          return true;
        }
        if (containsBannedField(field.getValue())) {
          return true;
        }
      }
    }
    if (node.isArray()) {
      for (JsonNode item : node) {
        if (containsBannedField(item)) {
          return true;
        }
      }
    }
    return false;
  }

  private void record(
      String family,
      String model,
      String status,
      Instant started,
      String fallbackReason,
      Integer tokenEstimate,
      Integer audioDurationSeconds) {
    long latencyMs = Math.max(0, Duration.between(started, Instant.now()).toMillis());
    telemetry.record(
        new AiProviderTelemetry.Event(
            "dashscope",
            model,
            family,
            status,
            latencyMs,
            fallbackReason == null ? "" : fallbackReason,
            "provider-default",
            tokenEstimate,
            audioDurationSeconds,
            costBucket(tokenEstimate, audioDurationSeconds)));
  }

  private String costBucket(Integer tokenEstimate, Integer audioDurationSeconds) {
    int units = (tokenEstimate == null ? 0 : tokenEstimate) + (audioDurationSeconds == null ? 0 : audioDurationSeconds * 2);
    if (units <= 100) {
      return "low";
    }
    if (units <= 600) {
      return "medium";
    }
    return "high";
  }
}
