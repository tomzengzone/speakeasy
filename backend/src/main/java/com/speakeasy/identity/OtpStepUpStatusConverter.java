package com.speakeasy.identity;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class OtpStepUpStatusConverter implements AttributeConverter<OtpStepUpStatus, String> {
  @Override
  public String convertToDatabaseColumn(OtpStepUpStatus attribute) {
    return attribute == null ? null : attribute.value();
  }

  @Override
  public OtpStepUpStatus convertToEntityAttribute(String dbData) {
    return dbData == null ? null : OtpStepUpStatus.fromValue(dbData);
  }
}
