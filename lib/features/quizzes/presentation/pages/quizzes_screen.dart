import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/quizzes/presentation/controllers/quizzes_controller.dart';
import 'package:nts_psc_app/presentation/widgets/category_filter_chips.dart';
import 'package:nts_psc_app/presentation/widgets/quiz_card.dart';

class QuizzesScreen extends ConsumerWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quizzesStateAsync = ref.watch(quizzesControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: quizzesStateAsync.when(
          data: (state) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 24.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quizzes',
                          style: AppTextStyles.interBold30.copyWith(
                            fontSize: 24.sp,
                            color: AppColors.onBackground,
                          ),
                        ),
                        Icon(Icons.search, color: AppColors.onBackground, size: 28.w),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  
                  // Weekly Goal Card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Weekly Goal',
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.grey500,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                '5 / 10 Quizzes',
                                style: AppTextStyles.interBold24.copyWith(
                                  fontSize: 18.sp,
                                  color: AppColors.onBackground,
                                ),
                              ),
                            ],
                          ),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 48.w,
                                height: 48.w,
                                child: CircularProgressIndicator(
                                  value: 0.5,
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  color: const Color(0xFF10B981),
                                  strokeWidth: 4.w,
                                ),
                              ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '50',
                                    style: AppTextStyles.interBold24.copyWith(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF10B981),
                                      height: 1.0,
                                    ),
                                  ),
                                  Text(
                                    '%',
                                    style: AppTextStyles.interBold24.copyWith(
                                      fontSize: 10.sp,
                                      color: const Color(0xFF10B981),
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  const Divider(color: Color(0xFFE2E8F0), height: 1, thickness: 1),
                  SizedBox(height: 24.h),
                  
                  const CategoryFilterChips(
                    filters: ['All Quizzes', 'AI Generated', 'Attempted', 'Missed'],
                  ),
                  SizedBox(height: 24.h),
                  
                  // Personalized AI Quizzes Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Personalized AI Quizzes',
                          style: AppTextStyles.interBold24.copyWith(
                            fontSize: 18.sp,
                            color: AppColors.onBackground,
                          ),
                        ),
                        Text(
                          'Generate New',
                          style: AppTextStyles.interMedium16.copyWith(
                            fontSize: 14.sp,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ListView.separated(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.aiQuizzes.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      return QuizCard(quiz: state.aiQuizzes[index]);
                    },
                  ),
                  
                  SizedBox(height: 32.h),
                  
                  // Course Quizzes Header
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Text(
                      'Course Quizzes',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ListView.separated(
                    padding: EdgeInsets.only(left: 24.w, right: 24.w, bottom: 48.h),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.courseQuizzes.length,
                    separatorBuilder: (context, index) => SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      return QuizCard(quiz: state.courseQuizzes[index]);
                    },
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => const Center(child: Text('Error loading quizzes')),
        ),
      ),
    );
  }
}
