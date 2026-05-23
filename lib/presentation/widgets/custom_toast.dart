import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class CustomToast {
  static void showSuccess(BuildContext context, {required String message}) {
    show(context, message: message, icon: Icons.check_circle, backgroundColor: AppColors.primary);
  }

  static void showError(BuildContext context, {required String message}) {
    show(context, message: message, icon: Icons.error_outline, backgroundColor: AppColors.error);
  }

  static void showInfo(BuildContext context, {required String message}) {
    show(context, message: message, icon: Icons.info_outline, backgroundColor: AppColors.primary);
  }

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    bool isRemoved = false;

    void removeOverlay() {
      if (!isRemoved) {
        isRemoved = true;
        overlayEntry.remove();
      }
    }

    overlayEntry = OverlayEntry(
      builder: (context) {
        final bottomOffset = MediaQuery.of(context).padding.bottom + 32.h;
        return Positioned(
          bottom: bottomOffset,
          left: 24.w,
          right: 24.w,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 250),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 20),
                    child: child,
                  ),
                );
              },
              child: Center(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: backgroundColor ?? AppColors.grey900.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 20.w),
                        SizedBox(width: 12.w),
                      ],
                      Expanded(
                        child: Text(
                          message,
                          textAlign: TextAlign.left,
                          style: AppTextStyles.interMedium16.copyWith(
                            fontSize: 14.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      GestureDetector(
                        onTap: removeOverlay,
                        child: Icon(Icons.close, color: Colors.white.withOpacity(0.8), size: 18.w),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    Future.delayed(duration, () {
      removeOverlay();
    });
  }
}
