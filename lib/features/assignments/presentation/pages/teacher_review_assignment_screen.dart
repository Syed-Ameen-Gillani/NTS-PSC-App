import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/assignment_status_badge.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/assignment_attachment_tile.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class TeacherReviewAssignmentScreen extends ConsumerStatefulWidget {
  final AssignmentModel? assignment;

  const TeacherReviewAssignmentScreen({super.key, this.assignment});

  @override
  ConsumerState<TeacherReviewAssignmentScreen> createState() =>
      _TeacherReviewAssignmentScreenState();
}

class _TeacherReviewAssignmentScreenState
    extends ConsumerState<TeacherReviewAssignmentScreen> {
  String _selectedStatus = 'all';

  Future<void> _review(
    AssignmentSubmissionModel submission,
    AssignmentReviewStatus decision,
  ) async {
    var feedback = '';
    if (decision == AssignmentReviewStatus.disapproved) {
      final comment = await _showFeedbackDialog(
        title: 'Request Revision',
        actionLabel: 'Request Revision',
        isDisapprove: true,
      );
      if (comment == null || !mounted) return;
      feedback = comment;
    }
    try {
      await ref
          .read(assignmentsControllerProvider.notifier)
          .review(
            submissionId: submission.id,
            decision: decision,
            feedback: feedback,
          );
      if (mounted) {
        CustomToast.showSuccess(
          context,
          message: decision == AssignmentReviewStatus.approved
              ? 'Submission approved'
              : 'Revision requested from student',
        );
      }
    } catch (_) {
      if (mounted) {
        CustomToast.showError(context, message: 'Could not review submission');
      }
    }
  }

  Future<String?> _showFeedbackDialog({
    required String title,
    required String actionLabel,
    required bool isDisapprove,
  }) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final presetChips = [
      'Needs stronger case citations',
      'Please revise Section III calculations',
      'Incomplete response, elaborate further',
      'Good effort, but missing constitutional references',
    ];

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            title,
            style: AppTextStyles.interBold24.copyWith(fontSize: 18.sp),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Feedback Snippets:',
                    style: AppTextStyles.interMedium16.copyWith(
                      fontSize: 12.sp,
                      color: AppColors.grey600,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 6.w,
                    runSpacing: 6.h,
                    children: presetChips.map((chipText) {
                      return ActionChip(
                        label: Text(
                          chipText,
                          style: AppTextStyles.interRegular14.copyWith(
                            fontSize: 11.sp,
                            color: AppColors.primary,
                          ),
                        ),
                        backgroundColor: AppColors.surface,
                        side: const BorderSide(color: AppColors.primaryLight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        onPressed: () {
                          setDialogState(() {
                            if (controller.text.isEmpty) {
                              controller.text = chipText;
                            } else {
                              controller.text = '${controller.text}; $chipText';
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16.h),
                  Form(
                    key: formKey,
                    child: CustomTextFormField(
                      controller: controller,
                      hintText: 'Enter specific instructor notes or guidance...',
                      maxLines: 4,
                      validator: (value) => isDisapprove && (value == null || value.trim().isEmpty)
                          ? 'Feedback is required when requesting revision'
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(dialogContext).pop(controller.text.trim());
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: isDisapprove ? AppColors.error : AppColors.primary,
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher =
        ref.watch(authControllerProvider).value?.selectedRole ==
        UserRole.teacher;
    final assignments = ref.watch(assignmentsControllerProvider);
    final assignment = widget.assignment;

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
          'Review Submissions',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: AppColors.grey300, height: 1.h),
        ),
      ),
      body: assignment == null
          ? const Center(child: Text('Assignment unavailable'))
          : !isTeacher
          ? const Center(child: Text('Teacher access only'))
          : assignments.when(
              data: (state) {
                final allSubmissions = state.submissionsFor(assignment.id);
                final pending = allSubmissions
                    .where((s) => s.status == AssignmentReviewStatus.pending)
                    .toList();
                final approved = allSubmissions
                    .where((s) => s.status == AssignmentReviewStatus.approved)
                    .toList();
                final disapproved = allSubmissions
                    .where((s) => s.status == AssignmentReviewStatus.disapproved)
                    .toList();

                final visible = switch (_selectedStatus) {
                  'pending' => pending,
                  'approved' => approved,
                  'disapproved' => disapproved,
                  _ => allSubmissions,
                };

                return SafeArea(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
                    children: [
                      // Assignment Header Overview Card
                      Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(color: AppColors.grey300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              assignment.courseTitle,
                              style: AppTextStyles.interMedium16.copyWith(
                                fontSize: 12.sp,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              assignment.title,
                              style: AppTextStyles.interBold24.copyWith(
                                fontSize: 18.sp,
                                color: AppColors.onBackground,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14.w,
                                  color: AppColors.grey600,
                                ),
                                SizedBox(width: 6.w),
                                Text(
                                  'Due ${MaterialLocalizations.of(context).formatMediumDate(assignment.dueAt)}',
                                  style: AppTextStyles.interRegular14.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.grey600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Text(
                              assignment.instructions,
                              style: AppTextStyles.interRegular14.copyWith(
                                fontSize: 13.sp,
                                color: AppColors.grey700,
                                height: 1.4,
                              ),
                            ),
                            if (assignment.attachments.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              Text(
                                'Reference Materials',
                                style: AppTextStyles.interSemiBold16.copyWith(
                                  fontSize: 12.sp,
                                  color: AppColors.onBackground,
                                ),
                              ),
                              SizedBox(height: 6.h),
                              for (final attachment in assignment.attachments)
                                Padding(
                                  padding: EdgeInsets.only(bottom: 6.h),
                                  child: AssignmentAttachmentTile(
                                    attachment: attachment,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),

                      // KPI Statistics Ribbon
                      Row(
                        children: [
                          _buildKpiCard(
                            label: 'Total',
                            value: '${allSubmissions.length}',
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 10.w),
                          _buildKpiCard(
                            label: 'Needs Review',
                            value: '${pending.length}',
                            color: const Color(0xFFD97706),
                          ),
                          SizedBox(width: 10.w),
                          _buildKpiCard(
                            label: 'Approved',
                            value: '${approved.length}',
                            color: const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),

                      // Submissions Header & Filters
                      Text(
                        'Student Submissions',
                        style: AppTextStyles.interSemiBold16.copyWith(
                          fontSize: 16.sp,
                          color: AppColors.onBackground,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All (${allSubmissions.length})'),
                            SizedBox(width: 8.w),
                            _buildFilterChip('pending', 'Needs Review (${pending.length})'),
                            SizedBox(width: 8.w),
                            _buildFilterChip('approved', 'Approved (${approved.length})'),
                            if (disapproved.isNotEmpty) ...[
                              SizedBox(width: 8.w),
                              _buildFilterChip('disapproved', 'Disapproved (${disapproved.length})'),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),

                      if (visible.isEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 36.h),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(
                                Icons.inbox_outlined,
                                size: 36.w,
                                color: AppColors.grey400,
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                'No submissions in this filter',
                                style: AppTextStyles.interMedium16.copyWith(
                                  fontSize: 14.sp,
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),

                      for (final submission in visible) ...[
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(16.w),
                          margin: EdgeInsets.only(bottom: 12.h),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.grey300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16.r,
                                    backgroundColor: AppColors.surface,
                                    child: Text(
                                      submission.studentName.isNotEmpty
                                          ? submission.studentName[0].toUpperCase()
                                          : 'S',
                                      style: AppTextStyles.interBold24.copyWith(
                                        fontSize: 13.sp,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10.w),
                                  Expanded(
                                    child: Text(
                                      submission.studentName,
                                      style: AppTextStyles.interSemiBold16.copyWith(
                                        fontSize: 15.sp,
                                        color: AppColors.onBackground,
                                      ),
                                    ),
                                  ),
                                  AssignmentStatusBadge(status: submission.status),
                                ],
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                submission.response,
                                style: AppTextStyles.interRegular14.copyWith(
                                  fontSize: 13.sp,
                                  color: AppColors.grey700,
                                  height: 1.5,
                                ),
                              ),
                              if (submission.attachments.isNotEmpty) ...[
                                SizedBox(height: 12.h),
                                Text(
                                  'Attachments',
                                  style: AppTextStyles.interSemiBold16.copyWith(
                                    fontSize: 12.sp,
                                    color: AppColors.onBackground,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                for (final attachment in submission.attachments)
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 6.h),
                                    child: AssignmentAttachmentTile(
                                      attachment: attachment,
                                    ),
                                  ),
                              ],
                              if (submission.revisions.length > 1)
                                ExpansionTile(
                                  tilePadding: EdgeInsets.zero,
                                  title: Text(
                                    'Revision History (${submission.revisions.length})',
                                    style: AppTextStyles.interMedium16.copyWith(
                                      fontSize: 12.sp,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  children: [
                                    for (final revision in submission.revisions.skip(1)) ...[
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Revision ${revision.number}',
                                          style: AppTextStyles.interBold24.copyWith(
                                            fontSize: 12.sp,
                                            color: AppColors.grey600,
                                          ),
                                        ),
                                      ),
                                      if (revision.response.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: 4.h),
                                          child: Text(
                                            revision.response,
                                            style: AppTextStyles.interRegular14.copyWith(
                                              fontSize: 12.sp,
                                              color: AppColors.grey700,
                                            ),
                                          ),
                                        ),
                                      for (final attachment in revision.attachments)
                                        AssignmentAttachmentTile(attachment: attachment),
                                      SizedBox(height: 8.h),
                                    ],
                                  ],
                                ),
                              if (submission.feedback.isNotEmpty) ...[
                                SizedBox(height: 10.h),
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey100,
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: AppColors.grey200),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.chat_bubble_outline,
                                        size: 14.w,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          submission.feedback,
                                          style: AppTextStyles.interRegular14.copyWith(
                                            fontSize: 12.sp,
                                            color: AppColors.grey700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (submission.status == AssignmentReviewStatus.pending) ...[
                                SizedBox(height: 14.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _review(
                                          submission,
                                          AssignmentReviewStatus.disapproved,
                                        ),
                                        icon: const Icon(Icons.refresh, size: 16),
                                        label: const Text('Request Revision'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: AppColors.error,
                                          side: const BorderSide(color: AppColors.error),
                                          padding: EdgeInsets.symmetric(vertical: 10.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 10.w),
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () => _review(
                                          submission,
                                          AssignmentReviewStatus.approved,
                                        ),
                                        icon: const Icon(Icons.check, size: 16),
                                        label: const Text('Approve'),
                                        style: FilledButton.styleFrom(
                                          backgroundColor: const Color(0xFF16A34A),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: 10.h),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8.r),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) =>
                  const Center(child: Text('Error loading submissions')),
            ),
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.interMedium16.copyWith(
                fontSize: 11.sp,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            Text(
              value,
              style: AppTextStyles.interBold24.copyWith(
                fontSize: 18.sp,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedStatus = value),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      backgroundColor: AppColors.grey100,
      side: BorderSide(
        color: isSelected ? AppColors.primary : AppColors.grey300,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(50.r),
      ),
      labelStyle: AppTextStyles.interSemiBold16.copyWith(
        fontSize: 12.sp,
        color: isSelected ? AppColors.onPrimary : AppColors.grey600,
      ),
    );
  }
}
