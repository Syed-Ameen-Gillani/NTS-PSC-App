import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/automatic_learning_status.dart';

void main() {
  testWidgets('banner only announces changes and supports dismissal', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final completedProvider = StateProvider<bool>((ref) => false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningOutcomeProvider('lesson').overrideWith(
            (ref) async => {
              'completed': ref.watch(completedProvider),
              'activities': const [],
            },
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) => Column(
                  children: [
                    AutomaticLearningStatus(lessonId: 'lesson'),
                    TextButton(
                      key: const ValueKey('toggle-status'),
                      onPressed: () {
                        final notifier = ref.read(completedProvider.notifier);
                        notifier.state = !notifier.state;
                      },
                      child: const Text('Toggle'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('lesson-completion-banner')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('toggle-status')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('LESSON COMPLETED'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('lesson-completion-banner')))
          .width,
      lessThan(390),
    );

    await tester.tap(find.byKey(const ValueKey('dismiss-completion-banner')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('LESSON COMPLETED'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('toggle-status')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LESSON INCOMPLETE'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('LESSON INCOMPLETE'), findsNothing);
  });

  testWidgets('completion waits until the lesson route is visible again', (
    tester,
  ) async {
    final completedProvider = StateProvider<bool>((ref) => false);
    late WidgetRef lessonRef;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningOutcomeProvider('lesson').overrideWith(
            (ref) async => {
              'completed': ref.watch(completedProvider),
              'activities': const [],
            },
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                lessonRef = ref;
                return Scaffold(
                  body: Column(
                    children: [
                      const AutomaticLearningStatus(lessonId: 'lesson'),
                      TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const Scaffold(
                              body: Center(child: Text('PDF reader')),
                            ),
                          ),
                        ),
                        child: const Text('Open PDF'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open PDF'));
    await tester.pumpAndSettle();

    lessonRef.read(completedProvider.notifier).state = true;
    await tester.pumpAndSettle();
    expect(find.text('LESSON COMPLETED'), findsNothing);

    Navigator.of(tester.element(find.text('PDF reader'))).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('LESSON COMPLETED'), findsOneWidget);
  });
}
