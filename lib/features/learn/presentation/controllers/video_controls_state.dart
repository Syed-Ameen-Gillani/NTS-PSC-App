import 'package:flutter_riverpod/legacy.dart';
import 'package:video_player/video_player.dart';

class VideoControlsState {
  const VideoControlsState({
    this.visible = true,
    this.scrubMilliseconds,
    this.resumeAfterScrub = false,
  });
  final bool visible;
  final double? scrubMilliseconds;
  final bool resumeAfterScrub;
}

final videoControlsProvider = StateProvider.autoDispose
    .family<VideoControlsState, Object>(
      (ref, key) => const VideoControlsState(),
    );
final videoCaptionsProvider = StateProvider.autoDispose
    .family<bool, VideoPlayerController>((ref, controller) => false);
final videoCoverFitProvider = StateProvider.autoDispose
    .family<bool, VideoPlayerController>((ref, controller) => false);
final videoUnmuteVolumeProvider = StateProvider.autoDispose
    .family<double, VideoPlayerController>((ref, controller) => 1);

String videoTime(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 1 << 31);
  final hours = seconds ~/ 3600;
  final minutes = (seconds ~/ 60) % 60;
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return hours > 0
      ? '$hours:${minutes.toString().padLeft(2, '0')}:$remainder'
      : '$minutes:$remainder';
}

Duration boundedVideoSeek(Duration position, Duration duration) => Duration(
  milliseconds: position.inMilliseconds.clamp(
    0,
    duration.inMilliseconds.clamp(0, 1 << 53),
  ),
);

String? activeVideoCaption(
  List<Map<String, dynamic>> segments,
  Duration position,
) {
  final seconds = position.inMilliseconds / 1000;
  for (final segment in segments) {
    final start = segment['start'];
    final end = segment['end'];
    final text = segment['text'];
    if (start is num &&
        end is num &&
        text is String &&
        start.isFinite &&
        end.isFinite &&
        seconds >= start &&
        seconds < end &&
        text.trim().isNotEmpty) {
      return text;
    }
  }
  return null;
}

final videoSpeedChangingProvider = StateProvider.autoDispose
    .family<bool, Object>((ref, controller) => false);
