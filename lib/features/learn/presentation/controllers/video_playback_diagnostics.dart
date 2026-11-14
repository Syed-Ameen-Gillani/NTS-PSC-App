import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

/// Transition-only diagnostics. Never includes media URLs, tokens or user data.
/// Enable in release builds with --dart-define=VIDEO_DIAGNOSTICS=true.
class VideoPlaybackDiagnostics {
  VideoPlaybackDiagnostics(
    this.controller, {
    required this.offline,
    bool? enabled,
    void Function(String)? output,
    int Function()? elapsedMilliseconds,
  }) : enabled =
           enabled ??
           (!kReleaseMode || const bool.fromEnvironment('VIDEO_DIAGNOSTICS')),
       _output = output ?? _log,
       _elapsed = elapsedMilliseconds {
    _clock.start();
    controller.addListener(_changed);
    _emit('attached');
    _changed();
  }

  final VideoPlayerController controller;
  final bool offline;
  final bool enabled;
  final void Function(String) _output;
  final int Function()? _elapsed;
  final _clock = Stopwatch();
  bool _ready = false;
  bool _started = false;
  bool _buffering = false;
  bool _failed = false;
  bool _disposed = false;
  double? _speed;
  int? _bufferStart;
  int _bufferCount = 0;
  int _bufferMs = 0;
  int get _now => _elapsed?.call() ?? _clock.elapsedMilliseconds;

  static void _log(String message) =>
      developer.log(message, name: 'CBOA.VideoPlayback');

  void _emit(String event) {
    if (!enabled) return;
    final value = controller.value;
    var ahead = 0;
    for (final range in value.buffered) {
      if (range.start <= value.position && range.end > value.position) {
        ahead = (range.end - value.position).inMilliseconds;
        break;
      }
    }
    _output(
      '$event elapsedMs=$_now source=${offline ? 'offline' : 'network'} '
      'positionMs=${value.position.inMilliseconds} bufferAheadMs=$ahead '
      'playing=${value.isPlaying} speed=${value.playbackSpeed}',
    );
  }

  void _changed() {
    if (_disposed || !enabled) return;
    final value = controller.value;
    if (value.isInitialized && !_ready) {
      _ready = true;
      _emit(
        'initialized durationMs=${value.duration.inMilliseconds} '
        'width=${value.size.width.toInt()} height=${value.size.height.toInt()}',
      );
    }
    // Position advancement is an observable startup proxy, not a native
    // first-frame callback. Initial seek/restore can also advance position.
    if (!_started && value.isPlaying && value.position > Duration.zero) {
      _started = true;
      _emit('first_playing_position');
    }
    if (value.isBuffering != _buffering) {
      _buffering = value.isBuffering;
      if (_buffering) {
        _bufferStart = _now;
        _bufferCount++;
        _emit(
          'buffer_start phase=${_started ? 'playback_or_seek' : 'startup'}',
        );
      } else {
        final duration = _now - (_bufferStart ?? _now);
        _bufferMs += duration;
        _bufferStart = null;
        _emit('buffer_end durationMs=$duration');
      }
    }
    if (_speed != value.playbackSpeed) {
      _speed = value.playbackSpeed;
      _emit('speed_changed');
    }
    if (value.hasError && !_failed) {
      _failed = true;
      // Native error descriptions can contain signed URLs.
      _emit('native_error');
    }
  }

  void dispose() {
    if (_disposed) return;
    controller.removeListener(_changed);
    final pending = _bufferStart == null ? 0 : _now - _bufferStart!;
    _emit(
      'session_end bufferEvents=$_bufferCount '
      'totalBufferMs=${_bufferMs + pending}',
    );
    _disposed = true;
    _clock.stop();
  }
}
