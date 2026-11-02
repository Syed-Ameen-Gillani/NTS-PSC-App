import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/constants/app_assets.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/app_avatar.dart';
import 'package:nts_psc_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/notification_inbox_controller.dart';
import 'package:nts_psc_app/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:nts_psc_app/features/teacher/domain/models/teacher_insights_models.dart';
import 'package:nts_psc_app/features/teacher/data/teacher_insights_repository_provider.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/pages/teacher_main_screen.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/teacher_metric_grid.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/teacher_quick_actions.dart';

class TeacherDashboardScreen extends ConsumerWidget {
  const TeacherDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherState = ref.watch(teacherControllerProvider);
    final financial = ref.watch(teacherFinancialOverviewProvider);
    final profile = ref.watch(profileControllerProvider).value;

    return AppScaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: teacherState.when(
          data: (state) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(profileControllerProvider);
              ref.invalidate(teacherControllerProvider);
              ref.invalidate(teacherFinancialOverviewProvider);
              await ref.read(teacherControllerProvider.future);
            },
            child: ListView(
              padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 28.h),
              children: [
                _DashboardHeader(
                  name: profile?.name ?? 'Instructor',
                  imagePath: profile?.imagePath ?? AppAssets.teacher1,
                  unreadCount: ref.watch(notificationUnreadCountProvider),
                  onNotifications: () =>
                      context.pushNamed(AppRoute.notificationInbox.name),
                ),
                SizedBox(height: 24.h),
                _TeachingSummary(
                  learnerCount: state.stats.totalStudents,
                  courseCount: state.stats.activeCourses,
                  onManageCourses: () =>
                      ref.read(teacherMainTabProvider.notifier).select(1),
                ),
                SizedBox(height: 24.h),
                _SectionTitle(
                  title: 'Studio overview',
                  actionLabel: 'View analytics',
                  onAction: () =>
                      context.pushNamed(AppRoute.teacherAnalytics.name),
                ),
                SizedBox(height: 12.h),
                TeacherMetricGrid(
                  items: [
                    TeacherMetricItem(
                      label: 'Learners',
                      value: '${state.stats.totalStudents} enrolled',
                      icon: Icons.people_outline,
                      onTap: () =>
                          context.pushNamed(AppRoute.teacherStudents.name),
                    ),
                    TeacherMetricItem(
                      label: 'Courses',
                      value: '${state.stats.activeCourses} published',
                      icon: Icons.school_outlined,
                      onTap: () =>
                          ref.read(teacherMainTabProvider.notifier).select(1),
                    ),
                    TeacherMetricItem(
                      label: 'Assessments',
                      value: '${state.stats.totalQuizzes} quizzes',
                      icon: Icons.assignment_outlined,
                      onTap: () =>
                          ref.read(teacherMainTabProvider.notifier).select(2),
                    ),
                    TeacherMetricItem(
                      label: 'Earnings',
                      value: financial.when(
                        data: (overview) =>
                            overview.formatMinor(overview.netEarningsMinor),
                        loading: () => '…',
                        error: (_, _) => 'Unavailable',
                      ),
                      icon: Icons.account_balance_wallet_outlined,
                      onTap: () =>
                          context.pushNamed(AppRoute.teacherPayouts.name),
                    ),
                  ],
                ),
                SizedBox(height: 28.h),
                _SectionTitle(title: 'Quick actions'),
                SizedBox(height: 12.h),
                TeacherQuickActions(
                  onCreateCourse: () =>
                      context.pushNamed(AppRoute.teacherCreateCourse.name),
                  onCreateQuiz: () =>
                      context.pushNamed(AppRoute.teacherCreateQuiz.name),
                  onCreateAssignment: () =>
                      context.pushNamed(AppRoute.teacherCreateAssignment.name),
                ),
                SizedBox(height: 28.h),
                _SectionTitle(
                  title: 'Recent enrollments',
                  actionLabel: state.recentEnrollments.isEmpty
                      ? null
                      : 'View learners',
                  onAction: () =>
                      context.pushNamed(AppRoute.teacherStudents.name),
                ),
                SizedBox(height: 10.h),
                _RecentEnrollments(items: state.recentEnrollments),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: TextButton(
              onPressed: () => ref.invalidate(teacherControllerProvider),
              child: const Text('Could not load dashboard. Try again'),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({
    required this.name,
    required this.imagePath,
    required this.unreadCount,
    required this.onNotifications,
  });

  final String name;
  final String imagePath;
  final int unreadCount;
  final VoidCallback onNotifications;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Educora Studio',
                    style: AppTextStyles.interSemiBold16.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(Icons.verified, size: 14.w, color: AppColors.primary),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interBold24.copyWith(
                  fontSize: 22.sp,
                  color: AppColors.onBackground,
                ),
              ),
            ],
          ),
        ),
        NotificationBellButton(
          unreadCount: unreadCount,
          onPressed: onNotifications,
        ),
        SizedBox(width: 8.w),
        AppAvatar(size: 48.w, imagePath: imagePath, name: name),
      ],
    );
  }
}

