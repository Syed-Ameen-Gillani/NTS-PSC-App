import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_instructor_provider.dart';
import 'package:nts_psc_app/presentation/widgets/app_avatar.dart';

class CourseInstructorTab extends ConsumerWidget {
  const CourseInstructorTab({super.key, required this.course});

  final CourseModel course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(courseInstructorProvider(course.instructorId));
    return profile.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(
        child: TextButton(
          onPressed: () =>
              ref.invalidate(courseInstructorProvider(course.instructorId)),
          child: const Text('Retry instructor details'),
        ),
      ),
      data: (teacher) => SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppAvatar(
                  size: 72.w,
                  imagePath: teacher?.imagePath ?? '',
                  name: teacher?.name ?? course.author,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher?.name ?? course.author,
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 18.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                      if (teacher != null &&
                          teacher.subject.trim().isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          teacher.subject,
                          style: AppTextStyles.interRegular14.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      if (teacher != null &&
                          teacher.qualification.trim().isNotEmpty) ...[
                        SizedBox(height: 4.h),
                        Text(
                          teacher.qualification,
                          style: AppTextStyles.interRegular14.copyWith(
                            color: AppColors.grey700,
                          ),
                        ),
                      ],
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
              teacher != null && teacher.bio.trim().isNotEmpty
                  ? teacher.bio
                  : 'No instructor biography added yet.',
              style: AppTextStyles.interRegular14.copyWith(
                color: AppColors.grey700,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
