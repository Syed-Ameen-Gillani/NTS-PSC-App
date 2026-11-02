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
}
