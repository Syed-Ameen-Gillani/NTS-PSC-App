import 'package:nts_psc_app/core/models/app_models.dart';

abstract class QuizRepository {
  Future<List<QuizModel>> getAiQuizzes();
  Future<List<QuizModel>> getCourseQuizzes();
  Future<List<QuizModel>> getTeacherQuizzes(String teacherId);
  Future<QuizModel?> getQuizById(String quizId);
  Future<QuizModel> generateAiQuiz({
    required String topic,
    required String difficulty,
    required int questionCount,
  });
  Future<QuizSubmissionResultModel> submitQuiz({
    required String quizId,
    required Map<int, int> userAnswers,
  });
  Future<QuizModel> createQuiz(QuizModel quiz);
}
