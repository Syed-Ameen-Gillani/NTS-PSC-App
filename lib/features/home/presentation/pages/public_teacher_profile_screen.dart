import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:nts_psc_app/presentation/widgets/dashboard_course_cover.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/app_avatar.dart';

final publicTeacherCoursesProvider = FutureProvider.autoDispose
    .family<List<CourseModel>, String>((ref, teacherId) async {
      if (AppConfig.isSupabaseEnabled) {
        ref.watch(
          authControllerProvider.select((state) => state.value?.user?.id),
        );
        return (ref.read(courseRepositoryProvider) as SupabaseCourseRepository)
            .getPublicCoursesByTeacher(teacherId);
      }
      return (await ref.watch(teacherControllerProvider.future)).courses;
    });

class PublicTeacherProfileScreen extends ConsumerWidget {
  final TeacherModel? teacher;

  const PublicTeacherProfileScreen({super.key, this.teacher});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.isSupabaseEnabled && teacher == null) {
      return const AppScaffold(
        body: Center(child: Text('Instructor not found')),
      );
    }
    final t =
        teacher ??
        TeacherModel(
          id: 't1',
          name: 'Sir Tariq Mahmood',
          subject: 'Pakistan Affairs & Customs Law Specialist',
          imagePath: 'assets/images/teacher1.png',
          qualification: 'M.Phil Political Science / Ex-Civil Servant',
          rating: 4.9,
          studentCount: 1240,
        );

    final coursesState = ref.watch(publicTeacherCoursesProvider(t.id));

    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Faculty Profile',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 18.sp,
            color: AppColors.onBackground,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar & Name Card
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      AppAvatar(
                        size: 96.w,
                        imagePath: t.imagePath,
                        name: t.name,
                      ),
                      if (!AppConfig.isSupabaseEnabled)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified,
                              color: Colors.white,
                              size: 18.w,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Text(
                    t.name,
                    style: AppTextStyles.interBold24.copyWith(fontSize: 22.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    t.subject,
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 13.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  if (t.qualification.isNotEmpty)
                    Text(
                      t.qualification,
                      style: AppTextStyles.interRegular14.copyWith(
                        fontSize: 12.sp,
                        color: AppColors.grey500,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            // 3-Metric Row
            if (!AppConfig.isSupabaseEnabled)
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${t.rating} ★',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 18.sp,
                              color: Colors.amber.shade800,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Rating',
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '${t.studentCount}+',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 18.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Students',
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '6+',
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 18.sp,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Courses',
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 11.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            SizedBox(height: 24.h),

            // About Faculty Bio
            if (!AppConfig.isSupabaseEnabled || t.bio.isNotEmpty) ...[
              Text(
                'About Instructor',
                style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp),
              ),
              SizedBox(height: 8.h),
              Text(
                AppConfig.isSupabaseEnabled
                    ? t.bio
                    : 'Senior faculty member with over 10 years of mentoring candidates for FPSC, CSS, NTS, and Provincial PSC exams. Specializes in analytical syllabus breakdown, high-scoring essay techniques, and past paper screening strategies.',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 13.sp,
                  height: 1.5,
                  color: AppColors.grey700,
                ),
              ),
              SizedBox(height: 24.h),
            ],

            // Courses Taught
            Text(
              'Courses by ${t.name}',
              style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp),
            ),
            SizedBox(height: 12.h),

            coursesState.when(
              data: (courses) {
                if (courses.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Text(
                      'No published courses yet.',
                      style: AppTextStyles.interRegular14.copyWith(
                        color: AppColors.grey500,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: courses.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final course = courses[index];
                    return Container(
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: DashboardCourseCover(
                              imagePath: course.imagePath,
                              coverUrl: course.coverUrl,
                              width: 70.w,
                              height: 55.h,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 13.sp,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  AppConfig.isSupabaseEnabled
                                      ? course.price
                                      : '${course.price} • ${course.enrolledCount} Enrolled',
                                  style: AppTextStyles.interRegular14.copyWith(
                                    fontSize: 11.sp,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              size: 14,
                              color: AppColors.grey500,
                            ),
                            onPressed: () {
                              context.pushNamed(
                                AppRoute.courseDetail.name,
                                extra: course,
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => TextButton(
                onPressed: () =>
                    ref.invalidate(publicTeacherCoursesProvider(t.id)),
                child: const Text('Could not load courses. Retry'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
