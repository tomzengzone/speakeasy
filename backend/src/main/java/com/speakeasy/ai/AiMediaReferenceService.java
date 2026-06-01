package com.speakeasy.ai;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Comparator;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class AiMediaReferenceService {
  private static final String SIGNATURE_PARAM = "media_sig";
  private static final String DURATION_PARAM = "duration_seconds";
  private static final String BYTES_PARAM = "bytes";

  private final AiMediaProperties properties;
  private final AiMediaAssetRepository mediaAssets;
  private final HttpClient httpClient;

  @Autowired
  public AiMediaReferenceService(AiMediaProperties properties, AiMediaAssetRepository mediaAssets) {
    this(properties, mediaAssets, HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build());
  }

  public AiMediaReferenceService(AiMediaProperties properties) {
    this(properties, null, HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(3)).build());
  }

  AiMediaReferenceService(AiMediaProperties properties, HttpClient httpClient) {
    this(properties, null, httpClient);
  }

  AiMediaReferenceService(AiMediaProperties properties, AiMediaAssetRepository mediaAssets, HttpClient httpClient) {
    this.properties = properties;
    this.mediaAssets = mediaAssets;
    this.httpClient = httpClient;
  }

  public TrustedAudioRef inspectAudioRef(String audioRef, boolean requireTrustedMetadata) {
    String value = audioRef == null ? "" : audioRef.trim();
    if (value.isBlank()) {
      return TrustedAudioRef.invalid(value, "blank_audio_ref");
    }
    URI uri = parseUri(value);
    if (uri != null && "media".equalsIgnoreCase(uri.getScheme())) {
      return inspectStoredMediaRef(value, uri, requireTrustedMetadata);
    }
    if (uri == null || !isHttp(uri)) {
      return TrustedAudioRef.invalid(value, "unsupported_media_ref");
    }
    QueryParams query = QueryParams.parse(uri.getRawQuery());
    Long duration = query.longValue(DURATION_PARAM);
    Long bytes = query.longValue(BYTES_PARAM);
    String signature = query.first(SIGNATURE_PARAM);
    if (duration != null && bytes != null && !signature.isBlank()) {
      if (validSignature(value, duration, bytes, signature)) {
        return TrustedAudioRef.trusted(value, auditRef(value), duration.intValue(), bytes);
      }
      return TrustedAudioRef.invalid(value, "invalid_media_metadata_signature");
    }
    if (requireTrustedMetadata && properties.isAllowUnsignedHeadMetadata()) {
      return inspectHeadMetadata(value, uri);
    }
    if (requireTrustedMetadata) {
      return TrustedAudioRef.invalid(value, "trusted_media_metadata_required");
    }
    return TrustedAudioRef.untrusted(value, auditRef(value));
  }

  private TrustedAudioRef inspectStoredMediaRef(String value, URI uri, boolean requireTrustedMetadata) {
    if (mediaAssets == null) {
      return TrustedAudioRef.invalid(value, "media_repository_unavailable");
    }
    Optional<UUID> mediaId = parseMediaId(uri);
    if (mediaId.isEmpty()) {
      return TrustedAudioRef.invalid(value, "invalid_media_ref");
    }
    return mediaAssets.findById(mediaId.get())
        .map(asset -> trustedRefForAsset(value, asset))
        .orElseGet(() -> TrustedAudioRef.invalid(value, "media_not_found"));
  }

  private TrustedAudioRef trustedRefForAsset(String value, AiMediaAsset asset) {
    Instant now = Instant.now();
    if (!asset.isValidatedAt(now)) {
      return TrustedAudioRef.invalid(value, "media_not_validated");
    }
    return TrustedAudioRef.trusted(
        asset.getProviderRef(), asset.getAuditRef(), asset.getDurationSeconds(), asset.getByteSize());
  }

  public String signTrustedAudioRef(String providerAudioRef, int durationSeconds, long bytes) {
    if (properties.getMetadataSigningKey().isBlank()) {
      throw new IllegalStateException("media metadata signing key is not configured");
    }
    String base = stripMetadataParams(providerAudioRef);
    String unsigned =
        base
            + (base.contains("?") ? "&" : "?")
            + DURATION_PARAM
            + "="
            + durationSeconds
            + "&"
            + BYTES_PARAM
            + "="
            + bytes;
    return unsigned + "&" + SIGNATURE_PARAM + "=" + signatureFor(unsigned, (long) durationSeconds, bytes);
  }

  public String auditRef(String sourceRef) {
    String value = sourceRef == null ? "" : sourceRef.trim();
    if (value.isBlank()) {
      return "media:none";
    }
    return "media:" + sha256(value).substring(0, 16);
  }

  private TrustedAudioRef inspectHeadMetadata(String value, URI uri) {
    try {
      HttpRequest request =
          HttpRequest.newBuilder(uri)
              .timeout(properties.getMetadataTimeout())
              .method("HEAD", HttpRequest.BodyPublishers.noBody())
              .build();
      HttpResponse<Void> response = httpClient.send(request, HttpResponse.BodyHandlers.discarding());
      if (response.statusCode() < 200 || response.statusCode() >= 300) {
        return TrustedAudioRef.invalid(value, "media_metadata_unavailable");
      }
      Long bytes = response.headers().firstValueAsLong("Content-Length").isPresent()
          ? response.headers().firstValueAsLong("Content-Length").getAsLong()
          : null;
      Integer duration = response.headers().firstValue(properties.getDurationHeader())
          .flatMap(AiMediaReferenceService::parsePositiveInt)
          .orElse(null);
      if (bytes == null || duration == null) {
        return TrustedAudioRef.invalid(value, "trusted_media_metadata_required");
      }
      return TrustedAudioRef.trusted(value, auditRef(value), duration, bytes);
    } catch (Exception e) {
      return TrustedAudioRef.invalid(value, "media_metadata_unavailable");
    }
  }

  private boolean validSignature(String ref, Long duration, Long bytes, String signature) {
    if (properties.getMetadataSigningKey().isBlank()) {
      return false;
    }
    String unsigned = stripMetadataParams(ref)
        + (stripMetadataParams(ref).contains("?") ? "&" : "?")
        + DURATION_PARAM
        + "="
        + duration
        + "&"
        + BYTES_PARAM
        + "="
        + bytes;
    return MessageDigest.isEqual(
        signature.getBytes(StandardCharsets.UTF_8),
        signatureFor(unsigned, duration, bytes).getBytes(StandardCharsets.UTF_8));
  }

  private String signatureFor(String unsignedRef, Long duration, Long bytes) {
    try {
      Mac mac = Mac.getInstance("HmacSHA256");
      mac.init(new SecretKeySpec(properties.getMetadataSigningKey().getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
      String payload = canonicalMetadataPayload(unsignedRef, duration, bytes);
      return Base64.getUrlEncoder().withoutPadding().encodeToString(mac.doFinal(payload.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException("media metadata signing failed", e);
    }
  }

  private String canonicalMetadataPayload(String ref, Long duration, Long bytes) {
    return stripMetadataParams(ref) + "\n" + duration + "\n" + bytes;
  }

  private String stripMetadataParams(String ref) {
    URI uri = parseUri(ref);
    if (uri == null || uri.getRawQuery() == null || uri.getRawQuery().isBlank()) {
      return ref;
    }
    List<QueryParam> kept = QueryParams.parse(uri.getRawQuery()).params().stream()
        .filter(param -> !DURATION_PARAM.equals(param.name()))
        .filter(param -> !BYTES_PARAM.equals(param.name()))
        .filter(param -> !SIGNATURE_PARAM.equals(param.name()))
        .sorted(Comparator.comparing(QueryParam::name).thenComparing(QueryParam::value))
        .toList();
    StringBuilder builder = new StringBuilder();
    builder.append(uri.getScheme()).append("://").append(uri.getRawAuthority()).append(uri.getRawPath());
    if (!kept.isEmpty()) {
      builder.append('?');
      for (int i = 0; i < kept.size(); i++) {
        if (i > 0) {
          builder.append('&');
        }
        builder.append(kept.get(i).raw());
      }
    }
    return builder.toString();
  }

  private URI parseUri(String value) {
    try {
      return URI.create(value);
    } catch (IllegalArgumentException e) {
      return null;
    }
  }

  private boolean isHttp(URI uri) {
    String scheme = uri.getScheme();
    return "http".equalsIgnoreCase(scheme) || "https".equalsIgnoreCase(scheme);
  }

  private Optional<UUID> parseMediaId(URI uri) {
    if (!"audio".equalsIgnoreCase(uri.getHost())) {
      return Optional.empty();
    }
    String path = uri.getPath() == null ? "" : uri.getPath().replaceFirst("^/", "");
    if (path.isBlank()) {
      return Optional.empty();
    }
    try {
      return Optional.of(UUID.fromString(path));
    } catch (IllegalArgumentException e) {
      return Optional.empty();
    }
  }

  private String sha256(String value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException("sha256 unavailable", e);
    }
  }

  private static java.util.Optional<Integer> parsePositiveInt(String value) {
    try {
      int parsed = Integer.parseInt(value);
      return parsed >= 0 ? java.util.Optional.of(parsed) : java.util.Optional.empty();
    } catch (NumberFormatException e) {
      return java.util.Optional.empty();
    }
  }

  private record QueryParam(String name, String value, String raw) {}

  private record QueryParams(List<QueryParam> params) {
    static QueryParams parse(String rawQuery) {
      List<QueryParam> params = new ArrayList<>();
      if (rawQuery == null || rawQuery.isBlank()) {
        return new QueryParams(params);
      }
      for (String part : rawQuery.split("&")) {
        if (part.isBlank()) {
          continue;
        }
        String[] pair = part.split("=", 2);
        params.add(new QueryParam(pair[0], pair.length == 2 ? pair[1] : "", part));
      }
      return new QueryParams(params);
    }

    String first(String name) {
      return params.stream().filter(param -> name.equals(param.name())).map(QueryParam::value).findFirst().orElse("");
    }

    Long longValue(String name) {
      String value = first(name);
      if (value.isBlank()) {
        return null;
      }
      try {
        return Long.parseLong(value);
      } catch (NumberFormatException e) {
        return null;
      }
    }
  }

  public record TrustedAudioRef(
      String providerRef,
      String auditRef,
      Integer durationSeconds,
      Long bytes,
      boolean trustedMetadata,
      String invalidReason) {
    static TrustedAudioRef trusted(String providerRef, String auditRef, Integer durationSeconds, Long bytes) {
      return new TrustedAudioRef(providerRef, auditRef, durationSeconds, bytes, true, "");
    }

    static TrustedAudioRef untrusted(String providerRef, String auditRef) {
      return new TrustedAudioRef(providerRef, auditRef, null, null, false, "");
    }

    static TrustedAudioRef invalid(String providerRef, String invalidReason) {
      return new TrustedAudioRef(providerRef, "media:invalid", null, null, false, invalidReason);
    }

    boolean valid() {
      return invalidReason == null || invalidReason.isBlank();
    }
  }
}
