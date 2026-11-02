import 'package:nts_psc_app/presentation/widgets/app_scaffold.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/notifications/data/notification_lifecycle.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/notification_settings_controller.dart';
import 'package:nts_psc_app/features/profile/presentation/providers/notifications_provider.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferenceState = ref.watch(notificationsProvider);
    final permissionState = ref.watch(notificationPermissionProvider);
    final state = preferenceState.value;
    final notifier = ref.read(notificationsProvider.notifier);
    final permission = permissionState.value;
    final permissionAllows =
        permission == NotificationPermissionStatus.authorized ||
        permission == NotificationPermissionStatus.provisional;
    final effectivePush = state?.pushNotifications == true && permissionAllows;

    Future<void> update(Future<void> Function(bool) change, bool value) async {
      try {
        await change(value);
      } catch (_) {
        if (context.mounted) {
          CustomToast.showError(
            context,
            message: 'Could not save notification setting',
          );
        }
      }
    }

    Future<void> updatePush(bool value) async {
      try {
        final result = await ref
            .read(notificationSettingsControllerProvider)
            .setPushEnabled(value);
        if (!context.mounted) return;
        if (result == PushPreferenceResult.settingsRequired) {
          CustomToast.showInfo(
            context,
            message: 'Enable notifications in device settings',
          );
          await ref
              .read(notificationPermissionProvider.notifier)
              .openDeviceSettings();
        } else if (result == PushPreferenceResult.permissionDenied) {
          CustomToast.showInfo(
            context,
            message: 'Notifications remain off until you allow them',
          );
        } else if (result == PushPreferenceResult.unavailable) {
          CustomToast.showError(
            context,
            message: 'Push notifications are unavailable in this build',
          );
        }
      } catch (_) {
        if (context.mounted) {
          CustomToast.showError(
            context,
            message: 'Could not save notification setting',
          );
        }
      }
    }

    return AppScaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.onBackground,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.interBold24.copyWith(
            fontSize: 20.sp,
            color: AppColors.onBackground,
          ),
        ),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Container(color: const Color(0xFFE2E8F0), height: 1.h),
        ),
      ),
      body: state == null
          ? Center(
              child: preferenceState.hasError
                  ? TextButton.icon(
                      onPressed: () => ref.invalidate(notificationsProvider),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry loading notifications'),
                    )
                  : const CircularProgressIndicator(),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Notification inbox',
                        style: AppTextStyles.interSemiBold16,
                      ),
                      subtitle: Text(
                        'View your recent updates',
                        style: AppTextStyles.interRegular14.copyWith(
                          color: AppColors.grey500,
                        ),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.pushNamed(AppRoute.notificationInbox.name),
                    ),
                    if (permission == NotificationPermissionStatus.denied) ...[
                      SizedBox(height: 8.h),
                      Material(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8.r),
                        child: ListTile(
                          leading: const Icon(
                            Icons.notifications_off_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(
                            'Notifications are blocked on this device',
                            style: AppTextStyles.interMedium16.copyWith(
                              fontSize: 14.sp,
                            ),
                          ),
                          trailing: TextButton(
                            onPressed: () => ref
                                .read(notificationPermissionProvider.notifier)
                                .openDeviceSettings(),
                            child: const Text('Settings'),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 30.h),
                    _buildSectionTitle('DELIVERY METHODS'),
                    SizedBox(height: 16.h),
                    _buildSectionContainer(
                      children: [
                        _buildToggleItem(
                          title: 'Push Notifications',
                          subtitle:
                              permission == NotificationPermissionStatus.denied
                              ? 'Enable in device settings to receive alerts'
                              : 'Receive alerts on your device',
                          value: effectivePush,
                          onChanged: updatePush,
                        ),
                        SizedBox(height: 1.h),
                        //let it be commented for now, as we are not using email and sms notifications
                        // _buildDivider(),
                        // _buildToggleItem(
                        //   title: 'Email Notifications',
                        //   subtitle: 'Receive daily and weekly summaries',
                        //   value: state.emailNotifications,
                        //   onChanged: (value) => update(notifier.toggleEmailNotifications, value),
                        // ),
                        // _buildDivider(),
                        // _buildToggleItem(
                        //   title: 'SMS Notifications',
                        //   subtitle: 'Receive critical alerts via text',
                        //   value: state.smsNotifications,
                        //   onChanged: notifier.toggleSmsNotifications,
                        // ),
                      ],
                    ),
                    SizedBox(height: 30.h),
                    _buildSectionTitle('NOTIFICATION TYPES'),
                    SizedBox(height: 16.h),
                    _buildSectionContainer(
                      children: [
                        _buildToggleItem(
                          title: 'Course Updates',
                          subtitle: 'New lessons and materials',
                          value: effectivePush && state.courseUpdates,
                          onChanged: (value) =>
                              update(notifier.toggleCourseUpdates, value),
                          enabled: effectivePush,
                          icon: Icons.menu_book_outlined,
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          title: 'Messages & Discussions',
                          subtitle: 'Replies and direct messages',
                          value: effectivePush && state.messagesDiscussions,
                          onChanged: (value) =>
                              update(notifier.toggleMessagesDiscussions, value),
                          enabled: effectivePush,
                          icon: Icons.chat_bubble_outline,
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          title: 'Exam Results',
                          subtitle: 'Scores and evaluations',
                          value: effectivePush && state.examResults,
                          onChanged: (value) =>
                              update(notifier.toggleExamResults, value),
                          enabled: effectivePush,
                          icon: Icons.badge_outlined,
                        ),
                        _buildDivider(),
                        _buildToggleItem(
                          title: 'Promotions',
                          subtitle: 'Special offers and discounts',
                          value: effectivePush && state.promotions,
                          onChanged: (value) =>
                              update(notifier.togglePromotions, value),
                          enabled: effectivePush,
                          icon: Icons.star_border,
                        ),
                      ],
                    ),
                    SizedBox(height: 48.h),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.interBold24.copyWith(
        fontSize: 14.sp,
        color: AppColors.grey500,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildSectionContainer({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Divider(
        color: const Color(0xFFE2E8F0),
        height: 1.h,
        thickness: 1.h,
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
    bool enabled = true,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: enabled ? const Color(0xFFE8F0FE) : AppColors.grey100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: enabled ? const Color(0xFF1976D2) : AppColors.grey400,
                size: 20.w,
              ),
            ),
            SizedBox(width: 16.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.interMedium16.copyWith(
                    fontSize: 16.sp,
                    color: enabled ? AppColors.onBackground : AppColors.grey400,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: AppTextStyles.interRegular14.copyWith(
                    fontSize: 12.sp,
                    color: enabled ? AppColors.grey500 : AppColors.grey400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          CupertinoSwitch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: const Color(0xFF1976D2),
            inactiveTrackColor: const Color(0xFFE2E8F0),
          ),
        ],
      ),
    );
  }
}
