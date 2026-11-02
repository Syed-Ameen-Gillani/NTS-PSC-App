import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/notifications/presentation/controllers/notification_inbox_controller.dart';
import 'package:nts_psc_app/features/notifications/presentation/widgets/notification_bell_button.dart';
import 'package:nts_psc_app/presentation/widgets/app_avatar.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).value;
    final isGuest = AppConfig.isSupabaseEnabled && authState?.user == null;
    final userName = isGuest
        ? 'Explore courses'
        : authState?.user?.name ??
              (AppConfig.isSupabaseEnabled ? 'Student' : 'Ahmed Ali');
    final userImage = authState?.user?.imagePath ?? '';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good morning,',
                  style: AppTextStyles.interRegular16.copyWith(
                    color: AppColors.grey500,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.interBold24.copyWith(
                    color: AppColors.onBackground,
                    fontSize: 22.sp,
                  ),
                ),
              ],
            ),
          ),
          if (!isGuest)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                NotificationBellButton(
                  unreadCount: ref.watch(notificationUnreadCountProvider),
                  onPressed: () =>
                      context.pushNamed(AppRoute.notificationInbox.name),
                ),
                SizedBox(width: 8.w),
                AppAvatar(size: 48.w, imagePath: userImage, name: userName),
              ],
            ),
        ],
      ),
    );
  }
}
