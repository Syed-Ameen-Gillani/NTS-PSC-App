import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/in_video_quiz_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_playback_controller.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';

class LessonVideoViewport extends ConsumerStatefulWidget {
  final CourseModel course;
  final LessonModel lesson;

  const LessonVideoViewport({
    super.key,
    required this.course,
    required this.lesson,
  });

  @override
  ConsumerState<LessonVideoViewport> createState() => _LessonVideoViewportState();
}

class _LessonVideoViewportState extends ConsumerState<LessonVideoViewport> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Edge case for 1M+ scale: automatically pause playback when backgrounded
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      ref.read(lessonPlaybackControllerProvider.notifier).pause();
    }
  }

  void _showSpeedPicker(BuildContext context, double currentSpeed) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Playback Speed', style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp)),
                SizedBox(height: 12.h),
                ...speeds.map((s) {
                  final isSelected = (s == currentSpeed);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${s}x', style: AppTextStyles.interSemiBold16.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.onBackground,
                    )),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () {
                      ref.read(lessonPlaybackControllerProvider.notifier).setSpeed(s);
                      Navigator.pop(ctx);
                      CustomToast.showInfo(context, message: 'Speed set to ${s}x');
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

  void _showQualityPicker(BuildContext context, String currentQuality) {
    showModalBottomSheet<void>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (ctx) {
        final qualities = ['1080p HD', '720p', '480p', 'Auto'];
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Video Quality', style: AppTextStyles.interBold24.copyWith(fontSize: 16.sp)),
                SizedBox(height: 12.h),
                ...qualities.map((q) {
                  final isSelected = (q == currentQuality);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(q, style: AppTextStyles.interSemiBold16.copyWith(
                      color: isSelected ? AppColors.primary : AppColors.onBackground,
                    )),
                    trailing: isSelected ? const Icon(Icons.check, color: AppColors.primary) : null,
                    onTap: () {
                      ref.read(lessonPlaybackControllerProvider.notifier).setQuality(q);
                      Navigator.pop(ctx);
                      CustomToast.showInfo(context, message: 'Resolution switched to $q');
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

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(lessonPlaybackControllerProvider);
    final quizState = ref.watch(inVideoQuizControllerProvider);

    // Calculate checkpoint pip position (06:14 / 25:00 = 374 / 1500)
    final checkpointPipProgress = 374.0 / 1500.0;
    final isCheckpointCompleted = quizState.completedQuizIds.contains('quiz_ajk_01');

    return Container(
      width: double.infinity,
      height: 220.h,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Simulated Video Background
          Image.asset(
            widget.course.imagePath,
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFF1E293B),
              child: const Center(child: Icon(Icons.videocam_outlined, color: Colors.white54, size: 48)),
            ),
          ),
          Container(
            color: Colors.black.withValues(alpha: 0.50),
          ),

          // Play / Pause central button
          GestureDetector(
            onTap: () => ref.read(lessonPlaybackControllerProvider.notifier).togglePlayPause(),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.90),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                playbackState.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 32.w,
              ),
            ),
          ),

          // Top back button
          Positioned(
            top: 8.h,
            left: 8.w,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              onPressed: () => context.pop(),
            ),
          ),

          // Top resolution badge
          Positioned(
            top: 14.h,
            right: 16.w,
            child: GestureDetector(
              onTap: () => _showQualityPicker(context, playbackState.quality),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(6.r),
                  border: Border.all(color: Colors.white24, width: 0.8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      playbackState.quality,
                      style: AppTextStyles.interMedium16.copyWith(
                        color: Colors.white,
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(Icons.arrow_drop_down, size: 14.w, color: Colors.white70),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls Bar with Scrubber & Coursera Cue Pip
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
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
                  // Scrubber Stack with Checkpoint Diamond Cue Pip
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final sliderWidth = constraints.maxWidth;
                      // Account for slider padding (approx 12px on each side for thumbs)
                      final usableWidth = sliderWidth - 24.w;
                      final pipOffset = 12.w + (usableWidth * checkpointPipProgress);

                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                              overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
                              trackHeight: 3.h,
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.white24,
                              thumbColor: Colors.white,
                            ),
                            child: Slider(
                              value: playbackState.progress,
                              onChanged: (val) {
                                ref.read(lessonPlaybackControllerProvider.notifier).seekProgress(val);
                              },
                            ),
                          ),

                          // Coursera Diamond Cue Pip Indicator
                          Positioned(
                            left: pipOffset - 5.w,
                            child: GestureDetector(
                              onTap: () {
                                ref.read(inVideoQuizControllerProvider.notifier).triggerQuizById('quiz_ajk_01');
                              },
                              child: Container(
                                width: 10.w,
                                height: 10.w,
                                decoration: BoxDecoration(
                                  color: isCheckpointCompleted ? Colors.greenAccent : const Color(0xFFFFB300),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isCheckpointCompleted ? Colors.green : Colors.orange).withValues(alpha: 0.8),
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

                  // Bottom Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Timestamp (06:14 / 25:00)
                      Text(
                        '${playbackState.formattedPosition} / ${playbackState.formattedDuration}',
                        style: AppTextStyles.interRegular14.copyWith(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                      ),

                      // Speed and Fullscreen
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => _showSpeedPicker(context, playbackState.speed),
                            child: Row(
                              children: [
                                Icon(Icons.speed, color: Colors.white70, size: 16.w),
                                SizedBox(width: 4.w),
                                Text(
                                  '${playbackState.speed}x',
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
                            onTap: () {
                              CustomToast.showInfo(context, message: 'Fullscreen mode');
                            },
                            child: Icon(Icons.fullscreen, color: Colors.white, size: 20.w),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
