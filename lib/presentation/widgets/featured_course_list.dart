import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';

class FeaturedCourseList extends StatelessWidget {
  final List<CourseModel> courses;

  const FeaturedCourseList({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 235.h, // Slightly larger than 231.8 to prevent overflow, or exactly 231.8.h
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        separatorBuilder: (context, index) => SizedBox(width: 16.w),
        itemBuilder: (context, index) {
          final course = courses[index];
          return Container(
            width: 220.w,
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: const Color(0xFFDADCE0), width: 1.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with Featured Badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                      child: Image.asset(
                        course.imagePath,
                        width: 218.w,
                        height: 122.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (course.isFeatured)
                      Positioned(
                        top: 12.h,
                        left: 12.w,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Featured',
                            style: AppTextStyles.interSemiBold16.copyWith(
                              color: Colors.white,
                              fontSize: 10.sp,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                // Content
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
                        maxLines: 2,
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
                          SizedBox(width: 16.w), // Fixed smaller gap instead of spaceBetween
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
              ],
            ),
          );
        },
      ),
    );
  }
}
