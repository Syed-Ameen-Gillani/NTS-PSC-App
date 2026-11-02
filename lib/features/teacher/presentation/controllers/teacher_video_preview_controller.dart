import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:video_player/video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_initialization.dart';

final teacherVideoPreviewProvider = FutureProvider.autoDispose
    .family<VideoPlayerController, String>((ref, path) async {
      var disposed = false;
      VideoPlayerController? controller;
      ref.onDispose(() {
        disposed = true;
        controller?.dispose();
      });
      final uri = await ref
          .read(lessonMediaRepositoryProvider)
          .signedVideoUrl(path)
          .timeout(videoLoadTimeout);
      if (disposed) throw StateError('Preview closed.');
      final video = VideoPlayerController.networkUrl(uri);
      controller = video;
      await initializeLessonVideo(video);
      if (disposed) throw StateError('Preview closed.');
      try {
        await ref
            .read(learningEvidenceRepositoryProvider)
            .confirmVideo(path, video.value.duration.inMilliseconds);
      } catch (_) {
        /* Preview remains usable if metadata registration fails. */
      }
      return video;
    });
