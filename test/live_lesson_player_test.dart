import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/live_lesson_player_screen.dart';

void main() {
  testWidgets('live lesson uses stored notes and completion state', (
    tester,
  ) async {
    final course = CourseModel(
      id: 'course-1',
      title: 'FPSC Preparation',
      author: 'Instructor',
      rating: 0,
      price: 'Free',
      imagePath: '',
      modules: [
        CourseModuleModel(
          id: 'module-1',
          title: 'Foundation',
          lessons: [
            LessonModel(
              id: 'lesson-1',
              title: 'Introduction',
              durationMinutes: 12,
              notes: 'Read the syllabus first.',
              isCompleted: true,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) =>
              MaterialApp(home: LiveLessonPlayerScreen(course: course)),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Introduction'), findsWidgets);
    expect(find.text('Read the syllabus first.'), findsOneWidget);
    expect(find.text('No video attached'), findsNothing);
    expect(find.text('Lesson completed'), findsOneWidget);
    expect(
      find.text('Module 1: Constitutional & Administrative Framework'),
      findsNothing,
    );
  });
}

