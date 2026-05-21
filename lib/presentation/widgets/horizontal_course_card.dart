import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class HorizontalCourseCard extends StatelessWidget {
  final CourseModel course;

  const HorizontalCourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final progressPct = (course.progress ?? 0) * 100;
    
    return Container(
      width: double.infinity,
      height: 120.h,
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.horizontal(left: Radius.circular(16.r)),
            child: Image.asset(
              course.imagePath,
              width: 130.w,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    course.title,
                    style: AppTextStyles.interBold24.copyWith(
                      fontSize: 16.sp,
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
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 12.sp,
                          color: AppColors.grey500,
                        ),
                      ),
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
          ),
        ],
      ),
    );
  }
}
