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
import java.util.concurrent.atomic.AtomicReference;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

class WechatIdentityVerifierTest {
  private HttpServer server;
  private final AtomicReference<String> response =
      new AtomicReference<>("{\"openid\":\"wechat-user-123\"}");
  private final AtomicReference<String> query = new AtomicReference<>();

  @BeforeEach
  void startServer() throws IOException {
    server = HttpServer.create(new InetSocketAddress("127.0.0.1", 0), 0);
    server.createContext("/token", this::respond);
    server.start();
  }

  @AfterEach
  void stopServer() {
    server.stop(0);
  }

  @Test
  void exchangesTheAuthorizationCodeAndMapsProviderErrorSemantics() {
    WechatIdentityVerifier verifier = verifier();

    assertThat(verifier.verify("authorization code").subject())
        .isEqualTo("wechat-user-123");
    assertThat(query.get()).contains(
        "appid=wechat-app-id",
        "secret=runtime-secret",
        "code=authorization+code",
        "grant_type=authorization_code");

    response.set("{\"errcode\":40029}");
    assertThatThrownBy(() -> verifier.verify("expired-code"))
        .isInstanceOf(ApiException.class)
        .extracting("code")
        .isEqualTo("UNAUTHENTICATED");

    response.set("{\"errcode\":-1}");
    assertThatThrownBy(() -> verifier.verify("provider-error"))
        .isInstanceOf(ApiException.class)
        .extracting("code")
        .isEqualTo("PROVIDER_UNAVAILABLE");
  }

  private WechatIdentityVerifier verifier() {
    AuthProviderProperties.Wechat properties = new AuthProviderProperties.Wechat();
    properties.setAppId("wechat-app-id");
    properties.setAppSecret("runtime-secret");
    properties.setTokenUrl("http://127.0.0.1:" + server.getAddress().getPort() + "/token");
    return new WechatIdentityVerifier(
        properties, Duration.ofSeconds(2), HttpClient.newHttpClient(), new ObjectMapper());
  }

  private void respond(HttpExchange exchange) throws IOException {
    query.set(exchange.getRequestURI().getRawQuery());
    byte[] bytes = response.get().getBytes(StandardCharsets.UTF_8);
    exchange.getResponseHeaders().set("Content-Type", "application/json");
    exchange.sendResponseHeaders(200, bytes.length);
    exchange.getResponseBody().write(bytes);
    exchange.close();
  }
}
