import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_initialization.dart';

import 'support/fake_video_controller.dart';

class _LoadingVideo extends FakeVideoController {
  final loading = Completer<void>();
  @override
  Future<void> initialize() => loading.future;
}

void main() {
  test('successful initialization leaves controller owned by caller', () async {
    final video = _LoadingVideo()..loading.complete();
    addTearDown(video.dispose);
    await initializeLessonVideo(video);
    expect(video.disposed, false);
  });

  test('stalled initialization times out and starts cleanup', () async {
    final video = _LoadingVideo();
    await expectLater(
      initializeLessonVideo(video, timeout: const Duration(milliseconds: 10)),
      throwsA(isA<TimeoutException>()),
    );
    await Future<void>.delayed(Duration.zero);
    expect(video.disposed, true);
    // Late native errors are still handled by the timed-out future.
    video.loading.completeError(StateError('Late decoder error'));
    await Future<void>.delayed(Duration.zero);
  });

  test(
    'decoder failure is surfaced and failed controller is cleaned up',
    () async {
      final video = _LoadingVideo();
      final initialized = initializeLessonVideo(video);
      video.loading.completeError(StateError('Decoder unavailable'));
      await expectLater(initialized, throwsStateError);
      expect(video.disposed, true);
    },
  );
}
