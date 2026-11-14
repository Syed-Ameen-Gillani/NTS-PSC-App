import 'dart:async';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/learn/data/course_download_ledger.dart';
import 'package:nts_psc_app/features/learn/data/offline_lesson_library.dart';
import 'package:nts_psc_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/offline_downloads_controller.dart';

class CourseDownloadState {
  const CourseDownloadState({
    this.phase = CourseDownloadPhase.idle,
    this.running = false,
    this.saved = 0,
    this.total = 0,
    this.failed = 0,
    this.unavailable = 0,
    this.progress = 0,
    this.cancelled = false,
    this.errorMessage,
  });

  final CourseDownloadPhase phase;
  final bool running;
  final int saved;
  final int total;
  final int failed;
  final int unavailable;
  final double progress;
  final bool cancelled;
  final String? errorMessage;
}

String studentDownloadError(Object error) {
  if (error is SocketException) return 'Connection lost. Reconnect and retry.';
  if (error is FileSystemException) {
    return 'Storage unavailable. Free space and retry.';
  }
  if (error is StateError) {
    final message = error.message.toString();
    if (message.contains('Account changed') || message.contains('Sign in')) {
      return 'Sign in again to continue this download.';
    }
    if (message.contains('not match') || message.contains('incomplete')) {
      return 'Downloaded file was incomplete. Retry it.';
    }
    if (message.contains('no longer available')) {
      return 'This video is no longer available to download.';
    }
    if (message.contains('partial')) {
      return 'Partial download expired. Retry the video.';
    }
  }
  return 'Download failed. Check your connection and retry.';
}

enum CourseDownloadPhase {
  idle,
  preparing,
  downloading,
  pausing,
  paused,
  completed,
  failed,
  cancelled,
}

final courseDownloadProvider =
    NotifierProvider.family<
      CourseDownloadController,
      CourseDownloadState,
      String
    >(CourseDownloadController.new);

final courseDownloadPendingProvider = FutureProvider.autoDispose
    .family<CourseDownloadQueue?, String>((ref, courseId) async {
      final owner = ref.watch(
        authControllerProvider.select((state) => state.value?.user?.id),
      );
      if (owner == null) return null;
      return ref.read(courseDownloadLedgerProvider).read(owner, courseId);
    });

final courseDownloadTransferProvider = FutureProvider.autoDispose
    .family<PendingLessonTransfer?, String>((ref, courseId) async {
      final queue = await ref.watch(
        courseDownloadPendingProvider(courseId).future,
      );
      if (queue == null) return null;
      final library = ref.read(offlineLessonLibraryProvider);
      for (final id in queue.remainingLessonIds) {
        final transfer = await library.pendingTransfer(id);
        if (transfer != null &&
            (transfer.status == TaskStatus.paused ||
                transfer.status == TaskStatus.running ||
                transfer.status == TaskStatus.enqueued)) {
          return transfer;
        }
      }
      return null;
    });

class CourseDownloadController extends Notifier<CourseDownloadState> {
  CourseDownloadController(this.courseId);
  final String courseId;
  bool _cancelled = false;
  bool _inFlight = false;
  bool _pauseRequested = false;
  Completer<void>? _resumeSignal;
  String? _activeLessonId;
  String? _ownerId;

  Future<bool> pause() async {
    if (!_inFlight || _pauseRequested || _cancelled) return false;
    _pauseRequested = true;
    final previous = state;
    state = CourseDownloadState(
      phase: CourseDownloadPhase.pausing,
      running: true,
      saved: previous.saved,
      total: previous.total,
      failed: previous.failed,
      unavailable: previous.unavailable,
      progress: previous.progress,
    );
    final id = _activeLessonId;
    if (id != null) {
      final accepted = await ref
          .read(offlineLessonLibraryProvider)
          .pauseDownload(id);
      if (!accepted) {
        _pauseRequested = false;
        state = CourseDownloadState(
          phase: CourseDownloadPhase.downloading,
          running: true,
          saved: previous.saved,
          total: previous.total,
          failed: previous.failed,
          unavailable: previous.unavailable,
          progress: previous.progress,
        );
        return false;
      }
    }
    if (state.phase == CourseDownloadPhase.pausing) {
      state = CourseDownloadState(
        phase: CourseDownloadPhase.paused,
        running: true,
        saved: previous.saved,
        total: previous.total,
        failed: previous.failed,
        unavailable: previous.unavailable,
        progress: previous.progress,
      );
    }
    return true;
  }

