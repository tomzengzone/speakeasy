package com.speakeasy.content;

import java.util.Collection;
import java.util.List;
import java.util.UUID;
import org.springframework.data.jpa.repository.JpaRepository;

public interface CourseContentBindingRepository extends JpaRepository<CourseContentBinding, UUID> {
  List<CourseContentBinding> findByCourseVersionId(UUID courseVersionId);

  List<CourseContentBinding> findByCourseVersionIdIn(Collection<UUID> courseVersionIds);
}
