import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';

void main() {
  test('maps teacher-owned learner counts by course', () {
    final counts = SupabaseCourseRepository.mapTeacherEnrollmentCounts([
      {'course_id': 'kashmir', 'learner_count': 1},
      {'course_id': 'other', 'learner_count': 0},
    ]);

    expect(counts['kashmir'], 1);
    expect(counts['other'], 0);
  });

  test('maps a published course and ordered curriculum', () {
    final course = SupabaseCourseRepository.mapCourseRow(
      {
        'id': 'course-1',
        'instructor_id': 'teacher-1',
        'title': 'FPSC Preparation',
        'description': 'Exam preparation',
        'price_amount': 0,
        'status': 'published',
        'is_featured': false,
        'image_path': 'https://example.com/course-cover.jpg',
        'categories': {'id': 'category-1', 'name': 'FPSC'},
        'course_modules': [
          {
            'id': 'module-2',
            'title': 'Practice',
            'display_order': 1,
            'lessons': <Map<String, dynamic>>[],
          },
          {
            'id': 'module-1',
            'title': 'Fundamentals',
            'display_order': 0,
            'lessons': [
              {
                'id': 'lesson-2',
                'title': 'Second lesson',
                'duration_seconds': 121,
                'external_video_url': null,
                'notes': '',
                'display_order': 1,
              },
              {
                'id': 'lesson-1',
                'title': 'Introduction',
                'duration_seconds': 60,
                'external_video_url': 'https://example.com/lesson.mp4',
                'notes': 'Read first',
                'display_order': 0,
              },
            ],
          },
        ],
      },
      {'teacher-1': 'Ayesha Khan'},
    );

    expect(course.author, 'Ayesha Khan');
    expect(course.price, 'Free');
    expect(course.isPublished, isTrue);
    expect(course.coverUrl, 'https://example.com/course-cover.jpg');
    expect(course.modules.map((module) => module.title), [
      'Fundamentals',
      'Practice',
    ]);
    expect(course.modules.first.lessons.map((lesson) => lesson.title), [
      'Introduction',
      'Second lesson',
    ]);
    expect(course.modules.first.lessons.last.durationMinutes, 3);
    expect(
      course.modules.first.lessons.first.videoUrl,
      'https://example.com/lesson.mp4',
    );
  });
}
