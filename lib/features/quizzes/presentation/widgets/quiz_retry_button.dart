import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';

final _retryQuizProvider = FutureProvider.autoDispose
    .family<QuizModel?, String>(
      (ref, id) => ref.watch(quizRepositoryProvider).getQuizById(id),
    );

class QuizRetryButton extends ConsumerWidget {
  const QuizRetryButton({super.key, required this.quizId});
  final String quizId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(_retryQuizProvider(quizId))
      .when(
        data: (quiz) => quiz == null || !quiz.isPublished
            ? const SizedBox.shrink()
            : TextButton(
                onPressed: () => context.pushReplacementNamed(
                  AppRoute.activeQuiz.name,
                  extra: quiz,
                ),
                child: const Text('Try again'),
              ),
        loading: () => const SizedBox.shrink(),
        error: (_, __) => TextButton(
          onPressed: () => ref.invalidate(_retryQuizProvider(quizId)),
          child: const Text('Check retry availability'),
        ),
      );
}
