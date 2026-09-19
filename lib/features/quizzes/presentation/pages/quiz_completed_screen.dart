import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';

class QuizCompletedScreen extends ConsumerWidget {
  final QuizSubmissionResultModel? result;

  const QuizCompletedScreen({super.key, this.result});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = result?.totalQuestions ?? 4;
    final score = result?.score ?? 3;
    final percentage = total > 0 ? ((score / total) * 100).toInt() : 0;
    final isPassed = percentage >= 60;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.grey900, size: 24.w),
            onPressed: () => context.goNamed(AppRoute.main.name),
          ),
          SizedBox(width: 8.w),
        ],
        title: Text(
          'Assessment Results',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 18.sp,
            color: AppColors.grey900,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1.h,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 24.h),
              Container(
                width: 96.w,
                height: 96.w,
                decoration: BoxDecoration(
                  color: isPassed ? const Color(0xFFFFF7E6) : const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    isPassed ? Icons.emoji_events : Icons.refresh_rounded,
                    color: isPassed ? const Color(0xFFFA8C16) : AppColors.error,
                    size: 48.w,
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                isPassed ? 'Test Passed!' : 'Practice Makes Perfect!',
                textAlign: TextAlign.center,
                style: AppTextStyles.interBold30.copyWith(
                  fontSize: 26.sp,
                  color: AppColors.grey900,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                result != null
                    ? 'You have completed "${result!.quizTitle}" with $percentage% accuracy.'
                    : 'You have successfully completed the competitive practice challenge.',
                textAlign: TextAlign.center,
                style: AppTextStyles.interRegular14.copyWith(
                  color: AppColors.grey500,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 36.h),

              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Performance Breakdown',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.grey900,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    _buildSpecRow(
                      Icons.check_circle_outline,
                      'Score: $score / $total',
                      const Color(0xFF10B981),
                      const Color(0xFFD1FAE5),
                    ),
                    SizedBox(height: 14.h),
                    _buildSpecRow(
                      Icons.pie_chart_outline,
                      'Accuracy: $percentage%',
                      AppColors.primary,
                      const Color(0xFFE3F2FD),
                    ),
                    SizedBox(height: 14.h),
                    _buildSpecRow(
                      Icons.timer_outlined,
                      'Time Taken: 04:32',
                      const Color(0xFFF59E0B),
                      const Color(0xFFFEF3C7),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 36.h),

              // Action buttons
              CustomButton(
                text: 'Review Answers & Explanations',
                color: AppColors.primary,
                trailingIcon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                onPressed: () {
                  context.pushNamed(
                    AppRoute.quizReview.name,
                    extra: result,
                  );
                },
              ),
              SizedBox(height: 14.h),
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: OutlinedButton(
                  onPressed: () => context.goNamed(AppRoute.main.name),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.grey300, width: 1.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.r)),
                  ),
                  child: Text(
                    'Return to Dashboard',
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 15.sp,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpecRow(IconData icon, String text, Color iconColor, Color bgColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: bgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20.w),
        ),
        SizedBox(width: 12.w),
        Text(
          text,
          style: AppTextStyles.interMedium16.copyWith(
            fontSize: 15.sp,
            color: AppColors.grey700,
          ),
        ),
      ],
    );
  }
}
