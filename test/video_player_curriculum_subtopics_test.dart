import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_subtopic.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/live_lesson_module_group.dart';

Widget _testApp(Widget child) => ProviderScope(
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, _) => MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );

void main() {
  group('LessonSubTopic domain tests', () {
    test('maps LessonActivity of quiz, assignment, and material correctly', () {
      final quizActivity = const LessonActivity(
        id: 'a_quiz',
        kind: 'quiz',
        title: 'Weekly Quiz 1',
        order: 1,
        isRequired: true,
      );
      final assignmentActivity = const LessonActivity(
        id: 'a_assign',
        kind: 'assignment',
        title: 'Research Assignment',
        order: 2,
        isRequired: false,
      );
      final handoutActivity = const LessonActivity(
        id: 'a_mat',
        kind: 'material',
        title: 'Summary Handout',
        order: 3,
        isRequired: false,
      );
      final videoActivity = const LessonActivity(
        id: 'a_vid',
        kind: 'video',
        title: 'Video',
        order: 4,
        isRequired: true,
      );

      final quizSub = LessonSubTopic.fromActivity(quizActivity);
      final assignSub = LessonSubTopic.fromActivity(assignmentActivity);
      final handoutSub = LessonSubTopic.fromActivity(handoutActivity);
      final videoSub = LessonSubTopic.fromActivity(videoActivity);

      expect(quizSub, isNotNull);
      expect(quizSub!.kind, LessonSubTopicKind.quiz);
      expect(quizSub.kindLabel, 'Quiz');
      expect(quizSub.title, 'Weekly Quiz 1');
      expect(quizSub.isRequired, true);
      expect(quizSub.icon, Icons.quiz_outlined);

      expect(assignSub, isNotNull);
      expect(assignSub!.kind, LessonSubTopicKind.assignment);
      expect(assignSub.kindLabel, 'Assignment');
      expect(assignSub.title, 'Research Assignment');
      expect(assignSub.isRequired, false);
      expect(assignSub.icon, Icons.assignment_outlined);

      expect(handoutSub, isNotNull);
      expect(handoutSub!.kind, LessonSubTopicKind.handout);
      expect(handoutSub.kindLabel, 'Handout');
      expect(handoutSub.title, 'Summary Handout');
      expect(handoutSub.icon, Icons.description_outlined);

      // Video activity is the main lesson, not a subtopic
      expect(videoSub, isNull);
    });

    test('maps CurriculumAssessment and CurriculumMaterial to LessonSubTopic', () {
      final assessment = const CurriculumAssessment(
        id: 'link_1',
        assessmentId: 'quiz_123',
        title: 'Chapter Assessment',
        kind: 'quiz',
        status: 'published',
      );
      final material = const CurriculumMaterial(
        id: 'mat_1',
        title: 'Constitutional Charter PDF',
        path: 'materials/charter.pdf',
        sizeBytes: 1024,
      );

      final assessSub = LessonSubTopic.fromAssessment(assessment);
      final matSub = LessonSubTopic.fromMaterial(material);

      expect(assessSub.assessmentId, 'quiz_123');
      expect(assessSub.title, 'Chapter Assessment');
      expect(assessSub.kind, LessonSubTopicKind.quiz);

      expect(matSub.materialId, 'mat_1');
      expect(matSub.materialPath, 'materials/charter.pdf');
      expect(matSub.title, 'Constitutional Charter PDF');
      expect(matSub.kind, LessonSubTopicKind.handout);
    });
  });

  group('LiveLessonModuleGroup sub-topics widget tests', () {
    testWidgets('renders subtopics under lesson row on video player screen',
        (tester) async {
      final lessonWithSubTopics = LessonModel(
        id: 'lesson_101',
        title: 'Constitutional Guarantees',
        durationMinutes: 25,
        videoPath: 'courses/c1/v1.mp4',
        activities: const [
          LessonActivity(
            id: 'act_quiz_1',
            kind: 'quiz',
            title: 'Fundamental Rights Quiz',
            order: 1,
            isRequired: true,
          ),
          LessonActivity(
            id: 'act_handout_1',
            kind: 'material',
            title: 'Articles 1-28 Reference Handout',
            order: 2,
            isRequired: false,
          ),
          LessonActivity(
            id: 'act_assign_1',
            kind: 'assignment',
            title: 'Case Summary Submission',
            order: 3,
            isRequired: false,
          ),
        ],
      );

      final module = CourseModuleModel(
        id: 'mod_1',
        title: 'Module 1: Basic Rights',
        lessons: [lessonWithSubTopics],
      );

      await tester.pumpWidget(
        _testApp(
          LiveLessonModuleGroup(
            courseId: 'c1',
            module: module,
            moduleNumber: 1,
            currentLesson: lessonWithSubTopics,
            completedLessonIds: const {},
            onSelectLesson: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Lesson row title and duration
      expect(find.text('1.1 Constitutional Guarantees'), findsOneWidget);
      expect(find.text('25 min'), findsOneWidget);

      // Sub-topics under the lesson
      expect(find.text('Fundamental Rights Quiz'), findsOneWidget);
      expect(find.text('Quiz'), findsOneWidget);
      expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);

      expect(find.text('Articles 1-28 Reference Handout'), findsOneWidget);
      expect(find.text('Handout'), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);

      expect(find.text('Case Summary Submission'), findsOneWidget);
      expect(find.text('Assignment'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
    });

    testWidgets('lesson without subtopics renders cleanly without subtopic rows',
        (tester) async {
      final lessonClean = LessonModel(
        id: 'lesson_102',
        title: 'Introductory Lecture',
        durationMinutes: 15,
        videoPath: 'courses/c1/v2.mp4',
        activities: const [],
      );

      final module = CourseModuleModel(
        id: 'mod_1',
        title: 'Module 1: Basic Rights',
        lessons: [lessonClean],
      );

      await tester.pumpWidget(
        _testApp(
          LiveLessonModuleGroup(
            courseId: 'c1',
            module: module,
            moduleNumber: 1,
            currentLesson: lessonClean,
            completedLessonIds: const {},
            onSelectLesson: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1.1 Introductory Lecture'), findsOneWidget);
      expect(find.text('Quiz'), findsNothing);
      expect(find.text('Handout'), findsNothing);
      expect(find.text('Assignment'), findsNothing);
    });
  });
}
