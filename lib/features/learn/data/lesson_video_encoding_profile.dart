import 'package:flutter_compress/flutter_compress.dart';

/// Size budgeting follows flutter_compress's 5% muxing safety allowance.
/// Audio is reserved conservatively because Android chooses its own AAC rate.
class LessonVideoEncodingProfile {
  static const targetMegabytes = 23;
  static const audioKbps = 192;
  static const minimumVideoKbps = 250;

  static VideoCompressConfig build(VideoInfo info, {int? targetMB}) {
    if (targetMB != null) {
      // A very short, high-bitrate source does not need the whole size budget.
      final sourceCeiling = info.bitrateKbps > 0
          ? info.bitrateKbps.clamp(1, 2500)
          : 2500;
      final usefulMB =
          ((sourceCeiling + audioKbps) *
                  info.durationMs /
                  (8 * 1024 * 1024 * .95))
              .ceil();
      targetMB = usefulMB.clamp(1, targetMB);
    }
    final budgetKbps = targetMB == null
        ? 2500
        : (targetMB * 1024 * 1024 * 8 * .95 / info.durationMs - audioKbps)
              .floor();
    if (budgetKbps < minimumVideoKbps) {
      throw ArgumentError(
        'This video is too long for the 25 MB limit. Split it into shorter lessons.',
      );
    }
    final shortEdge = budgetKbps >= 1500
        ? 720
        : budgetKbps >= 500
        ? 480
        : 360;
    final longEdge = shortEdge == 720
        ? 1280
        : shortEdge == 480
        ? 854
        : 640;
    return VideoCompressConfig(
      codec: VideoCodec.h264,
      container: VideoContainer.mp4,
      maxWidth: info.width >= info.height ? longEdge : shortEdge,
      maxHeight: info.width >= info.height ? shortEdge : longEdge,
      targetSizeMB: targetMB,
      videoBitrateKbps: targetMB != null
          ? null
          : (info.bitrateKbps > 0 ? info.bitrateKbps.clamp(1, 2500) : 2500),
      frameRate: 30,
      removeAudio: false,
      audioBitrateKbps: audioKbps,
      keepOriginalIfLarger: targetMB == null,
    );
  }
}
