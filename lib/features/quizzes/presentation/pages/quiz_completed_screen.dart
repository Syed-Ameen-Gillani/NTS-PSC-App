import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quizzes_controller.dart';
import 'package:nts_psc_app/features/quizzes/presentation/widgets/quiz_retry_button.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';

class QuizCompletedScreen extends ConsumerWidget {
  const QuizCompletedScreen({super.key, this.result, this.attemptId});

  final QuizSubmissionResultModel? result;
  final String? attemptId;

  void _continueLearning(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.main.name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.isSupabaseEnabled) {
      final id = attemptId ?? result?.attemptId;
      if (id == null) return const _ResultState(message: 'Result unavailable');
      return ref
          .watch(quizAttemptResultProvider(id))
          .when(
            data: (saved) => saved == null
                ? const _ResultState(message: 'Result unavailable')
                : _buildResult(context, saved),
            loading: () => const _ResultState(loading: true),
            error: (_, __) => const _ResultState(
              message: 'Could not load assessment result.',
            ),
          );
    }
    return _buildResult(context, result);
  }

  Widget _buildResult(BuildContext context, QuizSubmissionResultModel? result) {
    final savedAttemptId = result?.attemptId;
    final total = result?.totalQuestions ?? 4;
    final score = result?.score ?? 3;
    final passingScore = result?.passingScore ?? 60;
    final percentage = total > 0 ? ((score / total) * 100).round() : 0;
    final isPassed = result?.isPassed ?? percentage >= passingScore;
    final statusColor = isPassed ? AppColors.success : AppColors.error;

    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Assessment Results',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 18.sp,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Close results',
            onPressed: () => _continueLearning(context),
            icon: Icon(Icons.close_rounded, size: 22.w),
            color: AppColors.onBackground,
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: const Divider(height: 1, color: AppColors.grey300),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 32.h),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ResultSummary(
                    passed: isPassed,
                    percentage: percentage,
                    quizTitle: result?.quizTitle,
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.grey300, width: 1.w),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Performance breakdown',
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 15.sp,
                            color: AppColors.onBackground,
                          ),
                        ),
                        SizedBox(height: 14.h),
                        _ResultMetric(
                          icon: Icons.check_circle_outline_rounded,
                          label: 'Correct answers',
                          value: '$score of $total',
                          color: statusColor,
                        ),
                        SizedBox(height: 12.h),
                        _ResultMetric(
                          icon: Icons.pie_chart_outline_rounded,
                          label: 'Accuracy',
                          value: '$percentage%',
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 12.h),
                        _ResultMetric(
                          icon: Icons.flag_outlined,
                          label: 'Pass mark',
                          value: '$passingScore%',
                          color: AppColors.accent,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  SizedBox(
                    height: 50.h,
                    child: FilledButton.icon(
                      onPressed: () => context.pushNamed(
                        AppRoute.quizReview.name,
                        queryParameters: savedAttemptId == null
                            ? const {}
                            : {'attemptId': savedAttemptId},
                        extra: result,
                      ),
                      icon: Icon(Icons.fact_check_outlined, size: 19.w),
                      label: const Text('Review answers'),
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                      ),
                    ),
                  ),
                  if (result != null && !isPassed) ...[
                    SizedBox(height: 12.h),
                    QuizRetryButton(quizId: result.quizId),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ResultSummary extends StatelessWidget {
  const _ResultSummary({
    required this.passed,
    required this.percentage,
    required this.quizTitle,
  });

  final bool passed;
  final int percentage;
  final String? quizTitle;

  @override
  Widget build(BuildContext context) {
    final color = passed ? AppColors.success : AppColors.error;
    return Column(
      children: [
        Container(
          width: 72.w,
          height: 72.w,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            passed ? Icons.emoji_events_outlined : Icons.replay_rounded,
            size: 34.w,
            color: color,
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          passed ? 'Assessment passed' : 'Keep practicing',
          textAlign: TextAlign.center,
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 22.sp,
            color: AppColors.onBackground,
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          quizTitle == null
              ? 'You completed this assessment with $percentage% accuracy.'
              : '$quizTitle · $percentage% accuracy',
          textAlign: TextAlign.center,
          style: AppTextStyles.interRegular14.copyWith(
            fontSize: 13.sp,
            height: 1.4,
            color: AppColors.grey600,
          ),
        ),
      ],
    );
  }
}

class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36.w,
        height: 36.w,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(icon, color: color, size: 19.w),
      ),
      SizedBox(width: 12.w),
      Expanded(
        child: Text(
          label,
          style: AppTextStyles.interRegular14.copyWith(
            fontSize: 13.sp,
            color: AppColors.grey600,
          ),
        ),
      ),
      SizedBox(width: 12.w),
      Text(
        value,
        textAlign: TextAlign.right,
        style: AppTextStyles.interSemiBold16.copyWith(
          fontSize: 14.sp,
          color: AppColors.onBackground,
        ),
      ),
    ],
  );
}

class _ResultState extends StatelessWidget {
  const _ResultState({this.message, this.loading = false});

  final String? message;
  final bool loading;

  @override
  Widget build(BuildContext context) => AppScaffold(
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: Center(
      child: loading
          ? const CircularProgressIndicator()
          : Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Text(
                message ?? 'Result unavailable',
                textAlign: TextAlign.center,
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ),
    ),
  );
}
