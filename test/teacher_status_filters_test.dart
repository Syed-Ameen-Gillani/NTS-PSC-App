import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/teacher_assignments_section.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_studio_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_assessment_list_screen.dart';

class _QuizController extends TeacherController {
  _QuizController(this.quizzes);

  final List<QuizModel> quizzes;

  @override
  FutureOr<TeacherState> build() => TeacherState(
    stats: TeacherStatsModel(
      totalStudents: 0,
      activeCourses: 0,
      totalQuizzes: quizzes.length,
      avgRating: 0,
      totalEarnings: 'Rs 0',
    ),
    quizzes: quizzes,
  );
}

class _AssignmentController extends AssignmentsController {
  _AssignmentController(this.assignments);

  final List<AssignmentModel> assignments;

  @override
  FutureOr<AssignmentsState> build() =>
      AssignmentsState(assignments: assignments);
}

QuizModel _quiz(String id, {required bool published}) => QuizModel(
  id: id,
  title: published ? 'Published quiz' : 'Draft quiz',
  category: 'FPSC',
  totalQuestions: 5,
  isPublished: published,
  courseId: published ? 'course-1' : null,
);

AssignmentModel _assignment(String id, {required bool published}) =>
    AssignmentModel(
      id: id,
      courseId: 'course-1',
      courseTitle: 'FPSC Preparation',
      title: published ? 'Published assignment' : 'Draft assignment',
      instructions: 'Complete the work.',
      dueAt: DateTime(2026, 10, 20),
      isPublished: published,
    );

Widget _quizApp(List<QuizModel> quizzes) => ProviderScope(
  overrides: [
    teacherControllerProvider.overrideWith(() => _QuizController(quizzes)),
  ],
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: const TeacherQuizStudioScreen(),
    ),
  ),
);

Widget _assignmentApp(List<AssignmentModel> assignments) => ProviderScope(
  overrides: [
    assignmentsControllerProvider.overrideWith(
      () => _AssignmentController(assignments),
    ),
  ],
  child: ScreenUtilInit(
    designSize: const Size(375, 812),
    builder: (_, __) => MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(body: TeacherAssignmentsSection()),
    ),
  ),
);

