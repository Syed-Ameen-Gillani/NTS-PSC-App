import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class CustomConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String? cancelText;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final bool isDestructive;
  final IconData? icon;
  final Color? backgroundColor;

  const CustomConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.confirmText,
    this.cancelText,
    required this.onConfirm,
    this.onCancel,
    this.isDestructive = false,
    this.icon,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final defaultBgColor = backgroundColor ?? (isDestructive ? Colors.white : const Color(0xFFF4F7FD));
    final iconColor = isDestructive ? const Color(0xFFD32F2F) : AppColors.primary;
    final iconBgColor = isDestructive ? const Color(0xFFFCE4EC) : const Color(0xFFD0E3FA);
    final displayIcon = icon ?? (isDestructive ? Icons.warning_amber_rounded : Icons.headset_mic_outlined);

    return Dialog(
      backgroundColor: defaultBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: const Color(0xFFE2E8F0), width: 1.w),
      ),
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.only(bottom: 16.h),
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                displayIcon,
                color: iconColor,
                size: 32.w,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.interBold24.copyWith(
                fontSize: 20.sp,
                color: AppColors.onBackground,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              content,
              textAlign: TextAlign.center,
              style: AppTextStyles.interRegular16.copyWith(
                color: AppColors.grey500,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32.h),
            if (cancelText != null)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 56.h,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          if (onCancel != null) onCancel!();
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppColors.grey300, width: 1.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                        ),
                        child: Text(
                          cancelText!,
                          style: AppTextStyles.interSemiBold16.copyWith(
                            color: AppColors.onBackground,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: SizedBox(
                      height: 56.h,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive ? const Color(0xFFE53935) : AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50.r),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmText,
                          style: AppTextStyles.interSemiBold16.copyWith(
                            color: Colors.white,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 56.h,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDestructive ? const Color(0xFFE53935) : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50.r),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    confirmText,
                    style: AppTextStyles.interSemiBold16.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
