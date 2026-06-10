package com.speakeasy.api;

import com.speakeasy.common.SchemaResponse;
import com.speakeasy.identity.AuthService;
import com.speakeasy.identity.IdentityService;
import com.speakeasy.ops.AccountDeletionService;
import com.speakeasy.security.CurrentUser;
import jakarta.validation.Valid;
import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AuthController {
  private final AuthService authService;
  private final IdentityService identityService;
  private final AccountDeletionService accountDeletionService;

  public AuthController(AuthService authService, IdentityService identityService, AccountDeletionService accountDeletionService) {
    this.authService = authService;
    this.identityService = identityService;
    this.accountDeletionService = accountDeletionService;
  }

  @PostMapping("/auth/login/phone")
  public AuthSessionResponse loginPhone(@Valid @RequestBody PhoneLoginRequest request) {
    return AuthSessionResponse.from(authService.loginPhone(request.phoneNumber(), request.verificationCode(), request.termsAccepted()));
  }

  @PostMapping("/auth/login/apple")
  public AuthSessionResponse loginApple(@Valid @RequestBody SocialLoginRequest request) {
    return AuthSessionResponse.from(authService.loginSocial("apple", request.providerToken(), request.termsAccepted()));
  }

  @PostMapping("/auth/login/wechat")
  public AuthSessionResponse loginWechat(@Valid @RequestBody SocialLoginRequest request) {
    return AuthSessionResponse.from(authService.loginSocial("wechat", request.providerToken(), request.termsAccepted()));
  }

  @PostMapping("/auth/refresh")
  public AuthSessionResponse refresh(@Valid @RequestBody RefreshTokenRequest request) {
    return AuthSessionResponse.from(authService.refresh(request.refreshToken()));
  }

  @PostMapping("/auth/logout")
  @ResponseStatus(HttpStatus.NO_CONTENT)
  public void logout(@AuthenticationPrincipal CurrentUser currentUser) {
    authService.logout(currentUser.sessionId());
  }

  @GetMapping("/user/me")
  public UserProfileResponse getMe(@AuthenticationPrincipal CurrentUser currentUser) {
    return UserProfileResponse.from(identityService.getCurrentUser(currentUser.userId()));
  }

  @PatchMapping("/user/me")
  public UserProfileResponse updateMe(
      @AuthenticationPrincipal CurrentUser currentUser, @Valid @RequestBody UpdateUserProfileRequest request) {
    return UserProfileResponse.from(identityService.updateCurrentUser(currentUser.userId(),
        new IdentityService.UpdateUserProfileCommand(
            request.displayName(), request.targetLevel(), request.dailyMinutes(), request.reminderEnabled(), request.reminderTime())));
  }

  @DeleteMapping("/user/me")
  @ResponseStatus(HttpStatus.ACCEPTED)
  public AccountDeletionJobResponse requestAccountDeletion(
      @AuthenticationPrincipal CurrentUser currentUser,
      @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
      @RequestHeader(value = "X-Request-Id", required = false) String requestId) {
    return AccountDeletionJobResponse.from(
        1, accountDeletionService.requestDeletion(currentUser.userId(), idempotencyKey, requestId));
  }

  @GetMapping("/user/deletion-status")
  public AccountDeletionJobResponse deletionStatus(@AuthenticationPrincipal CurrentUser currentUser) {
    return AccountDeletionJobResponse.from(1, accountDeletionService.latestDeletionJob(currentUser.userId()));
  }

  public record PhoneLoginRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String phoneNumber,
      @NotBlank String verificationCode,
      @NotNull @AssertTrue Boolean termsAccepted) {}

  public record SocialLoginRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      @NotBlank String providerToken,
      String nonce,
      @NotNull @AssertTrue Boolean termsAccepted) {}

  public record RefreshTokenRequest(@NotNull @Min(1) @Max(1) Integer schemaVersion, @NotBlank String refreshToken) {}

  public record UpdateUserProfileRequest(
      @NotNull @Min(1) @Max(1) Integer schemaVersion,
      String displayName,
      String targetLevel,
      @Min(1) Integer dailyMinutes,
      Boolean reminderEnabled,
      @Pattern(regexp = "^([01][0-9]|2[0-3]):[0-5][0-9]$") String reminderTime) {}

  public record AuthSessionResponse(
      int schemaVersion, UserProfileDto user, String accessToken, String refreshToken, Instant expiresAt) implements SchemaResponse {
    static AuthSessionResponse from(AuthService.AuthSessionResult result) {
      return new AuthSessionResponse(
          1,
          UserProfileDto.from(result.user(), result.profile()),
          result.accessToken(),
          result.refreshToken(),
          result.expiresAt());
    }
  }

  public record UserProfileResponse(int schemaVersion, UserProfileDto user) implements SchemaResponse {
    static UserProfileResponse from(IdentityService.UserProfileView user) {
      return new UserProfileResponse(
          1,
          new UserProfileDto(
              user.userId(),
              user.displayName(),
              user.avatarRef(),
              user.locale(),
              user.targetLevel(),
              user.dailyMinutes(),
              user.accountStatus(),
              user.onboardingStatus()));
    }
  }

  public record UserProfileDto(
      UUID userId,
      String displayName,
      String avatarRef,
      String locale,
      String targetLevel,
      Integer dailyMinutes,
      String accountStatus,
      String onboardingStatus) {
    static UserProfileDto from(com.speakeasy.identity.UserAccount user, com.speakeasy.identity.UserProfile profile) {
      return new UserProfileDto(
          user.getUserId(),
          user.getDisplayName(),
          user.getAvatarRef(),
          user.getLocale(),
          profile.getTargetLevel(),
          profile.getDailyMinutes(),
          user.getAccountStatus(),
          user.getOnboardingStatus());
    }
  }

}
