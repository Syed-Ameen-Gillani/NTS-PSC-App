import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/pages/teacher_course_assignments_screen.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';

class _TeacherAuth extends AuthController {
  @override
  AuthState build() => AuthState(selectedRole: UserRole.teacher);
}

class _Assignments extends AssignmentsController {
  @override
  FutureOr<AssignmentsState> build() => AssignmentsState(
    assignments: [
      AssignmentModel(
        id: 'assignment',
        courseId: 'course',
        courseTitle: 'Course',
        title: 'Written assignment',
        instructions: 'Answer the prompt',
        dueAt: DateTime(2027),
      ),
    ],
  );
}

class _Teacher extends TeacherController {
  @override
  FutureOr<TeacherState> build() => TeacherState(
    stats: TeacherStatsModel(
      totalStudents: 0,
      activeCourses: 1,
      totalQuizzes: 1,
      avgRating: 0,
      totalEarnings: 'Rs 0',
    ),
    quizzes: [
      QuizModel(
        id: 'quiz',
        title: 'Course quiz',
        category: 'Pakistan Affairs',
        totalQuestions: 4,
        courseId: 'course',
      ),
    ],
  );
}

class _EmptyAssignments extends AssignmentsController {
  @override
  FutureOr<AssignmentsState> build() => AssignmentsState();
}

class _EmptyTeacher extends TeacherController {
  @override
  FutureOr<TeacherState> build() => TeacherState(
    stats: TeacherStatsModel(
      totalStudents: 0,
      activeCourses: 1,
      totalQuizzes: 0,
      avgRating: 0,
      totalEarnings: 'Rs 0',
    ),
  );
}

Future<void> pumpCourseAssessments(
  WidgetTester tester, {
  required bool hasQuizzes,
  required bool hasAssignments,
}) async {
  final course = CourseModel(
    id: 'course',
    title: 'Course',
    author: 'Teacher',
    rating: 0,
    price: 'Free',
    imagePath: '',
    category: 'AJK PSC',
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_TeacherAuth.new),
        assignmentsControllerProvider.overrideWith(
          hasAssignments ? _Assignments.new : _EmptyAssignments.new,
        ),
        teacherControllerProvider.overrideWith(
          hasQuizzes ? _Teacher.new : _EmptyTeacher.new,
        ),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          theme: AppTheme.lightTheme,
          home: TeacherCourseAssignmentsScreen(course: course),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('centers one empty state when a course has no assessments', (
    tester,
  ) async {
    await pumpCourseAssessments(
      tester,
      hasQuizzes: false,
      hasAssignments: false,
    );
    expect(find.text('No assessments yet'), findsOneWidget);
    expect(
      find.ancestor(
        of: find.text('No assessments yet'),
        matching: find.byType(Center),
      ),
      findsOneWidget,
    );
    expect(find.text('Quizzes'), findsNothing);
    expect(find.text('Assignments'), findsNothing);
  });

  for (final hasQuizzes in [true, false]) {
    testWidgets('shows only the populated assessment section ($hasQuizzes)', (
      tester,
    ) async {
      await pumpCourseAssessments(
        tester,
        hasQuizzes: hasQuizzes,
        hasAssignments: !hasQuizzes,
      );
      expect(find.text('No assessments yet'), findsNothing);
      expect(find.text('Quizzes'), hasQuizzes ? findsOneWidget : findsNothing);
      expect(
        find.text('Assignments'),
        hasQuizzes ? findsNothing : findsOneWidget,
      );
      expect(
        find.text('Course quiz'),
        hasQuizzes ? findsOneWidget : findsNothing,
      );
      expect(
        find.text('Written assignment'),
        hasQuizzes ? findsNothing : findsOneWidget,
      );
    });
  }

  testWidgets(
    'course assessments list links quiz analysis and assignment review',
    (tester) async {
      final course = CourseModel(
        id: 'course',
        title: 'Course',
        author: 'Teacher',
        rating: 0,
        price: 'Free',
        imagePath: '',
        category: 'AJK PSC',
      );
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => TeacherCourseAssignmentsScreen(course: course),
          ),
          GoRoute(
            path: AppRoute.teacherQuizAnalysis.path,
            name: AppRoute.teacherQuizAnalysis.name,
            builder: (_, state) => Scaffold(
              body: Text(
                state.extra is QuizModel
                    ? 'Quiz analysis opened'
                    : 'Wrong quiz',
              ),
            ),
          ),
          GoRoute(
            path: AppRoute.teacherReviewAssignment.path,
            name: AppRoute.teacherReviewAssignment.name,
            builder: (_, state) => Scaffold(
              body: Text(
                state.extra is AssignmentModel
                    ? 'Assignment review opened'
                    : 'Wrong assignment',
              ),
            ),
          ),
          GoRoute(
            path: AppRoute.teacherQuizStudio.path,
            name: AppRoute.teacherQuizStudio.name,
            builder: (_, state) {
              final args = state.extra as Map<String, dynamic>;
              final scope = args['targetScope'] as CurriculumScope;
              return Scaffold(
                body: Text(
                  scope.courseId == 'course'
                      ? 'Course quiz manager opened'
                      : 'Wrong course',
                ),
              );
            },
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authControllerProvider.overrideWith(_TeacherAuth.new),
            assignmentsControllerProvider.overrideWith(_Assignments.new),
            teacherControllerProvider.overrideWith(_Teacher.new),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp.router(
              theme: AppTheme.lightTheme,
              routerConfig: router,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Assessments'), findsOneWidget);
      expect(find.text('Quizzes'), findsOneWidget);
      expect(find.text('Assignments'), findsOneWidget);
      expect(find.text('Course quiz'), findsOneWidget);
      expect(find.text('Written assignment'), findsOneWidget);
      await tester.tap(find.text('Course quiz'));
      await tester.pumpAndSettle();
      expect(find.text('Quiz analysis opened'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Written assignment'));
      await tester.pumpAndSettle();
      expect(find.text('Assignment review opened'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add assessment'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manage quizzes'));
      await tester.pumpAndSettle();
      expect(find.text('Course quiz manager opened'), findsOneWidget);
    },
  );
}
