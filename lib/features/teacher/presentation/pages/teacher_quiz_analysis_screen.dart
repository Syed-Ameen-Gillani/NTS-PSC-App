import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_quiz_analysis_provider.dart';
import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';

class TeacherQuizAnalysisScreen extends ConsumerWidget {
  const TeacherQuizAnalysisScreen({super.key, required this.quiz});

  final QuizModel quiz;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    void refresh() => ref.invalidate(teacherQuizSummaryProvider(quiz.id));

    return AppScaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(Icons.arrow_back_ios_new, size: 20.w),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Quiz Analysis',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: colors.onSurface,
          ),
        ),
        actions: AppConfig.isSupabaseEnabled
            ? [
                IconButton(
                  tooltip: 'Refresh analysis',
                  icon: const Icon(Icons.refresh),
                  onPressed: refresh,
                ),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _QuizHeader(quiz: quiz),
                    SizedBox(height: 28.h),
                    _QuizSetup(quiz: quiz),
                    SizedBox(height: 34.h),
                    Text(
                      'Results',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 18.sp,
                        color: colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (!AppConfig.isSupabaseEnabled)
                      const _ResultsNotice(
                        title: 'Live results unavailable',
                        message: 'Performance appears with live quiz attempts.',
                      )
                    else
                      ref
                          .watch(teacherQuizSummaryProvider(quiz.id))
                          .when(
                            loading: () => const _ResultsLoading(),
                            error: (_, _) => _ResultsNotice(
                              title: 'Results unavailable',
                              message: 'Could not load quiz performance.',
                              onRetry: refresh,
                            ),
                            data: (summary) => summary.attempts == 0
                                ? _ResultsEmpty(isPublished: quiz.isPublished)
                                : _ResultsPanel(
                                    attempts: summary.attempts,
                                    averagePercent: summary.averagePercent,
                                    passMark: quiz.passingScore,
                                  ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuizHeader extends StatelessWidget {
  const _QuizHeader({required this.quiz});

  final QuizModel quiz;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 5.h),
              decoration: BoxDecoration(
                color: quiz.isPublished
                    ? colors.primaryContainer
                    : colors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(5.r),
              ),
              child: Text(
                quiz.isPublished ? 'Published' : 'Draft',
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 11.sp,
                  color: quiz.isPublished
                      ? colors.onPrimaryContainer
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                quiz.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          quiz.title,
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 23.sp,
            color: colors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _QuizSetup extends StatelessWidget {
  const _QuizSetup({required this.quiz});

  final QuizModel quiz;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 17.h),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.grey300, width: 1.w),
          bottom: BorderSide(color: AppColors.grey300, width: 1.w),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SetupFact(
              label: 'Questions',
              value: '${quiz.totalQuestions}',
            ),
          ),
          _FactDivider(),
          Expanded(
            child: _SetupFact(
              label: 'Duration',
              value: '${quiz.durationMinutes} min',
            ),
          ),
          _FactDivider(),
          Expanded(
            child: _SetupFact(
              label: 'Pass mark',
              value: '${quiz.passingScore}%',
            ),
          ),
        ],
      ),
    );
  }
}

class _FactDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 32.h, width: 1.w, color: AppColors.grey300);
}

class _SetupFact extends StatelessWidget {
  const _SetupFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 17.sp,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            label,
            maxLines: 1,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 11.sp,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsPanel extends StatelessWidget {
  const _ResultsPanel({
    required this.attempts,
    required this.averagePercent,
    required this.passMark,
  });

  final int attempts;
  final double averagePercent;
  final int passMark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _ResultFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Average score',
                      style: AppTextStyles.interMedium16.copyWith(
                        fontSize: 13.sp,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      '${averagePercent.toStringAsFixed(1)}%',
                      style: AppTextStyles.interBold30.copyWith(
                        fontSize: 34.sp,
                        color: colors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$attempts',
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 18.sp,
                      color: colors.onSurface,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Attempts',
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 12.sp,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 25.h),
          _ScoreScale(score: averagePercent, passMark: passMark),
        ],
      ),
    );
  }
}

class _ScoreScale extends StatelessWidget {
  const _ScoreScale({required this.score, required this.passMark});

  final double score;
  final int passMark;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final threshold = (passMark / 100).clamp(0.0, 1.0);
        return Column(
          children: [
            SizedBox(
              height: 12.h,
              child: Stack(
                children: [
                  Positioned.fill(
                    top: 3.h,
                    bottom: 3.h,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.grey300,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 3.h,
                    left: 0,
                    bottom: 3.h,
                    width: width * (score / 100).clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                  ),
                  Positioned(
                    left: (width * threshold - 1.w).clamp(0.0, width - 2.w),
                    top: 0,
                    bottom: 0,
                    child: Container(width: 2.w, color: AppColors.grey300),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8.h),
            Row(
              children: [
                Text('0', style: _scaleLabel(colors)),
                const Spacer(),
                Text('Pass mark $passMark%', style: _scaleLabel(colors)),
                const Spacer(),
                Text('100', style: _scaleLabel(colors)),
              ],
            ),
          ],
        );
      },
    );
  }

  TextStyle _scaleLabel(ColorScheme colors) => AppTextStyles.interRegular14
      .copyWith(fontSize: 11.sp, color: colors.onSurfaceVariant);
}

class _ResultsEmpty extends StatelessWidget {
  const _ResultsEmpty({required this.isPublished});

  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0 attempts',
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 18.sp,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            isPublished
                ? 'Scores will appear after students complete this quiz.'
                : 'Publish and link this quiz to collect results.',
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 13.sp,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsNotice extends StatelessWidget {
  const _ResultsNotice({
    required this.title,
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return _ResultFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.bar_chart_outlined, size: 25.w, color: colors.primary),
          SizedBox(height: 14.h),
          Text(
            title,
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 16.sp,
              color: colors.onSurface,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            message,
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 13.sp,
              color: colors.onSurfaceVariant,
            ),
          ),
          if (onRetry != null) ...[
            SizedBox(height: 12.h),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    );
  }
}

class _ResultsLoading extends StatelessWidget {
  const _ResultsLoading();

  @override
  Widget build(BuildContext context) => _ResultFrame(
    child: Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: const Center(child: CircularProgressIndicator()),
    ),
  );
}

class _ResultFrame extends StatelessWidget {
  const _ResultFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(20.w),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      border: Border.all(color: AppColors.grey300, width: 1.w),
      borderRadius: BorderRadius.circular(8.r),
    ),
    child: child,
  );
}
