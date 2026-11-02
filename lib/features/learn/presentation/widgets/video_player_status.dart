import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class VideoPlayerStatus extends StatelessWidget {
  const VideoPlayerStatus({
    super.key,
    this.loading = false,
    this.message = 'Video unavailable',
    this.onRetry,
  });
  final bool loading;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 16 / 9,
    child: ColoredBox(
      color: AppColors.videoBackground,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_disabled_outlined,
                      color: AppColors.videoForeground,
                      size: 28.r,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.interRegular14.copyWith(
                        color: AppColors.videoForeground,
                      ),
                    ),
                    if (onRetry != null)
                      TextButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.videoForeground,
                        ),
                      ),
                  ],
                ),
        ),
      ),
    ),
  );
}
