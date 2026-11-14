import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';

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
            : _RetryAction(
                label: 'Try again',
                icon: Icon(Icons.replay_rounded, size: 19.w),
                onPressed: () => context.pushReplacementNamed(
                  AppRoute.activeQuiz.name,
                  extra: quiz,
                ),
              ),
        loading: () => _RetryAction(
          label: 'Try again',
          icon: SizedBox.square(
            dimension: 17.w,
            child: const CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        error: (_, __) => _RetryAction(
          label: 'Check retry availability',
          icon: Icon(Icons.refresh_rounded, size: 19.w),
          onPressed: () => ref.invalidate(_retryQuizProvider(quizId)),
        ),
      );
}

class _RetryAction extends StatelessWidget {
  const _RetryAction({required this.label, required this.icon, this.onPressed});

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50.h,
    child: OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon,
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        disabledForegroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
      ),
    ),
  );
}
