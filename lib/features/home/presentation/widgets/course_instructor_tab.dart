import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class CourseInstructorTab extends StatelessWidget {
  final CourseModel course;

  const CourseInstructorTab({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 36.r,
                backgroundImage: const AssetImage('assets/images/teacher1.png'),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.author,
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 18.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'Senior Faculty & Competitive Exam Mentor',
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 13.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                        SizedBox(width: 4.w),
                        Text(
                          '${course.rating} Instructor Rating',
                          style: AppTextStyles.interMedium16.copyWith(
                            fontSize: 12.sp,
                            color: AppColors.grey700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          Text(
            'About Instructor',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 16.sp,
              color: AppColors.onBackground,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Specializing in competitive civil service exam mentoring for over 8 years. Personally guided hundreds of successful candidates in FPSC, PMS, CSS, and AJK PSC through focused lectures and diagnostic assessments.',
            style: AppTextStyles.interRegular16.copyWith(
              fontSize: 14.sp,
              color: AppColors.grey700,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
