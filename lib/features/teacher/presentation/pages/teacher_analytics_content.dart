import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';

class TeacherAnalyticsScreen extends ConsumerWidget {
  const TeacherAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherControllerProvider);
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Analytics',
          style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(height: 1.h, color: AppColors.grey300),
        ),
      ),
      body: SafeArea(
        child: teacherState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) =>
              const Center(child: Text('Unable to load analytics')),
          data: (state) {
            final students = state.students;
            final courses = state.courses;
            final scoredStudents = students
                .where((s) => s.quizBreakdown.isNotEmpty)
                .toList();
            final averageScore = scoredStudents.isEmpty
                ? null
                : scoredStudents.fold<int>(
                        0,
                        (sum, s) => sum + s.averageQuizScore,
                      ) /
                      scoredStudents.length;
            final averageProgress = students.isEmpty
                ? null
                : students.fold<double>(0, (sum, s) => sum + s.progress) /
                      students.length;
            final needsAttention = students
                .where((s) => s.status == 'Needs Attention')
                .toList();
            final publishedCourses = courses
                .where((c) => c.isPublished)
                .toList();

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Teaching overview',
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 22.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        'Based on your courses and learner enrollments.',
                        style: AppTextStyles.interRegular14.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                      SizedBox(height: 24.h),
                      _summary(
                        AppConfig.isSupabaseEnabled
                            ? state.stats.totalStudents
                            : students.length,
                        publishedCourses.length,
                        averageProgress,
                        averageScore,
                      ),
                      SizedBox(height: 32.h),
                      _sectionHeading(
                        'Courses',
                        '${publishedCourses.length} published',
                      ),
                      SizedBox(height: 12.h),
                      if (courses.isEmpty)
                        _empty('No courses to analyze yet.')
                      else
                        for (final course in courses)
                          _courseRow(context, course),
                      SizedBox(height: 28.h),
                      if (!AppConfig.isSupabaseEnabled) ...[
                        _sectionHeading(
                          'Learners to review',
                          '${needsAttention.length} flagged',
                        ),
                        SizedBox(height: 6.h),
                        if (needsAttention.isEmpty)
                          _empty('No learners are marked as needing attention.')
                        else
                          for (final student in needsAttention)
                            _studentRow(context, student),
                      ],
                      SizedBox(height: 12.h),
                      TextButton.icon(
                        onPressed: () =>
                            context.pushNamed(AppRoute.teacherStudents.name),
                        icon: const Icon(Icons.arrow_forward, size: 18),
                        label: const Text('View all learners'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _summary(
    int learners,
    int published,
    double? progress,
    double? score,
  ) {
    final entries = [
      ('Learners', '$learners', Icons.people_outline),
      ('Published courses', '$published', Icons.menu_book_outlined),
      (
        'Average progress',
        progress == null ? '--' : '${(progress * 100).round()}%',
        Icons.trending_up,
      ),
      (
        'Average quiz score',
        score == null ? '--' : '${score.round()}%',
        Icons.quiz_outlined,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 600 ? 4 : 2;
        final gap = 12.w;
        final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final entry in entries)
              SizedBox(
                width: width,
                child: Container(
                  padding: EdgeInsets.all(14.w),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    border: Border.all(color: AppColors.grey300),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(entry.$3, size: 19.w, color: AppColors.primary),
                      SizedBox(height: 12.h),
                      Text(
                        entry.$2,
                        style: AppTextStyles.interBold24.copyWith(
                          fontSize: 20.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        entry.$1,
                        style: AppTextStyles.interRegular14.copyWith(
                          fontSize: 11.sp,
                          color: AppColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _sectionHeading(String title, String count) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 17.sp,
            color: AppColors.onBackground,
          ),
        ),
      ),
      Text(
        count,
        style: AppTextStyles.interRegular14.copyWith(
          fontSize: 12.sp,
          color: AppColors.grey500,
        ),
      ),
    ],
  );

  Widget _empty(String message) => Padding(
    padding: EdgeInsets.symmetric(vertical: 18.h),
    child: Text(
      message,
      style: AppTextStyles.interRegular14.copyWith(color: AppColors.grey500),
    ),
  );

  Widget _courseRow(BuildContext context, CourseModel course) {
    final lessons = course.modules.fold<int>(
      0,
      (sum, m) => sum + m.lessons.length,
    );
    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            course.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.interSemiBold16.copyWith(fontSize: 14.sp),
          ),
          subtitle: Text(
            '${course.isPublished ? 'Published' : 'Draft'}  |  ${course.enrolledCount} learners  |  $lessons lessons',
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 11.sp,
              color: AppColors.grey500,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
          onTap: () => context.pushNamed(
            AppRoute.teacherManageCourse.name,
            extra: course,
          ),
        ),
        const Divider(height: 1, color: AppColors.grey300),
      ],
    );
  }

  Widget _studentRow(
    BuildContext context,
    StudentRosterModel student,
  ) => Column(
    children: [
      ListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          student.name,
          style: AppTextStyles.interSemiBold16.copyWith(fontSize: 14.sp),
        ),
        subtitle: Text(
          '${student.courseTitle}  |  ${(student.progress * 100).round()}% complete',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.interRegular14.copyWith(
            fontSize: 11.sp,
            color: AppColors.grey500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.grey400),
        onTap: () => context.pushNamed(
          AppRoute.teacherStudents.name,
          extra: student.courseTitle,
        ),
      ),
      const Divider(height: 1, color: AppColors.grey300),
    ],
  );
}
