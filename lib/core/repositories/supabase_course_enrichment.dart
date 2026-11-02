import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Adds public cover URLs and verified learner counts to catalog records.
class SupabaseCourseEnrichment {
  SupabaseCourseEnrichment(this._client);

  final SupabaseClient _client;

  Future<List<CourseModel>> enrich(List<CourseModel> courses) async {
    final publishedIds = [
      for (final course in courses)
        if (course.isPublished) course.id,
    ];
    final counts = <String, int>{};
    final ratings = <String, double>{};
    const batchSize = 200;
    for (var offset = 0; offset < publishedIds.length; offset += batchSize) {
      final ids = publishedIds.skip(offset).take(batchSize).toList();
      final rows =
          await _client.rpc(
                'get_public_course_learner_counts',
                params: {'p_course_ids': ids},
              )
              as List<dynamic>;
      final reviewRows =
          await _client.rpc(
                'get_public_course_ratings',
                params: {'p_course_ids': ids},
              )
              as List;
      for (final row in reviewRows.cast<Map>()) {
        ratings[row['course_id'] as String] = (row['rating'] as num).toDouble();
      }
      for (final row in rows) {
        final data = row as Map<String, dynamic>;
        counts[data['course_id'] as String] = (data['learner_count'] as num)
            .toInt();
      }
    }
    return courses.map((course) {
      final path = course.coverUrl;
      final cover = path == null || path.isEmpty || path.startsWith('https://')
          ? path
          : _client.storage.from('course-thumbnails').getPublicUrl(path);
      return course.copyWith(
        coverUrl: cover,
        rating: ratings[course.id] ?? 0,
        enrolledCount: course.isPublished ? counts[course.id] ?? 0 : 0,
      );
    }).toList();
  }
}
