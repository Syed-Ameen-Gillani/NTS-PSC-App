import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';

class VideoScrubberBar extends StatelessWidget {
  final double activeProgress;
  final double checkpointPipProgress;
  final bool isCheckpointCompleted;
  final String formattedPosition;
  final String formattedDuration;
  final double speed;
  final bool isFullScreen;
  final ValueChanged<double> onChangeStart;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final VoidCallback onCheckpointTap;
  final VoidCallback onSpeedTap;
  final VoidCallback onFullscreenTap;

  const VideoScrubberBar({
    super.key,
    required this.activeProgress,
    required this.checkpointPipProgress,
    required this.isCheckpointCompleted,
    required this.formattedPosition,
    required this.formattedDuration,
    required this.speed,
    this.isFullScreen = false,
    required this.onChangeStart,
    required this.onChanged,
    required this.onChangeEnd,
    required this.onCheckpointTap,
    required this.onSpeedTap,
    required this.onFullscreenTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.85)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Draggable Scrubber with Checkpoint Cue Pip
          LayoutBuilder(
            builder: (context, constraints) {
              final sliderWidth = constraints.maxWidth;
              final usableWidth = sliderWidth - 24.w;
              final pipOffset =
                  12.w + (usableWidth * checkpointPipProgress.clamp(0.0, 1.0));

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      thumbShape: RoundSliderThumbShape(
                        enabledThumbRadius: 6.r,
                      ),
                      overlayShape: RoundSliderOverlayShape(
                        overlayRadius: 14.r,
                      ),
                      trackHeight: 3.h,
                      activeTrackColor: AppColors.primary,
                      inactiveTrackColor: Colors.white24,
                      thumbColor: Colors.white,
                    ),
                    child: Slider(
                      value: activeProgress.clamp(0.0, 1.0),
                      onChangeStart: onChangeStart,
                      onChanged: onChanged,
                      onChangeEnd: onChangeEnd,
                    ),
                  ),

                  // Coursera Checkpoint Pip
                  Positioned(
                    left: pipOffset - 5.w,
                    child: GestureDetector(
                      onTap: onCheckpointTap,
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          color: isCheckpointCompleted
                              ? Colors.greenAccent
                              : const Color(0xFFFFB300),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  (isCheckpointCompleted
                                          ? Colors.green
                                          : Colors.orange)
                                      .withValues(alpha: 0.8),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // Bottom Timestamps and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$formattedPosition / $formattedDuration',
                style: AppTextStyles.interRegular14.copyWith(
                  color: Colors.white70,
                  fontSize: 11.sp,
                ),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onSpeedTap,
                    child: Row(
                      children: [
                        Icon(Icons.speed, color: Colors.white70, size: 16.w),
                        SizedBox(width: 4.w),
                        Text(
                          '${speed}x',
                          style: AppTextStyles.interMedium16.copyWith(
                            color: Colors.white70,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 14.w),
                  GestureDetector(
                    onTap: onFullscreenTap,
                    child: Icon(
                      isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                      size: 20.w,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
