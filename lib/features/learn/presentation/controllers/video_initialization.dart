import 'dart:async';

import 'package:video_player/video_player.dart';

const videoLoadTimeout = Duration(seconds: 30);

/// Native initialization can remain pending on an unreachable media URL. Return
/// an actionable error without awaiting a decoder teardown that may also stall.
Future<void> initializeLessonVideo(
  VideoPlayerController controller, {
  Duration timeout = videoLoadTimeout,
}) async {
  try {
    await controller.initialize().timeout(timeout);
  } catch (_) {
    unawaited(controller.dispose().catchError((Object _) {}));
    rethrow;
  }
}
