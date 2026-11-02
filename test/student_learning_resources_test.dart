import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/curriculum/presentation/student_learning_resources.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_access_provider.dart';

void main() {
  for (final hasWork in [false, true]) {
    testWidgets('lesson resources are video-free; combined empty=$hasWork', (tester) async {
      const scope = CurriculumScope(courseId: 'course', moduleId: 'module', lessonId: 'lesson');
      await tester.pumpWidget(ProviderScope(overrides: [
        curriculumMaterialsProvider(scope).overrideWith((ref) async => []),
        curriculumAssessmentsProvider(scope).overrideWith((ref) async => hasWork ? [
          const CurriculumAssessment(id: 'link', assessmentId: 'quiz', title: 'Lesson quiz', kind: 'quiz', status: 'published'),
          const CurriculumAssessment(id: 'draft', assessmentId: 'draft-quiz', title: 'Hidden draft', kind: 'quiz', status: 'draft'),
        ] : []),
        lessonAccessCourseProvider('course').overrideWith((ref) async => CourseModel(id: 'course', title: 'Course', author: 'Teacher',
          rating: 0, price: 'Free', imagePath: '', modules: [CourseModuleModel(id: 'module', title: 'Module', lessons: [
            LessonModel(id: 'lesson', title: 'Lesson', durationMinutes: 10, videoPath: 'private/video.mp4'),
          ])])),
      ], child: ScreenUtilInit(designSize: const Size(390, 844), builder: (_, _) => const MaterialApp(home: Scaffold(body:
        StudentLearningResources(details: CurriculumContext(scope: scope, title: 'Lesson', courseTitle: 'Course', canManage: false)))))));
      await tester.pumpAndSettle();
      expect(find.text('Hidden draft'), findsNothing);
      expect(find.text('Materials'), findsNothing);
      expect(find.text('Lesson quiz'), hasWork ? findsOneWidget : findsNothing);
      expect(find.text('No materials or assessments yet'), hasWork ? findsNothing : findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
      if (!hasWork) {
        final center = tester.getCenter(find.text('No materials or assessments yet'));
        expect(center.dy, greaterThan(200));
      }
      expect(tester.takeException(), isNull);
    });
  }
}

