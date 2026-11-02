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
    this.running = false,
    this.saved = 0,
    this.total = 0,
    this.failed = 0,
    this.unavailable = 0,
    this.progress = 0,
    this.cancelled = false,
  });

  final bool running;
  final int saved;
  final int total;
  final int failed;
  final int unavailable;
  final double progress;
  final bool cancelled;
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

class CourseDownloadController extends Notifier<CourseDownloadState> {
  CourseDownloadController(this.courseId);
  final String courseId;
  bool _cancelled = false;
  String? _activeLessonId;

  Future<void> cancel() async {
    _cancelled = true;
    final lessonId = _activeLessonId;
    if (lessonId != null) {
      await ref.read(offlineLessonLibraryProvider).cancelDownload(lessonId);
    }
  }

  @override
  CourseDownloadState build() => const CourseDownloadState();

  Future<void> download(CourseModel course, {required bool wifiOnly}) async {
    if (state.running) return;
    if (course.id != courseId) throw ArgumentError('Course does not match.');
    _cancelled = false;
    final repo = ref.read(lessonMediaRepositoryProvider);
    final owner = repo.client.auth.currentUser?.id;
    if (owner == null) throw StateError('Sign in to download lessons.');
    final library = ref.read(offlineLessonLibraryProvider);
    final ledger = ref.read(courseDownloadLedgerProvider);
    final existingDownloads = await library.listDownloads();
    final lessons = course.modules.expand((module) => module.lessons).toList();
    if (lessons.isEmpty) {
      throw StateError('No lessons are available to download.');
    }
    final remaining = lessons
        .where((lesson) => lesson.videoPath.isNotEmpty)
        .map((lesson) => lesson.id)
        .toSet();
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
    void publish({bool running = true, double progress = 0}) {
      if (!ref.mounted) return;
      state = CourseDownloadState(
        running: running,
        saved: saved,
        total: lessons.length,
        failed: failed,
        unavailable: unavailable,
        progress: progress,
        cancelled: _cancelled,
      );
    }

    publish();
    try {
      for (final lesson in lessons) {
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
            await ref
                .read(learningEvidenceRepositoryProvider)
                .videoSession(lesson.id);
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
        } catch (_) {
          if (!_cancelled) failed++;
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
