import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quizzes_controller.dart';

void main() {
  setUp(() => AppConfig.isSupabaseEnabled = false);

  test(
    'quiz result updates assessment filters immediately in both directions',
    () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(quizzesControllerProvider.future);

      final controller = container.read(quizzesControllerProvider.notifier);
      controller.recordResult(
        QuizSubmissionResultModel(
          quizId: 'q2',
          quizTitle: 'Quiz',
          score: 3,
          totalQuestions: 3,
          passingScore: 60,
          userAnswers: const {},
          questions: const [],
        ),
      );

      var quiz = container
          .read(quizzesControllerProvider)
          .requireValue
          .courseQuizzes
          .firstWhere((item) => item.id == 'q2');
      expect(quiz.score, '3/3');

      controller.recordResult(
        QuizSubmissionResultModel(
          quizId: 'q2',
          quizTitle: 'Quiz',
          score: 1,
          totalQuestions: 3,
          passingScore: 60,
          userAnswers: const {},
          questions: const [],
        ),
      );

      quiz = container
          .read(quizzesControllerProvider)
          .requireValue
          .courseQuizzes
          .firstWhere((item) => item.id == 'q2');
      expect(quiz.score, '1/3');
    },
  );
}
