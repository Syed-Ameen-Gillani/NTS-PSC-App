import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/curriculum/data/course_outline_loader.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_mapping.dart';

void main() {
  test(
    'explicit entitlement and future locks preserve the complete outline',
    () {
      final row = <String, dynamic>{
        'id': 'course',
        'instructor_id': 'teacher',
        'title': 'Course',
        'description': '',
        'price_amount': 2500,
        'status': 'published',
        'is_featured': false,
        'categories': {'name': 'General'},
        'course_modules': [
          {
            'id': 'module',
            'title': 'Module',
            'display_order': 0,
            'lessons': [
              {
                'id': 'current',
                'title': 'Current',
                'display_order': 0,
                'duration_seconds': 60,
                'notes': 'Current reading',
              },
              {
                'id': 'future',
                'title': 'Future',
                'display_order': 1,
                'duration_seconds': 60,
                'notes': 'Stale protected reading',
                'video_path': 'stale/path.mp4',
              },
            ],
          },
        ],
      };
      mergeCourseAccess(
        [row],
        [
          {
            'course_id': 'course',
            'entitled': true,
            'lesson_states': {
              'current': 'available',
              'future': 'prerequisite_required',
            },
          },
        ],
      );
      final course = mapSupabaseCourseRow(row, {});
      expect(course.hasEntitlement, true);
      expect(course.progress, isNull);
      expect(course.priceAmount, 2500);
      expect(course.copyWith(title: 'Updated').priceAmount, 2500);
      expect(course.modules.single.lessons.length, 2);
      expect(course.modules.single.lessons.first.isLocked, false);
      final future = course.modules.single.lessons.last;
      expect(future.isLocked, true);
      expect(future.notes, isEmpty);
      expect(future.videoPath, isEmpty);
    },
  );
  test('missing access state fails closed for a student', () {
    final row = <String, dynamic>{
      'id': 'course',
      'instructor_id': 'teacher',
      'course_modules': [
        {
          'id': 'module',
          'lessons': [
            {'id': 'lesson', 'notes': 'Private'},
          ],
        },
      ],
    };
    mergeCourseAccess([row], [], userId: 'student');
    final lesson = row['course_modules'][0]['lessons'][0];
    expect(lesson['is_locked'], true);
    expect(lesson['notes'], '');
  });
}
