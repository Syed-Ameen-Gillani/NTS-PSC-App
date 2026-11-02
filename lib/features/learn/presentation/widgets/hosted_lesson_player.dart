import 'package:flutter_riverpod/legacy.dart';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' show ClientException;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/learn/data/offline_lesson_library.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/offline_downloads_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/video_initialization.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/study_video_player.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nts_psc_app/core/theme/app_colors.dart';
import 'package:nts_psc_app/core/theme/app_text_styles.dart';
import 'package:nts_psc_app/features/learn/presentation/widgets/video_player_status.dart';

part 'coursera_checkpoint_sheet.dart';

class HostedLessonPlayer extends ConsumerStatefulWidget {
  const HostedLessonPlayer({
    super.key,
    required this.lesson,
    this.autoPlay = false,
    this.trackLearning = false,
    this.instructorPreview = false,
    this.onEnded,
  });
  final LessonModel lesson;
  final bool autoPlay;
  final bool trackLearning;
  final bool instructorPreview;
  final VoidCallback? onEnded;

  @override
  ConsumerState<HostedLessonPlayer> createState() => _HostedLessonPlayerState();
}

class _HostedLessonPlayerState extends ConsumerState<HostedLessonPlayer> {
  final revision = ValueNotifier<int>(0);
  VideoPlayerController? video;
  LessonMedia? media;
  OfflineLesson? downloaded;
  List<Map<String, dynamic>> checks = [];
  List<Map<String, dynamic>> segments = [];
  final completed = <String>{};
  String? error;
  bool loading = true;
  bool showingCheck = false;
  bool downloading = false;
  bool wifiOnly = true;
  double downloadProgress = 0;
  Timer? syncTimer;
  int _displayedSecond = -1;
  bool _endedHandled = false;

  Future<void> _retry() async {
    if (loading) return;
    loading = true;
    syncTimer?.cancel();
    final previous = video;
    video = null;
    previous?.removeListener(onTick);
    await previous?.dispose();
    if (!mounted) return;
    error = null;
    checks = [];
    segments = [];
    completed.clear();
    refresh();
    await initialize();
  }

