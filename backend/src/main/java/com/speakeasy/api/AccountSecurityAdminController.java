package com.speakeasy.api;

import com.speakeasy.common.SchemaResponse;
import com.speakeasy.identity.AccountSecurityService;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.security.Principal;
import java.util.UUID;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AccountSecurityAdminController {
  private final AccountSecurityService accountSecurity;

  public AccountSecurityAdminController(AccountSecurityService accountSecurity) {
    this.accountSecurity = accountSecurity;
  }

  @PostMapping("/admin/users/{userId}/disable")
  public AccountStatusResponse disable(
      Principal principal,
      @PathVariable UUID userId,
      @Valid @RequestBody AccountStatusRequest request,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId) {
    return AccountStatusResponse.from(accountSecurity.disableAccount(
        userId, principal.getName(), request.reasonCode(), request.caseReference(), requestId));
  }

  @PostMapping("/admin/users/{userId}/enable")
  public AccountStatusResponse enable(
      Principal principal,
      @PathVariable UUID userId,
      @Valid @RequestBody AccountStatusRequest request,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId) {
    return AccountStatusResponse.from(accountSecurity.enableAccount(
        userId, principal.getName(), request.reasonCode(), request.caseReference(), requestId));
  }

  public record AccountStatusRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank @Pattern(regexp = "^[a-z0-9]+(?:_[a-z0-9]+)*$") String reasonCode,
      @Pattern(regexp = "^[A-Za-z0-9_.:-]{1,120}$") String caseReference) {}

  public record AccountStatusResponse(
      int schemaVersion, UUID userId, String accountStatus, int revokedSessionCount) implements SchemaResponse {
    static AccountStatusResponse from(AccountSecurityService.AccountStatusChange result) {
      return new AccountStatusResponse(
          1, result.userId(), result.accountStatus(), result.revokedSessionCount());
    }
  }
}
