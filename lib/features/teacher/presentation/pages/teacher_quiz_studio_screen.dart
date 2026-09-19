import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/quiz_item_analysis_sheet.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherQuizStudioScreen extends ConsumerWidget {
  const TeacherQuizStudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Assessment Studio',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => context.pushNamed(AppRoute.teacherCreateQuiz.name),
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: teacherState.when(
          data: (state) {
            final quizzes = state.quizzes;

            if (quizzes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.quiz_outlined, size: 48.w, color: AppColors.grey400),
                    SizedBox(height: 12.h),
                    Text(
                      'No mock quizzes created yet.',
                      style: AppTextStyles.interMedium16.copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: EdgeInsets.all(24.w),
              itemCount: quizzes.length,
              separatorBuilder: (context, index) => SizedBox(height: 16.h),
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return Container(
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: AppColors.grey300, width: 1.w),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              quiz.category,
                              style: AppTextStyles.interSemiBold16.copyWith(
                                fontSize: 11.sp,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          Text(
                            '${quiz.durationMinutes} mins',
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        quiz.title,
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 15.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                      SizedBox(height: 12.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 12.w,
                              runSpacing: 4.h,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.format_list_numbered, size: 16.w, color: AppColors.grey500),
                                    SizedBox(width: 4.w),
                                    Text(
                                      '${quiz.totalQuestions} Questions',
                                      style: AppTextStyles.interRegular14.copyWith(
                                        fontSize: 12.sp,
                                        color: AppColors.grey700,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_outlined, size: 16.w, color: AppColors.success),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Pass Mark: ${quiz.passingScore}%',
                                      style: AppTextStyles.interRegular14.copyWith(
                                        fontSize: 12.sp,
                                        color: AppColors.grey700,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                  minimumSize: Size(0, 28.h),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  CustomToast.showInfo(
                                    context,
                                    message: 'Question bank opened for ${quiz.title}',
                                  );
                                },
                                child: Text(
                                  'Edit MCQs',
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                  minimumSize: Size(0, 28.h),
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  QuizItemAnalysisSheet.show(context, quizTitle: quiz.title);
                                },
                                icon: Icon(Icons.analytics_outlined, size: 14.w, color: const Color(0xFF059669)),
                                label: Text(
                                  'Analysis',
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 11.sp,
                                    color: const Color(0xFF059669),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading quizzes')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'teacher_quiz_fab',
        backgroundColor: AppColors.primary,
        onPressed: () => context.pushNamed(AppRoute.teacherCreateQuiz.name),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Create Quiz',
          style: AppTextStyles.interSemiBold16.copyWith(
            fontSize: 14.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
