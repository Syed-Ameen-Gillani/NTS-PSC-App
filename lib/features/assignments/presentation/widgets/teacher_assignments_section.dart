import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/presentation/curriculum_providers.dart';
import 'package:nts_psc_app/features/curriculum/presentation/course_link_dialog.dart';
import 'package:nts_psc_app/features/curriculum/presentation/assessment_link_confirmation.dart';
import 'package:nts_psc_app/presentation/widgets/assessment_status_section.dart';

class TeacherAssignmentsSection extends ConsumerWidget {
  const TeacherAssignmentsSection({super.key, this.targetScope});

  final CurriculumScope? targetScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(assignmentsControllerProvider)
        .when(
          data: (state) {
            final published = state.assignments
                .where((assignment) => assignment.isPublished)
                .toList();
            final drafts = state.assignments
                .where(
                  (assignment) =>
                      !assignment.isPublished &&
                      (targetScope == null ||
                          assignment.courseId == targetScope?.courseId),
                )
                .toList();
            return ColoredBox(
              color: AppColors.background,
              child: published.isEmpty && drafts.isEmpty
                  ? const _AssignmentEmptyState()
                  : ListView(
                      padding: EdgeInsets.fromLTRB(20.w, 18.h, 20.w, 104.h),
                      children: [
                        AssessmentStatusSection(
                          title: 'Published',
                          count: published.length,
                          onSeeAll: () => context.pushNamed(
                            AppRoute.teacherAssessmentList.name,
                            queryParameters: {
                              'kind': 'assignment',
                              'status': 'published',
                            },
                            extra: targetScope,
                          ),
                          children: [
                            for (final assignment in published.take(
                              AssessmentStatusSection.previewLimit,
                            ))
                              TeacherAssignmentListItem(
                                assignment: assignment,
                                state: state,
                                targetScope: targetScope,
                              ),
                          ],
                        ),
                        if (published.isNotEmpty && drafts.isNotEmpty)
                          SizedBox(height: 28.h),
                        AssessmentStatusSection(
                          title: 'Drafts',
                          count: drafts.length,
                          onSeeAll: () => context.pushNamed(
                            AppRoute.teacherAssessmentList.name,
                            queryParameters: {
                              'kind': 'assignment',
                              'status': 'draft',
                            },
                            extra: targetScope,
                          ),
                          children: [
                            for (final assignment in drafts.take(
                              AssessmentStatusSection.previewLimit,
                            ))
                              TeacherAssignmentListItem(
                                assignment: assignment,
                                state: state,
                                targetScope: targetScope,
                              ),
                          ],
                        ),
                      ],
                    ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(
            child: Text(
              'Could not load assignments.',
              style: AppTextStyles.interMedium16.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ),
        );
  }
}

class TeacherAssignmentListItem extends ConsumerWidget {
  const TeacherAssignmentListItem({
    super.key,
    required this.assignment,
    required this.state,
    this.targetScope,
  });

  final AssignmentModel assignment;
  final AssignmentsState state;
  final CurriculumScope? targetScope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissions = state.submissionsFor(assignment.id);
    final submissionCount = submissions.length;
    final pendingCount = submissions
        .where((item) => item.status == AssignmentReviewStatus.pending)
        .length;
    final linkedAssessments = targetScope != null
        ? ref.watch(curriculumAssessmentsProvider(targetScope!)).value ?? []
        : const <CurriculumAssessment>[];
    final isLinked =
        targetScope != null &&
        linkedAssessments.any(
          (a) => a.kind == 'assignment' && a.assessmentId == assignment.id,
        );

    return Material(
      color: AppColors.grey100,
      borderRadius: BorderRadius.circular(8.r),
      child: InkWell(
        onTap: () => context.pushNamed(
          assignment.isPublished
              ? AppRoute.teacherReviewAssignment.name
              : AppRoute.teacherCreateAssignment.name,
          extra: assignment,
        ),
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(color: AppColors.grey300, width: 1.w),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                assignment.courseTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.interMedium16.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: 5.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
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
                          '$submissionCount submitted · $pendingCount awaiting review',
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 12.sp,
                            color: pendingCount > 0
                                ? AppColors.primary
                                : AppColors.grey500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  PopupMenuButton<String>(
                    tooltip: 'Assignment actions',
                    color: Theme.of(context).scaffoldBackgroundColor,
                    onSelected: (action) {
                      if (action == 'edit') {
                        context.pushNamed(
                          AppRoute.teacherCreateAssignment.name,
                          extra: assignment,
                        );
                      } else if (action == 'link') {
                        showCourseLinkDialog(
                          context: context,
                          ref: ref,
                          kind: 'assignment',
                          assessmentId: assignment.id,
                          title: assignment.title,
                          status: assignment.isPublished
                              ? 'published'
                              : 'draft',
                        );
                      }
                    },
                    itemBuilder: (_) => [
                      if (!assignment.isPublished)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Text('Edit draft'),
                        ),
                      const PopupMenuItem(
                        value: 'link',
                        child: Text('Link to course'),
                      ),
                    ],
                  ),
                ],
              ),
              if (targetScope != null) ...[
                SizedBox(height: 12.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isLinked)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 5.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check,
                              size: 14,
                              color: Color(0xFF16A34A),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              'Linked to ${targetScope!.targetLabel}',
                              style: AppTextStyles.interBold24.copyWith(
                                fontSize: 11.sp,
                                color: const Color(0xFF166534),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      FilledButton.icon(
                        onPressed: () async {
                          final confirmed = await confirmAssessmentLinkChange(
                            context: context,
                            title: assignment.title,
                            target: targetScope!.targetLabel.toLowerCase(),
                            unlink: false,
                            publish: !assignment.isPublished,
                          );
                          if (!confirmed || !context.mounted) return;
                          try {
                            await ref
                                .read(
                                  curriculumActionsProvider(
                                    targetScope!,
                                  ).notifier,
                                )
                                .link(
                                  CurriculumAssessment(
                                    id: assignment.id,
                                    assessmentId: assignment.id,
                                    title: assignment.title,
                                    kind: 'assignment',
                                    status: assignment.isPublished
                                        ? 'published'
                                        : 'draft',
                                  ),
                                );
                            ref.invalidate(assignmentsControllerProvider);
                            if (context.mounted) {
                              CustomToast.showSuccess(
                                context,
                                message: assignment.isPublished
                                    ? 'Assignment linked to ${targetScope!.targetLabel.toLowerCase()}.'
                                    : 'Assignment published in ${targetScope!.targetLabel.toLowerCase()}.',
                              );
                            }
                          } catch (_) {
                            if (context.mounted) {
                              CustomToast.showError(
                                context,
                                message: 'Could not link assignment to course.',
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.link, size: 16),
                        label: Text('Link to ${targetScope!.targetLabel}'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.w,
                            vertical: 8.h,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AssignmentEmptyState extends StatelessWidget {
  const _AssignmentEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 42.w,
              color: AppColors.grey400,
            ),
            SizedBox(height: 10.h),
            Text(
              'No assignments yet',
              style: AppTextStyles.interSemiBold16.copyWith(
                fontSize: 15.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Create an assignment for one of your courses.',
              textAlign: TextAlign.center,
              style: AppTextStyles.interRegular14.copyWith(
                fontSize: 12.sp,
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
