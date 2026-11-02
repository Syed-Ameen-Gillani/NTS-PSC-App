import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:nts_psc_app/features/learn/domain/playback_evidence_sampler.dart';
import 'professional_video_player.dart' show VideoPlayerSession;

/// Lifecycle glue only; persistence and verification live in the repository/SQL.
class VideoLearningObserver extends ConsumerStatefulWidget {
  const VideoLearningObserver({
    super.key,
    required this.lessonId,
    required this.source,
    required this.controller,
    required this.child,
  });
  final String lessonId;
  final String source;
  final VideoPlayerController controller;
  final Widget child;
  @override
  ConsumerState<VideoLearningObserver> createState() =>
      _VideoLearningObserverState();
}

class _VideoLearningObserverState extends ConsumerState<VideoLearningObserver>
    with WidgetsBindingObserver {
  final sampler = PlaybackEvidenceSampler();
  final clock = Stopwatch();
  late final LearningEvidenceRepository repository;
  Map<String, dynamic>? ticket;
  String? owner;
  Timer? timer;
  bool foreground = true;
  bool busy = false;
  int ticks = 0;
  int nextAttemptMs = 0;
  bool wasPlaying = false;
  ({int start, int end, int wallMs, double speed})? pending;

  @override
  void initState() {
    super.initState();
    repository = ref.read(learningEvidenceRepositoryProvider);
    owner = repository.user;
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(transition);
    clock.start();
    timer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => unawaited(tick()),
    );
    unawaited(tick());
  }

  void transition() {
    final value = widget.controller.value;
    if (value.isPlaying && !wasPlaying) {
      sampler.reset();
      sampler.sample(
        positionMs: value.position.inMilliseconds,
        clockMs: clock.elapsedMilliseconds,
        playing: true,
        buffering: value.isBuffering,
        active: foreground,
        speed: value.playbackSpeed,
      );
    }
    if (!value.isPlaying && wasPlaying) unawaited(_syncPlaybackBoundary());
    wasPlaying = value.isPlaying;
  }

  Future<void> _syncPlaybackBoundary() async {
    try {
      // A timer tick may already be sampling. Wait for it rather than allowing
      // the video-end callback to sync an incomplete queue.
      while (busy && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      if (!mounted) return;
      await tick();
      while (busy && mounted) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      if (!mounted) return;
      await flush();
      await repository.sync();
    } catch (_) {
      // The durable queue retries on the next periodic sync or reconnection.
    }
  }

  Future<void> flush() async {
    final value = pending;
    pending = null;
    if (value == null || ticket == null || owner == null) return;
    await repository.append(
      owner!,
      ticket!,
      start: value.start,
      end: value.end,
      wallMs: value.wallMs,
      speed: value.speed,
    );
  }

  Future<void> tick() async {
    if (busy || !mounted || owner != repository.user) return;
    busy = true;
    try {
      if (ticket == null) {
        if (clock.elapsedMilliseconds < nextAttemptMs) return;
        // Retry on connection recovery, without interrupting playback.
        ticket = await repository.videoSession(
          widget.lessonId,
          source: widget.source,
        );
        developer.log(
          ticket == null
              ? 'No video activity session for lesson ${widget.lessonId}.'
              : 'Tracking lesson ${widget.lessonId}; durationMs=${ticket!['units']}.',
          name: 'CBOA.LearningProgress',
        );
        sampler.reset();
        wasPlaying = false;
        if (mounted) transition();
        return;
      }
      if (!mounted) return;
      final current = ModalRoute.of(context)?.isCurrent ?? false;
      final route = GoRouter.maybeOf(context)?.state;
      final session = route?.extra;
      final fullscreen =
          route?.uri.path == AppRoute.videoFullscreen.path &&
          session is VideoPlayerSession &&
          identical(session.controller, widget.controller);
      final value = widget.controller.value;
      final evidence = sampler.sample(
        positionMs: value.position.inMilliseconds,
        clockMs: clock.elapsedMilliseconds,
        playing: value.isPlaying,
        buffering: value.isBuffering,
        active: foreground && (current || fullscreen),
        speed: value.playbackSpeed,
      );
      if (evidence != null && owner != null) {
        final before = pending;
        if (before != null &&
            before.end == evidence.start &&
            before.speed == evidence.speed &&
            before.wallMs + evidence.wallMs <= 8000) {
          pending = (
            start: before.start,
            end: evidence.end,
            wallMs: before.wallMs + evidence.wallMs,
            speed: evidence.speed,
          );
        } else {
          await flush();
          pending = evidence;
        }
        if (pending!.wallMs >= 5000) await flush();
      } else {
        await flush();
      }
      if (++ticks % 20 == 0) {
        await flush();
        unawaited(repository.sync());
        final renewed = await repository.videoSession(
          widget.lessonId,
          source: widget.source,
        );
        if (renewed?['id'] != ticket?['id']) sampler.reset();
        ticket = renewed;
      }
    } catch (error, stackTrace) {
      developer.log(
        'Could not record playback for lesson ${widget.lessonId}.',
        name: 'CBOA.LearningProgress',
        error: error,
        stackTrace: stackTrace,
      );
      sampler.reset();
      ticket = null;
      nextAttemptMs = clock.elapsedMilliseconds + 15000;
    } finally {
      busy = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    foreground = state == AppLifecycleState.resumed;
    sampler.reset();
    if (!foreground) {
      unawaited(
        flush().then((_) => repository.sync()).catchError((Object _) {}),
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    widget.controller.removeListener(transition);
    clock.stop();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(flush().then((_) => repository.sync()).catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