  Future<void> resume() async {
    if (!_inFlight || !_pauseRequested || _cancelled) return;
    final id = _activeLessonId;
    if (id != null) {
      final resumed = await ref
          .read(offlineLessonLibraryProvider)
          .resumeDownload(id);
      if (!resumed) {
        throw StateError('This partial download cannot resume. Retry it.');
      }
    }
    _pauseRequested = false;
    _resumeSignal?.complete();
    _resumeSignal = null;
    final previous = state;
    state = CourseDownloadState(
      phase: CourseDownloadPhase.downloading,
      running: true,
      saved: previous.saved,
      total: previous.total,
      failed: previous.failed,
      unavailable: previous.unavailable,
      progress: previous.progress,
    );
  }

  Future<void> _waitIfPaused() async {
    while (_pauseRequested && !_cancelled) {
      await (_resumeSignal ??= Completer<void>()).future;
    }
  }

  Future<void> cancel() async {
    _cancelled = true;
    _pauseRequested = false;
    _resumeSignal?.complete();
    _resumeSignal = null;
    final lessonId = _activeLessonId;
    if (lessonId != null) {
      await ref.read(offlineLessonLibraryProvider).cancelDownload(lessonId);
    } else if (!_inFlight) {
      final repo = ref.read(lessonMediaRepositoryProvider);
      final owner = repo.client.auth.currentUser?.id;
      if (owner != null) {
        final ledger = ref.read(courseDownloadLedgerProvider);
        final queue = await ledger.read(owner, courseId);
        final library = ref.read(offlineLessonLibraryProvider);
        for (final id in queue?.remainingLessonIds ?? const <String>[]) {
          await library.cancelDownload(id);
        }
        await ledger.remove(owner, courseId);
        ref.invalidate(courseDownloadPendingProvider(courseId));
        ref.invalidate(courseDownloadTransferProvider(courseId));
      }
      state = const CourseDownloadState(
        phase: CourseDownloadPhase.cancelled,
        cancelled: true,
      );
    }
  }

  @override
  CourseDownloadState build() {
    final owner = ref.watch(
      authControllerProvider.select((value) => value.value?.user?.id),
    );
    if (_ownerId != null && owner != _ownerId) {
      _cancelled = true;
      _pauseRequested = false;
      _resumeSignal?.complete();
      _resumeSignal = null;
    }
    return const CourseDownloadState();
  }

  Future<void> download(CourseModel course, {required bool wifiOnly}) async {
    if (_inFlight) return;
    if (course.id != courseId) throw ArgumentError('Course does not match.');
    _inFlight = true;
    _ownerId = ref
        .read(lessonMediaRepositoryProvider)
        .client
        .auth
        .currentUser
        ?.id;
    _cancelled = false;
    _pauseRequested = false;
    state = const CourseDownloadState(
      phase: CourseDownloadPhase.preparing,
      running: true,
    );
    try {
      await _downloadCourse(course, wifiOnly: wifiOnly);
    } catch (error) {
      if (ref.read(lessonMediaRepositoryProvider).client.auth.currentUser?.id ==
          _ownerId) {
        state = CourseDownloadState(
          phase: _cancelled
              ? CourseDownloadPhase.cancelled
              : CourseDownloadPhase.failed,
          saved: state.saved,
          total: state.total,
          failed: state.failed + (_cancelled ? 0 : 1),
          unavailable: state.unavailable,
          progress: state.progress,
          cancelled: _cancelled,
          errorMessage: _cancelled ? null : studentDownloadError(error),
        );
      }
      rethrow;
    } finally {
      _inFlight = false;
    }
  }

