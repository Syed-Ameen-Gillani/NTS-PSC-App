import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/lesson_authoring_sheet.dart';

void main() {
  for (final width in [320.0, 768.0]) {
    testWidgets(
      'lesson form validates title and retains studio guidance at $width',
      (tester) async {
        AppConfig.isSupabaseEnabled = true;
        addTearDown(() => AppConfig.isSupabaseEnabled = false);
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          ProviderScope(
            child: ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, _) => const MaterialApp(
                home: Scaffold(
                  body: LessonAuthoringSheet(
                    courseId: 'course',
                    moduleId: 'module',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Lesson title'), findsOneWidget);
        expect(find.text('Estimated duration'), findsOneWidget);
        expect(find.text('Streaming URL (optional)'), findsOneWidget);
        expect(
          find.text(
            'Upload video, handouts, and assessments in Lesson Studio.',
          ),
          findsOneWidget,
        );
        final create = find.widgetWithText(FilledButton, 'Create lesson');
        await tester.ensureVisible(create);
        await tester.tap(create);
        await tester.pumpAndSettle();
        expect(find.text('Enter a lesson title'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
