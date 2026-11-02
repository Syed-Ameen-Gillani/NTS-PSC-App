import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuizSessionState {
  const QuizSessionState({
    this.answers = const {},
    this.index = 0,
    this.seconds = 0,
    this.loading = true,
    this.busy = false,
    this.error,
    this.result,
    this.questions = const [],
    this.exitAllowed = false,
  });
  final Map<int, int> answers;
  final int index, seconds;
  final bool loading, busy;
  final String? error;
  final QuizSubmissionResultModel? result;
  final List<QuizQuestionModel> questions;
  final bool exitAllowed;
  QuizSessionState copy({
    Map<int, int>? answers,
    int? index,
    int? seconds,
    bool? loading,
    bool? busy,
    String? error,
    QuizSubmissionResultModel? result,
    List<QuizQuestionModel>? questions,
    bool? exitAllowed,
  }) => QuizSessionState(
    answers: answers ?? this.answers,
    index: index ?? this.index,
    seconds: seconds ?? this.seconds,
    loading: loading ?? this.loading,
    busy: busy ?? this.busy,
    error: error,
    result: result ?? this.result,
    questions: questions ?? this.questions,
    exitAllowed: exitAllowed ?? this.exitAllowed,
  );
}

final quizSessionProvider = NotifierProvider.autoDispose
    .family<QuizSessionController, QuizSessionState, QuizModel>(
      QuizSessionController.new,
    );

/// The server owns the deadline and saved answers. A monotonic clock avoids
/// extending a session when the device clock changes or the app backgrounds.
class QuizSessionController extends Notifier<QuizSessionState> {
  QuizSessionController(this.quiz);
  final QuizModel quiz;
  String? _sessionId;
  Timer? _timer;
  final _clock = Stopwatch();
  int _duration = 0;
  Future<void> _pendingSave = Future.value();
  bool _disposed = false;
  bool _confirmingExit = false;
  bool beginExit() {
    if (state.busy || _confirmingExit) return false;
    _confirmingExit = true;
    return true;
  }

  Future<void> finishExit(bool leave) async {
    if (leave) await _pendingSave;
    _confirmingExit = false;
    if (!_disposed && leave) state = state.copy(exitAllowed: true);
  }

  Future<void> refreshDeadline() async {
    if (_disposed ||
        state.loading ||
        state.busy ||
        state.result != null ||
        _sessionId == null) {
      return;
    }
    final repository = ref.read(quizRepositoryProvider);
    if (repository is! SupabaseQuizRepository) return;
    try {
      final status = await repository.sessionStatus(_sessionId!);
      if (_disposed || state.busy || state.result != null) return;
      final attemptId = status['attempt_id'] as String?;
      if (attemptId != null) {
        final result = await repository.getAttemptResult(attemptId);
        if (!_disposed && result != null) state = state.copy(result: result);
        return;
      }
      _duration = DateTime.parse(
        status['expires_at'] as String,
      ).difference(DateTime.parse(status['server_now'] as String)).inSeconds;
      _clock
        ..reset()
        ..start();
      state = state.copy(
        seconds: _duration.clamp(0, 10800),
        error: state.error,
      );
      if (_duration <= 0) await submit();
    } catch (_) {
      /* The server still checks expiry on each answer and submit. */
    }
  }

  List<QuizQuestionModel> get questions =>
      state.questions.isEmpty ? quiz.questions : state.questions;

  @override
  QuizSessionState build() {
    ref.onDispose(() {
      _disposed = true;
      _timer?.cancel();
      _clock.stop();
    });
    Future.microtask(load);
    return const QuizSessionState();
  }