  void refresh() {
    if (mounted) revision.value++;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => initialize());
  }

  Future<void> initialize() async {
    if (!mounted) return;
    final repo = ref.read(lessonMediaRepositoryProvider);
    final library = ref.read(offlineLessonLibraryProvider);
    try {
      downloaded = await library.find(
        widget.lesson.id,
        widget.lesson.videoPath,
      );
      if (downloaded == null) {
        media =
            (await repo
                    .listForLesson(
                      widget.lesson.id,
                      includeUnreleased: widget.instructorPreview,
                    )
                    .timeout(videoLoadTimeout))
                .where(
                  (item) =>
                      item.path == widget.lesson.videoPath &&
                      (item.status == 'ready' ||
                          (widget.instructorPreview &&
                              item.status != 'uploading' &&
                              item.status != 'archived')),
                )
                .firstOrNull;
        if (media == null) {
          throw StateError('Enrollment or video access was revoked.');
        }
        if (media != null) {
          if (AppConfig.areLessonCheckpointsEnabled) {
            checks = await repo
                .studentCheckpoints(media!.id)
                .timeout(videoLoadTimeout);
          }
          segments = media!.segments;
        }
      }
      if (downloaded != null) {
        if (AppConfig.areLessonCheckpointsEnabled) {
          checks = downloaded!.checkpoints;
        }
        segments = downloaded!.segments;
      }
      if (media == null && downloaded == null) {
        throw StateError('This video is not available for your enrollment.');
      }
      final VideoPlayerController candidate;
      if (downloaded != null) {
        candidate = VideoPlayerController.file(File(downloaded!.path));
      } else {
        final uri = await repo
            .signedVideoUrl(widget.lesson.videoPath)
            .timeout(videoLoadTimeout);
        candidate = VideoPlayerController.networkUrl(uri);
      }
      await initializeLessonVideo(candidate);
      if (!mounted) {
        await candidate.dispose();
        return;
      }
      video = candidate;
      candidate.addListener(onTick);
      Future<void> loadAnsweredCheckpoints() async {
        try {
          final answered = await repo
              .answeredCheckpointIds(
                checks.map((check) => check['id'] as String).toList(),
              )
              .timeout(videoLoadTimeout);
          if (mounted) {
            completed.addAll(answered);
            refresh();
          }
        } catch (_) {
          if (downloaded == null) rethrow;
        }
      }

      if (downloaded == null) {
        await loadAnsweredCheckpoints();
      } else {
        unawaited(loadAnsweredCheckpoints());
      }
      completed.addAll(await library.pendingAnswerIds());
      if (!mounted) return;
      unawaited(library.syncAnswers());
      syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
        unawaited(library.syncAnswers());
      });
    } catch (_) {
      error = 'Video could not be loaded. Check your enrollment or connection.';
    } finally {
      loading = false;
      refresh();
    }
  }

  void onTick() {
    final controller = video;
    if (controller == null || !controller.value.isInitialized || showingCheck) {
      return;
    }
    final ended =
        controller.value.duration > Duration.zero &&
        controller.value.position >= controller.value.duration;
    if (!ended) _endedHandled = false;
    if (controller.value.isPlaying || ended) {
      final seconds = controller.value.position.inSeconds;
      for (final check in checks) {
        final id = check['id'] as String;
        if (!completed.contains(id) &&
            seconds >= (check['timestamp_seconds'] as num)) {
          showingCheck = true;
          unawaited(controller.pause());
          WidgetsBinding.instance.addPostFrameCallback((_) => showCheck(check));
          break;
        }
      }
    }
    if (ended && !showingCheck && !_endedHandled) {
      _endedHandled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onEnded?.call();
      });
    }
    if (controller.value.position.inSeconds != _displayedSecond) {
      _displayedSecond = controller.value.position.inSeconds;
      refresh();
    }
  }

  Future<void> showCheck(Map<String, dynamic> check) async {
    if (!mounted) return;
    final options = (check['options'] as List).cast<String>();
    final checkpointId = check['id'] as String;
    final question = check['question'] as String? ?? '';
    final timestampSeconds = (check['timestamp_seconds'] as num?)?.toInt() ?? 0;
    final minutes = timestampSeconds ~/ 60;
    final remainingSecs = timestampSeconds % 60;
    final timestampDisplay =
        '$minutes:${remainingSecs.toString().padLeft(2, '0')}';

    final resultAction = await showModalBottomSheet<_CheckpointAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => _CourseraCheckpointSheet(
        question: question,
        options: options,
        timestampDisplay: timestampDisplay,
        onSubmit: (selectedOption) async {
          final library = ref.read(offlineLessonLibraryProvider);
          try {
            final res = await ref
                .read(lessonMediaRepositoryProvider)
                .answerCheckpoint(checkpointId, selectedOption);
            return res;
          } on SocketException {
            await library.queueAnswer(checkpointId, selectedOption);
            return {'queued': true};
          } on TimeoutException {
            await library.queueAnswer(checkpointId, selectedOption);
            return {'queued': true};
          } on ClientException {
            await library.queueAnswer(checkpointId, selectedOption);
            return {'queued': true};
          } on AuthException {
            return {'error': 'Sign in again to answer this checkpoint.'};
          } catch (_) {
            return {'error': 'Answer could not be saved. Retry playback.'};
          }
        },
      ),
    );

    completed.add(checkpointId);
    showingCheck = false;
    refresh();

    if (mounted) {
      if (resultAction == _CheckpointAction.rewind) {
        final pos = video?.value.position ?? Duration.zero;
        final newPos = pos > const Duration(seconds: 15)
            ? pos - const Duration(seconds: 15)
            : Duration.zero;
        await video?.seekTo(newPos);
      }
      await video?.play();
    }
  }

  Future<void> download() async {
    if (media == null || downloading) return;
    downloading = true;
    refresh();
    try {
      downloaded = await ref
          .read(offlineLessonLibraryProvider)
          .download(
            lessonId: widget.lesson.id,
            title: widget.lesson.title,
            durationMinutes: widget.lesson.durationMinutes,
            media: media!,
            checkpoints: checks,
            wifiOnly: wifiOnly,
            onProgress: (value) {
              downloadProgress = value;
              refresh();
            },
          );
      if (mounted) ref.invalidate(offlineDownloadsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video saved for offline viewing')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Download failed. Please retry.')),
        );
      }
    } finally {
      downloading = false;
      refresh();
    }
  }

  Future<void> removeDownload() async {
    try {
      final current = video;
      await current?.pause();
      await ref
          .read(offlineLessonLibraryProvider)
          .delete(widget.lesson.id, widget.lesson.videoPath);
      if (!mounted) return;
      downloaded = null;
      ref.invalidate(offlineDownloadsProvider);
      if (current != null) {
        current.removeListener(onTick);
        await current.dispose();
      }
      video = null;
      syncTimer?.cancel();
      loading = true;
      error = null;
      refresh();
      await initialize();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not remove download. Please retry.'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    syncTimer?.cancel();
    video?.removeListener(onTick);
    video?.dispose();
    revision.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: revision,
    builder: (context, _, __) {
      final controller = video;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller != null &&
              controller.value.isInitialized &&
              error == null)
            StudyVideoPlayer(
              controller: controller,
              lessonId: widget.lesson.id,
              source: widget.lesson.videoPath,
              autoPlay: widget.autoPlay,
              trackLearning: widget.trackLearning,
              title: widget.lesson.title,
              segments: segments,
              onRetry: _retry,
              showStudyPanel: false,
            )
          else
            VideoPlayerStatus(
              loading: loading,
              message: error ?? 'Video unavailable',
              onRetry: loading ? null : _retry,
            ),
        ],
      );
    },
  );
}
