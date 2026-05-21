import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class QuizCard extends StatelessWidget {
  final QuizModel quiz;

  const QuizCard({super.key, required this.quiz});

  @override
  Widget build(BuildContext context) {
    final isAttempted = quiz.score != null;
    final categoryColor = quiz.isAiGenerated ? const Color(0xFF9333EA) : const Color(0xFF1976D2);
    final categoryBgColor = quiz.isAiGenerated ? const Color(0xFFF3E8FF) : const Color(0xFFE3F2FD);
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: categoryBgColor,
                    borderRadius: BorderRadius.circular(100.r),
                  ),
                  child: Text(
                    quiz.category,
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 10.sp,
                      color: categoryColor,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  quiz.title,
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 16.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 16.h),
                Divider(color: const Color(0xFFDADCE0), height: 1.h, thickness: 1.h),
                SizedBox(height: 16.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description_outlined, color: AppColors.grey500, size: 16.w),
                        SizedBox(width: 6.w),
                        Text(
                          '${quiz.totalQuestions} Questions',
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                    isAttempted
                        ? Row(
                            children: [
                              Text(
                                'Score: ',
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.grey500,
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(8.r),
                                ),
                                child: Text(
                                  quiz.score!,
                                  style: AppTextStyles.interBold24.copyWith(
                                    fontSize: 12.sp,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF3E0),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Text(
                              'Not Attempted',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                fontSize: 10.sp,
                                color: const Color(0xFFF57C00),
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
          if (quiz.isAiGenerated)
            Positioned(
              top: -1, // Shift up by 1 to cover border
              right: -1, // Shift right by 1 to cover border
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF7E22CE), // Dark purple for badge
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(16.r),
                    bottomLeft: Radius.circular(12.r),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 12.w),
                    SizedBox(width: 4.w),
                    Text(
                      'AI Generated',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        fontSize: 10.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
