import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/in_video_quiz_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_playback_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_player_sheets.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_scrubber_bar.dart';
import 'package:nts_psc_app/features/learn/presentation/pages/full_screen_video_player_page.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:video_player/video_player.dart';

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
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;

  bool _showControls = true;
  Timer? _hideControlsTimer;

  bool _isDragging = false;
  double _dragProgress = 0.0;

  String? _seekFeedback;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      VideoPlayerController controller;
      if (widget.lesson.videoUrl.isNotEmpty && widget.lesson.videoUrl.startsWith('http')) {
        controller = VideoPlayerController.networkUrl(Uri.parse(widget.lesson.videoUrl));
      } else {
        controller = VideoPlayerController.asset('assets/videos/lecture.mp4');
      }

      await controller.initialize();
      await controller.setVolume(1.0);
      controller.setLooping(true);

      final currentPos = ref.read(lessonPlaybackControllerProvider).positionSeconds;
      if (currentPos > 0) {
        await controller.seekTo(Duration(seconds: currentPos));
      }

      if (mounted) {
        setState(() {
          _videoController = controller;
          _isVideoInitialized = true;
        });
        _videoController!.addListener(_onVideoTick);
      }
    } catch (_) {
      // Graceful fallback to synced simulation if offline or in test environment
      if (mounted) {
        setState(() => _isVideoInitialized = false);
      }
    }
  }

  void _onVideoTick() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    if (_isDragging) return; // Do not overwrite while learner is actively scrubbing

    final positionSec = _videoController!.value.position.inSeconds;
    final durationSec = _videoController!.value.duration.inSeconds;

    ref.read(lessonPlaybackControllerProvider.notifier).syncFromVideo(
      positionSec,
      durationSeconds: durationSec > 0 ? durationSec : 1500,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideControlsTimer?.cancel();
    _feedbackTimer?.cancel();
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausePlayback();
    }
  }

  void _startHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(milliseconds: 3500), () {
      if (mounted && ref.read(lessonPlaybackControllerProvider).isPlaying && !_isDragging) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls && ref.read(lessonPlaybackControllerProvider).isPlaying) {
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    final isPlaying = ref.read(lessonPlaybackControllerProvider).isPlaying;
    if (isPlaying) {
      _pausePlayback();
    } else {
      _resumePlayback();
    }
  }

  void _pausePlayback() {
    ref.read(lessonPlaybackControllerProvider.notifier).pause();
    _videoController?.pause();
    _hideControlsTimer?.cancel();
    setState(() => _showControls = true);
  }

  void _resumePlayback() {
    ref.read(lessonPlaybackControllerProvider.notifier).play();
    _videoController?.play();
    _startHideControlsTimer();
  }

  void _seekBy(int seconds) {
    _startHideControlsTimer();
    ref.read(lessonPlaybackControllerProvider.notifier).seekBy(seconds);

    if (_videoController != null && _videoController!.value.isInitialized) {
      final current = _videoController!.value.position;
      final target = current + Duration(seconds: seconds);
      final clamped = target < Duration.zero
          ? Duration.zero
          : (target > _videoController!.value.duration ? _videoController!.value.duration : target);
      _videoController!.seekTo(clamped);
    }

    _showSeekFeedback(seconds > 0 ? '+$seconds sec' : '$seconds sec');
  }

  void _showSeekFeedback(String text) {
    setState(() => _seekFeedback = text);
    _feedbackTimer?.cancel();
    _feedbackTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _seekFeedback = null);
    });
  }

  void _onSliderChangeStart(double val) {
    _hideControlsTimer?.cancel();
    setState(() {
      _isDragging = true;
      _dragProgress = val;
      _showControls = true;
    });
  }

  void _onSliderChanged(double val) {
    setState(() {
      _dragProgress = val;
    });
  }

  void _onSliderChangeEnd(double val) {
    setState(() {
      _isDragging = false;
    });

    ref.read(lessonPlaybackControllerProvider.notifier).seekProgress(val);

    if (_videoController != null && _videoController!.value.isInitialized) {
      final totalMs = _videoController!.value.duration.inMilliseconds;
      final targetMs = (val * totalMs).round();
      _videoController!.seekTo(Duration(milliseconds: targetMs));
    }

    _startHideControlsTimer();
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(lessonPlaybackControllerProvider);
    final quizState = ref.watch(inVideoQuizControllerProvider);

    final checkpointPipProgress = 374.0 / playbackState.durationSeconds;
    final isCheckpointCompleted = quizState.completedQuizIds.contains('quiz_ajk_01');

    final activeProgress = _isDragging ? _dragProgress : playbackState.progress;
    final displayedPositionSec = _isDragging
        ? (_dragProgress * playbackState.durationSeconds).round()
        : playbackState.positionSeconds;

    return Container(
      width: double.infinity,
      height: 220.h,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Real Video Player OR Fallback Poster Thumbnail
          if (_isVideoInitialized && _videoController != null)
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            )
          else
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

          // Dark overlay when controls are visible
          AnimatedOpacity(
            opacity: _showControls ? 0.45 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Container(color: Colors.black),
          ),

          // Double tap gesture detection areas
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                    onDoubleTap: () => _seekBy(-10),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                    onDoubleTap: () => _seekBy(10),
                  ),
                ),
              ],
            ),
          ),

          // Double-Tap Feedback Indicator (+10s / -10s)
          if (_seekFeedback != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _seekFeedback!.startsWith('+') ? Icons.fast_forward : Icons.fast_rewind,
                    color: Colors.white,
                    size: 16.w,
                  ),
                  SizedBox(width: 6.w),
                  Text(_seekFeedback!, style: AppTextStyles.interBold24.copyWith(color: Colors.white, fontSize: 13.sp)),
                ],
              ),
            ),

          // Auto-Hiding Controls Overlay Layer
          IgnorePointer(
            ignoring: !_showControls,
            child: AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 250),
              child: Stack(
                children: [
                  // Top Back Button & Resolution Badge
                  Positioned(
                    top: 8.h,
                    left: 8.w,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Positioned(
                    top: 14.h,
                    right: 16.w,
                    child: GestureDetector(
                      onTap: () {
                        _hideControlsTimer?.cancel();
                        VideoPlayerSheets.showQualityPicker(
                          context: context,
                          currentQuality: playbackState.quality,
                          onQualitySelected: (q) {
                            ref.read(lessonPlaybackControllerProvider.notifier).setQuality(q);
                            _startHideControlsTimer();
                            CustomToast.showInfo(context, message: 'Resolution switched to $q');
                          },
                        );
                      },
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

                  // Center Controls: 10s Rewind | Play/Pause | 10s Forward
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 32.w,
                          icon: const Icon(Icons.replay_10, color: Colors.white),
                          onPressed: () => _seekBy(-10),
                        ),
                        SizedBox(width: 24.w),
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            padding: EdgeInsets.all(14.w),
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
                        SizedBox(width: 24.w),
                        IconButton(
                          iconSize: 32.w,
                          icon: const Icon(Icons.forward_10, color: Colors.white),
                          onPressed: () => _seekBy(10),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Controls: VideoScrubberBar Component
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoScrubberBar(
                      activeProgress: activeProgress,
                      checkpointPipProgress: checkpointPipProgress,
                      isCheckpointCompleted: isCheckpointCompleted,
                      formattedPosition: _formatTime(displayedPositionSec),
                      formattedDuration: playbackState.formattedDuration,
                      speed: playbackState.speed,
                      onChangeStart: _onSliderChangeStart,
                      onChanged: _onSliderChanged,
                      onChangeEnd: _onSliderChangeEnd,
                      onCheckpointTap: () {
                        _pausePlayback();
                        ref.read(inVideoQuizControllerProvider.notifier).triggerQuizById('quiz_ajk_01');
                      },
                      onSpeedTap: () {
                        _hideControlsTimer?.cancel();
                        VideoPlayerSheets.showSpeedPicker(
                          context: context,
                          currentSpeed: playbackState.speed,
                          onSpeedSelected: (s) {
                            ref.read(lessonPlaybackControllerProvider.notifier).setSpeed(s);
                            _videoController?.setPlaybackSpeed(s);
                            _startHideControlsTimer();
                            CustomToast.showInfo(context, message: 'Speed set to ${s}x');
                          },
                        );
                      },
                      onFullscreenTap: () {
                        _pausePlayback();
                        FullScreenVideoPlayerPage.push(
                          context,
                          course: widget.course,
                          lesson: widget.lesson,
                        );
                      },
                    ),
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
