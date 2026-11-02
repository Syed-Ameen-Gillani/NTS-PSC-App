import 'package:nts_psc_app/core/repositories/public_course_syllabus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Loads published metadata in batches and overlays private owner draft values.
class CourseOutlineLoader {
  const CourseOutlineLoader(this.client);
  final SupabaseClient client;
  static const batchSize = 200;

  Future<void> hydrate(List<Map<String, dynamic>> courses) async {
    for (var offset = 0; offset < courses.length; offset += batchSize) {
      final batch = courses.skip(offset).take(batchSize).toList();
      final ids = batch.map((row) => row['id'] as String).toList();
      final outline =
          await client.rpc(
                'get_public_course_outline',
                params: {'p_course_ids': ids},
              )
              as List<dynamic>;
      mergePublicCourseSyllabus(batch, outline.cast<Map<String, dynamic>>());
      final access =
          await client.rpc(
                'get_my_course_access',
                params: {'p_course_ids': ids},
              )
              as List<dynamic>;
      mergeCourseAccess(
        batch,
        access.cast<Map<String, dynamic>>(),
        userId: client.auth.currentUser?.id,
      );
      final ownerIds = batch
          .where((c) => c['instructor_id'] == client.auth.currentUser?.id)
          .map((c) => c['id'] as String)
          .toList();
      if (ownerIds.isEmpty) continue;
      final drafts = await client
          .from('curriculum_draft_changes')
          .select('course_id,module_id,lesson_id,changes')
          .inFilter('course_id', ownerIds);
      final activities =
          await client.rpc(
                'get_teacher_lesson_activity_drafts',
                params: {'p_course_ids': ownerIds},
              )
              as List<dynamic>;
      mergeOwnerCurriculumDrafts(
        batch,
        drafts,
        activities.cast<Map<String, dynamic>>(),
      );
    }
  }
}

void mergeCourseAccess(
  List<Map<String, dynamic>> courses,
  List<Map<String, dynamic>> access, {
  String? userId,
}) {
  final byId = {for (final row in access) row['course_id']: row};
  for (final course in courses) {
    final state = byId[course['id']];
    course['has_entitlement'] = state?['entitled'] == true;
    final lessons = Map<String, dynamic>.from(
      state?['lesson_states'] as Map? ?? {},
    );
    final modules = [
      for (final raw in (course['course_modules'] as List<dynamic>? ?? []))
        Map<String, dynamic>.from(raw as Map),
    ];
    for (final module in modules) {
      final children = [
        for (final raw in (module['lessons'] as List<dynamic>? ?? []))
          Map<String, dynamic>.from(raw as Map),
      ];
      for (final lesson in children) {
        final value =
            lessons[lesson['id']] as String? ??
            (userId != null && course['instructor_id'] == userId
                ? 'preview'
                : 'unavailable');
        lesson['access_state'] = value;
        lesson['is_locked'] = !const [
          'available',
          'completed',
          'preview',
        ].contains(value);
        if (lesson['is_locked'] == true) {
          lesson['notes'] = '';
          lesson['video_path'] = '';
          lesson['external_video_url'] = '';
        }
      }
      module['lessons'] = children;
    }
    course['course_modules'] = modules;
  }
}

/// Pure merge used by the owner preview. Student records never receive drafts.
void mergeOwnerCurriculumDrafts(
  List<Map<String, dynamic>> courses,
  List<Map<String, dynamic>> drafts,
  List<Map<String, dynamic>> activities,
) {
  final lessonActivities = {
    for (final a in activities) a['lesson_id']: a['activities'],
  };
  for (final course in courses) {
    final changes = drafts.where((d) => d['course_id'] == course['id']);
    final modules = [
      for (final raw in (course['course_modules'] as List<dynamic>? ?? []))
        Map<String, dynamic>.from(raw as Map),
    ];
    for (final module in modules) {
      for (final d in changes.where((d) => d['module_id'] == module['id'])) {
        module.addAll(Map<String, dynamic>.from(d['changes'] as Map));
      }
      final lessons = [
        for (final raw in (module['lessons'] as List<dynamic>? ?? []))
          Map<String, dynamic>.from(raw as Map),
      ];
      for (final lesson in lessons) {
        for (final d in changes.where((d) => d['lesson_id'] == lesson['id'])) {
          lesson.addAll(Map<String, dynamic>.from(d['changes'] as Map));
        }
        if (lessonActivities.containsKey(lesson['id'])) {
          lesson['activities'] = lessonActivities[lesson['id']];
        }
      }
      module['lessons'] = lessons;
    }
    course['course_modules'] = modules;
  }
}
