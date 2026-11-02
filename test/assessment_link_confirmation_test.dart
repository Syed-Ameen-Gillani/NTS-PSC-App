import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/curriculum/presentation/assessment_link_confirmation.dart';

void main() {
  testWidgets('link confirmation can be cancelled or approved', (tester) async {
    final result = ValueNotifier<bool?>(null);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result.value = await confirmAssessmentLinkChange(
                  context: context,
                  title: 'Practice quiz',
                  target: 'Module 1',
                  unlink: false,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Link assessment?'), findsOneWidget);
    expect(result.value, isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result.value, isFalse);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Link'));
    await tester.pumpAndSettle();
    expect(result.value, isTrue);
    result.dispose();
  });

  testWidgets('unlink explains the student impact', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => confirmAssessmentLinkChange(
                context: context,
                title: 'Essay',
                target: 'this lesson',
                unlink: true,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Unlink assessment?'), findsOneWidget);
    expect(
      find.textContaining('Publish course changes to update what students see.'),
      findsOneWidget,
    );
  });

  testWidgets('publish confirmation describes curriculum placement', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => confirmAssessmentLinkChange(
                context: context,
                title: 'Practice quiz',
                target: 'Module 1',
                unlink: false,
                publish: true,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Link assessment?'), findsOneWidget);
    expect(
      find.textContaining('Link "Practice quiz" to Module 1?'),
      findsOneWidget,
    );
  });
}
