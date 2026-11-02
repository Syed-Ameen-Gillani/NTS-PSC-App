import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_studio_screen.dart';

void main() {
  testWidgets('published course quiz can be linked to one of its lessons', (
    tester,
  ) async {
    const scope = CurriculumScope(
      courseId: 'course',
      moduleId: 'module',
      lessonId: 'lesson',
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curriculumAssessmentsProvider(scope).overrideWith((ref) async => []),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: TeacherQuizListItem(
                targetScope: scope,
                quiz: QuizModel(
                  id: 'quiz',
                  title: 'Published quiz',
                  category: 'Pakistan Affairs',
                  totalQuestions: 4,
                  courseId: 'course',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Link to Lesson'), findsOneWidget);
  });
}
