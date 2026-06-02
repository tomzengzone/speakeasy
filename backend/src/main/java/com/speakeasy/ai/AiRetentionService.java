package com.speakeasy.ai;

import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AuditLog;
import com.speakeasy.ops.AuditLogRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Clock;
import java.time.Instant;
import java.util.HexFormat;
import java.util.Map;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AiRetentionService {
  private final AiRetentionJobRepository jobs;
  private final AiMediaAssetRepository mediaAssets;
  private final AiTtsCacheEntryRepository ttsCacheEntries;
  private final AiTtsCacheOwnerRepository ttsCacheOwners;
  private final AiProviderInvocationMetricRepository providerMetrics;
  private final AuditLogRepository auditLogs;
  private final JdbcTemplate jdbcTemplate;
  private final Clock clock;

  public AiRetentionService(
      AiRetentionJobRepository jobs,
      AiMediaAssetRepository mediaAssets,
      AiTtsCacheEntryRepository ttsCacheEntries,
      AiTtsCacheOwnerRepository ttsCacheOwners,
      AiProviderInvocationMetricRepository providerMetrics,
      AuditLogRepository auditLogs,
      JdbcTemplate jdbcTemplate,
      Clock clock) {
    this.jobs = jobs;
    this.mediaAssets = mediaAssets;
    this.ttsCacheEntries = ttsCacheEntries;
    this.ttsCacheOwners = ttsCacheOwners;
    this.providerMetrics = providerMetrics;
    this.auditLogs = auditLogs;
    this.jdbcTemplate = jdbcTemplate;
    this.clock = clock;
  }

  @Transactional
  public AiRetentionJob createAndRun(String scope, String userRef, String reason, String idempotencyKey, String requestId) {
    requireIdempotencyKey(idempotencyKey);
    AiRetentionJob existing = jobs.findByIdempotencyKey(idempotencyKey).orElse(null);
    if (existing != null) {
      return existing;
    }
    String normalizedScope = normalizeScope(scope);
    Instant now = Instant.now(clock);
    AiRetentionJob job = jobs.save(new AiRetentionJob(
        UUID.randomUUID(),
        idempotencyKey,
        normalizedScope,
        redactedUserRef(userRef),
        safeReason(reason),
        now));
    return run(job, null, requestId);
  }

  @Transactional
  public AiRetentionJob runAccountDeletion(UUID userId, String idempotencyKey, String requestId) {
    requireIdempotencyKey(idempotencyKey);
    AiRetentionJob existing = jobs.findByIdempotencyKey(idempotencyKey).orElse(null);
    if (existing != null) {
      return existing;
    }
    Instant now = Instant.now(clock);
    AiRetentionJob job = jobs.save(new AiRetentionJob(
        UUID.randomUUID(),
        idempotencyKey,
        "account_deletion",
        userHashFor(userId),
        "account_deletion",
        now));
    return run(job, userId, requestId);
  }

  @Transactional
  public void attachTtsCacheOwner(String cacheId, UUID userId) {
    if (cacheId == null || cacheId.isBlank() || userId == null) {
      return;
    }
    try {
      UUID parsed = UUID.fromString(cacheId);
      ttsCacheEntries.findById(parsed).ifPresent(entry -> {
        Instant now = Instant.now(clock);
        entry.attachOwner(userHashFor(userId));
        ttsCacheEntries.save(entry);
        attachOwnerRef(parsed, userHashFor(userId), now);
      });
    } catch (IllegalArgumentException ignored) {
      // Non-UUID media ids are legacy/dev results and do not carry persistent cache ownership.
    }
  }

  @Transactional(readOnly = true)
  public AiRetentionJob getJob(String jobId) {
    try {
      return jobs.findById(UUID.fromString(jobId))
          .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "AI retention job was not found."));
    } catch (IllegalArgumentException e) {
      throw new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "AI retention job was not found.");
    }
  }

  public String userHashFor(UUID userId) {
    return "user_sha256:" + sha256(userId == null ? "unknown" : userId.toString()).substring(0, 16);
  }

  private AiRetentionJob run(AiRetentionJob job, UUID userId, String requestId) {
    job.start();
    jobs.save(job);
    try {
      Counts counts = switch (job.getScope()) {
        case "expired_media", "policy_backfill" -> runExpiredMedia();
        case "account_deletion" -> runAccountDeletionScope(userId, job.getUserRef());
        default -> throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Unsupported AI retention scope.");
      };
      job.complete(
          counts.mediaDeletedCount(),
          counts.transcriptDeletedCount(),
          counts.ttsCacheDeletedCount(),
          counts.providerPayloadRedactedCount(),
          Instant.now(clock));
      audit(job, requestId, counts);
      return jobs.save(job);
    } catch (RuntimeException e) {
      job.failRetryable("retention_execution_failed", Instant.now(clock));
      audit(job, requestId, new Counts(0, 0, 0, 0));
      jobs.save(job);
      throw e;
    }
  }

  private Counts runExpiredMedia() {
    Instant now = Instant.now(clock);
    var expiredMedia = mediaAssets.findByDeletedAtIsNullAndExpiresAtBefore(now);
    expiredMedia.forEach(asset -> asset.markDeleted(now));
    mediaAssets.saveAll(expiredMedia);

    var expiredCache = ttsCacheEntries.findByStatusAndExpiresAtBefore("active", now);
    expiredCache.forEach(entry -> entry.markDeleted(now));
    ttsCacheEntries.saveAll(expiredCache);
    expiredCache.forEach(entry -> ttsCacheOwners.deleteByCacheId(entry.getCacheId()));
    return new Counts(expiredMedia.size(), 0, expiredCache.size(), 0);
  }

  private Counts runAccountDeletionScope(UUID userId, String userRef) {
    Instant now = Instant.now(clock);
    String hash = userId == null ? redactedUserRef(userRef) : userHashFor(userId);
    if (hash == null || hash.isBlank()) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "AI account deletion retention requires a redacted user_ref.");
    }

    int mediaCount = 0;
    int transcriptCount = 0;
    if (userId != null) {
      var userMedia = mediaAssets.findByUserIdAndDeletedAtIsNull(userId);
      userMedia.forEach(asset -> asset.markDeleted(now));
      mediaAssets.saveAll(userMedia);
      mediaCount = userMedia.size();
      transcriptCount = countUserTranscriptRefs(userId);
    }

    java.util.Set<UUID> deletedCacheIds = new java.util.HashSet<>();
    for (AiTtsCacheOwner ownerRef : ttsCacheOwners.findByOwnerHash(hash)) {
      UUID cacheId = ownerRef.getCacheId();
      ttsCacheOwners.delete(ownerRef);
      long remainingOwners = ttsCacheOwners.countByCacheId(cacheId);
      ttsCacheEntries.findById(cacheId)
          .ifPresent(entry -> {
            entry.clearOwnerIfMatches(hash);
            if (remainingOwners == 0 && entry.getDeletedAt() == null) {
              entry.markDeleted(now);
              ttsCacheOwners.deleteByCacheId(cacheId);
              deletedCacheIds.add(cacheId);
            }
            ttsCacheEntries.save(entry);
          });
    }

    var legacyOwnedCache = ttsCacheEntries.findByOwnerHashAndDeletedAtIsNull(hash);
    legacyOwnedCache.stream()
        .filter(entry -> !deletedCacheIds.contains(entry.getCacheId()))
        .filter(entry -> ttsCacheOwners.countByCacheId(entry.getCacheId()) == 0)
        .forEach(entry -> {
          entry.markDeleted(now);
          ttsCacheEntries.save(entry);
          ttsCacheOwners.deleteByCacheId(entry.getCacheId());
          deletedCacheIds.add(entry.getCacheId());
        });
    long redactedMetrics = providerMetrics.deleteByUserHash(hash);
    return new Counts(mediaCount, transcriptCount, deletedCacheIds.size(), Math.toIntExact(redactedMetrics));
  }

  private void attachOwnerRef(UUID cacheId, String ownerHash, Instant now) {
    ttsCacheOwners.findByCacheIdAndOwnerHash(cacheId, ownerHash)
        .ifPresentOrElse(
            owner -> {
              owner.markHit(now);
              ttsCacheOwners.save(owner);
            },
            () -> ttsCacheOwners.save(new AiTtsCacheOwner(UUID.randomUUID(), cacheId, ownerHash, now)));
  }

  private int countUserTranscriptRefs(UUID userId) {
    Integer count = jdbcTemplate.queryForObject(
        "SELECT COUNT(*) FROM practice_turns WHERE user_id = ? AND (transcript IS NOT NULL OR audio_ref IS NOT NULL)",
        Integer.class,
        userId);
    return count == null ? 0 : count;
  }

  private void audit(AiRetentionJob job, String requestId, Counts counts) {
    auditLogs.save(new AuditLog(
        UUID.randomUUID(),
        "ops",
        "ai-retention",
        "ai_retention_job_completed",
        "ai_retention:" + job.getJobId(),
        Map.of(
            "scope", job.getScope(),
            "user_ref", job.getUserRef() == null ? "none" : job.getUserRef(),
            "media_deleted_count", counts.mediaDeletedCount(),
            "transcript_deleted_count", counts.transcriptDeletedCount(),
            "tts_cache_deleted_count", counts.ttsCacheDeletedCount(),
            "provider_payload_redacted_count", counts.providerPayloadRedactedCount(),
            "evidence_ref", job.getRedactedEvidenceRef()).toString(),
        requestId,
        Instant.now(clock)));
  }

  private String normalizeScope(String scope) {
    String cleaned = scope == null ? "" : scope.trim();
    if ("expired_media".equals(cleaned) || "account_deletion".equals(cleaned) || "policy_backfill".equals(cleaned)) {
      return cleaned;
    }
    throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Unsupported AI retention scope.");
  }

  private String redactedUserRef(String value) {
    String cleaned = value == null ? "" : value.trim();
    if (cleaned.isBlank()) {
      return null;
    }
    if (cleaned.startsWith("user_sha256:") || cleaned.startsWith("deletion_job:")) {
      return cleaned;
    }
    return "user_ref_sha256:" + sha256(cleaned).substring(0, 16);
  }

  private String safeReason(String value) {
    String cleaned = value == null ? "" : value.trim();
    if (cleaned.isBlank()) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "AI retention reason is required.");
    }
    return cleaned.replaceAll("[\\r\\n\\t]+", " ");
  }

  private void requireIdempotencyKey(String idempotencyKey) {
    if (idempotencyKey == null || idempotencyKey.length() < 8 || idempotencyKey.length() > 128) {
      throw new ApiException(HttpStatus.UNPROCESSABLE_ENTITY, "SCHEMA_VALIDATION_FAILED", "Idempotency-Key is required.");
    }
  }

  private String sha256(String value) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(value.getBytes(StandardCharsets.UTF_8)));
    } catch (Exception e) {
      throw new IllegalStateException("sha256 unavailable", e);
    }
  }

  private record Counts(
      int mediaDeletedCount,
      int transcriptDeletedCount,
      int ttsCacheDeletedCount,
      int providerPayloadRedactedCount) {}
}
