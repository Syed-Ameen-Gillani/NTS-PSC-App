import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/draft_lesson_video_picker.dart';

void main() {
  for (final busy in [false, true]) {
    testWidgets('selected draft video can only be removed when idle: $busy', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: DraftLessonVideoPicker(draftId: 'draft', busy: busy),
              ),
            ),
          ),
        ),
      );
      container.read(draftLessonVideoProvider('draft').notifier).state = (
        path: '/private/test.mp4',
        name: 'test.mp4',
        mimeType: 'video/mp4',
      );
      await tester.pump();
      expect(find.text('test.mp4'), findsOneWidget);
      final remove = find.byWidgetPredicate(
        (widget) =>
            widget is IconButton && widget.tooltip == 'Remove selected video',
      );
      expect(tester.widget<IconButton>(remove).onPressed == null, busy);
      if (!busy) {
        await tester.tap(remove);
        await tester.pump();
        expect(find.text('Add lesson video (optional)'), findsOneWidget);
        expect(container.read(draftLessonVideoProvider('draft')), isNull);
      }
      expect(tester.takeException(), isNull);
    });
  }
}
