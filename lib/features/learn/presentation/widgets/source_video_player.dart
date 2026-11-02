import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_source_provider.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/study_video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_player_status.dart';

class SourceVideoPlayer extends ConsumerWidget {
  const SourceVideoPlayer({
    super.key,
    required this.source,
    required this.title,
    required this.lessonId,
    this.autoPlay = false,
    this.trackLearning = false,
    this.onEnded,
  });
  final LessonVideoSource source;
  final String title;
  final String lessonId;
  final bool autoPlay;
  final bool trackLearning;
  final VoidCallback? onEnded;
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(videoSourceProvider(source))
      .when(
        loading: () => const VideoPlayerStatus(loading: true),
        error: (_, _) => VideoPlayerStatus(
          message: 'Video could not be loaded.',
          onRetry: () => ref.invalidate(videoSourceProvider(source)),
        ),
        data: (controller) => StudyVideoPlayer(
          controller: controller,
          lessonId: lessonId,
          source: source.location,
          autoPlay: autoPlay,
          trackLearning: trackLearning,
          onEnded: onEnded,
          title: title,
          onRetry: () => ref.invalidate(videoSourceProvider(source)),
        ),
      );
}
