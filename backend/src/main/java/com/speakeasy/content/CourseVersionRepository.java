package com.speakeasy.content;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CourseVersionRepository extends JpaRepository<CourseVersion, UUID> {
  List<CourseVersion> findByCourseIdInAndPublicationStatus(
      Collection<UUID> courseIds, String publicationStatus);
}
