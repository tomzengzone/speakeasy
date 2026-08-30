package com.speakeasy;

import static org.assertj.core.api.Assertions.assertThat;

import com.speakeasy.common.ApiException;
import com.speakeasy.identity.AuthService;
import java.util.List;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.postgresql.PostgreSQLContainer;

@SpringBootTest
@AutoConfigureMockMvc
@ActiveProfiles("test")
@Testcontainers(disabledWithoutDocker = true)
class AuthConcurrencyPostgresTest extends BackendIntegrationTestSupport {
  @Container
  static final PostgreSQLContainer postgres = new PostgreSQLContainer("postgres:15")
      .withDatabaseName("speakeasy_auth_test")
      .withUsername("speakeasy")
      .withPassword("speakeasy");

  @DynamicPropertySource
  static void postgresProperties(DynamicPropertyRegistry registry) {
    registry.add("spring.datasource.url", postgres::getJdbcUrl);
    registry.add("spring.datasource.username", postgres::getUsername);
    registry.add("spring.datasource.password", postgres::getPassword);
    registry.add("spring.datasource.driver-class-name", () -> "org.postgresql.Driver");
  }

  @Autowired AuthService authService;

  @Test
  void oneTimeRefreshTokenRemainsSingleUseUnderPostgresRowLocks() throws Exception {
    AuthService.AuthSessionResult login = authService.loginPhone("+8613800138300", "123456", true);
    CountDownLatch start = new CountDownLatch(1);
    var executor = Executors.newFixedThreadPool(2);
    try {
      var first = executor.submit(() -> refreshAfter(start, login.refreshToken()));
      var second = executor.submit(() -> refreshAfter(start, login.refreshToken()));
      start.countDown();

      List<Object> outcomes = List.of(first.get(10, TimeUnit.SECONDS), second.get(10, TimeUnit.SECONDS));
      assertThat(outcomes).filteredOn(AuthService.AuthSessionResult.class::isInstance).hasSize(1);
      assertThat(outcomes).filteredOn("TOKEN_REUSE_DETECTED"::equals).hasSize(1);
      AuthService.AuthSessionResult issued = (AuthService.AuthSessionResult) outcomes.stream()
          .filter(AuthService.AuthSessionResult.class::isInstance).findFirst().orElseThrow();
      assertThat(authService.authenticateAccessToken(issued.accessToken())).isEmpty();
    } finally {
      executor.shutdownNow();
    }
  }

  private Object refreshAfter(CountDownLatch start, String token) throws InterruptedException {
    start.await();
    try {
      return authService.refresh(token);
    } catch (ApiException exception) {
      return exception.getCode();
    }
  }
}
