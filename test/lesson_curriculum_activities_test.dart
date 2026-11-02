import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/lesson_activity.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/lesson_curriculum_tile.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/live_lesson_module_group.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/learning_outcome_provider.dart';

const _scope = CurriculumScope(
  courseId: 'course',
  moduleId: 'module',
  lessonId: 'lesson',
);
const _activities = [
  LessonActivity(
    id: 'video',
    kind: 'video',
    title: 'Video',
    order: 0,
    isRequired: true,
  ),
  LessonActivity(
    id: 'quiz',
    kind: 'quiz',
    title: 'Knowledge check',
    order: 2,
    isRequired: true,
    assessmentLinkId: 'quiz-link',
  ),
  LessonActivity(
    id: 'pdf',
    kind: 'material',
    title: 'Lesson handout',
    order: 1,
    isRequired: false,
    materialId: 'pdf-file',
  ),
  LessonActivity(
    id: 'assignment',
    kind: 'assignment',
    title: 'Written work',
    order: 3,
    isRequired: true,
    assessmentLinkId: 'assignment-link',
  ),
  LessonActivity(
    id: 'reading',
    kind: 'reading',
    title: 'Lesson notes',
    order: 4,
    isRequired: true,
  ),
];

void main() {
  final reflectPushes = GoRouter.optionURLReflectsImperativeAPIs;
  setUp(() => GoRouter.optionURLReflectsImperativeAPIs = true);
  tearDown(() => GoRouter.optionURLReflectsImperativeAPIs = reflectPushes);
  test('outline retains source identifiers for exact activity navigation', () {
    final activity = LessonActivity.fromRow({
      'id': 'activity',
      'kind': 'quiz',
      'title': 'Quiz',
      'display_order': 1,
      'required': true,
      'assessment_link_id': 'link',
      'material_id': null,
    });
    expect(activity.assessmentLinkId, 'link');
    expect(activity.materialId, isNull);
  });

  Future<GoRouter> mount(
    WidgetTester tester, {
    bool locked = false,
    bool preview = false,
    bool missingQuiz = false,
    double width = 390,
  }) async {
    tester.view.physicalSize = Size(width, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lesson = LessonModel(
      id: 'lesson',
      title: 'Main lesson',
      durationMinutes: 15,
      videoPath: 'video.mp4',
      activities: _activities,
      isLocked: locked,
    );
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: SingleChildScrollView(
              child: LiveLessonModuleGroup(
                courseId: 'course',
                module: CourseModuleModel(
                  id: 'module',
                  title: 'Module',
                  lessons: [lesson],
                ),
                moduleNumber: 1,
                currentLesson: lesson,
                completedLessonIds: const {},
                onSelectLesson: (_) {},
                isInstructorPreview: preview,
              ),
            ),
          ),
        ),
        for (final route in [
          AppRoute.activeQuiz,
          AppRoute.studentAssignment,
          AppRoute.lessonReading,
        ])
          GoRoute(
            path: '/${route.name}',
            name: route.name,
            builder: (_, state) =>
                Scaffold(body: Text('${route.name}:${state.uri.query}')),
          ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningOutcomeProvider('lesson').overrideWith(
            (ref) async => {
              'completed': false,
              'activities': [
                {'id': 'quiz', 'completed': true},
              ],
            },
          ),
          curriculumAssessmentsProvider(_scope).overrideWith(
            (ref) async => [
              // Duplicate titles must never cause selection of another source ID.
              const CurriculumAssessment(
                id: 'other-link',
                assessmentId: 'wrong-quiz',
                title: 'Knowledge check',
                kind: 'quiz',
                status: 'published',
              ),
              if (!missingQuiz)
                const CurriculumAssessment(
                  id: 'quiz-link',
                  assessmentId: 'actual-quiz',
                  title: 'Knowledge check',
                  kind: 'quiz',
                  status: 'published',
                ),
              const CurriculumAssessment(
                id: 'assignment-link',
                assessmentId: 'actual-assignment',
                title: 'Written work',
                kind: 'assignment',
                status: 'published',
              ),
            ],
          ),
          curriculumMaterialsProvider(_scope).overrideWith(
            (ref) async => [
              const CurriculumMaterial(
                id: 'pdf-file',
                title: 'Lesson handout',
                path: 'private/handout.pdf',
                sizeBytes: 100,
              ),
            ],
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  for (final width in [320.0, 390.0, 768.0]) {
    testWidgets(
      'activity rows share lesson styling without indexes at $width',
      (tester) async {
        await mount(tester, width: width);
        expect(find.byType(LessonCurriculumTile), findsNWidgets(5));
        expect(find.text('1.1 Main lesson'), findsOneWidget);
        expect(find.text('Knowledge check'), findsOneWidget);
        expect(find.byIcon(Icons.folder_open_outlined), findsNothing);
        expect(find.byIcon(Icons.quiz_outlined), findsNothing);
        expect(find.byIcon(Icons.check_circle_outline_rounded), findsOneWidget);
        expect(find.byIcon(Icons.assignment_outlined), findsOneWidget);
        expect(find.byIcon(Icons.description_outlined), findsOneWidget);
        expect(find.byIcon(Icons.article_outlined), findsOneWidget);
        expect(
          tester
              .widget<LessonCurriculumTile>(
                find.byKey(const ValueKey('curriculum-activity-quiz')),
              )
              .complete,
          isTrue,
        );
        expect(
          tester.getTopLeft(find.text('Lesson handout')).dx,
          greaterThan(tester.getTopLeft(find.text('1.1 Main lesson')).dx),
        );
        expect(
          tester.getTopLeft(find.text('Lesson handout')).dy,
          lessThan(tester.getTopLeft(find.text('Knowledge check')).dy),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final entry in [
    ('Knowledge check', AppRoute.activeQuiz, 'quizId', 'actual-quiz'),
    (
      'Written work',
      AppRoute.studentAssignment,
      'assignmentId',
      'actual-assignment',
    ),
    ('Lesson handout', AppRoute.lessonReading, 'materialId', 'pdf-file'),
    ('Lesson notes', AppRoute.lessonReading, 'lessonId', 'lesson'),
  ]) {
    testWidgets('${entry.$1} opens its exact destination directly', (
      tester,
    ) async {
      final router = await mount(tester);
      await tester.tap(find.text(entry.$1));
      await tester.pumpAndSettle();
      final uri = router.routeInformationProvider.value.uri;
      expect(uri.path, '/${entry.$2.name}');
      expect(uri.queryParameters[entry.$3], entry.$4);
      if (entry.$1 == 'Lesson handout') {
        expect(uri.queryParameters['lessonId'], 'lesson');
      }
      expect(find.text('Materials & Assessments'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  for (final preview in [false, true]) {
    testWidgets('activities remain visible but disabled; preview=$preview', (
      tester,
    ) async {
      final router = await mount(tester, preview: preview, locked: !preview);
      final row = tester.widget<LessonCurriculumTile>(
        find.byKey(const ValueKey('curriculum-activity-quiz')),
      );
      expect(row.onTap, isNull);
      expect(router.routeInformationProvider.value.uri.path, '/');
    });
  }

  testWidgets('missing exact assessment link never opens a matching title', (
    tester,
  ) async {
    final router = await mount(tester, missingQuiz: true);
    await tester.tap(find.text('Knowledge check'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(router.routeInformationProvider.value.uri.path, '/');
    expect(
      find.text('Could not open this activity. Try again.'),
      findsOneWidget,
    );
    await tester.pump(const Duration(seconds: 4));
  });
}
