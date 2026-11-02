import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/presentation/widgets/dashboard_course_cover.dart';

class FeaturedCourseList extends StatelessWidget {
  final List<CourseModel> courses;

  const FeaturedCourseList({super.key, required this.courses});

  @override
  Widget build(BuildContext context) {
    if (courses.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: MediaQuery.textScalerOf(context).scale(246.h),
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        scrollDirection: Axis.horizontal,
        itemCount: courses.length,
        separatorBuilder: (context, index) => SizedBox(width: 16.w),
        itemBuilder: (context, index) {
          final course = courses[index];
          return InkWell(
            onTap: () {
              context.pushNamed(AppRoute.courseDetail.name, extra: course);
            },
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
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
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16.r),
                        ),
                        child: DashboardCourseCover(
                          imagePath: course.imagePath,
                        coverUrl: course.coverUrl,
                          width: 218.w,
                          height: 118.h,
                        ),
                      ),
                      if (course.isFeatured)
                        Positioned(
                          top: 12.h,
                          left: 12.w,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
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
                        Wrap(
                          spacing: 16.w,
                          runSpacing: 2.h,
                          children: [
                            if (course.rating > 0)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_border,
                                    color: Colors.orange,
                                    size: 16.w,
                                  ),
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
