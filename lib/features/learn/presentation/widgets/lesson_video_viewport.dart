import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/lesson_playback_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_source_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_player_status.dart';
import 'package:video_player/video_player.dart';

class LessonVideoViewport extends ConsumerWidget {
  const LessonVideoViewport({
    super.key,
    required this.course,
    required this.lesson,
  });
  final CourseModel course;
  final LessonModel lesson;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (AppConfig.isSupabaseEnabled && lesson.videoUrl.isEmpty) {
      return const VideoPlayerStatus(message: 'No video attached');
    }
    final source = (
      location: lesson.videoUrl.isNotEmpty
          ? lesson.videoUrl
          : 'assets/videos/lecture.mp4',
      asset: lesson.videoUrl.isEmpty,
    );
    return ref
        .watch(videoSourceProvider(source))
        .when(
          loading: () => const VideoPlayerStatus(loading: true),
          error: (_, _) => VideoPlayerStatus(
            message: 'Video could not be loaded.',
            onRetry: () => ref.invalidate(videoSourceProvider(source)),
          ),
          data: (controller) => _LegacyPlaybackBridge(
            controller: controller,
            title: lesson.title,
          ),
        );
  }
}

class _LegacyPlaybackBridge extends ConsumerStatefulWidget {
  const _LegacyPlaybackBridge({required this.controller, required this.title});
  final VideoPlayerController controller;
  final String title;
  @override
  ConsumerState<_LegacyPlaybackBridge> createState() =>
      _LegacyPlaybackBridgeState();
}

class _LegacyPlaybackBridgeState extends ConsumerState<_LegacyPlaybackBridge> {
  int _second = -1;
  bool? _playing;
  bool _syncingFromVideo = false;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_tick);
  }

  @override
  void didUpdateWidget(covariant _LegacyPlaybackBridge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_tick);
      _second = -1;
      _playing = null;
      widget.controller.addListener(_tick);
    }
  }

  void _tick() {
    if (!mounted) return;
    final value = widget.controller.value;
    if (_second == value.position.inSeconds && _playing == value.isPlaying) {
      return;
    }
    _second = value.position.inSeconds;
    _playing = value.isPlaying;
    _syncingFromVideo = true;
    try {
      ref
          .read(lessonPlaybackControllerProvider.notifier)
          .syncFromVideo(
            _second,
            durationSeconds: value.duration.inSeconds,
            isPlaying: value.isPlaying,
          );
    } finally {
      _syncingFromVideo = false;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_tick);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(lessonPlaybackControllerProvider, (previous, next) {
      final checkpointTriggered =
          next.activeQuizTriggerId != null &&
          previous?.activeQuizTriggerId != next.activeQuizTriggerId;
      if (!checkpointTriggered &&
          (_syncingFromVideo || previous?.isPlaying == next.isPlaying)) {
        return;
      }
      if (next.isPlaying != widget.controller.value.isPlaying) {
        if (next.isPlaying) {
          widget.controller.play();
        } else {
          widget.controller.pause();
        }
      }
    });
    return ProfessionalVideoPlayer(
      controller: widget.controller,
      title: widget.title,
    );
  }
}
