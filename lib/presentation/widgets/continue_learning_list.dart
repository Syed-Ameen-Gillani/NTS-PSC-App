import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class ContinueLearningList extends StatelessWidget {
  final List<CourseModel> courses;

  const ContinueLearningList({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            'Continue Learning',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 18.sp,
              color: AppColors.onBackground,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          height: 260.h, // Slightly larger than 258.38.h to prevent RenderFlex overflow
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            separatorBuilder: (context, index) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final course = courses[index];
              final progressPct = (course.progress ?? 0) * 100;
              return Container(
                width: 260.w, // width: 260
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA), // background: #F8F9FA
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: const Color(0xFFDADCE0), width: 1.w), // border: #DADCE0
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      child: Image.asset(
                        course.imagePath,
                        width: 258.w,
                        height: 145.h,
                        fit: BoxFit.cover,
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
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 12.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Text(
                                'Progress',
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.grey500,
                                ),
                              ),
                              SizedBox(width: 8.w), // Fixed smaller gap instead of spaceBetween
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
                            value: course.progress,
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
              );
            },
          ),
        ),
      ],
    );
  }
}
