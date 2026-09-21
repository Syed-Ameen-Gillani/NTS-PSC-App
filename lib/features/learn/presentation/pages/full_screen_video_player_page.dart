import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/in_video_quiz_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_playback_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/in_video_quiz_dialog.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_player_sheets.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_scrubber_bar.dart';
import 'package:nts_psc_app/presentation/widgets/custom_toast.dart';
import 'package:video_player/video_player.dart';

class FullScreenVideoPlayerPage extends ConsumerStatefulWidget {
  final CourseModel course;
  final LessonModel lesson;

  const FullScreenVideoPlayerPage({
    super.key,
    required this.course,
    required this.lesson,
  });

  static Future<void> push(BuildContext context, {required CourseModel course, required LessonModel lesson}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => FullScreenVideoPlayerPage(course: course, lesson: lesson),
      ),
    );
  }

  @override
  ConsumerState<FullScreenVideoPlayerPage> createState() => _FullScreenVideoPlayerPageState();
}

class _FullScreenVideoPlayerPageState extends ConsumerState<FullScreenVideoPlayerPage> {
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
    // Lock to landscape and immersive mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

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

      // Seek to current playback position
      final currentPos = ref.read(lessonPlaybackControllerProvider).positionSeconds;
      if (currentPos > 0) {
        await controller.seekTo(Duration(seconds: currentPos));
      }

      if (ref.read(lessonPlaybackControllerProvider).isPlaying) {
        await controller.play();
      }

      if (mounted) {
        setState(() {
          _videoController = controller;
          _isVideoInitialized = true;
        });
        _videoController!.addListener(_onVideoTick);
      }
    } catch (_) {
      if (mounted) setState(() => _isVideoInitialized = false);
    }
  }

  void _onVideoTick() {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    if (_isDragging) return;

    final positionSec = _videoController!.value.position.inSeconds;
    final durationSec = _videoController!.value.duration.inSeconds;

    ref.read(lessonPlaybackControllerProvider.notifier).syncFromVideo(
      positionSec,
      durationSeconds: durationSec > 0 ? durationSec : 1500,
    );
  }

  @override
  void dispose() {
    // Restore portrait and normal system overlays
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    _hideControlsTimer?.cancel();
    _feedbackTimer?.cancel();
    _videoController?.removeListener(_onVideoTick);
    _videoController?.dispose();
    super.dispose();
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
    setState(() => _showControls = !_showControls);
    if (_showControls && ref.read(lessonPlaybackControllerProvider).isPlaying) {
      _startHideControlsTimer();
    }
  }

  void _togglePlayPause() {
    final isPlaying = ref.read(lessonPlaybackControllerProvider).isPlaying;
    if (isPlaying) {
      ref.read(lessonPlaybackControllerProvider.notifier).pause();
      _videoController?.pause();
      _hideControlsTimer?.cancel();
      setState(() => _showControls = true);
    } else {
      ref.read(lessonPlaybackControllerProvider.notifier).play();
      _videoController?.play();
      _startHideControlsTimer();
    }
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

    setState(() => _seekFeedback = seconds > 0 ? '+$seconds sec' : '$seconds sec');
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
    setState(() => _dragProgress = val);
  }

  void _onSliderChangeEnd(double val) {
    setState(() => _isDragging = false);
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

    // Listen for surprise quiz in fullscreen mode
    ref.listen<LessonPlaybackState>(
      lessonPlaybackControllerProvider,
      (prev, next) {
        if (next.activeQuizTriggerId != null && prev?.activeQuizTriggerId != next.activeQuizTriggerId) {
          _videoController?.pause();
          ref.read(inVideoQuizControllerProvider.notifier).triggerQuizById(next.activeQuizTriggerId!);
          InVideoQuizDialog.show(context);
        }
      },
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Fullscreen Video Viewport
          if (_isVideoInitialized && _videoController != null)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            Image.asset(
              widget.course.imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),

          // Dark overlay when controls visible
          AnimatedOpacity(
            opacity: _showControls ? 0.45 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Container(color: Colors.black),
          ),

          // Double tap gesture detection (Left 50% = -10s, Right 50% = +10s)
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
              child: SafeArea(
                child: Stack(
                  children: [
                    // Top Bar: Back / Exit button & Lecture Title
                    Positioned(
                      top: 12.h,
                      left: 16.w,
                      right: 16.w,
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.course.title,
                                  style: AppTextStyles.interMedium16.copyWith(color: Colors.white70, fontSize: 11.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  widget.lesson.title,
                                  style: AppTextStyles.interBold24.copyWith(color: Colors.white, fontSize: 14.sp),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
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
                              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(6.r),
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: Text(
                                playbackState.quality,
                                style: AppTextStyles.interMedium16.copyWith(color: Colors.white, fontSize: 11.sp),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Center Controls: 10s Rewind | Play/Pause | 10s Forward
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            iconSize: 40.w,
                            icon: const Icon(Icons.replay_10, color: Colors.white),
                            onPressed: () => _seekBy(-10),
                          ),
                          SizedBox(width: 36.w),
                          GestureDetector(
                            onTap: _togglePlayPause,
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
                                size: 36.w,
                              ),
                            ),
                          ),
                          SizedBox(width: 36.w),
                          IconButton(
                            iconSize: 40.w,
                            icon: const Icon(Icons.forward_10, color: Colors.white),
                            onPressed: () => _seekBy(10),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Controls: VideoScrubberBar Component (isFullScreen: true)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: VideoScrubberBar(
                        activeProgress: activeProgress,
                        checkpointPipProgress: checkpointPipProgress,
                        isCheckpointCompleted: isCheckpointCompleted,
                        isFullScreen: true,
                        formattedPosition: _formatTime(displayedPositionSec),
                        formattedDuration: playbackState.formattedDuration,
                        speed: playbackState.speed,
                        onChangeStart: _onSliderChangeStart,
                        onChanged: _onSliderChanged,
                        onChangeEnd: _onSliderChangeEnd,
                        onCheckpointTap: () {
                          _videoController?.pause();
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
                        onFullscreenTap: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
