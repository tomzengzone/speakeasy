package com.speakeasy.ai;

import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class AiMediaStorageConfiguration {
  @Bean
  @ConditionalOnProperty(prefix = "speakeasy.ai.media", name = "storage-provider", havingValue = "aliyun-oss")
  AiMediaStorageService aliyunOssMediaStorageService(AiMediaProperties properties) {
    return new AliyunOssMediaStorageService(properties);
  }

  @Bean
  @ConditionalOnMissingBean(AiMediaStorageService.class)
  AiMediaStorageService localMediaStorageService(AiMediaProperties properties) {
    return new LocalAiMediaStorageService(properties);
  }
}
