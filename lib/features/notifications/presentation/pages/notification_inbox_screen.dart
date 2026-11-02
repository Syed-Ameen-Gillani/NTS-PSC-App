import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/notifications/data/notification_lifecycle.dart';
import 'package:nts_psc_app/features/notifications/domain/notification_models.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/notification_inbox_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class NotificationInboxScreen extends ConsumerWidget {
  const NotificationInboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(notificationInboxProvider);
    final state = inbox.value;
    return AppScaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.interBold24.copyWith(fontSize: 20.sp),
        ),
        actions: [
          if ((state?.unreadCount ?? 0) > 0)
            TextButton(
              onPressed: () async {
                try {
                  await ref
                      .read(notificationInboxProvider.notifier)
                      .markAllRead();
                } catch (_) {
                  if (context.mounted) {
                    CustomToast.showError(
                      context,
                      message: 'Could not mark notifications as read',
                    );
                  }
                }
              },
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: SafeArea(
        child: inbox.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _InboxMessage(
            icon: Icons.cloud_off_outlined,
            title: 'Could not load notifications',
            action: TextButton.icon(
              onPressed: () => ref.invalidate(notificationInboxProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ),
          data: (value) => value.items.isEmpty
              ? const _InboxMessage(
                  icon: Icons.notifications_none,
                  title: 'No notifications yet',
                  subtitle: 'Course and assessment updates will appear here.',
                )
              : RefreshIndicator(
                  onRefresh: ref
                      .read(notificationInboxProvider.notifier)
                      .refresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 8.h),
                    itemCount: value.items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1.h,
                      indent: 72.w,
                      color: AppColors.grey200,
                    ),
                    itemBuilder: (context, index) =>
                        _NotificationTile(item: value.items[index]),
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});
  final AppNotificationItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
    color: item.isRead ? AppColors.background : AppColors.surfaceVariant,
    child: InkWell(
      onTap: () async {
        try {
          await ref.read(notificationInboxProvider.notifier).markRead(item.id);
        } catch (_) {
          // Opening the item should not be blocked by a read-state sync failure.
        }
        ref.read(notificationIntentProvider.notifier).receive(item.payload);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _icon(item.type),
                color: AppColors.primary,
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: AppTextStyles.interSemiBold16.copyWith(
                            fontSize: 15.sp,
                            color: AppColors.onBackground,
                          ),
                        ),
                      ),
                      if (!item.isRead) ...[
                        SizedBox(width: 8.w),
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 13.sp,
                      color: AppColors.grey600,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    _relativeTime(item.createdAt),
                    style: AppTextStyles.interRegular14.copyWith(
                      fontSize: 11.sp,
                      color: AppColors.grey500,
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

  IconData _icon(AppNotificationType type) => switch (type) {
    AppNotificationType.liveClassScheduled ||
    AppNotificationType.liveClassUpdated ||
    AppNotificationType.liveClassCancelled ||
    AppNotificationType.liveClassReminder => Icons.videocam_outlined,
    AppNotificationType.assignmentPublished ||
    AppNotificationType.assignmentDueReminder ||
    AppNotificationType.assignmentSubmitted ||
    AppNotificationType.assignmentReviewed => Icons.assignment_outlined,
    AppNotificationType.quizPublished => Icons.quiz_outlined,
    AppNotificationType.discussionReply ||
    AppNotificationType.directFeedback ||
    AppNotificationType.studyNudge => Icons.chat_bubble_outline,
    AppNotificationType.promotion => Icons.local_offer_outlined,
    _ => Icons.school_outlined,
  };

  String _relativeTime(DateTime date) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InboxMessage extends StatelessWidget {
  const _InboxMessage({
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(32.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40.w, color: AppColors.grey400),
          SizedBox(height: 12.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.interSemiBold16,
          ),
          if (subtitle != null) ...[
            SizedBox(height: 6.h),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: AppTextStyles.interRegular14.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
          if (action != null) ...[SizedBox(height: 12.h), action!],
        ],
      ),
    ),
  );
}
