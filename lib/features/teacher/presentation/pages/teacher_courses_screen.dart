import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';

class TeacherCoursesScreen extends ConsumerStatefulWidget {
  const TeacherCoursesScreen({super.key});

  @override
  ConsumerState<TeacherCoursesScreen> createState() => _TeacherCoursesScreenState();
}

class _TeacherCoursesScreenState extends ConsumerState<TeacherCoursesScreen> {
  int _selectedFilter = 0; // 0: Published, 1: Drafts

  @override
  Widget build(BuildContext context) {
    final teacherState = ref.watch(teacherControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Course Studio',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            onPressed: () => context.pushNamed(AppRoute.teacherCreateCourse.name),
          ),
          SizedBox(width: 8.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: SafeArea(
        child: teacherState.when(
          data: (state) {
            final courses = state.courses;

            return Column(
              children: [
                // Filter Tabs
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                  child: Row(
                    children: [
                      _buildTabChip('Published (${courses.length})', 0),
                      SizedBox(width: 12.w),
                      _buildTabChip('Drafts (1)', 1),
                    ],
                  ),
                ),

                // Courses List
                Expanded(
                  child: courses.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.school_outlined, size: 48.w, color: AppColors.grey400),
                              SizedBox(height: 12.h),
                              Text(
                                'No courses published yet.',
                                style: AppTextStyles.interMedium16.copyWith(color: AppColors.grey500),
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 8.h),
                          itemCount: courses.length,
                          separatorBuilder: (context, index) => SizedBox(height: 16.h),
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            return InkWell(
                              onTap: () => context.pushNamed(AppRoute.teacherManageCourse.name, extra: course),
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(color: AppColors.grey300, width: 1.w),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10.r),
                                          child: Image.asset(
                                            course.imagePath,
                                            width: 90.w,
                                            height: 70.h,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        SizedBox(width: 12.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surface,
                                                      borderRadius: BorderRadius.circular(4.r),
                                                    ),
                                                    child: Text(
                                                      course.category,
                                                      style: AppTextStyles.interSemiBold16.copyWith(
                                                        fontSize: 10.sp,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    course.price,
                                                    style: AppTextStyles.interBold24.copyWith(
                                                      fontSize: 13.sp,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                course.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: AppTextStyles.interBold24.copyWith(
                                                  fontSize: 14.sp,
                                                  color: AppColors.onBackground,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12.h),
                                    Divider(height: 1.h, color: AppColors.grey300),
                                    SizedBox(height: 8.h),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Wrap(
                                            spacing: 8.w,
                                            runSpacing: 4.h,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.people_outline, size: 14.w, color: AppColors.grey500),
                                                  SizedBox(width: 3.w),
                                                  Text(
                                                    '${course.enrolledCount}',
                                                    style: AppTextStyles.interRegular14.copyWith(
                                                      fontSize: 11.sp,
                                                      color: AppColors.grey500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(Icons.menu_book_outlined, size: 14.w, color: AppColors.grey500),
                                                  SizedBox(width: 3.w),
                                                  Text(
                                                    '${course.modules.length} Mods',
                                                    style: AppTextStyles.interRegular14.copyWith(
                                                      fontSize: 11.sp,
                                                      color: AppColors.grey500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            InkWell(
                                              borderRadius: BorderRadius.circular(6.r),
                                              onTap: () {
                                                context.pushNamed(AppRoute.courseDetail.name, extra: course);
                                              },
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
                                                child: Text(
                                                  'View',
                                                  style: AppTextStyles.interSemiBold16.copyWith(
                                                    fontSize: 12.sp,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 4.w),
                                            InkWell(
                                              borderRadius: BorderRadius.circular(6.r),
                                              onTap: () {
                                                context.pushNamed(AppRoute.teacherManageCourse.name, extra: course);
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                                decoration: BoxDecoration(
                                                  color: AppColors.surface,
                                                  borderRadius: BorderRadius.circular(6.r),
                                                ),
                                                child: Text(
                                                  'Manage',
                                                  style: AppTextStyles.interSemiBold16.copyWith(
                                                    fontSize: 11.sp,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Center(child: Text('Error loading courses')),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'teacher_courses_fab',
        backgroundColor: AppColors.primary,
        onPressed: () => context.pushNamed(AppRoute.teacherCreateCourse.name),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'New Course',
          style: AppTextStyles.interSemiBold16.copyWith(
            fontSize: 14.sp,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.grey100,
          borderRadius: BorderRadius.circular(50.r),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: 1.w,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.interSemiBold16.copyWith(
            fontSize: 13.sp,
            color: isSelected ? Colors.white : AppColors.grey500,
          ),
        ),
      ),
    );
  }
}
