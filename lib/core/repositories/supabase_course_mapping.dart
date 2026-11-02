import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';

String categoryIconForSlug(String slug) => switch (slug) {
  'fpsc' || 'pakistan-affairs' => 'globe',
  'nts' => 'clipboard',
  'ajk-psc' => 'document',
  _ => 'book',
};

Map<String, int> mapTeacherCounts(List<dynamic> rows) => {
  for (final item in rows)
    (item as Map<String, dynamic>)['course_id'] as String:
        ((item['learner_count'] as num?) ?? 0).toInt(),
};

/// Maps the catalog projection after the public syllabus metadata is merged.
CourseModel mapSupabaseCourseRow(
  Map<String, dynamic> row,
  Map<String, String> names, {
  bool isOwner = false,
}) {
  final modules =
      (row['course_modules'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
        ..sort(
          (a, b) =>
              (a['display_order'] as int).compareTo(b['display_order'] as int),
        );
  return CourseModel(
    id: row['id'] as String,
    title: row['title'] as String,
    author: names[row['instructor_id']] ?? 'Instructor',
    rating: 0,
    price: (row['price_amount'] as int) == 0
        ? 'Free'
        : 'Rs ${row['price_amount']}',
    priceAmount: row['price_amount'] as int,
    currency: row['currency'] as String? ?? 'PKR',
    hasEntitlement: row['has_entitlement'] == true,
    imagePath: AppAssets.course1,
    coverUrl: isOwner
        ? (row['pending_image_path'] as String?) ?? row['image_path'] as String?
        : row['image_path'] as String?,
    isFeatured: row['is_featured'] as bool,
    description: row['description'] as String,
    instructorId: row['instructor_id'] as String,
    category: (row['categories'] as Map<String, dynamic>)['name'] as String,
    enrolledCount: 0,
    isPublished: row['status'] == 'published',
    modules: modules.map((module) {
      final lessons =
          (module['lessons'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()
            ..sort(
              (a, b) => (a['display_order'] as int).compareTo(
                b['display_order'] as int,
              ),
            );
      return CourseModuleModel(
        id: module['id'] as String,
        title: module['title'] as String,
        lessons: lessons
            .map(
              (lesson) => LessonModel(
                id: lesson['id'] as String,
                title: lesson['title'] as String,
                durationMinutes: ((lesson['duration_seconds'] as int) / 60)
                    .ceil(),
                videoUrl: lesson['external_video_url'] as String? ?? '',
                videoPath: lesson['video_path'] as String? ?? '',
                isLocked: lesson['is_locked'] as bool? ?? false,
                accessState: lesson['access_state'] as String?,
                notes: lesson['notes'] as String? ?? '',
                activities: List.unmodifiable(
                  (lesson['activities'] as List<dynamic>? ?? const []).map(
                    (item) => LessonActivity.fromRow(
                      Map<String, dynamic>.from(item as Map),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      );
    }).toList(),
  );
}
