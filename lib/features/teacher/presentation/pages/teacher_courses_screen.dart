import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:nts_psc_app/presentation/widgets/dashboard_course_cover.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/home/domain/course_view_mode.dart';

class TeacherCoursesScreen extends ConsumerWidget {
  const TeacherCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherControllerProvider);

    return DefaultTabController(
      length: 2,
      child: AppScaffold(
        backgroundColor: const Color(0xFFF8FAFC),
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
        ),
        body: SafeArea(
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: AppColors.grey300, width: 1.h),
                  ),
                ),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  labelPadding: EdgeInsets.symmetric(horizontal: 12.w),
                  indicatorColor: AppColors.primary,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorWeight: 3.h,
                  dividerColor: Colors.transparent,
                  labelStyle: AppTextStyles.interMedium16.copyWith(
                    fontSize: 14.sp,
                  ),
                  unselectedLabelStyle: AppTextStyles.interRegular14.copyWith(
                    fontSize: 14.sp,
                  ),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.grey600,
                  tabs: const [
                    Tab(text: 'Published'),
                    Tab(text: 'Drafts'),
                  ],
                ),
              ),
              Expanded(
                child: teacherState.when(
                  data: (state) {
                    final published = state.courses
                        .where((course) => course.isPublished)
                        .toList();
                    final drafts = state.courses
                        .where((course) => !course.isPublished)
                        .toList();

                    return TabBarView(
                      children: [
                        _buildCourseList(
                          context,
                          published,
                          emptyMessage: 'No courses published yet.',
                        ),
                        _buildCourseList(
                          context,
                          drafts,
                          emptyMessage: 'No draft courses.',
                        ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) =>
                      const Center(child: Text('Error loading courses')),
                ),
              ),
            ],
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
      ),
    );
  }

  Widget _buildCourseList(
    BuildContext context,
    List<CourseModel> courses, {
    required String emptyMessage,
  }) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school_outlined, size: 48.w, color: AppColors.grey400),
            SizedBox(height: 12.h),
            Text(
              emptyMessage,
              style: AppTextStyles.interMedium16.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 104.h),
      itemCount: courses.length,
      separatorBuilder: (context, index) => SizedBox(height: 12.h),
      itemBuilder: (context, index) =>
          _buildCourseCard(context, courses[index]),
    );
  }

  Widget _buildCourseCard(BuildContext context, CourseModel course) {
    final moduleCount = course.modules.length;
    final lessonCount = course.modules.fold<int>(
      0,
      (sum, m) => sum + m.lessons.length,
    );
    final isFree = course.price.trim().toLowerCase() == 'free';
    final isPublished = course.isPublished;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pushNamed(
            AppRoute.teacherManageCourse.name,
            extra: course,
          ),
          borderRadius: BorderRadius.circular(14.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP IDENTITY TIER (Coursera / Udemy Style Header)
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 10.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 92.w,
                      height: 72.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1.w,
                        ),
                        color: const Color(0xFFF1F5F9),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9.r),
                        child: DashboardCourseCover(
                          imagePath: course.imagePath,
                          coverUrl: course.coverUrl,
                          width: 92.w,
                          height: 72.h,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 6.w,
                                    vertical: 2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(4.r),
                                  ),
                                  child: Text(
                                    course.category.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.interBold24.copyWith(
                                      fontSize: 9.5.sp,
                                      letterSpacing: 0.3,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 7.w,
                                  vertical: 2.h,
                                ),
                                decoration: BoxDecoration(
                                  color: isPublished
                                      ? const Color(0xFFDCFCE7)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 5.w,
                                      height: 5.w,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isPublished
                                            ? const Color(0xFF16A34A)
                                            : const Color(0xFFD97706),
                                      ),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      isPublished ? 'LIVE' : 'DRAFT',
                                      style: AppTextStyles.interBold24.copyWith(
                                        fontSize: 9.sp,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                        color: isPublished
                                            ? const Color(0xFF166534)
                                            : const Color(0xFF92400E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            course.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interSemiBold16.copyWith(
                              fontSize: 14.5.sp,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),
                          SizedBox(height: 5.h),
                          Text(
                            isFree ? 'Free course' : course.price,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.interRegular14.copyWith(
                              fontSize: 11.5.sp,
                              color: AppColors.grey500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Course structure at a glance.
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 12.w),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.w,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildMicroMetric(
                        icon: Icons.layers_outlined,
                        label:
                            '$moduleCount ${moduleCount == 1 ? 'Module' : 'Modules'}',
                      ),
                    ),
                    _buildMetricDivider(),
                    Expanded(
                      child: _buildMicroMetric(
                        icon: Icons.play_circle_outline,
                        label:
                            '$lessonCount ${lessonCount == 1 ? 'Lesson' : 'Lessons'}',
                      ),
                    ),
                    _buildMetricDivider(),
                    Expanded(
                      child: _buildMicroMetric(
                        icon: isPublished
                            ? Icons.people_outline
                            : Icons.checklist_outlined,
                        label: isPublished
                            ? '${course.enrolledCount} Learners'
                            : (course.modules.isNotEmpty
                                  ? 'Ready'
                                  : 'Not started'),
                      ),
                    ),
                  ],
                ),
              ),

              // Primary course actions.
              Padding(
                padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 12.h),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.pushNamed(
                            AppRoute.courseDetail.name,
                            extra: {
                              'course': course,
                              'viewMode': CourseViewMode.learnerPreview,
                            },
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                width: 1.w,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.visibility_outlined,
                                  size: 16.w,
                                  color: const Color(0xFF475569),
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    'Student preview',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.interMedium16.copyWith(
                                      fontSize: 12.sp,
                                      color: const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      flex: 5,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => context.pushNamed(
                            AppRoute.teacherManageCourse.name,
                            extra: course,
                          ),
                          borderRadius: BorderRadius.circular(8.r),
                          child: Container(
                            alignment: Alignment.center,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8.r),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune,
                                  size: 16.w,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    'Manage course',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.interSemiBold16
                                        .copyWith(
                                          fontSize: 12.sp,
                                          color: Colors.white,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMicroMetric({required IconData icon, required String label}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13.5.w, color: const Color(0xFF64748B)),
        SizedBox(width: 4.w),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.interMedium16.copyWith(
              fontSize: 10.5.sp,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricDivider() => Container(
    width: 1.w,
    height: 14.h,
    margin: EdgeInsets.symmetric(horizontal: 2.w),
    color: const Color(0xFFCBD5E1),
  );
}
