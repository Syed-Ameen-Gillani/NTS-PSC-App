import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_quiz_repository.dart';

class QuizzesState {
  final List<QuizModel> courseQuizzes;
  final int weeklyCompleted;

  QuizzesState({this.courseQuizzes = const [], this.weeklyCompleted = 5});
}

class QuizzesController extends AsyncNotifier<QuizzesState> {
  @override
  FutureOr<QuizzesState> build() async {
    final repository = ref.read(quizRepositoryProvider);
    final quizzes = await repository.getCourseQuizzes();
    final weeklyCompleted = repository is SupabaseQuizRepository
        ? await repository.getWeeklyAttemptCount()
        : 5;
    return QuizzesState(
      courseQuizzes: quizzes,
      weeklyCompleted: weeklyCompleted,
    );
  }

  void recordResult(QuizSubmissionResultModel result) {
    final current = state.value;
    if (current == null) {
      developer.log(
        'Quiz ${result.quizId} finished with '
        '${result.score}/${result.totalQuestions}, but the assessment list '
        'is not loaded. Scheduling a fresh load.',
        name: 'CBOA.AssessmentFilters',
      );
      ref.invalidateSelf();
      return;
    }
    QuizModel? existing;
    for (final quiz in current.courseQuizzes) {
      if (quiz.id == result.quizId) {
        existing = quiz;
        break;
      }
    }
    if (existing == null) {
      developer.log(
        'Quiz ${result.quizId} finished with '
        '${result.score}/${result.totalQuestions}, but it is not present in '
        'the loaded assessment list. No chip contents were changed.',
        name: 'CBOA.AssessmentFilters',
      );
      return;
    }
    final previousBucket = _filterBucket(existing);
    final updated = existing.copyWith(
      score: '${result.score}/${result.totalQuestions}',
      attemptId: result.attemptId,
    );
    final nextBucket = _filterBucket(updated);
    state = AsyncValue.data(
      QuizzesState(
        courseQuizzes: [
          for (final quiz in current.courseQuizzes)
            quiz.id == result.quizId ? updated : quiz,
        ],
        weeklyCompleted: current.weeklyCompleted + 1,
      ),
    );
    developer.log(
      'Quiz ${result.quizId} assessment filter updated immediately: '
      '$previousBucket -> $nextBucket '
      '(score ${result.score}/${result.totalQuestions}, '
      'pass mark ${existing.passingScore}%).',
      name: 'CBOA.AssessmentFilters',
    );
  }

  String _filterBucket(QuizModel quiz) {
    final parts = quiz.score?.split('/');
    if (parts == null || parts.length != 2) return 'Needs action';
    final correct = int.tryParse(parts.first.trim());
    final total = int.tryParse(parts.last.trim());
    if (correct == null || total == null || total <= 0) return 'Needs action';
    return correct * 100 / total >= quiz.passingScore
        ? 'Completed'
        : 'Needs action';
  }
}

final quizzesControllerProvider =
    AsyncNotifierProvider<QuizzesController, QuizzesState>(() {
      return QuizzesController();
    });

final quizAttemptResultProvider =
    FutureProvider.family<QuizSubmissionResultModel?, String>((ref, attemptId) {
      return ref.watch(quizRepositoryProvider).getAttemptResult(attemptId);
    });
