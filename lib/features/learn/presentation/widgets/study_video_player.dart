import 'video_learning_observer.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/core/models/user_role.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:video_player/video_player.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/data/video_study_repository.dart';
import 'package:nts_psc_app/features/learn/domain/video_study_state.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_controls_state.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_study_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/professional_video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_player_status.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_study_panel.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_initialization.dart';

final _restoredVideo = StateProvider.autoDispose.family<bool, Object>(
  (ref, key) => false,
);

class StudyVideoPlayer extends ConsumerWidget {
  const StudyVideoPlayer({
    super.key,
    required this.controller,
    required this.lessonId,
    required this.source,
    required this.title,
    this.segments = const [],
    this.onRetry,
    this.autoPlay = false,
    this.onEnded,
    this.showStudyPanel = false,
    this.trackLearning = false,
  });
  final VideoPlayerController controller;
  final String lessonId;
  final String source;
  final String title;
  final List<Map<String, dynamic>> segments;
  final VoidCallback? onRetry;
  final bool autoPlay;
  final VoidCallback? onEnded;
  final bool showStudyPanel;
  final bool trackLearning;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(
      authControllerProvider.select((auth) => auth.value?.user?.id),
    );
    if (userId == null) {
      return ProfessionalVideoPlayer(
        controller: controller,
        title: title,
        segments: segments,
        onRetry: onRetry,
      );
    }
    final scope = (userId: userId, lessonId: lessonId, source: source);
    return _StudySession(
      key: ValueKey((controller, scope)),
      player: this,
      scope: scope,
    );
  }
}

class _StudySession extends ConsumerStatefulWidget {
  const _StudySession({super.key, required this.player, required this.scope});
  final StudyVideoPlayer player;
  final VideoStudyKey scope;
  @override
  ConsumerState<_StudySession> createState() => _StudySessionState();
}

class _StudySessionState extends ConsumerState<_StudySession>
    with WidgetsBindingObserver {
  final _identity = Object();
  VideoPlayerController get video => widget.player.controller;
  late final VideoStudyRepository _repository;
  VideoStudyState? _snapshot;
  bool _restoring = false;
  bool _ready = false;
  bool _captions = false;
  bool _playing = false;
  int _savedSecond = -1;
  bool _ended = false;

  @override
  void initState() {
    super.initState();
    _repository = ref.read(videoStudyRepositoryProvider);
    video.addListener(_tick);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _restore(VideoStudyState saved) async {
    if (_restoring) return;
    _restoring = true;
    try {
      await video
          .seekTo(saved.resumePosition(video.value.duration))
          .timeout(videoLoadTimeout);
      if (!mounted) return;
      await video.setPlaybackSpeed(saved.speed).timeout(videoLoadTimeout);
      if (!mounted) return;
      await video.setVolume(saved.volume).timeout(videoLoadTimeout);
      if (!mounted) return;
      ref.read(videoCaptionsProvider(video).notifier).state = saved.captions;
      if (AppConfig.isSupabaseEnabled &&
          ref.read(authControllerProvider).value?.user?.role ==
              UserRole.teacher &&
          widget.player.source.startsWith('https://')) {
        unawaited(
          ref
              .read(learningEvidenceRepositoryProvider)
              .confirmVideo(
                widget.player.source,
                video.value.duration.inMilliseconds,
                lessonId: widget.player.lessonId,
              )
              .catchError((Object _) {}),
        );
      }
      if (widget.player.autoPlay) await video.play();
    } catch (_) {
      // A platform seek or disk failure must not lock the playback surface.
    } finally {
      if (mounted) {
        _ready = true;
        ref.read(_restoredVideo(_identity).notifier).state = true;
      }
    }
  }

  void _tick() {
    if (!_ready || !mounted) return;
    final value = video.value;
    final second = value.position.inSeconds;
    final paused = _playing && !value.isPlaying;
    _playing = value.isPlaying;
    if (value.position < value.duration) _ended = false;
    if (!_ended &&
        value.duration > Duration.zero &&
        value.position >= value.duration) {
      _ended = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.player.onEnded?.call();
      });
    }
    if (paused || (second - _savedSecond).abs() >= 5) {
      _savedSecond = second;
      unawaited(_save());
    }
  }

  Future<void> _save() async {
    if (!_ready || !mounted) return;
    try {
      await ref
          .read(videoStudyProvider(widget.scope).notifier)
          .savePlayback(
            video.value.position.inMilliseconds,
            video.value.playbackSpeed,
            _captions,
            volume: video.value.volume,
          );
    } catch (_) {
      // Save again on the next tick/pause; playback remains available offline.
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) unawaited(_save());
  }

  @override
  void dispose() {
    video.removeListener(_tick);
    WidgetsBinding.instance.removeObserver(this);
    final saved = _snapshot;
    if (_ready && saved != null) {
      final value = video.value;
      unawaited(
        _repository
            .writePlayback(
              widget.scope,
              saved.copyWith(
                positionMs: value.position.inMilliseconds,
                speed: value.playbackSpeed,
                captions: _captions,
                volume: value.volume,
              ),
            )
            .catchError((Object _) {}),
      );
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _snapshot = ref.watch(videoStudyProvider(widget.scope)).value;
    _captions = ref.watch(videoCaptionsProvider(video));
    final ready = ref.watch(_restoredVideo(_identity));
    if (!ready && _snapshot != null && !_restoring) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_restore(_snapshot!));
      });
    }
    if (!ready) return const VideoPlayerStatus(loading: true);
    final playerWidget = ProfessionalVideoPlayer(
      controller: video,
      title: widget.player.title,
      segments: widget.player.segments,
      onRetry: widget.player.onRetry,
    );
    final observed = widget.player.trackLearning
        ? VideoLearningObserver(
            lessonId: widget.player.lessonId,
            source: widget.player.source,
            controller: video,
            child: playerWidget,
          )
        : playerWidget;
    if (!widget.player.showStudyPanel) return observed;
    return Column(
      children: [
        observed,
        VideoStudyPanel(
          controller: video,
          scope: widget.scope,
          segments: widget.player.segments,
        ),
      ],
    );
  }
}
