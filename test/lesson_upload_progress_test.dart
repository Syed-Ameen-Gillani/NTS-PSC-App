import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/lesson_upload_progress.dart';

void main() {
  testWidgets('shows compression percentage, sizes, and upload-limit status', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const MaterialApp(
          home: Scaffold(
            body: LessonUploadProgressDetails(
              value: LessonUploadProgressValue(
                label: 'Compressing video',
                value: 0.42,
                originalBytes: 40 * 1024 * 1024,
                expectedBytes: 20 * 1024 * 1024,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Compressing video'), findsOneWidget);
    expect(find.text('42%'), findsOneWidget);
    expect(find.text('40.0 MB'), findsOneWidget);
    expect(find.text('20.0 MB'), findsOneWidget);
    expect(
      find.text('Expected output is within the 25 MB upload limit.'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'cancel requires confirmation and keeping preparation preserves it',
    (tester) async {
      var cancelled = false;
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => LessonUploadProgressDetails(
                  value: const LessonUploadProgressValue(
                    label: 'Compressing video',
                    value: .25,
                  ),
                  showCancel: true,
                  onCancel: () async {
                    if (await confirmVideoPreparationCancellation(context)) {
                      cancelled = true;
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Cancel preparation'));
      await tester.pumpAndSettle();
      expect(find.text('Cancel video preparation?'), findsOneWidget);
      expect(cancelled, isFalse);
      await tester.tap(find.text('Keep preparing'));
      await tester.pumpAndSettle();
      expect(cancelled, isFalse);
      await tester.tap(find.byTooltip('Cancel preparation'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Cancel preparation'));
      await tester.pumpAndSettle();
      expect(cancelled, isTrue);
    },
  );

  testWidgets('upload progress exposes upload cancellation confirmation', (
    tester,
  ) async {
    var cancelled = false;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => LessonUploadProgressDetails(
                value: const LessonUploadProgressValue(
                  label: 'Uploading video',
                  value: .6,
                ),
                showCancel: true,
                onCancel: () async {
                  cancelled = await confirmVideoPreparationCancellation(
                    context,
                    uploading: true,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byTooltip('Cancel upload'), findsOneWidget);
    await tester.tap(find.byTooltip('Cancel upload'));
    await tester.pumpAndSettle();
    expect(find.text('Cancel video upload?'), findsOneWidget);
    expect(find.text('Keep uploading'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Cancel upload'));
    await tester.pumpAndSettle();
    expect(cancelled, isTrue);
  });

  testWidgets('cancelling hides transfer details and becomes indeterminate', (
    tester,
  ) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, _) => const MaterialApp(
          home: Scaffold(
            body: LessonUploadProgressDetails(
              value: LessonUploadProgressValue(
                label: 'Cancelling…',
                value: .72,
                originalBytes: 40 * 1024 * 1024,
                expectedBytes: 20 * 1024 * 1024,
              ),
              showCancel: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Cancelling…'), findsOneWidget);
    expect(find.text('72%'), findsNothing);
    expect(find.text('Original'), findsNothing);
    expect(find.text('Expected size'), findsNothing);
    expect(find.byTooltip('Cancel preparation'), findsNothing);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      isNull,
    );
  });
}
