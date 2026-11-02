import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';

/// A position in the published course outline; it grants no extra access.
class LessonNavigationItem {
  const LessonNavigationItem({
    required this.moduleId,
    required this.lesson,
    this.activity,
  });

  final String moduleId;
  final LessonModel lesson;
  final LessonActivity? activity;

  String get key => '${lesson.id}:${activity?.id ?? 'lesson'}';
  bool get isVideo =>
      activity?.kind == 'video' ||
      (activity == null &&
          (lesson.videoPath.isNotEmpty || lesson.videoUrl.isNotEmpty));

  static List<LessonNavigationItem> fromCourse(CourseModel course) => [
    for (final module in course.modules)
      for (final lesson in module.lessons) ..._lessonItems(module.id, lesson),
  ];

  static List<LessonNavigationItem> _lessonItems(
    String moduleId,
    LessonModel lesson,
  ) {
    final activities = [...lesson.activities];
    // Preserve source order when two activities have the same configured order.
    final indexed = activities.asMap().entries.toList()
      ..sort((a, b) {
        final order = a.value.order.compareTo(b.value.order);
        return order == 0 ? a.key.compareTo(b.key) : order;
      });
    return indexed.isEmpty
        ? [LessonNavigationItem(moduleId: moduleId, lesson: lesson)]
        : [
            for (final entry in indexed)
              LessonNavigationItem(
                moduleId: moduleId,
                lesson: lesson,
                activity: entry.value,
              ),
          ];
  }
}
