import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class CustomToast {
  static OverlayEntry? _activeEntry;
  static Timer? _dismissTimer;

  static void showSuccess(BuildContext context, {required String message}) {
    show(
      context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: AppColors.primary,
    );
  }

  static void showError(BuildContext context, {required String message}) {
    show(
      context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: AppColors.error,
    );
  }

  static void showInfo(BuildContext context, {required String message}) {
    show(
      context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: AppColors.primary,
    );
  }

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    _dismissTimer?.cancel();
    if (_activeEntry?.mounted ?? false) {
      _activeEntry!.remove();
    }

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    void removeOverlay() {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
      if (identical(_activeEntry, overlayEntry)) {
        _activeEntry = null;
      }
    }

    overlayEntry = OverlayEntry(
      builder: (context) {
        final bottomOffset = MediaQuery.of(context).padding.bottom + 32.h;
        return Positioned(
          bottom: bottomOffset,
          left: 16.w,
          right: 16.w,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 180),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, (1 - value) * 12.h),
                    child: child,
                  ),
                );
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 420.w),
                  child: Semantics(
                    liveRegion: true,
                    label: message,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(14.w, 6.h, 8.w, 6.h),
                      decoration: BoxDecoration(
                        color: backgroundColor ?? AppColors.grey900,
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 10.r,
                            offset: Offset(0, 4.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: Colors.white, size: 19.w),
                            SizedBox(width: 10.w),
                          ],
                          Expanded(
                            child: Text(
                              message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              softWrap: true,
                              textAlign: TextAlign.left,
                              style: AppTextStyles.interMedium16.copyWith(
                                fontSize: 13.sp,
                                height: 1.25,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 6.w),
                          IconButton(
                            tooltip: 'Dismiss',
                            onPressed: removeOverlay,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints.tightFor(
                              width: 32.w,
                              height: 32.w,
                            ),
                            icon: Icon(
                              Icons.close,
                              color: Colors.white.withValues(alpha: 0.82),
                              size: 18.w,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    _activeEntry = overlayEntry;
    overlayState.insert(overlayEntry);
    _dismissTimer = Timer(duration, removeOverlay);
  }
}
