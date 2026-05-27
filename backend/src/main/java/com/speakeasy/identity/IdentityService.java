package com.speakeasy.identity;

import com.speakeasy.common.ApiException;
import com.speakeasy.ops.AccountDeletionJob;
import com.speakeasy.ops.AccountDeletionJobRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class IdentityService {
  private final UserAccountRepository users;
  private final UserProfileRepository profiles;
  private final AccountDeletionJobRepository deletionJobs;
  private final AuthService authService;
  private final Clock clock;

  public IdentityService(
      UserAccountRepository users,
      UserProfileRepository profiles,
      AccountDeletionJobRepository deletionJobs,
      AuthService authService,
      Clock clock) {
    this.users = users;
    this.profiles = profiles;
    this.deletionJobs = deletionJobs;
    this.authService = authService;
    this.clock = clock;
  }

  @Transactional(readOnly = true)
  public UserProfileView getCurrentUser(UUID userId) {
    UserAccount user = requireUser(userId);
    UserProfile profile = profiles.findById(userId).orElse(null);
    return UserProfileView.from(user, profile);
  }

  @Transactional
  public UserProfileView updateCurrentUser(UUID userId, UpdateUserProfileCommand command) {
    Instant now = Instant.now(clock);
    UserAccount user = requireUser(userId);
    user.updateDisplayName(command.displayName(), now);
    UserProfile profile = profiles.findById(userId)
        .orElseGet(() -> profiles.save(new UserProfile(userId, user.getDisplayName(), "L1", 10, now)));
    profile.update(command.targetLevel(), command.dailyMinutes(), command.reminderEnabled(), command.reminderTime(), now);
    return UserProfileView.from(user, profile);
  }

  @Transactional
  public AccountDeletionJob requestAccountDeletion(UUID userId) {
    Instant now = Instant.now(clock);
    UserAccount user = requireUser(userId);
    user.requestDeletion(now);
    authService.revokeUserSessions(userId);
    return deletionJobs.save(new AccountDeletionJob(UUID.randomUUID(), userId, now));
  }

  private UserAccount requireUser(UUID userId) {
    return users.findById(userId)
        .filter(user -> !"deleted".equals(user.getAccountStatus()) && !"disabled".equals(user.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));
  }

  public record UpdateUserProfileCommand(
      String displayName, String targetLevel, Integer dailyMinutes, Boolean reminderEnabled, String reminderTime) {}

  public record UserProfileView(
      UUID userId,
      String displayName,
      String avatarRef,
      String locale,
      String targetLevel,
      Integer dailyMinutes,
      String accountStatus,
      String onboardingStatus) {
    static UserProfileView from(UserAccount user, UserProfile profile) {
      return new UserProfileView(
          user.getUserId(),
          user.getDisplayName(),
          user.getAvatarRef(),
          user.getLocale(),
          profile == null ? null : profile.getTargetLevel(),
          profile == null ? null : profile.getDailyMinutes(),
          user.getAccountStatus(),
          user.getOnboardingStatus());
    }
  }
}
