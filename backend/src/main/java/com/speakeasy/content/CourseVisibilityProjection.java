package com.speakeasy.content;

import com.speakeasy.commerce.EntitlementGateService;
import java.util.UUID;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Component
class CourseVisibilityProjection {
  private final EntitlementGateService entitlementGateService;

  CourseVisibilityProjection(EntitlementGateService entitlementGateService) {
    this.entitlementGateService = entitlementGateService;
  }

  @Transactional(propagation = Propagation.NOT_SUPPORTED)
  VisibilityContext current(UUID userId) {
    try {
      return new VisibilityContext(entitlementGateService.contentVisibility(userId));
    } catch (RuntimeException exception) {
      throw new CourseVisibilityDependencyException(exception);
    }
  }

  record VisibilityContext(EntitlementGateService.ContentVisibilityDecision decision) {
    String revision() {
      return decision.visibilityRevision();
    }

    boolean isThemeVisible(String scenarioId) {
      return visible(decision.theme(scenarioId));
    }

    boolean isCourseVisible(String scenarioId, String cefrLevel) {
      return visible(decision.course(scenarioId, cefrLevel));
    }

    private boolean visible(EntitlementGateService.ContentVisibilityOutcome outcome) {
      return switch (outcome) {
        case ALLOW -> true;
        case DENY -> false;
        case DEPENDENCY_UNAVAILABLE -> throw new CourseVisibilityDependencyException();
      };
    }
  }

  static final class CourseVisibilityDependencyException extends RuntimeException {
    CourseVisibilityDependencyException() {
      super("Course visibility dependency was unavailable.");
    }

    CourseVisibilityDependencyException(Throwable cause) {
      super("Course visibility dependency was unavailable.", cause);
    }
  }
}
