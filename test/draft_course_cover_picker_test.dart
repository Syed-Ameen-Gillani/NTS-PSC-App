import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/draft_course_cover_picker.dart';

void main() {
  testWidgets('shows required validation and selected cover preview', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => const MaterialApp(
            home: Scaffold(
              body: DraftCourseCoverPicker(draftId: 'draft', busy: false),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Upload course cover'), findsOneWidget);
    expect(find.text('JPEG, PNG or WebP · Up to 5 MB'), findsOneWidget);

    container.read(draftCourseCoverErrorProvider('draft').notifier).state =
        true;
    await tester.pump();
    expect(find.text('Please add a course cover'), findsOneWidget);

    final bytes = await tester.runAsync(
      () => File('assets/images/logo.png').readAsBytes(),
    );
    container.read(draftCourseCoverProvider('draft').notifier).state = (
      name: 'cover.png',
      bytes: bytes!,
    );
    container.read(draftCourseCoverErrorProvider('draft').notifier).state =
        false;
    await tester.pump();
    expect(find.text('Change cover'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Please add a course cover'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