class _TeachingSummary extends StatelessWidget {
  const _TeachingSummary({
    required this.learnerCount,
    required this.courseCount,
    required this.onManageCourses,
  });

  final int learnerCount;
  final int courseCount;
  final VoidCallback onManageCourses;

  @override
  Widget build(BuildContext context) {
    final hasActivity = learnerCount > 0 || courseCount > 0;
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasActivity
                ? 'Your teaching at a glance'
                : 'Build your first course',
            style: AppTextStyles.interSemiBold16.copyWith(
              fontSize: 13.sp,
              color: AppColors.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 7.h),
          Text(
            hasActivity
                ? '$learnerCount learners across $courseCount published courses'
                : 'Create a structured course, add lessons, then publish it to the catalog.',
            style: AppTextStyles.interBold24.copyWith(
              fontSize: 20.sp,
              height: 1.25,
              color: AppColors.onPrimary,
            ),
          ),
          SizedBox(height: 16.h),
          OutlinedButton(
            onPressed: onManageCourses,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.onPrimary,
              side: BorderSide(
                color: AppColors.onPrimary.withValues(alpha: 0.65),
              ),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text(
              hasActivity ? 'Manage courses' : 'Start a course',
              style: AppTextStyles.interSemiBold16.copyWith(fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.actionLabel, this.onAction});

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              minimumSize: Size(0, 40.h),
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _RecentEnrollments extends StatelessWidget {
  const _RecentEnrollments({required this.items});

  final List<RecentEnrollmentModel> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: AppColors.grey300, width: 1.w),
        ),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 30.w, color: AppColors.grey400),
            SizedBox(height: 10.h),
            Text(
              'No enrollments yet',
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 14.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'New learners will appear here after joining your courses.',
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

    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _EnrollmentRow(item: items[index]),
          if (index != items.length - 1)
            Divider(height: 1.h, color: AppColors.grey300, indent: 48.w),
        ],
      ],
    );
  }
}

class _EnrollmentRow extends StatelessWidget {
  const _EnrollmentRow({required this.item});

  final RecentEnrollmentModel item;

  @override
  Widget build(BuildContext context) {
    final initial = item.studentName.trim().isEmpty
        ? '?'
        : item.studentName.trim()[0].toUpperCase();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        children: [
          AppAvatar(size: 36.w, name: initial),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interSemiBold16.copyWith(
                    fontSize: 13.sp,
                    color: AppColors.onBackground,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  item.courseTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: AppColors.grey500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Text(
            _relativeTime(item.enrolledAt),
            style: AppTextStyles.interRegular14.copyWith(
              fontSize: 11.sp,
              color: AppColors.grey500,
            ),
          ),
        ],
      ),
    );
  }

  static String _relativeTime(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.isNegative || difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${value.day}/${value.month}/${value.year}';
  }
}
