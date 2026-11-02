import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/assignment_attachment_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/assignments/domain/assignment_link.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignments_controller.dart';
import 'package:nts_psc_app/features/assignments/presentation/controllers/assignment_draft_binding.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/assignment_status_badge.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/assignment_submission_guard.dart';
import 'package:nts_psc_app/features/assignments/presentation/widgets/assignment_attachment_tile.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_button.dart';
import 'package:nts_psc_app/presentation/widgets/custom_text_field.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentAssignmentScreen extends ConsumerStatefulWidget {
  final AssignmentModel? assignment;

  const StudentAssignmentScreen({super.key, this.assignment});

  @override
  ConsumerState<StudentAssignmentScreen> createState() =>
      _StudentAssignmentScreenState();
}

class _StudentAssignmentScreenState
    extends ConsumerState<StudentAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _response = TextEditingController();
  final _attachments = ValueNotifier<List<AssignmentAttachmentModel>>([]);
  bool _saving = false;
  AssignmentDraftBinding? _draft;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authControllerProvider).value?.user?.id;
    final assignmentId = widget.assignment?.id;
    if (AppConfig.isSupabaseEnabled && userId != null && assignmentId != null) {
      _draft = AssignmentDraftBinding(
        userId: userId,
        assignmentId: assignmentId,
        response: _response,
        attachments: _attachments,
        isCurrentUser: () =>
            mounted &&
            ref.read(authControllerProvider).value?.user?.id == userId,
        onError: () {
          if (mounted) {
            CustomToast.showError(
              context,
              message: 'Could not save your draft on this device.',
            );
          }
        },
      );
    }
  }

  Future<void> _openAssignmentLink(String url) async {
    if (assignmentLinkError(url) != null) {
      CustomToast.showError(context, message: 'This link is unavailable.');
      return;
    }
    try {
      if (!await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        throw StateError('Could not open link');
      }
    } catch (_) {
      if (mounted) {
        CustomToast.showError(context, message: 'Could not open the link.');
      }
    }
  }

  @override
  void dispose() {
    _draft?.dispose();
    _response.dispose();
    _attachments.dispose();
    super.dispose();
  }

  Future<void> _submit(String assignmentId) async {
    if (_saving || !_formKey.currentState!.validate()) return;
    _saving = true;
    ref.read(assignmentSubmittingProvider(assignmentId).notifier).state = true;
    try {
      await ref
          .read(assignmentsControllerProvider.notifier)
          .submit(
            assignmentId: assignmentId,
            response: _response.text.trim(),
            attachments: _attachments.value,
          );
      if (!mounted) return;
      try {
        await _draft?.clear();
      } catch (_) {
        /* Submission is already saved. */
      }
      if (!mounted) return;
      ref.read(assignmentSubmittingProvider(assignmentId).notifier).state =
          false;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      CustomToast.showSuccess(
        context,
        message: 'Assignment submitted for review',
      );
      context.pop();
    } catch (_) {
      if (mounted) {
        CustomToast.showError(context, message: 'Could not submit assignment');
      }
    } finally {
      _saving = false;
      if (mounted) {
        ref.read(assignmentSubmittingProvider(assignmentId).notifier).state =
            false;
      }
    }
  }

  Future<void> _pickAttachments() async {
    final updated = await pickAssignmentAttachments(
      context,
      _attachments.value,
    );
    if (mounted) _attachments.value = updated;
  }

  String _fileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider).value;
    final assignments = ref.watch(assignmentsControllerProvider);
    final assignment = widget.assignment;
    return AssignmentSubmissionGuard(
      assignmentId: assignment?.id ?? '',
      child: AppScaffold(
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
            'Assignment',
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
            : auth?.selectedRole != UserRole.student
            ? const Center(child: Text('Student access only'))
            : assignments.when(
                data: (state) {
                  final studentId =
                      auth?.user?.id ??
                      (AppConfig.isSupabaseEnabled ? '' : 'student_1');
                  final submission = state.submissionFor(
                    assignment.id,
                    studentId,
                  );
                  final canSubmit =
                      assignment.isPublished &&
                      (submission == null ||
                          submission.status ==
                              AssignmentReviewStatus.disapproved) &&
                      (DateTime.now().isBefore(assignment.dueAt) ||
                          submission?.status ==
                              AssignmentReviewStatus.disapproved);
                  return SafeArea(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(24.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            assignment.courseTitle,
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 13.sp,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            assignment.title,
                            style: AppTextStyles.interBold24.copyWith(
                              fontSize: 22.sp,
                              color: AppColors.onBackground,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Due ${MaterialLocalizations.of(context).formatMediumDate(assignment.dueAt)}',
                            style: AppTextStyles.interRegular14.copyWith(
                              color: AppColors.grey500,
                            ),
                          ),
                          SizedBox(height: 24.h),
                          Text(
                            'Instructions',
                            style: AppTextStyles.interSemiBold16.copyWith(
                              color: AppColors.onBackground,
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Text(
                            assignment.instructions,
                            style: AppTextStyles.interRegular14.copyWith(
                              color: AppColors.grey700,
                              height: 1.5,
                            ),
                          ),
                          if (assignment.externalUrl != null) ...[
                            SizedBox(height: 12.h),
                            TextButton.icon(
                              onPressed: () =>
                                  _openAssignmentLink(assignment.externalUrl!),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open assignment link'),
                            ),
                          ],
                          if (assignment.attachments.isNotEmpty) ...[
                            SizedBox(height: 16.h),
                            Text(
                              'Assignment Resources',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                color: AppColors.onBackground,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            for (final attachment in assignment.attachments)
                              AssignmentAttachmentTile(attachment: attachment),
                          ],
                          if (submission != null) ...[
                            SizedBox(height: 24.h),
                            AssignmentStatusBadge(status: submission.status),
                            SizedBox(height: 16.h),
                            Text(
                              'Your submission',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                color: AppColors.onBackground,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              submission.response,
                              style: AppTextStyles.interRegular14.copyWith(
                                color: AppColors.grey700,
                                height: 1.5,
                              ),
                            ),
                            if (submission.attachments.isNotEmpty) ...[
                              SizedBox(height: 12.h),
                              for (final attachment in submission.attachments)
                                AssignmentAttachmentTile(
                                  attachment: attachment,
                                ),
                            ],
                            if (submission.feedback.isNotEmpty) ...[
                              SizedBox(height: 16.h),
                              Text(
                                'Teacher feedback',
                                style: AppTextStyles.interSemiBold16.copyWith(
                                  color: AppColors.onBackground,
                                ),
                              ),
                              SizedBox(height: 8.h),
                              Text(
                                submission.feedback,
                                style: AppTextStyles.interRegular14.copyWith(
                                  color: AppColors.grey700,
                                ),
                              ),
                            ],
                          ],
                          if (canSubmit) ...[
                            SizedBox(height: 28.h),
                            Text(
                              submission == null
                                  ? 'Your answer'
                                  : 'Revised answer',
                              style: AppTextStyles.interSemiBold16.copyWith(
                                color: AppColors.onBackground,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Form(
                              key: _formKey,
                              child: CustomTextFormField(
                                controller: _response,
                                hintText: 'Write your answer here',
                                maxLines: 8,
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty) &&
                                        _attachments.value.isEmpty
                                    ? 'Enter an answer or add an attachment'
                                    : null,
                              ),
                            ),
                            SizedBox(height: 12.h),
                            Material(
                              color: AppColors.grey100,
                              borderRadius: BorderRadius.circular(16.r),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16.r),
                                onTap: _pickAttachments,
                                child: Container(
                                  width: double.infinity,
                                  constraints: BoxConstraints(minHeight: 56.h),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                    vertical: 10.h,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.grey300,
                                    ),
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8.w),
                                        decoration: const BoxDecoration(
                                          color: AppColors.surface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.attach_file,
                                          color: AppColors.primary,
                                          size: 20.w,
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          'Add media or document',
                                          style: AppTextStyles.interSemiBold16
                                              .copyWith(
                                                fontSize: 14.sp,
                                                color: AppColors.onBackground,
                                              ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: AppColors.grey400,
                                        size: 14.w,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ValueListenableBuilder<
                              List<AssignmentAttachmentModel>
                            >(
                              valueListenable: _attachments,
                              builder: (context, attachments, child) => Column(
                                children: [
                                  if (attachments.isNotEmpty)
                                    SizedBox(height: 8.h),
                                  for (final attachment in attachments)
                                    ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      dense: true,
                                      leading: Icon(
                                        Icons.insert_drive_file_outlined,
                                        color: AppColors.primary,
                                        size: 20.w,
                                      ),
                                      title: Text(
                                        attachment.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        _fileSize(attachment.sizeBytes),
                                      ),
                                      trailing: IconButton(
                                        tooltip: 'Remove attachment',
                                        icon: const Icon(Icons.close),
                                        onPressed: () =>
                                            _attachments.value = attachments
                                                .where(
                                                  (item) => item != attachment,
                                                )
                                                .toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            SizedBox(height: 20.h),
                            CustomButton(
                              text: submission == null
                                  ? 'Submit Assignment'
                                  : 'Resubmit Assignment',
                              color: AppColors.primary,
                              height: 56.h,
                              borderRadius: 16.r,
                              onPressed: () => _submit(assignment.id),
                            ),
                          ] else if (submission == null) ...[
                            SizedBox(height: 24.h),
                            Text(
                              'Submissions closed',
                              style: AppTextStyles.interMedium16.copyWith(
                                color: AppColors.grey500,
                              ),
                            ),
                          ],
                          SizedBox(height: 32.h),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: TextButton(
                    onPressed: () =>
                        ref.invalidate(assignmentsControllerProvider),
                    child: const Text('Could not load assignment. Retry'),
                  ),
                ),
              ),
      ),
    );
  }
}
