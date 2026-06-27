package com.speakeasy.api;

import com.speakeasy.common.SchemaResponse;
import com.speakeasy.ops.AuditLogService;
import java.time.Instant;
import java.util.List;
import java.util.Map;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AdminAuditController {
  private final AuditLogService auditLogService;

  public AdminAuditController(AuditLogService auditLogService) {
    this.auditLogService = auditLogService;
  }

  @GetMapping("/admin/audit")
  public AuditEventListResponse listAuditEvents(
      @RequestParam(value = "limit", required = false) Integer limit,
      @RequestParam(value = "cursor", required = false) String cursor,
      @RequestParam(value = "event_type", required = false) String eventType,
      @RequestParam(value = "actor_type", required = false) String actorType,
      @RequestParam(value = "target_ref", required = false) String targetRef,
      @RequestParam(value = "created_after", required = false) String createdAfter,
      @RequestParam(value = "created_before", required = false) String createdBefore,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId) {
    AuditLogService.AuditEventPage page = auditLogService.listAuditEvents(
        AuditLogService.AuditQuery.fromRaw(
            limit, cursor, eventType, actorType, targetRef, createdAfter, createdBefore),
        requestId);
    return new AuditEventListResponse(
        page.schemaVersion(),
        page.limit(),
        page.nextCursor(),
        page.events().stream().map(AuditEventDto::from).toList());
  }

  public record AuditEventListResponse(int schemaVersion, int limit, String nextCursor, List<AuditEventDto> events)
      implements SchemaResponse {}

  public record AuditEventDto(
      String auditLogId,
      String actorType,
      String eventType,
      String targetRef,
      String requestId,
      Map<String, Object> redactedDetails,
      Instant createdAt) {
    static AuditEventDto from(AuditLogService.AuditEventView event) {
      return new AuditEventDto(
          event.auditLogId(),
          event.actorType(),
          event.eventType(),
          event.targetRef(),
          event.requestId(),
          event.redactedDetails(),
          event.createdAt());
    }
  }
}
