import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/lesson_authoring_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_create_lesson_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/lesson_authoring_sheet.dart';

void main() {
  testWidgets('creating a lesson returns to its course through GoRouter', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LessonModel? saved;
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TextButton(
              onPressed: () async {
                await LessonAuthoringSheet.show(context, 'course', 'module');
              },
              child: const Text('Add lesson'),
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.teacherCreateLesson.path,
          name: AppRoute.teacherCreateLesson.name,
          builder: (context, state) => const TeacherCreateLessonScreen(
            courseId: 'course',
            moduleId: 'module',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lessonAuthoringProvider.overrideWith(
            (ref, key) => LessonAuthoringController(
              create: (lesson) async {
                saved = lesson;
                return lesson;
              },
              uploadVideo: (_, _, _) async {},
              uploadMaterial: (_, _) async {},
            ),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp.router(routerConfig: router),
        ),
      ),
    );

    await tester.tap(find.text('Add lesson'));
    await tester.pumpAndSettle();
    expect(find.text('Create lesson'), findsNWidgets(2));
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Add lesson'), findsOneWidget);

    await tester.tap(find.text('Add lesson'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'A new lesson');
    await tester.ensureVisible(find.text('Create lesson').last);
    await tester.tap(find.text('Create lesson').last);
    await tester.pumpAndSettle();

    expect(saved?.title, 'A new lesson');
    expect(find.text('Add lesson'), findsOneWidget);
    expect(find.text('Create lesson'), findsNothing);
    await tester.pump(const Duration(seconds: 4));
  });
}
