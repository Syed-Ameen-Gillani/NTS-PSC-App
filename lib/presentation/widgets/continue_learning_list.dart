import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/presentation/widgets/dashboard_course_cover.dart';

class ContinueLearningList extends StatelessWidget {
  final List<CourseModel> courses;
  final VoidCallback? onSeeAll;

  const ContinueLearningList({super.key, required this.courses, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();
    final scaler = MediaQuery.textScalerOf(context);
    final cardHeight = math.max(
      275.h,
      132.h +
          24.w +
          scaler.scale(14.sp) * 1.5 +
          scaler.scale(12.sp) * 3 +
          28.h +
          4.w,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Continue Learning',
                  style: AppTextStyles.interBold24.copyWith(
                    fontSize: 18.sp,
                    color: AppColors.onBackground,
                  ),
                ),
              ),
              if (onSeeAll != null)
                TextButton(onPressed: onSeeAll, child: const Text('See All')),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: cardHeight,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final course = courses[index];
              final progress = (course.progress ?? 0).clamp(0.0, 1.0);
              final progressPct = progress * 100;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16.r),
                  onTap: () => context.pushNamed(
                    AppRoute.courseDetail.name,
                    queryParameters: {'courseId': course.id},
                  ),
                  child: Ink(
                    width: 260.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(0xFFDADCE0),
                        width: 1.w,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(16.r),
                          ),
                          child: DashboardCourseCover(
                            imagePath: course.imagePath,
                            coverUrl: course.coverUrl,
                            width: 258.w,
                            height: 132.h,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.all(12.w),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                course.title,
                                style: AppTextStyles.interBold24.copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.onBackground,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                course.author,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.grey500,
                                ),
                              ),
                              SizedBox(height: 12.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Lesson progress',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.interRegular14
                                          .copyWith(
                                            fontSize: 12.sp,
                                            color: AppColors.grey500,
                                          ),
                                    ),
                                  ),
                                  SizedBox(width: 8.w),
                                  Text(
                                    '${progressPct.toInt()}%',
                                    style: AppTextStyles.interMedium16.copyWith(
                                      fontSize: 12.sp,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8.h),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: AppColors.grey300,
                                color: AppColors.primary,
                                minHeight: 4.h,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
