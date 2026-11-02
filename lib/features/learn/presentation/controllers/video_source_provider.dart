import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_initialization.dart';

typedef LessonVideoSource = ({String location, bool asset});

final videoSourceProvider = FutureProvider.autoDispose
    .family<VideoPlayerController, LessonVideoSource>((ref, source) async {
      var disposed = false;
      final video = source.asset
          ? VideoPlayerController.asset(source.location)
          : VideoPlayerController.networkUrl(Uri.parse(source.location));
      ref.onDispose(() {
        disposed = true;
        video.dispose();
      });
      await initializeLessonVideo(video);
      if (disposed) throw StateError('Player closed.');
      await video.setLooping(false);
      return video;
    });
