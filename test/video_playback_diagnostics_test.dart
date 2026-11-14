import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_playback_diagnostics.dart';

import 'support/fake_video_controller.dart';

void main() {
  test(
    'diagnostics log transitions once with buffer duration and no URL',
    () async {
      final video = FakeVideoController();
      addTearDown(video.dispose);
      final messages = <String>[];
      var elapsed = 0;
      final diagnostics = VideoPlaybackDiagnostics(
        video,
        offline: false,
        enabled: true,
        output: messages.add,
        elapsedMilliseconds: () => elapsed,
      );
      await video.play();
      video.value = video.value.copyWith(position: const Duration(seconds: 1));
      video.value = video.value.copyWith(isBuffering: true);
      elapsed = 1250;
      video.value = video.value.copyWith(isBuffering: false);
      for (var i = 2; i < 20; i++) {
        video.value = video.value.copyWith(position: Duration(seconds: i));
      }
      expect(
        messages.where((m) => m.startsWith('first_playing_position')).length,
        1,
      );
      expect(messages.where((m) => m.startsWith('buffer_start')).length, 1);
      expect(
        messages
            .where((m) => m.startsWith('buffer_end durationMs=1250'))
            .length,
        1,
      );
      video.value = video.value.copyWith(
        errorDescription: 'https://secret.invalid?token=private',
      );
      expect(
        messages.any(
          (m) => m.contains('secret.invalid') || m.contains('private'),
        ),
        false,
      );
      diagnostics.dispose();
      expect(messages.last, contains('totalBufferMs=1250'));
      final count = messages.length;
      video.value = video.value.copyWith(isBuffering: true);
      diagnostics.dispose();
      expect(messages.length, count);
    },
  );

  test('disabled diagnostics emit nothing', () async {
    final video = FakeVideoController();
    addTearDown(video.dispose);
    final messages = <String>[];
    final diagnostics = VideoPlaybackDiagnostics(
      video,
      offline: true,
      enabled: false,
      output: messages.add,
    );
    await video.play();
    diagnostics.dispose();
    expect(messages, isEmpty);
  });
}
