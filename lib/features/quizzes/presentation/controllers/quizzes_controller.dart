import 'dart:async';
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
}

final quizzesControllerProvider =
    AsyncNotifierProvider<QuizzesController, QuizzesState>(() {
      return QuizzesController();
    });

final quizAttemptResultProvider =
    FutureProvider.family<QuizSubmissionResultModel?, String>((ref, attemptId) {
      return ref.watch(quizRepositoryProvider).getAttemptResult(attemptId);
    });
