import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/config/routes/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/main.dart';

void main() {
  final course = CourseModel(
    id: 'c1',
    title: 'AJK PSC General Recruitment Masterclass',
    author: 'Dr. Usman',
    rating: 4.9,
    price: 'Rs 3,500',
    imagePath: 'assets/images/course4.jpg',
  );
  final lesson = LessonModel(
    id: 'l1',
    title: 'AJK Interim Constitution Act 1974',
    durationMinutes: 25,
  );
  final quiz = QuizModel(
    id: 'q1',
    title: 'Practice Quiz',
    category: 'AJK PSC',
    totalQuestions: 1,
    questions: [
      QuizQuestionModel(
        id: 'question1',
        questionText: 'Which option is correct?',
        options: ['First', 'Second'],
        correctOptionIndex: 0,
        explanation: 'First is correct.',
      ),
    ],
  );
  final result = QuizSubmissionResultModel(
    quizId: quiz.id,
    quizTitle: quiz.title,
    score: 1,
    totalQuestions: 1,
    userAnswers: {0: 0},
    questions: quiz.questions,
  );
  final assignment = AssignmentModel(
    id: 'assignment_1',
    courseId: course.id,
    courseTitle: course.title,
    title: 'Course assignment',
    instructions: 'Write a short answer about this course.',
    dueAt: DateTime.now().add(const Duration(days: 7)),
  );
  final routeExtras = <AppRoute, Object?>{
    AppRoute.courseDetail: course,
    AppRoute.lessonPlayer: {'course': course, 'lesson': lesson},
    AppRoute.teacherManageCourse: course,
    AppRoute.activeQuiz: quiz,
    AppRoute.quizCompleted: result,
    AppRoute.quizReview: result,
    AppRoute.studentAssignment: assignment,
    AppRoute.teacherCourseAssignments: course,
    AppRoute.teacherCreateAssignment: course,
    AppRoute.teacherReviewAssignment: assignment,
  };

  for (final (size, textScale) in [
    (const Size(320, 640), 1.0),
    (const Size(375, 812), 1.0),
    (const Size(800, 1100), 1.0),
    (const Size(640, 360), 1.0),
    (const Size(360, 720), 1.3),
  ]) {
    testWidgets(
      'registered routes fit ${size.width}x${size.height} at ${textScale}x text',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.platformDispatcher.clearTextScaleFactorTestValue();
        });

        final failures = <String>[];
        var activeRoute = AppRoute.welcomeRole;
        final previousErrorHandler = FlutterError.onError;
        FlutterError.onError = (details) {
          final source = RegExp(
            r'lib/[^\s]+\.dart:\d+',
          ).firstMatch(details.toString())?.group(0);
          failures.add(
            '${activeRoute.name}: ${details.exceptionAsString()} ${source ?? ''}',
          );
        };
        addTearDown(() => FlutterError.onError = previousErrorHandler);

        await tester.pumpWidget(const ProviderScope(child: MyApp()));

        Future<void> checkScrolledContent() async {
          for (final element in find.byType(Scrollable).evaluate()) {
            final scrollable = element.widget as Scrollable;
            if (scrollable.axisDirection != AxisDirection.down) {
              continue;
            }
            final position =
                (element as StatefulElement).state as ScrollableState;
            if (!position.position.hasContentDimensions ||
                position.position.maxScrollExtent <= 0) {
              continue;
            }
            position.position.jumpTo(position.position.maxScrollExtent);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 600));
            break;
          }
        }

        for (final route in AppRoute.values) {
          activeRoute = route;
          appRouter.go(route.path, extra: routeExtras[route]);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));
          await checkScrolledContent();
          final tabCount = switch (route) {
            AppRoute.main => 5,
            AppRoute.teacherMain => 4,
            _ => 0,
          };
          if (tabCount > 0) {
            for (var index = 1; index < tabCount; index++) {
              final bar = tester.getRect(find.byType(BottomNavigationBar));
              await tester.tapAt(
                Offset(
                  bar.left + bar.width * (index + 0.5) / tabCount,
                  bar.center.dy,
                ),
              );
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 600));
              await checkScrolledContent();
            }
          }
        }
        FlutterError.onError = previousErrorHandler;
        expect(failures, isEmpty, reason: failures.join('\n'));
      },
    );
  }
}
