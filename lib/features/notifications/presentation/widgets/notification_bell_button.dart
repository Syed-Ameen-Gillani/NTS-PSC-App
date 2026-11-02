import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Notifications',
    onPressed: onPressed,
    icon: SizedBox(
      width: 28.w,
      height: 28.w,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Icon(
              Icons.notifications_none,
              color: AppColors.onBackground,
              size: 24.w,
            ),
          ),
          if (unreadCount > 0)
            Positioned(
              right: -3.w,
              top: -3.h,
              child: Container(
                constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.w),
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 99 ? '99+' : '$unreadCount',
                  style: AppTextStyles.interSemiBold16.copyWith(
                    color: AppColors.onPrimary,
                    fontSize: 9.sp,
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
