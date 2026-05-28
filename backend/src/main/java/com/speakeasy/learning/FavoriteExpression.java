package com.speakeasy.learning;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "favorite_expressions")
public class FavoriteExpression {
  @Id
  private UUID favoriteId;
  private UUID userId;
  private UUID targetExpressionId;
  private String expressionText;
  private String normalizedText;
  private String sourceType;
  private String sourceId;
  private String status;
  private Instant createdAt;
  private Instant updatedAt;

  protected FavoriteExpression() {}

  public FavoriteExpression(
      UUID favoriteId,
      UUID userId,
      UUID targetExpressionId,
      String expressionText,
      String sourceType,
      String sourceId,
      Instant now) {
    this.favoriteId = favoriteId;
    this.userId = userId;
    this.targetExpressionId = targetExpressionId;
    this.expressionText = expressionText;
    this.normalizedText = normalize(expressionText);
    this.sourceType = sourceType;
    this.sourceId = sourceId;
    this.status = "active";
    this.createdAt = now;
    this.updatedAt = now;
  }

  public void reactivate(String expressionText, String sourceType, String sourceId, Instant now) {
    this.expressionText = expressionText;
    this.normalizedText = normalize(expressionText);
    this.sourceType = sourceType;
    this.sourceId = sourceId;
    this.status = "active";
    this.updatedAt = now;
  }

  public void remove(Instant now) {
    this.status = "removed";
    this.updatedAt = now;
  }

  private String normalize(String value) {
    return value == null ? "" : value.trim().toLowerCase();
  }

  public UUID getFavoriteId() {
    return favoriteId;
  }

  public UUID getUserId() {
    return userId;
  }

  public UUID getTargetExpressionId() {
    return targetExpressionId;
  }

  public String getExpressionText() {
    return expressionText;
  }

  public String getStatus() {
    return status;
  }
}
