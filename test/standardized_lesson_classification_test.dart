import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_classification.dart';
import 'package:nts_psc_app/features/home/presentation/widgets/course_curriculum_tab.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/course_workspace_module.dart';

Widget _testApp(Widget child) => ProviderScope(
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (context, _) => MaterialApp(home: Scaffold(body: child)),
  ),
);

void main() {
  group('LessonClassification domain logic', () {
    test('Video takes priority over assessment and reading', () {
      final lessonWithVideoAndQuiz = LessonModel(
        id: '1',
        title: 'Video + Quiz',
        durationMinutes: 10,
        videoPath: 'videos/sample.mp4',
        activities: const [
          LessonActivity(
            id: 'a1',
            kind: 'quiz',
            title: 'Quiz Check',
            order: 1,
            isRequired: true,
          ),
        ],
      );

      expect(
        LessonClassification.classify(lessonWithVideoAndQuiz),
        LessonClassification.videoLesson,
      );
      expect(
        LessonClassification.icon(lessonWithVideoAndQuiz),
        Icons.play_circle_outline,
      );
    });

    test('Assessment takes priority over reading when no video is present', () {
      final lessonWithAssessmentOnly = LessonModel(
        id: '2',
        title: 'Assessment Only',
        durationMinutes: 15,
        notes: 'Some reading notes',
        activities: const [
          LessonActivity(
            id: 'a2',
            kind: 'assignment',
            title: 'Final Task',
            order: 1,
            isRequired: true,
          ),
        ],
      );

      expect(
        LessonClassification.classify(lessonWithAssessmentOnly),
        LessonClassification.assessment,
      );
      expect(
        LessonClassification.icon(lessonWithAssessmentOnly),
        Icons.quiz_outlined,
      );
    });

    test('Reading lesson when neither video nor assessment is present', () {
      final readingLesson = LessonModel(
        id: '3',
        title: 'Reading Only',
        durationMinutes: 8,
        notes: 'Handout notes',
        activities: const [
          LessonActivity(
            id: 'a3',
            kind: 'material',
            title: 'PDF Handout',
            order: 1,
            isRequired: false,
          ),
        ],
      );

      expect(
        LessonClassification.classify(readingLesson),
        LessonClassification.readingLesson,
      );
      expect(
        LessonClassification.icon(readingLesson),
        Icons.article_outlined,
      );
    });
  });

  group('Student and Teacher curriculum tiles display all 3 classifications consistently', () {
    final videoLesson = LessonModel(
      id: 'l_vid',
      title: 'Intro Video',
      durationMinutes: 20,
      videoPath: 'path/to/video.mp4',
    );

    final assessmentLesson = LessonModel(
      id: 'l_quiz',
      title: 'Midterm Quiz',
      durationMinutes: 30,
      activities: const [
        LessonActivity(
          id: 'act_q',
          kind: 'quiz',
          title: 'Quiz',
          order: 1,
          isRequired: true,
        ),
      ],
    );

    final readingLesson = LessonModel(
      id: 'l_read',
      title: 'Chapter Reading',
      durationMinutes: 12,
      notes: 'Detailed notes',
    );

    final testModule = CourseModuleModel(
      id: 'mod_1',
      title: 'Module 1: General Knowledge',
      lessons: [videoLesson, assessmentLesson, readingLesson],
    );

    final testCourse = CourseModel(
      id: 'course_1',
      title: 'AJK PSC Prep',
      description: 'Prep Course',
      author: 'Teacher A',
      rating: 4.8,
      price: 'Free',
      imagePath: '',
      modules: [testModule],
    );

    testWidgets('Student CourseCurriculumTab renders all 3 classifications with correct labels and icons', (tester) async {
      await tester.pumpWidget(
        _testApp(
          CourseCurriculumTab(
            course: testCourse,
            isTeacher: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Module header
      expect(find.text('Module 1: General Knowledge'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('3/10 lessons'), findsOneWidget);

      // Lesson titles
      expect(find.text('1. Intro Video'), findsOneWidget);
      expect(find.text('2. Midterm Quiz'), findsOneWidget);
      expect(find.text('3. Chapter Reading'), findsOneWidget);

      // Classifications
      expect(find.text('Video lesson  |  20 min'), findsOneWidget);
      expect(find.text('Assessment  |  30 min'), findsOneWidget);
      expect(find.text('Reading lesson  |  12 min'), findsOneWidget);

      // Icons
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });

    testWidgets('Teacher CourseWorkspaceModule renders all 3 classifications with matching labels and icons', (tester) async {
      await tester.pumpWidget(
        _testApp(
          CourseWorkspaceModule(
            courseId: testCourse.id,
            module: testModule,
            index: 0,
            onAddLesson: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Module header
      expect(find.text('Module 1: General Knowledge'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(find.text('3/10 lessons'), findsOneWidget);

      // Lesson titles
      expect(find.text('1. Intro Video'), findsOneWidget);
      expect(find.text('2. Midterm Quiz'), findsOneWidget);
      expect(find.text('3. Chapter Reading'), findsOneWidget);

      // Classifications
      expect(find.text('Video lesson  |  20 min'), findsOneWidget);
      expect(find.text('Assessment  |  30 min'), findsOneWidget);
      expect(find.text('Reading lesson  |  12 min'), findsOneWidget);

      // Icons
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.quiz_outlined), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
    });
  });
}
