package com.speakeasy.ai;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Optional;
import java.util.UUID;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AiTtsCacheService {
  private final AiTtsCacheEntryRepository entries;
  private final DashScopeAiProperties dashScopeProperties;
  private final AiMediaProperties mediaProperties;
  private final Clock clock;

  public AiTtsCacheService(
      AiTtsCacheEntryRepository entries,
      DashScopeAiProperties dashScopeProperties,
      AiMediaProperties mediaProperties,
      Clock clock) {
    this.entries = entries;
    this.dashScopeProperties = dashScopeProperties;
    this.mediaProperties = mediaProperties;
    this.clock = clock;
  }

  public String cacheKey(String normalizedText, String voice, String language) {
    String resolvedVoice = voice == null || voice.isBlank() ? dashScopeProperties.getTtsVoice() : voice.trim();
    String resolvedLanguage = language == null || language.isBlank() ? "Auto" : language.trim();
    return sha256(normalizedText + "\n" + dashScopeProperties.getTtsModel() + "\n" + resolvedVoice + "\n" + resolvedLanguage);
  }

  @Transactional
  public Optional<AiTtsCacheEntry> lookup(String cacheKey) {
    Instant now = Instant.now(clock);
    Optional<AiTtsCacheEntry> found = entries.findByCacheKey(cacheKey);
    if (found.isEmpty()) {
      return Optional.empty();
    }
    AiTtsCacheEntry entry = found.get();
    if (entry.activeAt(now)) {
      entry.markHit(now);
      entries.save(entry);
      return Optional.of(entry);
    }
    if ("active".equals(entry.getStatus())) {
      entry.markStale(now);
      entries.save(entry);
    }
    return Optional.empty();
  }

  @Transactional
  public AiTtsCacheEntry store(String cacheKey, String normalizedText, String voice, String language, String audioRef) {
    Instant now = Instant.now(clock);
    var existing = entries.findByCacheKey(cacheKey);
    if (existing.isPresent()) {
      AiTtsCacheEntry entry = existing.get();
      if (entry.activeAt(now)) {
        return entry;
      }
      entry.refresh(audioRef, now.plus(mediaProperties.getTtsCacheTtl()), now);
      return entries.save(entry);
    }
    return entries.save(new AiTtsCacheEntry(
            UUID.randomUUID(),
            cacheKey,
            sha256(normalizedText),
            dashScopeProperties.getTtsModel(),
            voice == null || voice.isBlank() ? dashScopeProperties.getTtsVoice() : voice.trim(),
            language == null || language.isBlank() ? "Auto" : language.trim(),
            audioRef,
            now.plus(mediaProperties.getTtsCacheTtl()),
            now));
  }

  @Transactional
  public int markExpiredDeleted() {
    Instant now = Instant.now(clock);
    var expired = entries.findByStatusAndExpiresAtBefore("active", now);
    expired.forEach(entry -> entry.markDeleted(now));
    entries.saveAll(expired);
    return expired.size();
  }

  private String sha256(String value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException("sha256 unavailable", e);
    }
  }
}
