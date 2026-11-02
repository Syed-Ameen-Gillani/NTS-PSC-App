import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';

class CurriculumAssessmentPicker extends ConsumerWidget {
  const CurriculumAssessmentPicker({
    super.key,
    required this.courseId,
    required this.kind,
  });

  final String courseId;
  final String kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isQuiz = kind == 'quiz';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sheet Header
              Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 12.w, 12.h),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        isQuiz
                            ? Icons.quiz_outlined
                            : Icons.assignment_outlined,
                        color: AppColors.primary,
                        size: 20.w,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isQuiz ? 'Link Existing Quiz' : 'Link Assignment',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 16.sp,
                              color: AppColors.onBackground,
                            ),
                          ),
                          Text(
                            'Attach to this lesson or create a new one',
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      icon: const Icon(Icons.close, color: AppColors.grey500),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1.h, color: AppColors.grey200),

              // Create New Call to Action Card
              Padding(
                padding: EdgeInsets.all(16.w),
                child: InkWell(
                  onTap: () => Navigator.pop(context, 'create'),
                  borderRadius: BorderRadius.circular(10.r),
                  child: Container(
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16.r,
                          backgroundColor: AppColors.primary,
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create New ${isQuiz ? "Quiz" : "Assignment"}',
                                style: AppTextStyles.interSemiBold16.copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                isQuiz
                                    ? 'Build multiple choice questions or use AI'
                                    : 'Create writing task, instructions & rubrics',
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 11.sp,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
                child: Text(
                  'AVAILABLE ${isQuiz ? "QUIZZES" : "ASSIGNMENTS"}',
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 11.sp,
                    color: AppColors.grey500,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              Expanded(
                child: ref
                    .watch(curriculumCandidatesProvider(courseId))
                    .when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (_, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Could not load candidate assessments',
                              style: AppTextStyles.interRegular14.copyWith(
                                color: AppColors.grey600,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            TextButton.icon(
                              onPressed: () => ref.invalidate(
                                curriculumCandidatesProvider(courseId),
                              ),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                      data: (all) {
                        final items = all
                            .where((item) => item.kind == kind)
                            .toList();
                        if (items.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(24.w),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(16.w),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isQuiz
                                          ? Icons.quiz_outlined
                                          : Icons.assignment_outlined,
                                      size: 36.w,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  SizedBox(height: 14.h),
                                  Text(
                                    'No existing ${isQuiz ? "quizzes" : "assignments"} found',
                                    style: AppTextStyles.interMedium16.copyWith(
                                      fontSize: 14.sp,
                                      color: AppColors.grey700,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'Tap above to create one now.',
                                    style: AppTextStyles.interRegular14
                                        .copyWith(
                                          fontSize: 12.sp,
                                          color: AppColors.grey500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.w,
                            vertical: 8.h,
                          ),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => SizedBox(height: 8.h),
                          itemBuilder: (_, index) {
                            final item = items[index];
                            final isPublished = item.status == 'published';
                            return InkWell(
                              onTap: () => Navigator.pop(context, item),
                              borderRadius: BorderRadius.circular(8.r),
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: AppColors.grey100,
                                  borderRadius: BorderRadius.circular(8.r),
                                  border: Border.all(color: AppColors.grey200),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6.w),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Icon(
                                        isQuiz
                                            ? Icons.quiz_outlined
                                            : Icons.assignment_outlined,
                                        color: AppColors.primary,
                                        size: 20.w,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: AppTextStyles.interMedium16
                                                .copyWith(
                                                  fontSize: 13.sp,
                                                  color: AppColors.onBackground,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 2.h),
                                          Text(
                                            'Status: ${item.status.toUpperCase()}',
                                            style: AppTextStyles.interRegular14
                                                .copyWith(
                                                  fontSize: 11.sp,
                                                  color: isPublished
                                                      ? const Color(0xFF2E7D32)
                                                      : AppColors.grey500,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10.w,
                                        vertical: 4.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6.r,
                                        ),
                                      ),
                                      child: Text(
                                        'Select',
                                        style: AppTextStyles.interSemiBold16
                                            .copyWith(
                                              fontSize: 12.sp,
                                              color: AppColors.primary,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
