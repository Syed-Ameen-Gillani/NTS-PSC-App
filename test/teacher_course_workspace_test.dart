import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/teacher_course_workspace.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/course_workspace_module.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final text = FontLoader('Inter');
    for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
      text.addFont(rootBundle.load('assets/fonts/Inter_18pt-$weight.ttf'));
    }
    await text.load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  setUp(() => AppConfig.isSupabaseEnabled = true);
  tearDown(() => AppConfig.isSupabaseEnabled = false);

  testWidgets(
    'lesson rows use content icons without trailing actions or dividers',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            curriculumAttachmentSummaryProvider.overrideWith(
              (ref, scope) async => const CurriculumAttachmentSummary(
                handouts: 0,
                quizzes: 0,
                assignments: 0,
              ),
            ),
          ],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: CourseWorkspaceModule(
                  courseId: 'course',
                  module: CourseModuleModel(
                    id: 'module',
                    title: 'First module',
                    lessons: [
                      LessonModel(
                        id: 'lesson',
                        title: 'Welcome lesson',
                        durationMinutes: 25,
                        videoPath: 'lesson.mp4',
                      ),
                      LessonModel(
                        id: 'reading',
                        title: 'Reading lesson',
                        durationMinutes: 15,
                      ),
                    ],
                  ),
                  index: 0,
                  onAddLesson: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final tile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, '1. Welcome lesson'),
      );
      final readingTile = tester.widget<ListTile>(
        find.widgetWithText(ListTile, '2. Reading lesson'),
      );
      expect(tile.leading, isA<Icon>());
      expect(tile.trailing, isNull);
      expect(readingTile.leading, isA<Icon>());
      expect(readingTile.trailing, isNull);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.article_outlined), findsOneWidget);
      expect(find.text('Video lesson  |  25 min'), findsOneWidget);
      expect(find.text('Reading lesson  |  15 min'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('module allows ten lessons and disables adding an eleventh', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var additions = 0;
    Future<void> showModule(int count) => tester.pumpWidget(
      ProviderScope(
        overrides: [
          curriculumAttachmentSummaryProvider.overrideWith(
            (ref, scope) async => const CurriculumAttachmentSummary(
              handouts: 0,
              quizzes: 0,
              assignments: 0,
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: CourseWorkspaceModule(
                courseId: 'course',
                module: CourseModuleModel(
                  id: 'limited-module',
                  title: 'Module',
                  lessons: [
                    for (var i = 0; i < count; i++)
                      LessonModel(
                        id: '$i',
                        title: 'Lesson $i',
                        durationMinutes: 20,
                      ),
                  ],
                ),
                index: 0,
                onAddLesson: () => additions++,
              ),
            ),
          ),
        ),
      ),
    );

    await showModule(9);
    await tester.pumpAndSettle();
    expect(find.text('9/10 lessons'), findsOneWidget);
    await tester.ensureVisible(find.text('Add lesson'));
    await tester.tap(find.text('Add lesson'));
    expect(additions, 1);

    await showModule(10);
    await tester.pumpAndSettle();
    expect(find.text('10/10 lessons'), findsOneWidget);
    await tester.ensureVisible(find.text('Module full'));
    final button = tester.widget<TextButton>(
      find.ancestor(
        of: find.text('Module full'),
        matching: find.byType(TextButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('module materials action lets teacher choose the lesson', (
    tester,
  ) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: CourseWorkspaceModule(
              courseId: 'course',
              module: CourseModuleModel(
                id: 'module',
                title: 'Module',
                lessons: [
                  LessonModel(id: 'one', title: 'First', durationMinutes: 20),
                  LessonModel(id: 'two', title: 'Second', durationMinutes: 20),
                ],
              ),
              index: 0,
              onAddLesson: () {},
            ),
          ),
        ),
        GoRoute(
          name: AppRoute.teacherLessonMedia.name,
          path: AppRoute.teacherLessonMedia.path,
          builder: (_, state) => Scaffold(
            body: Text('Studio: ${(state.extra as LessonModel).title}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curriculumAttachmentSummaryProvider.overrideWith((ref, scope) async {
            if (scope.lessonId == 'two') {
              return const CurriculumAttachmentSummary(
                handouts: 1,
                quizzes: 1,
                assignments: 1,
              );
            }
            return const CurriculumAttachmentSummary(
              handouts: 0,
              quizzes: 0,
              assignments: 0,
            );
          }),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Materials & assessments'), findsOneWidget);
    final addLeft = tester
        .getTopLeft(
          find.ancestor(
            of: find.text('Add lesson'),
            matching: find.byType(TextButton),
          ),
        )
        .dx;
    final studioLeft = tester
        .getTopLeft(
          find.ancestor(
            of: find.text('Materials & assessments'),
            matching: find.byType(TextButton),
          ),
        )
        .dx;
    expect((addLeft - studioLeft).abs(), lessThan(1));
    expect(find.textContaining('1 handout'), findsOneWidget);
    await tester.tap(find.text('Materials & assessments'));
    await tester.pumpAndSettle();
    expect(find.text('Choose a lesson'), findsOneWidget);
    await tester.tap(find.text('2. Second').last);
    await tester.pumpAndSettle();
    expect(find.text('Studio: Second'), findsOneWidget);
  });

  testWidgets('tapping a lesson opens that lesson studio', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: CourseWorkspaceModule(
              courseId: 'course',
              module: CourseModuleModel(
                id: 'module',
                title: 'Module',
                lessons: [
                  LessonModel(id: 'one', title: 'First', durationMinutes: 20),
                  LessonModel(id: 'two', title: 'Second', durationMinutes: 20),
                ],
              ),
              index: 0,
              onAddLesson: () {},
            ),
          ),
        ),
        GoRoute(
          name: AppRoute.teacherLessonMedia.name,
          path: AppRoute.teacherLessonMedia.path,
          builder: (_, state) => Scaffold(
            body: Text('Studio: ${(state.extra as LessonModel).title}'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          curriculumAttachmentSummaryProvider.overrideWith(
            (ref, scope) async => const CurriculumAttachmentSummary(
              handouts: 0,
              quizzes: 0,
              assignments: 0,
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp.router(routerConfig: router),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('2. Second'));
    await tester.pumpAndSettle();

    expect(find.text('Studio: Second'), findsOneWidget);
  });

  for (final width in [320.0, 390.0, 768.0, 1024.0]) {
    testWidgets('course workspace stays aligned and interactive at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var addedModules = 0;
      String? addedLesson;
      bool? publication;
      final screenshot = GlobalKey();
      final course = CourseModel(
        id: 'course',
        title: 'Kashmir studies',
        author: 'Teacher',
        rating: 0,
        price: 'Free',
        imagePath: '',
        category: 'AJK PSC',
        isPublished: false,
        modules: [
          CourseModuleModel(
            id: 'module',
            title: 'First Module',
            lessons: [
              LessonModel(
                id: 'lesson',
                title:
                    'Welcome to Kashmir studies and the foundations of regional history',
                durationMinutes: 25,
              ),
            ],
          ),
        ],
      );
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            builder: (_, _) => MaterialApp(
              theme: AppTheme.lightTheme,
              home: RepaintBoundary(
                key: screenshot,
                child: Scaffold(
                  body: TeacherCourseWorkspace(
                    course: course,
                    assessmentCount: 0,
                    onPublish: (value) async {
                      publication = value;
                    },
                    onAddModule: () => addedModules++,
                    onAddLesson: (id) => addedLesson = id,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kashmir studies'), findsOneWidget);
      expect(find.text('Learners'), findsNWidgets(2));
      expect(find.text('Assessments'), findsOneWidget);
      expect(find.text('Materials & assessments'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (width == 390) {
        await tester.runAsync(() async {
          final boundary =
              screenshot.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final output = File('build/course_workspace_390.png');
          await output.parent.create(recursive: true);
          await output.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(find.byType(Switch), findsNothing);
      await tester.tap(find.text('Publish course'));
      await tester.pumpAndSettle();
      expect(publication, true);
      await tester.ensureVisible(find.text('Add module'));
      await tester.tap(find.text('Add module'));
      expect(addedModules, 1);
      await tester.ensureVisible(find.text('Add lesson'));
      await tester.tap(find.text('Add lesson'));
      expect(addedLesson, 'module');
      expect(find.textContaining('Reading lesson'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
