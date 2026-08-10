package com.speakeasy.content;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "content_course_version")
public class CourseVersion {
  @Id
  @Column(name = "course_version_id", nullable = false)
  private UUID courseVersionId;

  @Column(name = "course_id", nullable = false)
  private UUID courseId;

  @Column(name = "version_key", nullable = false)
  private String versionKey;

  @Column(name = "title_en", nullable = false)
  private String titleEn;

  @Column(name = "summary_zh", nullable = false)
  private String summaryZh;

  @Column(name = "cefr_level", nullable = false)
  private String cefrLevel;

  @Column(name = "duration_value", nullable = false)
  private BigDecimal durationValue;

  @Column(name = "duration_unit", nullable = false)
  private String durationUnit;

  @Column(name = "background_asset_ref")
  private String backgroundAssetRef;

  @Column(name = "publication_status", nullable = false)
  private String publicationStatus;

  @Column(name = "published_at")
  private Instant publishedAt;

  @Column(name = "superseded_at")
  private Instant supersededAt;

  @Column(name = "created_at", nullable = false)
  private Instant createdAt;

  @Column(name = "updated_at", nullable = false)
  private Instant updatedAt;

  protected CourseVersion() {}

  public UUID getCourseVersionId() {
    return courseVersionId;
  }

  public UUID getCourseId() {
    return courseId;
  }

  public String getVersionKey() {
    return versionKey;
  }

  public String getTitleEn() {
    return titleEn;
  }

  public String getSummaryZh() {
    return summaryZh;
  }

  public String getCefrLevel() {
    return cefrLevel;
  }

  public BigDecimal getDurationValue() {
    return durationValue;
  }

  public String getDurationUnit() {
    return durationUnit;
  }

  public String getBackgroundAssetRef() {
    return backgroundAssetRef;
  }

  public String getPublicationStatus() {
    return publicationStatus;
  }

  public Instant getPublishedAt() {
    return publishedAt;
  }

  public Instant getSupersededAt() {
    return supersededAt;
  }

  public Instant getCreatedAt() {
    return createdAt;
  }

  public Instant getUpdatedAt() {
    return updatedAt;
  }
}
