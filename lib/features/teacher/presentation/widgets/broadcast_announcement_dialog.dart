import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/core/utils/keyboard_dismissal.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/home/presentation/controllers/course_community_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/notifications/data/announcement_repository.dart';

class BroadcastAnnouncementDialog extends ConsumerStatefulWidget {
  final String courseId;
  final String courseTitle;

  const BroadcastAnnouncementDialog({
    super.key,
    required this.courseId,
    required this.courseTitle,
  });

  static void show(
    BuildContext context, {
    required String courseId,
    required String courseTitle,
  }) {
    showDialog(
      context: context,
      builder: (context) => BroadcastAnnouncementDialog(
        courseId: courseId,
        courseTitle: courseTitle,
      ),
    );
  }

  @override
  ConsumerState<BroadcastAnnouncementDialog> createState() =>
      _BroadcastAnnouncementDialogState();
}

class _BroadcastAnnouncementDialogState
    extends ConsumerState<BroadcastAnnouncementDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _isUrgent = false;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _dispatch() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      CustomToast.showError(
        context,
        message: 'Please enter both an announcement title and message.',
      );
      return;
    }

    try {
      if (AppConfig.isSupabaseEnabled) {
        await ref
            .read(announcementRepositoryProvider)
            .broadcast(
              courseId: widget.courseId,
              title: title,
              message: message,
              urgent: _isUrgent,
            );
      } else {
        final teacherName =
            ref.read(authControllerProvider).value?.user?.name ??
            'Course Instructor';
        ref
            .read(courseCommunityProvider.notifier)
            .broadcastAnnouncement(
              courseId: widget.courseId,
              courseTitle: widget.courseTitle,
              instructorName: teacherName,
              title: title,
              message: message,
              isUrgent: _isUrgent,
            );
      }
      if (!mounted) return;
      Navigator.pop(context);
      CustomToast.showSuccess(
        context,
        message: 'Announcement sent to enrolled learners',
      );
    } catch (_) {
      if (mounted) {
        CustomToast.showError(context, message: 'Could not send announcement');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.campaign_rounded,
                    color: AppColors.primary,
                    size: 24.w,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      'Broadcast Announcement',
                      style: AppTextStyles.interBold24.copyWith(
                        fontSize: 17.sp,
                        color: AppColors.onBackground,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              Text(
                'Send instant class notification to all candidates in ${widget.courseTitle}',
                style: AppTextStyles.interRegular14.copyWith(
                  fontSize: 12.sp,
                  color: AppColors.grey500,
                ),
              ),
              SizedBox(height: 16.h),
              TextField(
                onTapOutside: dismissKeyboardOnTapOutside,
                controller: _titleController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Announcement Headline',
                  hintText: 'e.g. 📢 Crucial Revision Session Rescheduled',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                onTapOutside: dismissKeyboardOnTapOutside,
                controller: _messageController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Message Body',
                  hintText:
                      'Type instructions, timetable changes, or past paper advice...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              SizedBox(height: 10.h),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isUrgent,
                activeColor: AppColors.primary,
                title: Text(
                  'Mark as High-Priority / Exam Alert',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onChanged: (val) => setState(() => _isUrgent = val ?? false),
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  SizedBox(width: 8.w),
                  ElevatedButton.icon(
                    onPressed: _dispatch,
                    icon: const Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Send Broadcast',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
