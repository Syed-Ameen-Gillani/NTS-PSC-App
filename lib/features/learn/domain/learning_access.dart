abstract final class LearningAccess {
  static String message(String? state) => switch (state) {
    'prerequisite_required' =>
      'Finish the earlier lessons and assessments first.',
    'access_revoked' => 'Your access to this course is no longer active.',
    'unavailable' => 'This lesson is unavailable.',
    _ => 'Enroll in this course to open its lessons.',
  };
}
