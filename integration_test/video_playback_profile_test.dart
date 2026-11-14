import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_playback_diagnostics.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'package:video_player/video_player.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('profile native playback, rate change and seeking', (
    tester,
  ) async {
    const source = String.fromEnvironment('VIDEO_PROFILE_URL');
    final video = source.isEmpty
        ? VideoPlayerController.asset('assets/videos/lecture.mp4')
        : VideoPlayerController.networkUrl(Uri.parse(source));
    final events = <String>[];
    final diagnostics = VideoPlaybackDiagnostics(
      video,
      offline: source.isEmpty,
      enabled: true,
      output: events.add,
    );
    final startup = Stopwatch()..start();
    try {
      await video.initialize().timeout(const Duration(seconds: 30));
      binding.reportData = {
        'source': source.isEmpty ? 'asset' : 'network',
        'initialization_ms': startup.elapsedMilliseconds,
      };
      await tester.pumpWidget(
        ProviderScope(
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (_, _) => MaterialApp(
              home: Scaffold(
                body: ProfessionalVideoPlayer(
                  controller: video,
                  title: 'Playback profile',
                ),
              ),
            ),
          ),
        ),
      );
      await binding.traceAction(() async {
        await video.play();
        for (var i = 0; i < 48; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(video.value.position, greaterThan(Duration.zero));
        // The sampled upload can be shorter than the first observation window.
        // Start the rate-change stage from zero even if it already ended.
        await video.seekTo(Duration.zero);
        await video.setPlaybackSpeed(2);
        await video.play();
        final before = video.value.position;
        for (var i = 0; i < 24; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(video.value.position, greaterThan(before));
        await video.seekTo(const Duration(seconds: 3));
        for (var i = 0; i < 16; i++) {
          await tester.pump(const Duration(milliseconds: 250));
        }
        expect(video.value.hasError, false);
        await video.pause();
      }, reportKey: 'playback_timeline');
    } finally {
      diagnostics.dispose();
      binding.reportData?['playback_events'] = events;
      await tester.pumpWidget(const SizedBox());
      await video.dispose();
    }
  });
}
