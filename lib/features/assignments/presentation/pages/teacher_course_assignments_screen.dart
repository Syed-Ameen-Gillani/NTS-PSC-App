import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_quiz_studio_screen.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';

class TeacherCourseAssignmentsScreen extends ConsumerWidget {
  final CourseModel? course;

  const TeacherCourseAssignmentsScreen({super.key, this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTeacher =
        (ref.watch(authControllerProvider).value?.user?.role ??
            ref.watch(authControllerProvider).value?.selectedRole) ==
        UserRole.teacher;
    final assignmentState = ref.watch(assignmentsControllerProvider);
    final teacherState = ref.watch(teacherControllerProvider);
    final quizzes =
        teacherState.value?.quizzes
            .where((item) => item.courseId == course?.id)
            .toList() ??
        const <QuizModel>[];
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20.w,
          ),
          onPressed: () => context.pop(),
        ),
        titleSpacing: 0,
        title: Text(
          'Assessments',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        actions: [
          if (isTeacher && course != null)
            PopupMenuButton<String>(
              tooltip: 'Add assessment',
              color: Theme.of(context).scaffoldBackgroundColor,
              icon: Icon(Icons.add, color: AppColors.primary, size: 24.w),
              onSelected: (type) => context.pushNamed(
                type == 'quiz'
                    ? AppRoute.teacherQuizStudio.name
                    : AppRoute.teacherCreateAssignment.name,
                extra: type == 'quiz'
                    ? {
                        'initialTab': 0,
                        'targetScope': CurriculumScope(courseId: course!.id),
                      }
                    : course,
              ),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'quiz', child: Text('Manage quizzes')),
                PopupMenuItem(
                  value: 'assignment',
                  child: Text('Create assignment'),
                ),
              ],
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: course == null
          ? const Center(child: Text('Course unavailable'))
          : !isTeacher
          ? const Center(child: Text('Teacher access only'))
          : assignmentState.when(
              data: (state) {
                final assignments = state.assignments
                    .where((item) => item.courseId == course!.id)
                    .toList();
                if (teacherState.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (teacherState.hasError) {
                  return const Center(
                    child: Text('Could not load assessments'),
                  );
                }
                if (quizzes.isEmpty && assignments.isEmpty) {
                  return const SafeArea(
                    child: Center(child: _AssessmentsEmptyState()),
                  );
                }
                return SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 16.h),
                        child: Text(
                          course!.title,
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 15.sp,
                            color: AppColors.grey700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 32.h),
                          children: [
                            if (quizzes.isNotEmpty) ...[
                              Text(
                                'Quizzes',
                                style: AppTextStyles.interSemiBold16,
                              ),
                              SizedBox(height: 12.h),
                              for (final quiz in quizzes) ...[
                                TeacherQuizListItem(quiz: quiz),
                                SizedBox(height: 12.h),
                              ],
                            ],
                            if (assignments.isNotEmpty) ...[
                              if (quizzes.isNotEmpty) SizedBox(height: 12.h),
                              Text(
                                'Assignments',
                                style: AppTextStyles.interSemiBold16,
                              ),
                              SizedBox(height: 12.h),
                              for (final assignment in assignments) ...[
                                _assignmentCard(context, state, assignment),
                                SizedBox(height: 12.h),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) =>
                  const Center(child: Text('Could not load assessments')),
            ),
    );
  }

  Widget _assignmentCard(
    BuildContext context,
    AssignmentsState state,
    AssignmentModel assignment,
  ) {
    final submissions = state.submissionsFor(assignment.id);
    final pending = submissions
        .where((item) => item.status == AssignmentReviewStatus.pending)
        .length;
    return InkWell(
      onTap: () => context.pushNamed(
        assignment.isPublished
            ? AppRoute.teacherReviewAssignment.name
            : AppRoute.teacherCreateAssignment.name,
        extra: assignment,
      ),
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.grey300, width: 1.w),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              assignment.title,
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 15.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Due ${MaterialLocalizations.of(context).formatMediumDate(assignment.dueAt)}',
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey500,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              '${submissions.length} submitted, $pending awaiting review',
              style: AppTextStyles.interMedium16.copyWith(
                fontSize: 12.sp,
                color: pending > 0 ? AppColors.primary : AppColors.grey700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AssessmentsEmptyState extends StatelessWidget {
  const _AssessmentsEmptyState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(24.w),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.fact_check_outlined, size: 42.w, color: AppColors.grey400),
        SizedBox(height: 10.h),
        Text(
          'No assessments yet',
          style: AppTextStyles.interSemiBold16.copyWith(
            fontSize: 15.sp,
            color: AppColors.onBackground,
          ),
        ),
        SizedBox(height: 3.h),
        Text(
          'Quizzes and assignments for this course will appear here.',
          textAlign: TextAlign.center,
          style: AppTextStyles.interRegular14.copyWith(
            fontSize: 12.sp,
            color: AppColors.grey500,
          ),
        ),
      ],
    ),
  );
}
