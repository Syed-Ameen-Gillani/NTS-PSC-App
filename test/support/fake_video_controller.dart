import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

/// Controller-level test double; no native decoder or network is exercised.
class FakeVideoController extends VideoPlayerController {
  FakeVideoController() : super.asset('test.mp4') {
    value = VideoPlayerValue(
      duration: const Duration(minutes: 2),
      size: const Size(1280, 720),
      isInitialized: true,
      buffered: [DurationRange(Duration.zero, const Duration(minutes: 1))],
    );
  }
  final seeks = <Duration>[];
  bool disposed = false;
  @override
  Future<void> play() async {
    value = value.copyWith(isPlaying: true);
  }

  @override
  Future<void> pause() async {
    value = value.copyWith(isPlaying: false);
  }

  @override
  Future<void> seekTo(Duration position) async {
    seeks.add(position);
    value = value.copyWith(position: position);
  }

  @override
  Future<void> setPlaybackSpeed(double speed) async {
    value = value.copyWith(playbackSpeed: speed);
  }

  @override
  Future<void> setVolume(double volume) async {
    value = value.copyWith(volume: volume);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await super.dispose();
  }
}
