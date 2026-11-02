import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_mapping.dart';
import 'package:nts_psc_app/features/curriculum/data/course_outline_loader.dart';

void main() {
  test(
    'owner draft changes stay in their course and retain protected content',
    () {
      final row = <String, dynamic>{
        'id': 'course',
        'instructor_id': 'teacher',
        'title': 'Course',
        'description': '',
        'price_amount': 0,
        'status': 'published',
        'is_featured': false,
        'categories': {'name': 'General'},
        'course_modules': [
          {
            'id': 'module',
            'title': 'Published module',
            'display_order': 0,
            'lessons': [
              {
                'id': 'lesson',
                'title': 'Published lesson',
                'display_order': 0,
                'duration_seconds': 120,
                'notes': 'Published reading',
                'video_path': 'private.mp4',
              },
            ],
          },
        ],
      };
      mergeOwnerCurriculumDrafts(
        [row],
        [
          {
            'course_id': 'other-course',
            'module_id': 'module',
            'changes': {'title': 'Wrong module'},
          },
          {
            'course_id': 'course',
            'module_id': 'module',
            'changes': {'title': 'Draft module'},
          },
          {
            'course_id': 'course',
            'lesson_id': 'lesson',
            'changes': {'notes': 'Draft reading'},
          },
        ],
        [
          {
            'lesson_id': 'lesson',
            'activities': [
              {
                'id': 'placement',
                'kind': 'video',
                'title': 'Video',
                'display_order': 0,
                'required': true,
              },
            ],
          },
        ],
      );
      final course = mapSupabaseCourseRow(row, {}, isOwner: true);
      expect(course.modules.single.title, 'Draft module');
      final lesson = course.modules.single.lessons.single;
      expect(lesson.notes, 'Draft reading');
      expect(lesson.videoPath, 'private.mp4');
      expect(lesson.activities.single.id, 'placement');
    },
  );
}
