part of 'professional_video_player.dart';

extension _VideoCanvas on _ProfessionalVideoPlayerState {
  Widget buildCanvas(VideoControlsState ui, bool captions, bool cover) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: video,
      builder: (context, value, _) {
        final showControls = ui.visible && !_waitingForPlayback;
        if (value.hasError) {
          return VideoPlayerStatus(
            message: 'Video could not be played.',
            onRetry:
                widget.onRetry ??
                (widget.fullscreen ? () => context.pop(true) : null),
          );
        }
        if (!value.isInitialized) return const VideoPlayerStatus(loading: true);
        final total = value.duration.inMilliseconds
            .toDouble()
            .clamp(1, double.maxFinite)
            .toDouble();
        final position =
            (ui.scrubMilliseconds ?? value.position.inMilliseconds.toDouble())
                .clamp(0, total)
                .toDouble();
        final caption = captions && !_waitingForPlayback
            ? activeVideoCaption(widget.segments, value.position)
            : null;
        return LayoutBuilder(
          builder: (context, bounds) => ColoredBox(
            color: AppColors.videoBackground,
            child: Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                ClipRect(
                  child: FittedBox(
                    fit: cover ? BoxFit.cover : BoxFit.contain,
                    child: SizedBox(
                      width: value.size.width,
                      height: value.size.height,
                      child: VideoPlayer(video),
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _focus.requestFocus();
                    if (showControls &&
                        (value.isPlaying || _waitingForPlayback)) {
                      ref
                          .read(videoControlsProvider(_identity).notifier)
                          .state = const VideoControlsState(
                        visible: false,
                      );
                    } else {
                      _reveal();
                      _scheduleHide();
                    }
                  },
                  onDoubleTapDown: (details) => _seek(
                    details.localPosition.dx < bounds.maxWidth / 2 ? -10 : 10,
                  ),
                  onDoubleTap: () {},
                ),
                if (caption != null)
                  Positioned(
                    left: 16.w,
                    right: 16.w,
                    // The seek track is 3.r high and flush with the frame.
                    // Keep captions two logical pixels above it in both states.
                    bottom: 3.r + 2,
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 6.h,
                        ),
                        color: AppColors.videoScrim,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: (bounds.maxHeight - 40.r).clamp(
                              20.r,
                              double.maxFinite,
                            ),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              caption,
                              textAlign: TextAlign.center,
                              style: AppTextStyles.interMedium16.copyWith(
                                fontSize: 14.sp.clamp(12, 20),
                                color: AppColors.videoForeground,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_showBuffering)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IgnorePointer(
                          child: SizedBox(
                            width: 28.r,
                            height: 28.r,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.videoForeground,
                              semanticsLabel: 'Buffering video',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                IgnorePointer(
                  ignoring: !showControls,
                  child: AnimatedOpacity(
                    opacity: showControls ? 1 : 0,
                    duration: _waitingForPlayback
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _focus.requestFocus();
                              if (showControls &&
                                  (value.isPlaying || _waitingForPlayback)) {
                                ref
                                    .read(
                                      videoControlsProvider(_identity).notifier,
                                    )
                                    .state = const VideoControlsState(
                                  visible: false,
                                );
                              } else {
                                _reveal();
                                _scheduleHide();
                              }
                            },
                            onDoubleTapDown: (details) => _seek(
                              details.localPosition.dx < bounds.maxWidth / 2
                                  ? -10
                                  : 10,
                            ),
                            onDoubleTap: () {},
                            child: const ColoredBox(
                              color: AppColors.videoScrim,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8.w),
                            child: Row(
                              children: [
                                if (widget.fullscreen) ...[
                                  _icon(
                                    'Exit fullscreen',
                                    Icons.arrow_back,
                                    _fullscreen,
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.interMedium16
                                          .copyWith(
                                            fontSize: 12.sp.clamp(11, 16),
                                            color: AppColors.videoForeground,
                                          ),
                                    ),
                                  ),
                                ] else
                                  const Spacer(),
                                if (widget.segments.isNotEmpty)
                                  _icon(
                                    'Captions',
                                    Icons.closed_caption_outlined,
                                    () {
                                      ref
                                              .read(
                                                videoCaptionsProvider(
                                                  video,
                                                ).notifier,
                                              )
                                              .state =
                                          !captions;
                                      _scheduleHide();
                                    },
                                    selected: captions,
                                  ),
                                _icon(
                                  value.volume == 0 ? 'Unmute' : 'Mute',
                                  value.volume == 0
                                      ? Icons.volume_off_outlined
                                      : Icons.volume_up_outlined,
                                  _toggleMute,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!value.isBuffering &&
                            (caption == null || bounds.maxHeight > 280))
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _icon(
                                  'Rewind 10 seconds',
                                  Icons.replay_10,
                                  () => _seek(-10),
                                ),
                                SizedBox(width: 12.w),
                                IconButton.filled(
                                  tooltip: value.isPlaying
                                      ? 'Pause'
                                      : value.position >= value.duration
                                      ? 'Replay'
                                      : 'Play',
                                  icon: Icon(
                                    value.isPlaying
                                        ? Icons.pause_rounded
                                        : value.position >= value.duration
                                        ? Icons.replay
                                        : Icons.play_arrow_rounded,
                                    size: 26.r.clamp(24, 30),
                                  ),
                                  onPressed: _togglePlay,
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.videoForeground,
                                    foregroundColor: AppColors.videoBackground,
                                    minimumSize: Size.square(
                                      44.r.clamp(44, 52),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                _icon(
                                  'Forward 10 seconds',
                                  Icons.forward_10,
                                  () => _seek(10),
                                ),
                              ],
                            ),
                          ),
                        Positioned(
                          left: 8.w,
                          right: 4.w,
                          bottom: 14.r,
                          child: Row(
                            children: [
                              Text(
                                '${videoTime(Duration(milliseconds: position.round())).padLeft(5, '0')} / ${videoTime(value.duration).padLeft(5, '0')}',
                                style: AppTextStyles.interMedium16.copyWith(
                                  fontSize: 12.sp.clamp(11, 14),
                                  color: AppColors.videoForeground,
                                ),
                              ),
                              const Spacer(),
                              PopupMenuButton<double>(
                                enabled: !ref.read(
                                  videoSpeedChangingProvider(video),
                                ),
                                tooltip: 'Playback speed',
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                icon: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.speed,
                                      color: AppColors.videoForeground,
                                      size: 24.r.clamp(24, 28),
                                    ),
                                    if (bounds.maxWidth > 340) ...[
                                      SizedBox(width: 2.w),
                                      Text(
                                        '${value.playbackSpeed}x',
                                        style: AppTextStyles.interMedium16
                                            .copyWith(
                                              fontSize: 10.sp.clamp(9, 12),
                                              color: AppColors.videoForeground,
                                            ),
                                      ),
                                    ],
                                  ],
                                ),
                                onOpened: () => _hideTimer?.cancel(),
                                onCanceled: _scheduleHide,
                                onSelected: _changeSpeed,
                                itemBuilder: (_) => [
                                  for (final speed in [
                                    0.5,
                                    0.75,
                                    1.0,
                                    1.25,
                                    1.5,
                                    1.75,
                                    2.0,
                                  ])
                                    CheckedPopupMenuItem(
                                      value: speed,
                                      checked: value.playbackSpeed == speed,
                                      child: Text('${speed}x'),
                                    ),
                                ],
                              ),
                              if (MediaQuery.orientationOf(context) ==
                                  Orientation.landscape)
                                _icon(
                                  cover ? 'Fit video' : 'Fill video',
                                  cover ? Icons.fit_screen : Icons.crop_free,
                                  () =>
                                      ref
                                              .read(
                                                videoCoverFitProvider(
                                                  video,
                                                ).notifier,
                                              )
                                              .state =
                                          !cover,
                                ),
                              _icon(
                                widget.fullscreen
                                    ? 'Exit fullscreen'
                                    : 'Fullscreen',
                                widget.fullscreen
                                    ? Icons.fullscreen_exit
                                    : Icons.fullscreen,
                                _fullscreen,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          // The track's lower edge sits exactly on the frame.
                          bottom: -(24.r.clamp(20, 28) / 2) + 1.5.r,
                          child: Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 24.r.clamp(20, 28),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 0,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: value.buffered.isEmpty
                                              ? 0
                                              : (value
                                                            .buffered
                                                            .last
                                                            .end
                                                            .inMilliseconds /
                                                        total)
                                                    .clamp(0, 1),
                                          minHeight: 3.r,
                                          color: AppColors.videoForeground
                                              .withValues(alpha: 0.4),
                                          backgroundColor: AppColors
                                              .videoForeground
                                              .withValues(alpha: 0.15),
                                        ),
                                      ),
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          trackHeight: 3.r,
                                          overlayShape:
                                              SliderComponentShape.noOverlay,
                                          thumbShape: RoundSliderThumbShape(
                                            enabledThumbRadius: 6.r,
                                          ),
                                          inactiveTrackColor:
                                              Colors.transparent,
                                          activeTrackColor: AppColors.primary,
                                          thumbColor: AppColors.primary,
                                        ),
                                        child: Slider(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 0,
                                          ),
                                          label: videoTime(
                                            Duration(
                                              milliseconds: position.round(),
                                            ),
                                          ),
                                          value: position,
                                          max: total,
                                          onChangeStart: (_) {
                                            _hideTimer?.cancel();
                                            ref
                                                .read(
                                                  videoControlsProvider(
                                                    _identity,
                                                  ).notifier,
                                                )
                                                .state = VideoControlsState(
                                              scrubMilliseconds: position,
                                              resumeAfterScrub: value.isPlaying,
                                            );
                                            unawaited(video.pause());
                                          },
                                          onChanged: (ms) {
                                            ref
                                                .read(
                                                  videoControlsProvider(
                                                    _identity,
                                                  ).notifier,
                                                )
                                                .state = VideoControlsState(
                                              scrubMilliseconds: ms,
                                              resumeAfterScrub:
                                                  controls.resumeAfterScrub,
                                            );
                                          },
                                          onChangeEnd: (ms) {
                                            final resume =
                                                controls.resumeAfterScrub;
                                            _perform(() async {
                                              await video.seekTo(
                                                Duration(
                                                  milliseconds: ms.round(),
                                                ),
                                              );
                                              if (resume) await video.play();
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
