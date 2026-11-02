import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves a bounded search page through the same RLS-backed catalog loader.
class SupabaseCourseSearch {
  SupabaseCourseSearch(this._client, this._loadDetails);

  final SupabaseClient _client;
  final Future<List<CourseModel>> Function(List<String> ids) _loadDetails;

  Future<List<CourseModel>> search(
    String query, {
    required int offset,
    int limit = 20,
  }) async {
    final rows =
        await _client.rpc(
              'search_published_courses',
              params: {
                'p_query': query.trim(),
                'p_limit': limit,
                'p_offset': offset,
              },
            )
            as List<dynamic>;
    if (rows.isEmpty) return [];
    final ids = [
      for (final row in rows)
        (row as Map<String, dynamic>)['course_id'] as String,
    ];
    final courses = await _loadDetails(ids);
    final byId = {for (final course in courses) course.id: course};
    return [for (final id in ids) byId[id]].whereType<CourseModel>().toList();
  }
}
