import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class LessonPlaybackState {
  final bool isPlaying;
  final int positionSeconds;
  final int durationSeconds;
  final double speed;
  final String quality;
  final bool isBuffering;
  final String? activeQuizTriggerId;

  const LessonPlaybackState({
    required this.isPlaying,
    required this.positionSeconds,
    required this.durationSeconds,
    required this.speed,
    required this.quality,
    this.isBuffering = false,
    this.activeQuizTriggerId,
  });

  double get progress => durationSeconds > 0
      ? (positionSeconds / durationSeconds).clamp(0.0, 1.0)
      : 0.0;

  String get formattedPosition => _formatTime(positionSeconds);
  String get formattedDuration => _formatTime(durationSeconds);

  static String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final mm = minutes.toString().padLeft(2, '0');
    final ss = seconds.toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  LessonPlaybackState copyWith({
    bool? isPlaying,
    int? positionSeconds,
    int? durationSeconds,
    double? speed,
    String? quality,
    bool? isBuffering,
    String? activeQuizTriggerId,
    bool clearActiveQuizTrigger = false,
  }) {
    return LessonPlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      positionSeconds: positionSeconds ?? this.positionSeconds,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      speed: speed ?? this.speed,
      quality: quality ?? this.quality,
      isBuffering: isBuffering ?? this.isBuffering,
      activeQuizTriggerId: clearActiveQuizTrigger ? null : (activeQuizTriggerId ?? this.activeQuizTriggerId),
    );
  }
}

/// Specialized Riverpod 3 Notifier managing video playback state at scale.
/// Isolates 1 Hz playback ticks to prevent UI tree re-render overhead.
class LessonPlaybackNotifier extends Notifier<LessonPlaybackState> {
  Timer? _playbackTimer;

  // Checkpoints (in seconds) for surprise quizzes
  // 374s = 06:14, exactly matching the screenshot
  static const int checkpoint1 = 374;
  static const int checkpoint2 = 780;

  final Set<int> _triggeredCheckpoints = {};

  @override
  LessonPlaybackState build() {
    ref.onDispose(() {
      _playbackTimer?.cancel();
    });

    // Start with 06:14 / 25:00 as seen in the user's screenshot
    const initialPosition = 374; // 06:14
    const totalDuration = 25 * 60; // 1500s (25:00)

    final initialState = const LessonPlaybackState(
      isPlaying: false,
      positionSeconds: initialPosition,
      durationSeconds: totalDuration,
      speed: 1.0,
      quality: '1080p HD',
    );

    return initialState;
  }

  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void play() {
    if (state.isPlaying) return;
    state = state.copyWith(isPlaying: true);
    _startTimer();
  }

  void pause() {
    _playbackTimer?.cancel();
    state = state.copyWith(isPlaying: false);
  }

  void seekToSeconds(int seconds, {bool allowSkipGuard = true}) {
    final clamped = seconds.clamp(0, state.durationSeconds);

    // Anti-Skip Guard (Coursera-style):
    // If user attempts to drag past an unattempted mandatory checkpoint (374s),
    // clamp to checkpoint and prompt knowledge check.
    if (allowSkipGuard &&
        state.positionSeconds < checkpoint1 &&
        clamped > checkpoint1 &&
        !_triggeredCheckpoints.contains(checkpoint1)) {
      _triggerCheckpoint(checkpoint1);
      state = state.copyWith(positionSeconds: checkpoint1);
      return;
    }

    state = state.copyWith(positionSeconds: clamped);
  }

  void seekProgress(double progress) {
    final targetSeconds = (progress * state.durationSeconds).round();
    seekToSeconds(targetSeconds);
  }

  void rewind(int seconds) {
    final target = (state.positionSeconds - seconds).clamp(0, state.durationSeconds);
    state = state.copyWith(positionSeconds: target);
  }

  void forward(int seconds) {
    seekToSeconds(state.positionSeconds + seconds);
  }

  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
    if (state.isPlaying) {
      _playbackTimer?.cancel();
      _startTimer();
    }
  }

  void setQuality(String quality) {
    state = state.copyWith(quality: quality);
  }

  void clearQuizTrigger() {
    state = state.copyWith(clearActiveQuizTrigger: true);
  }

  void markCheckpointCompleted(int checkpointSeconds) {
    _triggeredCheckpoints.add(checkpointSeconds);
    clearQuizTrigger();
  }

  void _startTimer() {
    _playbackTimer?.cancel();
    final intervalMs = (1000 / state.speed).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: intervalMs), (_) {
      _tick();
    });
  }

  void _tick() {
    if (!state.isPlaying) return;

    final nextPosition = state.positionSeconds + 1;

    // Checkpoint detection (e.g. 06:14 = 374s)
    if (nextPosition >= checkpoint1 && !_triggeredCheckpoints.contains(checkpoint1)) {
      _triggerCheckpoint(checkpoint1);
      return;
    } else if (nextPosition >= checkpoint2 && !_triggeredCheckpoints.contains(checkpoint2)) {
      _triggerCheckpoint(checkpoint2);
      return;
    }

    if (nextPosition >= state.durationSeconds) {
      pause();
      state = state.copyWith(positionSeconds: state.durationSeconds);
    } else {
      state = state.copyWith(positionSeconds: nextPosition);
    }
  }

  void _triggerCheckpoint(int checkpointSeconds) {
    pause();
    _triggeredCheckpoints.add(checkpointSeconds);
    state = state.copyWith(
      positionSeconds: checkpointSeconds,
      activeQuizTriggerId: checkpointSeconds == checkpoint1 ? 'quiz_ajk_01' : 'quiz_ajk_02',
    );
  }
}

final lessonPlaybackControllerProvider =
    NotifierProvider<LessonPlaybackNotifier, LessonPlaybackState>(
  LessonPlaybackNotifier.new,
);
