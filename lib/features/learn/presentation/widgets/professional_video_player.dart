import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:nts_psc_app/config/routes/app_routes.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_controls_state.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_player_status.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_quality_menu.dart';
import 'package:video_player/video_player.dart';

part 'professional_video_canvas.dart';

class VideoPlayerSession {
  const VideoPlayerSession({
    required this.controller,
    required this.title,
    this.segments = const [],
  });
  final VideoPlayerController controller;
  final String title;
  final List<Map<String, dynamic>> segments;
}

/// Rendering and transport controls only. Authorization, quizzes, downloads and
/// controller disposal remain with the owner so fullscreen never restarts video.
class ProfessionalVideoPlayer extends ConsumerStatefulWidget {
  const ProfessionalVideoPlayer({
    super.key,
    required this.controller,
    this.title = '',
    this.segments = const [],
    this.fullscreen = false,
    this.onRetry,
  });
  final VideoPlayerController controller;
  final String title;
  final List<Map<String, dynamic>> segments;
  final bool fullscreen;
  final VoidCallback? onRetry;
  @override
  ConsumerState<ProfessionalVideoPlayer> createState() =>
      _ProfessionalVideoPlayerState();
}

class _ProfessionalVideoPlayerState
    extends ConsumerState<ProfessionalVideoPlayer>
    with WidgetsBindingObserver {
  final _identity = Object();
  final _focus = FocusNode();
  Timer? _hideTimer;
  bool _wasPlaying = false;
  bool _wasBuffering = false;
  bool _covered = false;
  VideoPlayerController get video => widget.controller;
  VideoControlsState get controls => ref.read(videoControlsProvider(_identity));
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _wasPlaying = video.value.isPlaying;
    _wasBuffering = video.value.isBuffering;
    video.addListener(_playbackChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleHide();
    });
  }

  @override
  void didUpdateWidget(covariant ProfessionalVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != video) {
      oldWidget.controller.removeListener(_playbackChanged);
      video.addListener(_playbackChanged);
      _wasPlaying = video.value.isPlaying;
      _wasBuffering = video.value.isBuffering;
      _hideTimer?.cancel();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(video.pause());
    }
  }

  void _playbackChanged() {
    if (!mounted || _covered) return;
    if (controls.scrubMilliseconds != null) {
      _wasPlaying = video.value.isPlaying;
      _wasBuffering = video.value.isBuffering;
      return;
    }
    if (_wasBuffering != video.value.isBuffering) {
      _wasBuffering = video.value.isBuffering;
      if (_wasBuffering) {
        _reveal();
      } else {
        _scheduleHide();
      }
    }
    if (_wasPlaying != video.value.isPlaying) {
      _wasPlaying = video.value.isPlaying;
      if (_wasPlaying) {
        _scheduleHide();
      } else {
        _reveal();
      }
    }
  }

  void _reveal() {
    _hideTimer?.cancel();
    if (!mounted) return;
    ref.read(videoControlsProvider(_identity).notifier).state =
        const VideoControlsState();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    if (!video.value.isPlaying || video.value.isBuffering || _covered) return;
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted ||
          !video.value.isPlaying ||
          video.value.isBuffering ||
          controls.scrubMilliseconds != null ||
          MediaQuery.maybeOf(context)?.accessibleNavigation == true) {
        return;
      }
      ref.read(videoControlsProvider(_identity).notifier).state =
          const VideoControlsState(visible: false);
    });
  }

  Future<void> _perform(Future<void> Function() action) async {
    _reveal();
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          const SnackBar(
            content: Text('Playback action unavailable. Please retry.'),
          ),
        );
      }
    }
    if (mounted) _scheduleHide();
  }

  Future<void> _togglePlay() => _perform(() async {
    if (video.value.isPlaying) {
      await video.pause();
    } else {
      if (video.value.position >= video.value.duration) {
        await video.seekTo(Duration.zero);
      }
      await video.play();
    }
  });
  void _seek(int seconds) => _perform(
    () => video.seekTo(
      boundedVideoSeek(
        video.value.position + Duration(seconds: seconds),
        video.value.duration,
      ),
    ),
  );
  Future<void> _toggleMute() => _perform(() async {
    final current = video.value.volume;
    if (current > 0) {
      ref.read(videoUnmuteVolumeProvider(video).notifier).state = current;
      await video.setVolume(0);
    } else {
      await video.setVolume(ref.read(videoUnmuteVolumeProvider(video)));
    }
  });

  Future<void> _changeVolume(double delta) => _perform(() async {
    final volume = (video.value.volume + delta).clamp(0.0, 1.0);
    if (volume > 0) {
      ref.read(videoUnmuteVolumeProvider(video).notifier).state = volume;
    }
    await video.setVolume(volume);
  });

  Future<void> _changeSpeed(double speed) async {
    final controller = video;
    if (ref.read(videoSpeedChangingProvider(controller)) ||
        controller.value.playbackSpeed == speed) {
      return;
    }
    final changing = ref.read(videoSpeedChangingProvider(controller).notifier);
    changing.state = true;
    try {
      // Change only the rate: seeking or restoring play/pause here can fight
      // native buffering, a user pause, or an in-video checkpoint.
      await _perform(() => controller.setPlaybackSpeed(speed));
    } finally {
      if (changing.mounted) changing.state = false;
    }
  }

  Future<void> _fullscreen() async {
    if (widget.fullscreen) {
      context.pop();
      return;
    }
    _hideTimer?.cancel();
    _covered = true;
    try {
      final retry = await context.pushNamed<bool>(
        AppRoute.videoFullscreen.name,
        extra: VideoPlayerSession(
          controller: video,
          title: widget.title,
          segments: widget.segments,
        ),
      );
      if (retry == true && mounted) widget.onRetry?.call();
    } finally {
      _covered = false;
      if (mounted) {
        _reveal();
        _scheduleHide();
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    video.removeListener(_playbackChanged);
    WidgetsBinding.instance.removeObserver(this);
    _focus.dispose();
    super.dispose();
  }

  Widget _icon(
    String label,
    IconData icon,
    VoidCallback action, {
    bool selected = false,
  }) => IconButton(
    tooltip: label,
    onPressed: action,
    icon: Icon(icon, size: 22.r.clamp(18, 26)),
    color: selected ? AppColors.primaryLight : AppColors.videoForeground,
    padding: EdgeInsets.zero,
    constraints: BoxConstraints.tightFor(
      width: 44.r.clamp(44, 52),
      height: 44.r.clamp(44, 52),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final ui = ref.watch(videoControlsProvider(_identity));
    final captions = ref.watch(videoCaptionsProvider(video));
    final selectedCover = ref.watch(videoCoverFitProvider(video));
    ref.watch(videoUnmuteVolumeProvider(video));
    ref.watch(videoSpeedChangingProvider(video));
    final cover =
        MediaQuery.orientationOf(context) == Orientation.landscape &&
        selectedCover;
    final canvas = buildCanvas(ui, captions, cover);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _togglePlay,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _seek(-10),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _seek(10),
        const SingleActivator(LogicalKeyboardKey.keyF): _fullscreen,
        const SingleActivator(LogicalKeyboardKey.keyM): _toggleMute,
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _changeVolume(0.1),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _changeVolume(-0.1),
        const SingleActivator(LogicalKeyboardKey.keyC): () {
          if (widget.segments.isNotEmpty) {
            ref.read(videoCaptionsProvider(video).notifier).state = !captions;
            _reveal();
            _scheduleHide();
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (widget.fullscreen) context.pop();
        },
      },
      child: Focus(
        focusNode: _focus,
        autofocus: widget.fullscreen,
        child: widget.fullscreen
            ? canvas
            : AspectRatio(aspectRatio: 16 / 9, child: canvas),
      ),
    );
  }
}
