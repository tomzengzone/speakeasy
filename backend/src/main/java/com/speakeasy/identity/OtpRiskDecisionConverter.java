package com.speakeasy.identity;

import jakarta.persistence.AttributeConverter;
import jakarta.persistence.Converter;

@Converter
public class OtpRiskDecisionConverter implements AttributeConverter<OtpRiskDecision, String> {
  @Override
  public String convertToDatabaseColumn(OtpRiskDecision attribute) {
    return attribute == null ? null : attribute.value();
  }

  @Override
  public OtpRiskDecision convertToEntityAttribute(String dbData) {
    return dbData == null ? null : OtpRiskDecision.fromValue(dbData);
  }
}
