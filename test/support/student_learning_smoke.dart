import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';
import 'package:nts_psc_app/core/theme/app_theme.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/active_quiz_screen.dart';
import 'package:nts_psc_app/features/quizzes/presentation/pages/quiz_completed_screen.dart';

// Native UI smoke uses isolated repository responses. Hosted authorization,
// scoring, approval and PDF generation are verified by the separate live script.
class _SessionRepository extends SupabaseQuizRepository {
  _SessionRepository(super.client, this.quiz);
  final QuizModel quiz;
  Map<String, int> answers = {};
  int finishes = 0;
  @override
  Future<Map<String, dynamic>> startSession(String quizId) async => {
    'id': 'session',
    'expires_at': '2026-10-25T10:02:00Z',
    'server_now': '2026-10-25T10:00:00Z',
    'answers': <String, int>{},
  };
  @override
  Future<void> saveSession(String id, Map<String, int> answers) async {
    this.answers = Map.of(answers);
  }

  @override
  Future<QuizModel?> getQuizById(String id) async => quiz;
  @override
  Future<QuizSubmissionResultModel> finishSession(String id) async {
    finishes++;
    return QuizSubmissionResultModel(
      quizId: quiz.id,
      quizTitle: quiz.title,
      passingScore: 80,
      score: answers.values.where((value) => value == 1).length,
      totalQuestions: 2,
      questions: quiz.questions,
      userAnswers: {0: answers['one']!, 1: answers['two']!},
    );
  }
}

void runStudentLearningSmoke() {
  testWidgets('quiz exit, answer save, result and return flow', (
    tester,
  ) async {
    AppConfig.isSupabaseEnabled = false;
    final quiz = QuizModel(
      id: 'quiz',
      title: 'Native learning smoke',
      category: 'General',
      totalQuestions: 2,
      isPublished: true,
      passingScore: 80,
      questions: [
        QuizQuestionModel(
          id: 'one',
          questionText: 'First question',
          options: ['First A', 'First B'],
          correctOptionIndex: 1,
          explanation: 'B',
        ),
        QuizQuestionModel(
          id: 'two',
          questionText: 'Second question',
          options: ['Second A', 'Second B'],
          correctOptionIndex: 1,
          explanation: 'B',
        ),
      ],
    );
    final client = (await tester.runAsync(
      () async => SupabaseClient(
        'https://example.invalid',
        'test-key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
      ),
    ))!;
    final repository = _SessionRepository(client, quiz);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          name: AppRoute.main.name,
          builder: (context, _) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () =>
                    context.pushNamed(AppRoute.activeQuiz.name, extra: quiz),
                child: const Text('Open quiz'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoute.activeQuiz.path,
          name: AppRoute.activeQuiz.name,
          builder: (_, state) =>
              ActiveQuizScreen(quiz: state.extra as QuizModel),
        ),
        GoRoute(
          path: AppRoute.quizCompleted.path,
          name: AppRoute.quizCompleted.name,
          builder: (_, state) => QuizCompletedScreen(
            result: state.extra as QuizSubmissionResultModel,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    addTearDown(() => tester.runAsync(client.dispose));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [quizRepositoryProvider.overrideWithValue(repository)],
        child: ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (_, _) => MaterialApp.router(
            theme: AppTheme.lightTheme,
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    await tester.tap(find.text('Open quiz'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    await tester.tap(find.text('First B'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(find.text('Leave this quiz?'), findsOneWidget);
    await tester.tap(find.text('Keep working'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    await tester.tap(find.text('Next question'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    await tester.tap(find.text('Second B'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    await tester.tap(find.text('Submit quiz'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(find.text('Assessment Results'), findsOneWidget);
    expect(repository.finishes, 1);
    expect(repository.answers, {'one': 1, 'two': 1});
    await tester.ensureVisible(find.text('Continue learning'));
    await tester.tap(find.text('Continue learning'));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
    );
    expect(find.text('Open quiz'), findsOneWidget);
  });
}