void main() {
  testWidgets('quiz sections are hidden when both status groups are empty', (
    tester,
  ) async {
    await tester.pumpWidget(_quizApp([]));
    await tester.pumpAndSettle();

    expect(find.text('No quizzes yet'), findsOneWidget);
    expect(find.text('Published'), findsNothing);
    expect(find.text('Drafts'), findsNothing);
  });

  testWidgets('quiz headings show only statuses that contain data', (
    tester,
  ) async {
    await tester.pumpWidget(_quizApp([_quiz('draft', published: false)]));
    await tester.pumpAndSettle();

    expect(find.text('Drafts'), findsOneWidget);
    expect(find.text('Published'), findsNothing);
    expect(find.text('Draft quiz'), findsOneWidget);
  });

  testWidgets('quiz headings show both populated groups', (tester) async {
    await tester.pumpWidget(
      _quizApp([
        _quiz('published', published: true),
        _quiz('draft', published: false),
      ]),
    );
    await tester.pumpAndSettle();

    expect(find.text('Published quiz'), findsOneWidget);
    expect(find.text('Draft quiz'), findsOneWidget);
    expect(find.text('Published'), findsOneWidget);
    expect(find.text('Drafts'), findsOneWidget);
  });

  testWidgets('unlinked quiz has no analysis action', (tester) async {
    await tester.pumpWidget(_quizApp([_quiz('draft', published: false)]));
    await tester.pumpAndSettle();

    final PopupMenuButton<String> menu = tester.widget(
      find.byType(PopupMenuButton<String>),
    );
    final actions = menu.itemBuilder(
      tester.element(find.byType(PopupMenuButton<String>)),
    );
    expect(
      actions.whereType<PopupMenuItem<String>>().where(
        (item) => item.value == 'analysis',
      ),
      isEmpty,
    );
    expect(
      actions.whereType<PopupMenuItem<String>>().map((item) => item.value),
      contains('link'),
    );
    expect(
      actions.whereType<PopupMenuItem<String>>().map((item) => item.value),
      isNot(contains('publish')),
    );
    expect(menu.color, AppTheme.lightTheme.scaffoldBackgroundColor);
  });

  testWidgets('linked quiz has an analysis action', (tester) async {
    await tester.pumpWidget(_quizApp([_quiz('linked', published: true)]));
    await tester.pumpAndSettle();

    final PopupMenuButton<String> menu = tester.widget(
      find.byType(PopupMenuButton<String>),
    );
    final actions = menu.itemBuilder(
      tester.element(find.byType(PopupMenuButton<String>)),
    );
    expect(
      actions.whereType<PopupMenuItem<String>>().where(
        (item) => item.value == 'analysis',
      ),
      hasLength(1),
    );
  });

  testWidgets(
    'assignment headings hide absent statuses and show accurate counts',
    (tester) async {
      await tester.pumpWidget(
        _assignmentApp([
          _assignment('draft-1', published: false),
          _assignment('draft-2', published: false),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Drafts'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Published'), findsNothing);
      expect(find.text('Draft assignment'), findsNWidgets(2));
    },
  );

  testWidgets('quiz preview shows three and See all opens the full page', (
    tester,
  ) async {
    final quizzes = [
      for (var i = 1; i <= 3; i++) _quiz('published-$i', published: true),
      QuizModel(
        id: 'published-4',
        title: 'Fourth quiz',
        category: 'FPSC',
        totalQuestions: 5,
        isPublished: true,
        courseId: 'course-1',
      ),
    ];
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const TeacherQuizStudioScreen()),
        GoRoute(
          path: AppRoute.teacherAssessmentList.path,
          name: AppRoute.teacherAssessmentList.name,
          builder: (_, state) => TeacherAssessmentListScreen(
            kind: state.uri.queryParameters['kind'] ?? 'quiz',
            published: state.uri.queryParameters['status'] == 'published',
          ),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          teacherControllerProvider.overrideWith(
            () => _QuizController(quizzes),
          ),
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

    expect(find.byType(TeacherQuizListItem), findsNWidgets(3));
    await tester.tap(find.text('See all'));
    await tester.pumpAndSettle();
    expect(find.text('Published Quizzes'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Fourth quiz'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Fourth quiz'), findsOneWidget);
  });

  testWidgets(
    'assignment preview shows three and See all opens the full page',
    (tester) async {
      final assignments = [
        for (var i = 1; i <= 3; i++) _assignment('draft-$i', published: false),
        AssignmentModel(
          id: 'draft-4',
          courseId: 'course-1',
          courseTitle: 'FPSC Preparation',
          title: 'Fourth assignment',
          instructions: 'Complete the work.',
          dueAt: DateTime(2026, 10, 20),
          isPublished: false,
        ),
      ];
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) =>
                const Scaffold(body: TeacherAssignmentsSection()),
          ),
          GoRoute(
            path: AppRoute.teacherAssessmentList.path,
            name: AppRoute.teacherAssessmentList.name,
            builder: (_, state) => TeacherAssessmentListScreen(
              kind: state.uri.queryParameters['kind'] ?? 'assignment',
              published: state.uri.queryParameters['status'] == 'published',
            ),
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsControllerProvider.overrideWith(
              () => _AssignmentController(assignments),
            ),
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

      expect(find.byType(TeacherAssignmentListItem), findsNWidgets(3));
      final firstCard = find.byType(TeacherAssignmentListItem).first;
      final title = find.descendant(
        of: firstCard,
        matching: find.text('Draft assignment'),
      );
      final submissionStatus = find.descendant(
        of: firstCard,
        matching: find.textContaining('awaiting review'),
      );
      final gap =
          tester.getTopLeft(submissionStatus).dy -
          tester.getBottomLeft(title).dy;
      expect(gap, lessThan(16));
      await tester.tap(
        find.descendant(
          of: firstCard,
          matching: find.byTooltip('Assignment actions'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Edit draft'), findsOneWidget);
      expect(find.text('Link to course'), findsOneWidget);
      expect(find.text('Link in curriculum'), findsNothing);
      final menu = tester.widget<PopupMenuButton<String>>(
        find.descendant(
          of: firstCard,
          matching: find.byType(PopupMenuButton<String>),
        ),
      );
      expect(menu.color, AppTheme.lightTheme.scaffoldBackgroundColor);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See all'));
      await tester.pumpAndSettle();
      expect(find.text('Draft Assignments'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Fourth assignment'),
        220,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Fourth assignment'), findsOneWidget);
    },
  );

  testWidgets(
    'linking mode displays banner and link action button for quizzes',
    (tester) async {
      const scope = CurriculumScope(courseId: 'c1', lessonId: 'l1');
      final quiz = _quiz('q1', published: false);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherControllerProvider.overrideWith(
              () => _QuizController([quiz]),
            ),
            curriculumAssessmentsProvider(
              scope,
            ).overrideWith((ref) async => []),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              theme: AppTheme.lightTheme,
              home: const TeacherQuizStudioScreen(targetScope: scope),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('LINKING ASSESSMENTS TO LESSON'), findsOneWidget);
      expect(find.text('Physics 101'), findsNothing);
      expect(find.text('Done'), findsNothing);
      expect(find.text('Link to Lesson'), findsOneWidget);
      expect(find.text('Choose an assessment to link'), findsOneWidget);
      await tester.tap(find.text('Link to Lesson'));
      await tester.pumpAndSettle();
      expect(find.text('Link assessment?'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'linking mode shows Linked to Course badge when quiz is already linked',
    (tester) async {
      const scope = CurriculumScope(courseId: 'c1', lessonId: 'l1');
      final quiz = _quiz('q1', published: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            teacherControllerProvider.overrideWith(
              () => _QuizController([quiz]),
            ),
            curriculumAssessmentsProvider(scope).overrideWith(
              (ref) async => [
                const CurriculumAssessment(
                  id: 'q1',
                  assessmentId: 'q1',
                  title: 'Published quiz',
                  kind: 'quiz',
                  status: 'published',
                ),
              ],
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              theme: AppTheme.lightTheme,
              home: const TeacherQuizStudioScreen(targetScope: scope),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Linked to Lesson'), findsOneWidget);
      expect(find.text('Link to Lesson'), findsNothing);
      final quizMenu = tester.widget<PopupMenuButton<String>>(
        find.byType(PopupMenuButton<String>),
      );
      expect(
        quizMenu
            .itemBuilder(tester.element(find.byType(PopupMenuButton<String>)))
            .whereType<PopupMenuItem<String>>()
            .map((item) => item.value),
        contains('link'),
      );
      expect(find.text('Choose an assessment to link'), findsOneWidget);
      expect(find.text('Done'), findsNothing);
    },
  );

  testWidgets(
    'assignment section in linking mode shows link button and linked badge',
    (tester) async {
      const scope = CurriculumScope(courseId: 'c1', lessonId: 'l1');
      final assignment = _assignment('a1', published: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assignmentsControllerProvider.overrideWith(
              () => _AssignmentController([assignment]),
            ),
            curriculumAssessmentsProvider(
              scope,
            ).overrideWith((ref) async => []),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => MaterialApp(
              theme: AppTheme.lightTheme,
              home: const Scaffold(
                body: TeacherAssignmentsSection(targetScope: scope),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Link to Lesson'), findsOneWidget);
      final assignmentMenu = tester.widget<PopupMenuButton<String>>(
        find.byType(PopupMenuButton<String>),
      );
      expect(
        assignmentMenu
            .itemBuilder(tester.element(find.byType(PopupMenuButton<String>)))
            .whereType<PopupMenuItem<String>>()
            .map((item) => item.value),
        contains('link'),
      );
      await tester.tap(find.text('Link to Lesson'));
      await tester.pumpAndSettle();
      expect(find.text('Link assessment?'), findsOneWidget);
    },
  );
}
