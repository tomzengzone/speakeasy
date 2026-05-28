package com.speakeasy.content;

import com.speakeasy.common.ApiException;
import com.speakeasy.identity.LearningRoute;
import com.speakeasy.identity.LearningRouteRepository;
import com.speakeasy.identity.OnboardingAssessment;
import com.speakeasy.identity.OnboardingAssessmentRepository;
import com.speakeasy.identity.UserAccount;
import com.speakeasy.identity.UserAccountRepository;
import com.speakeasy.identity.UserProfile;
import com.speakeasy.identity.UserProfileRepository;
import com.speakeasy.practice.PracticeSessionRepository;
import java.time.Clock;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.UUID;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class OnboardingContentService {
  private static final List<String> OFFICIAL_SCENARIOS = List.of("job_interview", "onboarding_introduction");
  private static final List<String> UNFINISHED_PRACTICE_STATUSES = List.of("active", "feedback", "recoverable_error");
  private static final Map<String, String> ROUTE_MAP = Map.of(
      "job_interview", "job_interview",
      "onboarding_introduction", "onboarding_introduction",
      "work_communication", "onboarding_introduction");

  private final UserAccountRepository users;
  private final UserProfileRepository profiles;
  private final OnboardingAssessmentRepository assessments;
  private final LearningRouteRepository routes;
  private final ScenarioRepository scenarios;
  private final ScenarioVersionRepository versions;
  private final ScenarioLevelRepository levels;
  private final TargetExpressionRepository expressions;
  private final UserScenarioStateRepository userScenarios;
  private final PracticeSessionRepository practiceSessions;
  private final Clock clock;

  public OnboardingContentService(
      UserAccountRepository users,
      UserProfileRepository profiles,
      OnboardingAssessmentRepository assessments,
      LearningRouteRepository routes,
      ScenarioRepository scenarios,
      ScenarioVersionRepository versions,
      ScenarioLevelRepository levels,
      TargetExpressionRepository expressions,
      UserScenarioStateRepository userScenarios,
      PracticeSessionRepository practiceSessions,
      Clock clock) {
    this.users = users;
    this.profiles = profiles;
    this.assessments = assessments;
    this.routes = routes;
    this.scenarios = scenarios;
    this.versions = versions;
    this.levels = levels;
    this.expressions = expressions;
    this.userScenarios = userScenarios;
    this.practiceSessions = practiceSessions;
    this.clock = clock;
  }

  @Transactional
  public AssessmentResult submitAssessment(
      UUID userId, String goalDirection, List<String> painPoints, String outputLevel, int dailyMinutes) {
    Instant now = Instant.now(clock);
    UserAccount user = requireUser(userId);
    OnboardingAssessment assessment = assessments.save(new OnboardingAssessment(
        UUID.randomUUID(),
        userId,
        goalDirection,
        String.join("|", painPoints),
        outputLevel,
        dailyMinutes,
        now));
    user.completeOnboarding(now);
    profiles.findById(userId)
        .orElseGet(() -> profiles.save(new UserProfile(userId, user.getDisplayName(), outputLevel, dailyMinutes, now)))
        .update(outputLevel, dailyMinutes, null, null, now);

    String scenarioId = ROUTE_MAP.get(goalDirection);
    if (scenarioId == null) {
      return new AssessmentResult(new RouteView(null, outputLevel, List.of()));
    }

    requireOfficialScenario(scenarioId);
    joinScenarioInternal(userId, scenarioId, outputLevel, true, now);
    LearningRoute route = routes.findFirstByUserIdOrderByUpdatedAtDesc(userId)
        .orElseGet(() -> new LearningRoute(UUID.randomUUID(), userId, scenarioId, outputLevel, assessment.getAssessmentId(), now));
    route.updateCurrentScenario(scenarioId, outputLevel, now);
    route.linkAssessment(assessment.getAssessmentId());
    routes.save(route);
    return new AssessmentResult(new RouteView(scenarioId, outputLevel, joinedScenarioIds(userId)));
  }

  @Transactional(readOnly = true)
  public List<ScenarioSummaryView> listScenarios(UUID userId) {
    requireUser(userId);
    return OFFICIAL_SCENARIOS.stream().map(scenarioId -> scenarioSummary(userId, scenarioId)).toList();
  }

  @Transactional(readOnly = true)
  public ScenarioSummaryView getScenario(UUID userId, String scenarioId) {
    requireUser(userId);
    return scenarioSummary(userId, scenarioId);
  }

  @Transactional(readOnly = true)
  public LevelContentView getScenarioLevel(UUID userId, String scenarioId, String levelCode) {
    requireUser(userId);
    ScenarioVersion version = latestPublishedVersion(scenarioId);
    levels.findByScenarioIdAndLevelCode(scenarioId, levelCode)
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Scenario level was not found."));
    List<TargetExpressionView> targetExpressions =
        expressions.findByScenarioVersionIdAndLevelCodeOrderByTextAsc(version.getScenarioVersionId(), levelCode).stream()
            .map(expression -> new TargetExpressionView(
                expression.getTargetExpressionId().toString(),
                expression.getText(),
                expression.getMeaningCn(),
                tags(expression.getTags())))
            .toList();
    return new LevelContentView(scenarioId, levelCode, targetExpressions);
  }

  @Transactional
  public UserScenarioStateResult joinScenario(UUID userId, String scenarioId, String targetLevel, Boolean setCurrent) {
    Instant now = Instant.now(clock);
    requireUser(userId);
    UserScenarioState state = joinScenarioInternal(userId, scenarioId, normalizeLevel(targetLevel), setCurrent == null || setCurrent, now);
    return stateResult(userId, state);
  }

  @Transactional
  public UserScenarioStateResult removeScenario(UUID userId, String scenarioId) {
    Instant now = Instant.now(clock);
    requireUser(userId);
    requireOfficialScenario(scenarioId);
    UserScenarioState state = userScenarios.findByUserIdAndScenarioId(userId, scenarioId)
        .orElseGet(() -> new UserScenarioState(UUID.randomUUID(), userId, scenarioId, "L1", now));
    boolean wasCurrent = state.isCurrent();
    state.remove(now);
    userScenarios.save(state);
    if (wasCurrent) {
      userScenarios.findByUserIdAndState(userId, "joined").stream()
          .filter(candidate -> !candidate.getScenarioId().equals(scenarioId))
          .min(Comparator.comparing(UserScenarioState::getUpdatedAt))
          .ifPresent(candidate -> setOnlyCurrent(userId, candidate, candidate.getTargetLevel(), now));
    }
    return stateResult(userId, state);
  }

  @Transactional
  public UserScenarioStateResult setCurrentScenario(UUID userId, String scenarioId, String targetLevel) {
    Instant now = Instant.now(clock);
    requireUser(userId);
    UserScenarioState state = joinScenarioInternal(userId, scenarioId, normalizeLevel(targetLevel), true, now);
    return stateResult(userId, state);
  }

  @Transactional(readOnly = true)
  public HomeSummaryView homeSummary(UUID userId) {
    UserAccount user = requireUser(userId);
    List<HomeScenarioView> joined = joinedScenarios(userId);
    HomeScenarioView current = joined.stream().filter(HomeScenarioView::current).findFirst().orElse(null);
    HomeNextActionView nextAction;
    if (!"complete".equals(user.getOnboardingStatus())) {
      nextAction = new HomeNextActionView("complete_onboarding", null, null, "完成首评");
    } else if (current == null) {
      nextAction = new HomeNextActionView("choose_scenario", null, null, "选择一个官方场景");
    } else {
      nextAction = new HomeNextActionView("start_practice", current.scenarioId(), current.targetLevel(), "开始当前场景练习");
    }
    String unfinishedSessionStatus = practiceSessions.findFirstByUserIdAndStatusInOrderByUpdatedAtDesc(
            userId, UNFINISHED_PRACTICE_STATUSES)
        .map(session -> "recoverable_error".equals(session.getStatus()) ? "recoverable" : "active")
        .orElse("none");
    return new HomeSummaryView(
        user.getOnboardingStatus(),
        current,
        joined,
        "not_available",
        "not_available",
        unfinishedSessionStatus,
        nextAction);
  }

  private UserScenarioState joinScenarioInternal(
      UUID userId, String scenarioId, String targetLevel, boolean setCurrent, Instant now) {
    requireOfficialScenario(scenarioId);
    UserScenarioState state = userScenarios.findByUserIdAndScenarioId(userId, scenarioId)
        .orElseGet(() -> new UserScenarioState(UUID.randomUUID(), userId, scenarioId, targetLevel, now));
    state.join(targetLevel, now);
    if (setCurrent) {
      setOnlyCurrent(userId, state, targetLevel, now);
    }
    return userScenarios.save(state);
  }

  private void setOnlyCurrent(UUID userId, UserScenarioState currentState, String targetLevel, Instant now) {
    for (UserScenarioState existing : userScenarios.findByUserId(userId)) {
      existing.setCurrent(false, now);
    }
    currentState.changeLevel(targetLevel, now);
    currentState.setCurrent(true, now);
    LearningRoute route = routes.findFirstByUserIdOrderByUpdatedAtDesc(userId)
        .orElseGet(() -> new LearningRoute(UUID.randomUUID(), userId, currentState.getScenarioId(), targetLevel, now));
    route.updateCurrentScenario(currentState.getScenarioId(), targetLevel, now);
    routes.save(route);
  }

  private UserScenarioStateResult stateResult(UUID userId, UserScenarioState state) {
    return new UserScenarioStateResult(
        new UserScenarioStateView(
            state.getScenarioId(),
            state.getState(),
            state.isCurrent(),
            state.getTargetLevel(),
            state.getUpdatedAt()),
        homeSummary(userId));
  }

  private ScenarioSummaryView scenarioSummary(UUID userId, String scenarioId) {
    Scenario scenario = requireOfficialScenario(scenarioId);
    ScenarioVersion version = latestPublishedVersion(scenarioId);
    List<String> levelCodes = levels.findByScenarioIdOrderByLevelCodeAsc(scenarioId).stream()
        .map(ScenarioLevel::getLevelCode)
        .toList();
    Optional<UserScenarioState> state = userScenarios.findByUserIdAndScenarioId(userId, scenarioId)
        .filter(candidate -> "joined".equals(candidate.getState()));
    int expressionCount = levels.findByScenarioIdOrderByLevelCodeAsc(scenarioId).stream()
        .mapToInt(ScenarioLevel::getExpressionCount)
        .sum();
    return new ScenarioSummaryView(
        scenario.getScenarioId(),
        scenario.getTitle(),
        scenario.getSummary(),
        List.of("official"),
        levelCodes,
        scenario.getStatus(),
        true,
        null,
        version.getVersion(),
        expressionCount,
        state.isPresent());
  }

  private List<HomeScenarioView> joinedScenarios(UUID userId) {
    return userScenarios.findByUserIdAndState(userId, "joined").stream()
        .sorted(Comparator.comparing(UserScenarioState::getUpdatedAt))
        .map(state -> {
          Scenario scenario = requireOfficialScenario(state.getScenarioId());
          String version = versions.findFirstByScenarioIdAndContentStatusOrderByPublishedAtDesc(state.getScenarioId(), "published")
              .map(ScenarioVersion::getVersion)
              .orElse(null);
          return new HomeScenarioView(
              state.getScenarioId(), scenario.getTitle(), state.getTargetLevel(), state.isCurrent(), version);
        })
        .toList();
  }

  private List<String> joinedScenarioIds(UUID userId) {
    return userScenarios.findByUserIdAndState(userId, "joined").stream()
        .map(UserScenarioState::getScenarioId)
        .toList();
  }

  private Scenario requireOfficialScenario(String scenarioId) {
    if (!OFFICIAL_SCENARIOS.contains(scenarioId)) {
      throw new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Official scenario was not found.");
    }
    return scenarios.findById(scenarioId)
        .filter(scenario -> "available".equals(scenario.getStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Official scenario was not found."));
  }

  private ScenarioVersion latestPublishedVersion(String scenarioId) {
    return versions.findFirstByScenarioIdAndContentStatusOrderByPublishedAtDesc(scenarioId, "published")
        .orElseThrow(() -> new ApiException(HttpStatus.NOT_FOUND, "RESOURCE_NOT_FOUND", "Published scenario version was not found."));
  }

  private UserAccount requireUser(UUID userId) {
    return users.findById(userId)
        .filter(user -> !"deleted".equals(user.getAccountStatus()) && !"disabled".equals(user.getAccountStatus()))
        .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "UNAUTHENTICATED", "User is not active."));
  }

  private String normalizeLevel(String targetLevel) {
    return targetLevel == null || targetLevel.isBlank() ? "L1" : targetLevel;
  }

  private List<String> tags(String tags) {
    return tags == null || tags.isBlank() ? List.of() : List.of(tags.split(","));
  }

  public record AssessmentResult(RouteView route) {}

  public record RouteView(String currentScenarioId, String targetLevel, List<String> scenarioIds) {}

  public record ScenarioSummaryView(
      String scenarioId,
      String title,
      String summary,
      List<String> tags,
      List<String> levels,
      String status,
      boolean accessAllowed,
      String accessReasonCode,
      String version,
      int expressionCount,
      boolean joined) {}

  public record LevelContentView(String scenarioId, String levelCode, List<TargetExpressionView> targetExpressions) {}

  public record TargetExpressionView(String targetExpressionId, String text, String meaningCn, List<String> tags) {}

  public record UserScenarioStateResult(UserScenarioStateView state, HomeSummaryView homeSummary) {}

  public record UserScenarioStateView(String scenarioId, String state, boolean current, String targetLevel, Instant updatedAt) {}

  public record HomeSummaryView(
      String onboardingStatus,
      HomeScenarioView currentScenario,
      List<HomeScenarioView> joinedScenarios,
      String reviewStatus,
      String weaknessStatus,
      String unfinishedSessionStatus,
      HomeNextActionView nextAction) {}

  public record HomeScenarioView(String scenarioId, String title, String targetLevel, boolean current, String version) {}

  public record HomeNextActionView(String actionType, String scenarioId, String levelCode, String label) {}
}
