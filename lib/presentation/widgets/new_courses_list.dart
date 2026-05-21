import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class NewCoursesList extends StatelessWidget {
  final String title;
  final List<CourseModel> courses;

  const NewCoursesList({
    super.key,
    required this.title,
    required this.courses,
  });

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Text(
            title,
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 18.sp,
              color: AppColors.onBackground,
            ),
          ),
        ),
        SizedBox(height: 16.h),
        ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          itemCount: courses.length,
          separatorBuilder: (context, index) => SizedBox(height: 16.h),
          itemBuilder: (context, index) {
            final course = courses[index];
            return Container(
              height: 96.h,
              width: double.infinity, // Width expands to fill horizontal space, mirroring the 343px width proportionally
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
                      width: 120.w,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
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
                              SizedBox(height: 2.h),
                              Text(
                                course.author,
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.grey500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.star_border, color: Colors.orange, size: 16.w),
                                  SizedBox(width: 4.w),
                                  Text(
                                    course.rating.toString(),
                                    style: AppTextStyles.interMedium16.copyWith(
                                      fontSize: 12.sp,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                course.price,
                                style: AppTextStyles.interBold24.copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
