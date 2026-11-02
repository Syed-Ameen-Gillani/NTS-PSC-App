/// Merges public syllabus entries without inventing playback access. Authorized
/// lesson rows keep their private fields; metadata-only entries remain locked.
void mergePublicCourseSyllabus(
  List<Map<String, dynamic>> courses,
  List<Map<String, dynamic>> syllabus,
) {
  for (final course in courses) {
    final modules = (course['course_modules'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .toList();
    for (final entry in syllabus.where((e) => e['course_id'] == course['id'])) {
      final matching = modules.where((m) => m['id'] == entry['module_id']);
      if (matching.isEmpty && entry['module_title'] == null) continue;
      final module = matching.isNotEmpty
          ? matching.first
          : <String, dynamic>{
              'id': entry['module_id'],
              'title': entry['module_title'],
              'display_order': entry['module_order'],
              'lessons': <Map<String, dynamic>>[],
            };
      if (matching.isEmpty) modules.add(module);
      if (entry['lesson_id'] == null) continue;
      final lessons = (module['lessons'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();
      final authorized = lessons.where((l) => l['id'] == entry['lesson_id']);
      if (authorized.isNotEmpty) {
        authorized.first['activities'] = entry['activities'] ?? const [];
      } else {
        lessons.add({
          'id': entry['lesson_id'],
          'title': entry['title'],
          'duration_seconds': entry['duration_seconds'],
          'display_order': entry['display_order'],
          'status': 'published',
          'is_locked': true,
          'video_path': '',
          'external_video_url': '',
          'notes': '',
          'activities': entry['activities'] ?? const [],
        });
      }
      module['lessons'] = lessons;
    }
    course['course_modules'] = modules;
  }
}
