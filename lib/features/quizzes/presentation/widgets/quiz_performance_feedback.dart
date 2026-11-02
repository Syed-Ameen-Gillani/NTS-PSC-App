import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/presentation/widgets/assessment_feedback_banner.dart';

class QuizPerformanceFeedback extends StatelessWidget {
  const QuizPerformanceFeedback({super.key, required this.quizzes});

  final List<QuizModel> quizzes;

  double? _percentage(QuizModel quiz) {
    final parts = quiz.score?.split('/');
    if (parts == null || parts.length != 2) return null;
    final score = int.tryParse(parts.first.trim());
    final total = int.tryParse(parts.last.trim());
    if (score == null || total == null || total <= 0) return null;
    return score * 100 / total;
  }

  @override
  Widget build(BuildContext context) {
    final attempted = quizzes
        .where((quiz) => _percentage(quiz) != null)
        .toList();
    final retakes = attempted
        .where((quiz) => _percentage(quiz)! < quiz.passingScore)
        .toList();
    final average = attempted.isEmpty
        ? null
        : attempted.map((quiz) => _percentage(quiz)!).reduce((a, b) => a + b) /
              attempted.length;
    final recommended = retakes.firstOrNull;

    return AssessmentFeedbackBanner(
      icon: recommended == null ? Icons.insights_rounded : Icons.replay_rounded,
      title: attempted.isEmpty
          ? 'Your quiz feedback'
          : '${average!.round()}% average · ${attempted.length} attempted',
      message: attempted.isEmpty
          ? 'Complete a quiz to see personalized performance guidance.'
          : recommended == null
          ? 'You passed every attempted quiz. Keep up the strong work.'
          : 'Retake ${recommended.title} to improve your course progress.',
      onTap: recommended?.attemptId == null
          ? null
          : () => context.pushNamed(
              AppRoute.quizCompleted.name,
              queryParameters: {'attemptId': recommended!.attemptId!},
            ),
    );
  }
}

class AssessmentFeedbackLoading extends StatelessWidget {
  const AssessmentFeedbackLoading({super.key});

  @override
  Widget build(BuildContext context) => const AssessmentFeedbackBanner(
    icon: Icons.insights_rounded,
    title: 'Loading your feedback',
    message: 'Reviewing your latest assessment activity…',
  );
}

class AssessmentFeedbackUnavailable extends StatelessWidget {
  const AssessmentFeedbackUnavailable({super.key});

  @override
  Widget build(BuildContext context) => const AssessmentFeedbackBanner(
    icon: Icons.insights_rounded,
    title: 'Feedback unavailable',
    message: 'Your assessments are still available below.',
  );
}
