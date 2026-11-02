import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class VideoPlayerSheets {
  static void showSpeedPicker({
    required BuildContext context,
    required double currentSpeed,
    required ValueChanged<double> onSpeedSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Playback Speed',
                  style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp),
                ),
                SizedBox(height: 12.h),
                ...speeds.map((s) {
                  final isSelected = (s == currentSpeed);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${s}x',
                      style: AppTextStyles.interSemiBold16.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onBackground,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onSpeedSelected(s);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  static void showQualityPicker({
    required BuildContext context,
    required String currentQuality,
    required ValueChanged<String> onQualitySelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) {
        final qualities = ['1080p HD', '720p', '480p', 'Auto'];
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video Quality',
                  style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp),
                ),
                SizedBox(height: 12.h),
                ...qualities.map((q) {
                  final isSelected = (q == currentQuality);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      q,
                      style: AppTextStyles.interSemiBold16.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.onBackground,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      Navigator.pop(ctx);
                      onQualitySelected(q);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
