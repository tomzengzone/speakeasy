package com.speakeasy.identity;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class OtpChallengeStatusConverter implements AttributeConverter<OtpChallengeStatus, String> {
  @Override
  public String convertToDatabaseColumn(OtpChallengeStatus attribute) {
    return attribute == null ? null : attribute.value();
  }

  @Override
  public OtpChallengeStatus convertToEntityAttribute(String dbData) {
    return dbData == null ? null : OtpChallengeStatus.fromValue(dbData);
  }
}
