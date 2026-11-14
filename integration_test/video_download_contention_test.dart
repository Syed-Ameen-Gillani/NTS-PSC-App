import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_playback_diagnostics.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'package:video_player/video_player.dart';

// Isolated delivery benchmark: no student progress, enrollment or course writes.
// Supply an ephemeral URL through the existing ignored video_profile_config.json.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const source = String.fromEnvironment('VIDEO_PROFILE_URL');
  testWidgets(
    'same video streams alone, during native download, and offline',
    (tester) async {
      final results = <String, dynamic>{};
      final task = DownloadTask(
        url: source,
        baseDirectory: BaseDirectory.temporary,
        directory: 'cboa-contention-test',
        filename: 'contention-${DateTime.now().microsecondsSinceEpoch}.mp4',
        allowPause: true,
      );
      Future<TaskStatusUpdate>? transfer;
      var transferFinished = false;
      Future<void> observe(
        String name,
        VideoPlayerController video, {
        bool concurrent = false,
      }) async {
        final events = <String>[];
        final diagnostics = VideoPlaybackDiagnostics(
          video,
          offline: name == 'offline',
          enabled: true,
          output: events.add,
        );
        var overlapMs = 0;
        try {
          await video.initialize().timeout(const Duration(seconds: 45));
          await tester.pumpWidget(
            ProviderScope(
              child: ScreenUtilInit(
                designSize: const Size(390, 844),
                builder: (_, _) => MaterialApp(
                  home: Scaffold(
                    body: ProfessionalVideoPlayer(controller: video),
                  ),
                ),
              ),
            ),
          );
          if (concurrent) {
            transfer = FileDownloader().download(task).then((result) {
              transferFinished = true;
              return result;
            });
          }
          await video.play();
          final clock = Stopwatch()..start();
          while (clock.elapsed < const Duration(seconds: 15)) {
            await tester.pump(const Duration(milliseconds: 250));
            if (concurrent && !transferFinished) overlapMs += 250;
          }
          expect(video.value.hasError, false);
          expect(video.value.position, greaterThan(Duration.zero));
          results[name] = {
            'position_ms': video.value.position.inMilliseconds,
            'download_overlap_sample_ms': overlapMs,
            'download_finished_in_window': concurrent && transferFinished,
          };
        } finally {
          diagnostics.dispose();
          results['${name}_events'] = events;
          await tester.pumpWidget(const SizedBox());
          await video.dispose();
        }
      }

      try {
        await observe(
          'stream_only',
          VideoPlayerController.networkUrl(Uri.parse(source)),
        );
        await observe(
          'stream_with_download',
          VideoPlayerController.networkUrl(Uri.parse(source)),
          concurrent: true,
        );
        final result = await transfer!.timeout(const Duration(minutes: 3));
        expect(result.status, TaskStatus.complete);
        final file = File(await task.filePath());
        expect(await file.length(), greaterThan(0));
        await observe('offline', VideoPlayerController.file(file));
      } finally {
        await FileDownloader().cancelTaskWithId(task.taskId);
        final file = File(await task.filePath());
        if (await file.exists()) await file.delete();
        binding.reportData = results;
        // Emit only sanitized metrics. Signed URLs never enter the results.
        debugPrint('CBOA.ContentionBenchmark: $results');
      }
    },
    skip: source.isEmpty,
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
