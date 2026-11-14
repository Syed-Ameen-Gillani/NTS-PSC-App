import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class QuizCard extends StatelessWidget {
  const QuizCard({super.key, required this.quiz});

  final QuizModel quiz;

  @override
  Widget build(BuildContext context) {
    final isAttempted = quiz.score != null;
    return Material(
      color: AppColors.grey100,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: () {
          if (AppConfig.isSupabaseEnabled && quiz.attemptId != null) {
            context.pushNamed(
              AppRoute.quizCompleted.name,
              queryParameters: {'attemptId': quiz.attemptId!},
            );
            return;
          }
          context.pushNamed(AppRoute.activeQuiz.name, extra: quiz);
        },
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.grey300, width: 1.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quiz.category,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 5.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          quiz.title,
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 15.sp,
                            color: AppColors.onBackground,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${quiz.totalQuestions} questions · ${quiz.durationMinutes} min · Pass ${quiz.passingScore}%',
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 9.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isAttempted
                          ? AppColors.success.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      isAttempted ? quiz.score! : 'Start',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 11.sp,
                        color: isAttempted
                            ? AppColors.success
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
