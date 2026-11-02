import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quizzes_controller.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quizzes_screen.dart';

class _Quizzes extends QuizzesController {
  @override
  QuizzesState build() => QuizzesState(
    courseQuizzes: [
      QuizModel(
        id: 'one',
        title: 'Kashmir history',
        category: 'AJK PSC',
        totalQuestions: 4,
      ),
      QuizModel(
        id: 'two',
        title: 'Everyday science',
        category: 'NTS',
        totalQuestions: 4,
      ),
    ],
  );
}

class _OutcomeQuizzes extends QuizzesController {
  @override
  QuizzesState build() => QuizzesState(
    courseQuizzes: [
      QuizModel(
        id: 'todo',
        title: 'Needs another attempt',
        category: 'NTS',
        totalQuestions: 10,
        score: '4/10',
        passingScore: 60,
      ),
      QuizModel(
        id: 'complete',
        title: 'Passed quiz',
        category: 'NTS',
        totalQuestions: 10,
        score: '8/10',
        passingScore: 60,
      ),
    ],
  );
}

void main() {
  testWidgets(
    'quiz screen keeps assessments visible without persistent search',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [quizzesControllerProvider.overrideWith(_Quizzes.new)],
          child: ScreenUtilInit(
            designSize: const Size(375, 812),
            builder: (_, __) => const MaterialApp(home: QuizzesScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Your quiz feedback'), findsOneWidget);
      expect(find.text('Weekly Goal'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Kashmir history'), findsOneWidget);
      expect(find.text('Everyday science'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('quiz filters separate assigned work from completed outcomes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizzesControllerProvider.overrideWith(_OutcomeQuizzes.new),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, __) => const MaterialApp(home: QuizzesScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    await tester.tap(find.text('Needs action'));
    await tester.pumpAndSettle();
    expect(find.text('Needs another attempt'), findsOneWidget);
    expect(find.text('Passed quiz'), findsNothing);

    await tester.drag(find.byType(ListView).first, const Offset(-160, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Completed'));
    await tester.pumpAndSettle();
    expect(find.text('Passed quiz'), findsOneWidget);
    expect(find.text('Needs another attempt'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
