package com.speakeasy;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.jayway.jsonpath.JsonPath;
import com.speakeasy.ai.AiTtsCacheEntry;
import com.speakeasy.ai.AiTtsCacheService;
import com.speakeasy.ai.DashScopeHttpTransport;
import java.time.Duration;
import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.test.web.servlet.MvcResult;

@SpringBootTest(
    properties = {
      "speakeasy.ai.provider=dashscope",
      "speakeasy.ai.dashscope.api-key=test-secret",
      "speakeasy.ai.dashscope.tts-url=https://dashscope.test/tts",
      "speakeasy.ai.dashscope.tts-model=qwen3-tts-test",
      "speakeasy.ai.dashscope.tts-voice=Cherry",
      "speakeasy.ai.media.tts-cache-ttl=7d"
    })
@AutoConfigureMockMvc
@ActiveProfiles("test")
class PersistentTtsCacheTest extends BackendIntegrationTestSupport {
  @Autowired RecordingDashScopeTransport dashScopeTransport;
  @Autowired AiTtsCacheService ttsCacheService;

  @BeforeEach
  void resetTransport() {
    dashScopeTransport.reset();
  }

  @Test
  void ttsCachePersistsAcrossProviderCallsAndReturnsSameMediaRef() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138420");

    MvcResult first = synthesize(tokens, "Could you tell me about yourself?")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"))
        .andExpect(jsonPath("$.cache_status").value("miss"))
        .andExpect(jsonPath("$.media_id").exists())
        .andReturn();

    String firstAudioRef = JsonPath.read(first.getResponse().getContentAsString(), "$.audio_ref");
    String mediaId = JsonPath.read(first.getResponse().getContentAsString(), "$.media_id");

    MvcResult second = synthesize(tokens, "Could you tell me about yourself?")
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"))
        .andExpect(jsonPath("$.cache_status").value("hit"))
        .andExpect(jsonPath("$.media_id").value(mediaId))
        .andReturn();

    String secondAudioRef = JsonPath.read(second.getResponse().getContentAsString(), "$.audio_ref");
    org.assertj.core.api.Assertions.assertThat(secondAudioRef).isEqualTo(firstAudioRef);
    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.ttsCalls).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(ttsCacheEntries.findAll())
        .singleElement()
        .satisfies(entry -> {
          org.assertj.core.api.Assertions.assertThat(entry.getStatus()).isEqualTo("active");
          org.assertj.core.api.Assertions.assertThat(entry.getHitCount()).isEqualTo(1);
          org.assertj.core.api.Assertions.assertThat(entry.getNormalizedTextHash()).isNotBlank();
        });
  }

  @Test
  void expiredCacheEntryIsRefreshedInsteadOfReused() throws Exception {
    AuthTokens tokens = loginPhone("+8613800138421");
    String text = "Welcome to the team.";
    String cacheKey = ttsCacheService.cacheKey(text, "Cherry", "English");
    ttsCacheEntries.save(new AiTtsCacheEntry(
        UUID.randomUUID(),
        cacheKey,
        "old-text-hash",
        "qwen3-tts-test",
        "Cherry",
        "English",
        "https://media.example.com/old-tts.wav",
        Instant.now().minusSeconds(10),
        Instant.now().minusSeconds(3600)));

    synthesize(tokens, text)
        .andExpect(status().isOk())
        .andExpect(jsonPath("$.status").value("available"))
        .andExpect(jsonPath("$.cache_status").value("miss"))
        .andExpect(jsonPath("$.audio_ref").value("https://media.example.com/tts-1.wav"));

    org.assertj.core.api.Assertions.assertThat(dashScopeTransport.ttsCalls).isEqualTo(1);
    org.assertj.core.api.Assertions.assertThat(ttsCacheEntries.findByCacheKey(cacheKey))
        .isPresent()
        .get()
        .satisfies(entry -> {
          org.assertj.core.api.Assertions.assertThat(entry.getStatus()).isEqualTo("active");
          org.assertj.core.api.Assertions.assertThat(entry.getAudioRef()).isEqualTo("https://media.example.com/tts-1.wav");
          org.assertj.core.api.Assertions.assertThat(entry.getExpiresAt()).isAfter(Instant.now());
        });
  }

  private org.springframework.test.web.servlet.ResultActions synthesize(AuthTokens tokens, String text) throws Exception {
    return mvc.perform(post("/ai/tts")
        .header(HttpHeaders.AUTHORIZATION, bearer(tokens.accessToken()))
        .contentType(MediaType.APPLICATION_JSON)
        .content("""
            {
              "schema_version": 1,
              "text": "%s",
              "voice": "Cherry"
            }
            """.formatted(text)));
  }

  @TestConfiguration
  static class PersistentTtsCacheTestConfig {
    @Bean
    @Primary
    RecordingDashScopeTransport recordingDashScopeTransport(ObjectMapper mapper) {
      return new RecordingDashScopeTransport(mapper);
    }
  }

  static class RecordingDashScopeTransport implements DashScopeHttpTransport {
    private final ObjectMapper mapper;
    private int ttsCalls;

    RecordingDashScopeTransport(ObjectMapper mapper) {
      this.mapper = mapper;
    }

    void reset() {
      ttsCalls = 0;
    }

    @Override
    public JsonNode postJson(String url, JsonNode body, Map<String, String> headers, Duration timeout) {
      try {
        if (url.contains("/tts")) {
          ttsCalls += 1;
          return mapper.readTree("{\"output\":{\"audio\":{\"url\":\"https://media.example.com/tts-%d.wav\"}}}"
              .formatted(ttsCalls));
        }
        return mapper.readTree("{}");
      } catch (Exception e) {
        throw new RuntimeException(e);
      }
    }

    @Override
    public JsonNode getJson(String url, Map<String, String> headers, Duration timeout) {
      throw new UnsupportedOperationException("not used");
    }
  }
}
