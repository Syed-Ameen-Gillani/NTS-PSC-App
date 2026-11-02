import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quiz_session_controller.dart';

class SessionRepository extends SupabaseQuizRepository {
  SessionRepository(super.client);
  int finishes = 0;
  bool fail = false;
  bool expiredOnSave = false;
  Completer<void>? gate;
  final saved = <Map<String, int>>[];
  @override
  Future<Map<String, dynamic>> sessionStatus(String id) async => {
    'id': id,
    'expires_at': '2026-10-25T09:59:00Z',
    'server_now': '2026-10-25T10:00:00Z',
    'attempt_id': null,
  };
  @override
  Future<Map<String, dynamic>> startSession(String quizId) async => {
    'id': 'session',
    'server_now': '2026-10-25T10:00:00Z',
    'expires_at': '2026-10-25T10:02:00Z',
    'answers': {'question': 1},
  };
  @override
  Future<void> saveSession(String id, Map<String, int> answers) async {
    if (expiredOnSave) {
      throw const PostgrestException(message: 'Quiz time has ended');
    }
    saved.add(Map.of(answers));
    await gate?.future;
  }

  @override
  Future<QuizSubmissionResultModel> finishSession(String id) async {
    finishes++;
    if (fail) throw StateError('offline');
    return QuizSubmissionResultModel(
      quizId: 'quiz',
      quizTitle: 'Quiz',
      attemptId: 'attempt',
      score: 1,
      totalQuestions: 1,
      userAnswers: {0: 1},
      questions: [],
    );
  }
}

void main() {
  final quiz = QuizModel(
    id: 'quiz',
    title: 'Quiz',
    category: 'General',
    totalQuestions: 1,
    questions: [
      QuizQuestionModel(
        id: 'question',
        questionText: 'Question?',
        options: ['A', 'B'],
        correctOptionIndex: -1,
        explanation: '',
      ),
    ],
  );
  for (final scenario in [
    'restore',
    'wait for save',
    'retry',
    'resume expired',
    'server expiry on submit',
  ]) {
    test('quiz session $scenario', () async {
      final client = SupabaseClient('https://example.invalid', 'test-key');
      addTearDown(client.dispose);
      final repository = SessionRepository(client);
      final container = ProviderContainer(
        overrides: [quizRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final provider = quizSessionProvider(quiz);
      final subscription = container.listen(provider, (_, __) {});
      addTearDown(subscription.close);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(provider).answers, {0: 1});
      expect(container.read(provider).seconds, 120);
      final controller = container.read(provider.notifier);
      if (scenario == 'wait for save') {
        repository.gate = Completer<void>();
        controller.select(0);
        final submission = controller.submit();
        await Future<void>.delayed(Duration.zero);
        expect(container.read(provider).busy, true);
        expect(repository.finishes, 0);
        controller.select(1);
        expect(container.read(provider).answers, {0: 0});
        repository.gate!.complete();
        await submission;
        expect(repository.saved.last, {'question': 0});
        expect(repository.finishes, 1);
      } else if (scenario == 'resume expired') {
        await controller.refreshDeadline();
        expect(container.read(provider).result?.attemptId, 'attempt');
        expect(repository.finishes, 1);
      } else if (scenario == 'server expiry on submit') {
        repository.expiredOnSave = true;
        await controller.submit();
        expect(container.read(provider).result?.attemptId, 'attempt');
      } else if (scenario == 'retry') {
        repository.fail = true;
        await controller.submit();
        expect(container.read(provider).busy, false);
        expect(container.read(provider).error, isNotNull);
        expect(container.read(provider).answers, {0: 1});
        repository.fail = false;
        await controller.submit();
        expect(container.read(provider).result?.attemptId, 'attempt');
      }
    });
  }
}