  Future<void> load() async {
    if (_disposed) return;
    state = state.copy(loading: true);
    try {
      if (quiz.questions.isEmpty) throw StateError('No questions');
      final repository = ref.read(quizRepositoryProvider);
      var answers = <int, int>{};
      var sessionQuestions = quiz.questions;
      _duration = quiz.durationMinutes * 60;
      if (repository is SupabaseQuizRepository) {
        final row = await repository.startSession(quiz.id);
        _sessionId = row['id'] as String;
        _duration = DateTime.parse(
          row['expires_at'] as String,
        ).difference(DateTime.parse(row['server_now'] as String)).inSeconds;
        final saved = Map<String, dynamic>.from(row['answers'] as Map);
        if (row['questions'] is List) {
          sessionQuestions = (row['questions'] as List)
              .map(
                (item) => QuizQuestionModel(
                  id: item['id'] as String,
                  questionText: item['question_text'] as String,
                  options: (item['options'] as List).cast<String>(),
                  correctOptionIndex: -1,
                  explanation: '',
                ),
              )
              .toList();
        }
        for (var i = 0; i < sessionQuestions.length; i++) {
          final selected = saved[sessionQuestions[i].id];
          if (selected is int) answers[i] = selected;
        }
      }
      if (_disposed) return;
      _clock
        ..reset()
        ..start();
      state = state.copy(
        loading: false,
        answers: Map.unmodifiable(answers),
        seconds: _duration.clamp(0, 10800),
        questions: sessionQuestions,
        index: 0,
      );
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_disposed || state.busy || state.result != null) return;
        final seconds = (_duration - _clock.elapsed.inSeconds).clamp(0, 10800);
        state = state.copy(seconds: seconds, error: state.error);
        if (seconds == 0) {
          _timer?.cancel();
          unawaited(submit());
        }
      });
    } catch (_) {
      if (!_disposed) {
        state = state.copy(
          loading: false,
          error: 'Could not open this quiz. Please try again.',
        );
      }
    }
  }

  void move(int index) {
    if (!state.busy && index >= 0 && index < questions.length) {
      state = state.copy(index: index, error: state.error);
    }
  }

  void select(int option) {
    if (state.loading || state.busy || state.seconds <= 0) return;
    final answers = {...state.answers, state.index: option};
    state = state.copy(answers: Map.unmodifiable(answers));
    final repository = ref.read(quizRepositoryProvider);
    if (repository is! SupabaseQuizRepository || _sessionId == null) return;
    final payload = {
      for (final e in answers.entries) questions[e.key].id: e.value,
    };
    _pendingSave = _pendingSave.then((_) async {
      try {
        await repository.saveSession(_sessionId!, payload);
      } on PostgrestException catch (error) {
        if (error.message == 'Quiz time has ended') _duration = 0;
        if (!_disposed) {
          state = state.copy(error: 'Answer not saved. Check your connection.');
        }
      } catch (_) {
        if (!_disposed) {
          state = state.copy(error: 'Answer not saved. Check your connection.');
        }
      }
    });
  }

  Future<void> submit() async {
    if (state.busy || state.loading || state.result != null) return;
    state = state.copy(busy: true);
    try {
      await _pendingSave;
      final repository = ref.read(quizRepositoryProvider);
      QuizSubmissionResultModel result;
      if (repository is SupabaseQuizRepository) {
        if (_sessionId == null) throw StateError('No session');
        // Retry the latest complete answer map before an early submission.
        // After expiry, only answers already saved on the server are scored.
        if (_duration > _clock.elapsed.inSeconds) {
          try {
            await repository.saveSession(_sessionId!, {
              for (final e in state.answers.entries)
                questions[e.key].id: e.value,
            });
          } on PostgrestException catch (error) {
            if (error.message != 'Quiz time has ended') rethrow;
          }
        }
        result = await repository.finishSession(_sessionId!);
      } else {
        result = await repository.submitQuiz(
          quizId: quiz.id,
          userAnswers: state.answers,
        );
      }
      if (_disposed) return;
      _timer?.cancel();
      state = state.copy(busy: false, result: result);
    } catch (_) {
      if (!_disposed) {
        state = state.copy(
          busy: false,
          error: 'Could not submit. Your saved answers are safe. Try again.',
        );
      }
    }
  }
}