  Future<void> _downloadCourse(
    CourseModel course, {
    required bool wifiOnly,
  }) async {
    final repo = ref.read(lessonMediaRepositoryProvider);
    final owner = repo.client.auth.currentUser?.id;
    if (owner == null) throw StateError('Sign in to download lessons.');
    final library = ref.read(offlineLessonLibraryProvider);
    final ledger = ref.read(courseDownloadLedgerProvider);
    final existingDownloads = await library.listDownloads();
    final lessons = course.modules.expand((module) => module.lessons).toList();
    for (final lesson in lessons) {
      library.clearCancellation(lesson.id);
    }
    if (lessons.isEmpty) {
      throw StateError('No lessons are available to download.');
    }
    final remaining = lessons
        .where((lesson) => lesson.videoPath.isNotEmpty)
        .map((lesson) => lesson.id)
        .toSet();
    final downloadableCount = remaining.length;
    Future<void> persistQueue() async {
      if (repo.client.auth.currentUser?.id != owner) return;
      if (_cancelled || remaining.isEmpty) {
        await ledger.remove(owner, courseId);
      } else {
        await ledger.write(
          CourseDownloadQueue(
            owner: owner,
            courseId: courseId,
            remainingLessonIds: remaining.toList(),
            wifiOnly: wifiOnly,
          ),
        );
      }
      if (ref.mounted) ref.invalidate(courseDownloadPendingProvider(courseId));
    }

    await persistQueue();
    var saved = 0;
    var failed = 0;
    var unavailable = 0;
    String? lastError;
    void publish({bool running = true, double progress = 0}) {
      if (!ref.mounted) return;
      if (repo.client.auth.currentUser?.id != owner) return;
      if (_pauseRequested && running) return;
      state = CourseDownloadState(
        phase: running
            ? CourseDownloadPhase.downloading
            : _cancelled
            ? CourseDownloadPhase.cancelled
            : failed > 0
            ? CourseDownloadPhase.failed
            : CourseDownloadPhase.completed,
        running: running,
        saved: saved,
        total: lessons.length,
        failed: failed,
        unavailable: unavailable,
        progress: downloadableCount == 0
            ? 0
            : ((saved + progress) / downloadableCount).clamp(0.0, 1.0),
        cancelled: _cancelled,
        errorMessage: lastError,
      );
    }

    publish();
    try {
      for (final lesson in lessons) {
        if (_cancelled) break;
        await _waitIfPaused();
        if (_cancelled) break;
        _activeLessonId = lesson.id;
        if (repo.client.auth.currentUser?.id != owner) {
          throw StateError('Account changed during download.');
        }
        if (lesson.videoPath.isEmpty) {
          unavailable++;
          publish();
          continue;
        }
        try {
          final media = (await repo.listForLesson(lesson.id))
              .where(
                (item) =>
                    item.path == lesson.videoPath && item.status == 'ready',
              )
              .firstOrNull;
          if (media == null) {
            unavailable++;
            remaining.remove(lesson.id);
          } else if (existingDownloads.any(
            (entry) =>
                entry.lessonId == lesson.id &&
                entry.mediaPath == media.path &&
                !entry.needsAccessRefresh,
          )) {
            saved++;
            remaining.remove(lesson.id);
          } else if (existingDownloads.any(
            (entry) =>
                entry.lessonId == lesson.id &&
                entry.mediaPath == media.path &&
                entry.needsAccessRefresh,
          )) {
            await library.refreshAccess(lesson.id, media.path);
            saved++;
            remaining.remove(lesson.id);
          } else {
            final checks = AppConfig.areLessonCheckpointsEnabled
                ? await repo.studentCheckpoints(media.id)
                : <Map<String, dynamic>>[];
            if (_cancelled) break;
            await _waitIfPaused();
            if (_cancelled) break;
            await ref
                .read(learningEvidenceRepositoryProvider)
                .videoSession(lesson.id);
            await _waitIfPaused();
            if (_cancelled) break;
            await library.download(
              lessonId: lesson.id,
              title: lesson.title,
              durationMinutes: lesson.durationMinutes,
              media: media,
              checkpoints: checks,
              wifiOnly: wifiOnly,
              onProgress: (value) => publish(progress: value.clamp(0, 1)),
            );
            saved++;
            remaining.remove(lesson.id);
          }
        } catch (error) {
          if (!_cancelled) {
            failed++;
            lastError ??= studentDownloadError(error);
          }
        }
        publish();
        await persistQueue();
        ref.invalidate(offlineDownloadsProvider);
      }
    } finally {
      _activeLessonId = null;
      await persistQueue();
      publish(running: false);
      ref.invalidate(offlineDownloadsProvider);
    }
  }
}
