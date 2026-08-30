package com.speakeasy.identity.provider;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.speakeasy.common.ApiException;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.http.HttpClient;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class GatewayPhoneVerificationProviderTest {
  private HttpServer server;
  private final List<CapturedRequest> requests = new CopyOnWriteArrayList<>();
  private final AtomicReference<String> verificationResponse =
      new AtomicReference<>("{\"valid\":true}");

  @BeforeEach
  void startServer() throws IOException {
    server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
    server.createContext("/request", exchange -> respond(exchange, "{}"));
    server.createContext("/verify", exchange -> respond(exchange, verificationResponse.get()));
    server.start();
  }

  @AfterEach
  void stopServer() {
    server.stop(0);
  }

  @Test
  void sendsBearerAuthenticatedJsonAndRejectsAnInvalidCode() {
    GatewayPhoneVerificationProvider provider = provider();

    provider.requestCode("+8613800000000");
    provider.verify("+8613800000000", "123456");

    assertThat(requests).hasSize(2);
    assertThat(requests.get(0).path()).isEqualTo("/request");
    assertThat(requests.get(0).authorization()).isEqualTo("Bearer runtime-secret");
    assertThat(requests.get(0).body()).contains("\"phone_number\":\"+8613800000000\"");
    assertThat(requests.get(0).body()).contains("\"purpose\":\"login\"");
    assertThat(requests.get(1).body()).contains("\"verification_code\":\"123456\"");
    assertThat(requests.get(1).body()).contains("\"purpose\":\"login\"");

    verificationResponse.set("{\"valid\":false}");
    assertThatThrownBy(() -> provider.verify("+8613800000000", "000000"))
        .isInstanceOf(ApiException.class)
        .extracting("code")
        .isEqualTo("UNAUTHENTICATED");
  }

  @Test
  void sendsThePurposeOnRecoveryRequestsAndVerification() {
    GatewayPhoneVerificationProvider provider = provider();

    provider.requestCode(
        "+8613800000001", PhoneVerificationPurpose.ACCOUNT_RECOVERY);
    provider.verify(
        "+8613800000001", "654321", PhoneVerificationPurpose.ACCOUNT_RECOVERY);

    assertThat(requests).hasSize(2);
    assertThat(requests.get(0).body()).contains("\"purpose\":\"account_recovery\"");
    assertThat(requests.get(1).body()).contains("\"purpose\":\"account_recovery\"");
  }

  private GatewayPhoneVerificationProvider provider() {
    AuthProviderProperties.Phone properties = new AuthProviderProperties.Phone();
    String baseUrl = "http://127.0.0.1:" + server.getAddress().getPort();
    properties.setRequestUrl(baseUrl + "/request");
    properties.setVerifyUrl(baseUrl + "/verify");
    properties.setBearerToken("runtime-secret");
    return new GatewayPhoneVerificationProvider(
        properties, Duration.ofSeconds(2), HttpClient.newHttpClient(), new ObjectMapper());
  }

  private void respond(HttpExchange exchange, String responseBody) throws IOException {
    requests.add(new CapturedRequest(
        exchange.getRequestURI().getPath(),
        exchange.getRequestHeaders().getFirst("Authorization"),
        new String(exchange.getRequestBody().readAllBytes(), StandardCharsets.UTF_8)));
    byte[] bytes = responseBody.getBytes(StandardCharsets.UTF_8);
    exchange.getResponseHeaders().set("Content-Type", "application/json");
    exchange.sendResponseHeaders(200, bytes.length);
    exchange.getResponseBody().write(bytes);
    exchange.close();
  }

  private record CapturedRequest(String path, String authorization, String body) {}
}
