package com.speakeasy.api;

import com.speakeasy.ai.AiCostMetricsService;
import com.speakeasy.ai.AiRetentionJob;
import com.speakeasy.ai.AiRetentionService;
import com.speakeasy.common.SchemaResponse;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AiOpsController {
  private final AiCostMetricsService costMetricsService;
  private final AiRetentionService retentionService;

  public AiOpsController(AiCostMetricsService costMetricsService, AiRetentionService retentionService) {
    this.costMetricsService = costMetricsService;
    this.retentionService = retentionService;
  }

  @GetMapping("/admin/ai/cost-metrics")
  public AiCostMetricsResponse getAiCostMetrics() {
    AiCostMetricsService.CostMetrics dashboard = costMetricsService.dashboard();
    return new AiCostMetricsResponse(
        dashboard.schemaVersion(),
        dashboard.status(),
        dashboard.metrics().stream().map(AiCostMetricDto::from).toList());
  }

  @PostMapping("/admin/ai/retention-jobs")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public AiRetentionJobResponse createAiRetentionJob(
      @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId,
      @Valid @RequestBody AiRetentionJobCreateRequest request) {
    return AiRetentionJobResponse.from(retentionService.createAndRun(
        request.scope(), request.userRef(), request.reason(), idempotencyKey, requestId));
  }

  @GetMapping("/admin/ai/retention-jobs/{jobId}")
  public AiRetentionJobResponse getAiRetentionJob(@PathVariable String jobId) {
    return AiRetentionJobResponse.from(retentionService.getJob(jobId));
  }

  public record AiCostMetricsResponse(int schemaVersion, String status, List<AiCostMetricDto> metrics) implements SchemaResponse {}

  public record AiCostMetricDto(
      String period,
      String plan,
      String userHash,
      String providerFamily,
      String model,
      String capability,
      String status,
      boolean cacheHit,
      int callCount,
      Integer audioDurationSeconds,
      Integer tokenEstimate,
      BigDecimal estimatedCost,
      String budgetBucket,
      String marginRisk) {
    static AiCostMetricDto from(AiCostMetricsService.CostMetric metric) {
      return new AiCostMetricDto(
          metric.period(),
          metric.plan(),
          metric.userHash(),
          metric.providerFamily(),
          metric.model(),
          metric.capability(),
          metric.status(),
          metric.cacheHit(),
          metric.callCount(),
          metric.audioDurationSeconds(),
          metric.tokenEstimate(),
          metric.estimatedCost(),
          metric.budgetBucket(),
          metric.marginRisk());
    }
  }

  public record AiRetentionJobCreateRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String scope,
      String userRef,
      @NotBlank String reason) {}

  public record AiRetentionJobResponse(int schemaVersion, AiRetentionJobDto job) implements SchemaResponse {
    static AiRetentionJobResponse from(AiRetentionJob job) {
      return new AiRetentionJobResponse(1, AiRetentionJobDto.from(job));
    }
  }

  public record AiRetentionJobDto(
      String jobId,
      String scope,
      String status,
      int mediaDeletedCount,
      int transcriptDeletedCount,
      int ttsCacheDeletedCount,
      int providerPayloadRedactedCount,
      String redactedEvidenceRef,
      String failureReason,
      Instant createdAt,
      Instant completedAt) {
    static AiRetentionJobDto from(AiRetentionJob job) {
      return new AiRetentionJobDto(
          job.getJobId().toString(),
          job.getScope(),
          job.getStatus(),
          job.getMediaDeletedCount(),
          job.getTranscriptDeletedCount(),
          job.getTtsCacheDeletedCount(),
          job.getProviderPayloadRedactedCount(),
          job.getRedactedEvidenceRef(),
          job.getFailureReason(),
          job.getCreatedAt(),
          job.getCompletedAt());
    }
  }
}
