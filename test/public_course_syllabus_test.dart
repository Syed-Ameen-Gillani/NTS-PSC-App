import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/repositories/public_course_syllabus.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';

Map<String, dynamic> _course(List<Map<String, dynamic>> lessons) => {
  'id': 'course',
  'instructor_id': 'teacher',
  'title': 'Published course',
  'description': 'Saved description',
  'price_amount': 0,
  'image_path': null,
  'status': 'published',
  'is_featured': false,
  'categories': {'name': 'NTS'},
  'course_modules': [
    {'id': 'module', 'title': 'Module', 'display_order': 0, 'lessons': lessons},
  ],
};

Map<String, dynamic> _metadata(String id, int order) => {
  'course_id': 'course',
  'module_id': 'module',
  'lesson_id': id,
  'title': 'Published $id',
  'duration_seconds': 1500,
  'display_order': order,
};

void main() {
  test('full outline restores missing modules with safe typed activities', () {
    final row = _course([]);
    mergePublicCourseSyllabus(
      [row],
      [
        {
          ..._metadata('quiz-lesson', 0),
          'module_id': 'second-module',
          'module_title': 'Assessments',
          'module_order': 1,
          'activities': [
            {
              'id': 'placement',
              'kind': 'quiz',
              'title': 'Practice quiz',
              'display_order': 0,
              'required': true,
            },
          ],
        },
      ],
    );
    final mapped = SupabaseCourseRepository.mapCourseRow(row, {});
    expect(mapped.modules.length, 2);
    final lesson = mapped.modules.last.lessons.single;
    expect(lesson.isLocked, true);
    expect(lesson.activities.single.kind, 'quiz');
    expect(lesson.activities.single.isRequired, true);
    expect(
      lesson.copyWith(isCompleted: true).activities.single.id,
      'placement',
    );
    expect(lesson.notes, isEmpty);
  });

  test(
    'module-only outline keeps empty modules without inventing a lesson',
    () {
      final row = _course([]);
      mergePublicCourseSyllabus(
        [row],
        [
          {
            'course_id': 'course',
            'module_id': 'second',
            'module_title': 'Next module',
            'module_order': 1,
            'lesson_id': null,
          },
        ],
      );
      expect(
        SupabaseCourseRepository.mapCourseRow(row, {}).modules.last.lessons,
        isEmpty,
      );
    },
  );

  test(
    'unenrolled catalog counts actual published lessons without granting playback',
    () {
      final row = _course([]);
      mergePublicCourseSyllabus([row], [_metadata('lesson', 0)]);
      final course = SupabaseCourseRepository.mapCourseRow(row, {});
      expect(course.modules.single.lessons.length, 1);
      final lesson = course.modules.single.lessons.single;
      expect(lesson.title, 'Published lesson');
      expect(lesson.durationMinutes, 25);
      expect(lesson.isLocked, true);
      expect(lesson.videoPath, isEmpty);
      expect(lesson.videoUrl, isEmpty);
      expect(lesson.notes, isEmpty);
    },
  );

  test('enrolled lesson keeps authorized content without duplicates', () {
    final row = _course([
      {
        'id': 'lesson',
        'title': 'Authorized title',
        'duration_seconds': 1500,
        'display_order': 0,
        'video_path': 'private/video.mp4',
        'notes': 'Private notes',
      },
    ]);
    mergePublicCourseSyllabus([row], [_metadata('lesson', 0)]);
    final lessons = SupabaseCourseRepository.mapCourseRow(
      row,
      {},
    ).modules.single.lessons;
    expect(lessons.length, 1);
    expect(lessons.single.isLocked, false);
    expect(lessons.single.videoPath, 'private/video.mp4');
    expect(lessons.single.notes, 'Private notes');
  });

  test('metadata remains scoped to its course/module and ordered', () {
    final row = _course([]);
    mergePublicCourseSyllabus(
      [row],
      [
        _metadata('second', 1),
        _metadata('first', 0),
        {..._metadata('other', 0), 'course_id': 'other-course'},
      ],
    );
    final lessons = SupabaseCourseRepository.mapCourseRow(
      row,
      {},
    ).modules.single.lessons;
    expect(lessons.map((lesson) => lesson.id), ['first', 'second']);
  });

  test('empty syllabus does not invent lessons', () {
    final row = _course([]);
    mergePublicCourseSyllabus([row], []);
    expect(
      SupabaseCourseRepository.mapCourseRow(row, {}).modules.single.lessons,
      isEmpty,
    );
  });
}
