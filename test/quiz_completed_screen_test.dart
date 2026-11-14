import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/mock_data_sources.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quiz_completed_screen.dart';

class _DelayedQuizRepository extends MockQuizRepository {
  _DelayedQuizRepository(this.gate);

  final Future<void> gate;

  @override
  Future<QuizModel?> getQuizById(String quizId) async {
    await gate;
    return super.getQuizById(quizId);
  }
}

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = false);

  testWidgets('assessment result uses real metrics and aligned actions', (
    tester,
  ) async {
    final result = QuizSubmissionResultModel(
      quizId: 'q1',
      quizTitle: 'Current Affairs Weekly Challenge 2024',
      score: 3,
      totalQuestions: 4,
      passingScore: 60,
      userAnswers: const {},
      questions: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) =>
              MaterialApp(home: QuizCompletedScreen(result: result)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Assessment Results'), findsOneWidget);
    expect(find.text('Assessment passed'), findsOneWidget);
    expect(find.text('Correct answers'), findsOneWidget);
    expect(find.text('3 of 4'), findsOneWidget);
    expect(find.text('Accuracy'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Pass mark'), findsOneWidget);
    expect(find.text('60%'), findsOneWidget);
    expect(find.textContaining('Time Taken'), findsNothing);

    final review = find.widgetWithText(FilledButton, 'Review answers');
    expect(review, findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Try again'), findsNothing);
    expect(find.text('Continue learning'), findsNothing);
    expect(find.byIcon(Icons.fact_check_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('failed assessment shows retry immediately and then enables it', (
    tester,
  ) async {
    final retryGate = Completer<void>();
    final result = QuizSubmissionResultModel(
      quizId: 'q1',
      quizTitle: 'Current Affairs Weekly Challenge 2024',
      score: 1,
      totalQuestions: 4,
      passingScore: 60,
      userAnswers: const {},
      questions: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          quizRepositoryProvider.overrideWithValue(
            _DelayedQuizRepository(retryGate.future),
          ),
        ],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) =>
              MaterialApp(home: QuizCompletedScreen(result: result)),
        ),
      ),
    );

    await tester.pump();
    final loadingRetry = find.widgetWithText(OutlinedButton, 'Try again');
    expect(loadingRetry, findsOneWidget);
    expect(tester.widget<OutlinedButton>(loadingRetry).onPressed, isNull);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    retryGate.complete();
    await tester.pumpAndSettle();

    final enabledRetry = find.widgetWithText(OutlinedButton, 'Try again');
    expect(enabledRetry, findsOneWidget);
    expect(tester.widget<OutlinedButton>(enabledRetry).onPressed, isNotNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
