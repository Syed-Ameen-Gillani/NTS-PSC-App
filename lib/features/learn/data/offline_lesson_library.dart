import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/learn/data/offline_file_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final offlineLessonLibraryProvider = Provider<OfflineLessonLibrary>((ref) {
  return OfflineLessonLibrary(ref.read(lessonMediaRepositoryProvider));
});

class OfflineLesson {
  const OfflineLesson({
    required this.path,
    required this.mediaPath,
    required this.checkpoints,
    required this.segments,
  });
  final String path;
  final String mediaPath;
  final List<Map<String, dynamic>> checkpoints;
  final List<Map<String, dynamic>> segments;
}

class OfflineLessonEntry {
  const OfflineLessonEntry({
    required this.lessonId,
    required this.title,
    required this.durationMinutes,
    required this.mediaPath,
    required this.byteSize,
    this.needsAccessRefresh = false,
  });
  final String lessonId;
  final String title;
  final int durationMinutes;
  final String mediaPath;
  final int byteSize;
  final bool needsAccessRefresh;
}

class PendingLessonTransfer {
  const PendingLessonTransfer(this.status, this.progress);
  final TaskStatus status;
  final double progress;
}

class OfflineLessonLibrary {
  OfflineLessonLibrary(this.mediaRepository);
  final LessonMediaRepository mediaRepository;
  static Future<void> _queueTail = Future<void>.value();
  static bool _syncing = false;
  static final _activeDownloads = <String>{};
  static final _downloadTasks = <String, String>{};
  static final _taskResults = <String, Completer<TaskStatusUpdate>>{};
  static final _pauseAcks = <String, Completer<bool>>{};
  static final _taskProgress = <String, void Function(double)>{};
  static final _pauseRequested = <String>{};
  static final _requestedPauseKeys = <String>{};
  static final _cancelRequestedKeys = <String>{};
  static bool _callbacksRegistered = false;

  void clearCancellation(String lessonId) {
    final owner = _userId;
    if (owner != null) _cancelRequestedKeys.remove('$owner:$lessonId');
  }

  Future<PendingLessonTransfer?> pendingTransfer(String lessonId) async {
    OfflineFileStore.requireId(lessonId);
    final owner = _userId;
    if (owner == null) return null;
    final root = await getApplicationSupportDirectory();
    final pending = File(
      '${root.path}/lesson-videos/$owner/download-$lessonId.pending',
    );
    final id = await OfflineFileStore.pendingTaskId(pending);
    if (id == null) return null;
    final record = await FileDownloader().database.recordForId(id);
    if (record?.task is! DownloadTask ||
        record?.task.group != 'cboa-lesson-videos') {
      return null;
    }
    return PendingLessonTransfer(record!.status, record.progress);
  }

  static void registerTransferCallbacks() {
    if (_callbacksRegistered) return;
    _callbacksRegistered = true;
    FileDownloader().registerCallbacks(
      group: 'cboa-lesson-videos',
      taskStatusCallback: (update) {
        final id = update.task.taskId;
        if (update.status == TaskStatus.paused) {
          final ack = _pauseAcks.remove(id);
          if (ack != null && !ack.isCompleted) ack.complete(true);
        } else if (update.status.isFinalState) {
          final ack = _pauseAcks.remove(id);
          if (ack != null && !ack.isCompleted) ack.complete(false);
        }
        if (update.status == TaskStatus.running &&
            _pauseRequested.contains(id)) {
          unawaited(FileDownloader().pause(update.task as DownloadTask));
        }
        if (update.status.isFinalState || update.status == TaskStatus.paused) {
          final waiter = _taskResults.remove(id);
          if (waiter != null && !waiter.isCompleted) waiter.complete(update);
        }
      },
      taskProgressCallback: (update) {
        if (update.progress >= 0 && update.progress <= 1) {
          _taskProgress[update.task.taskId]?.call(update.progress);
        }
      },
    );
  }

  Future<bool> pauseDownload(String lessonId) async {
    final owner = _userId;
    if (owner == null) return false;
    final key = '$owner:$lessonId';
    _requestedPauseKeys.add(key);
    final id = _downloadTasks[key];
    if (id == null) return true;
    _pauseRequested.add(id);
    final task = await FileDownloader().taskForId(id);
    // The task is registered locally before enqueue reaches native storage.
    if (task is! DownloadTask) return true;
    final record = await FileDownloader().database.recordForId(id);
    if (record?.status == TaskStatus.paused) return true;
    if (record?.status != TaskStatus.running) return true;
    final ack = Completer<bool>();
    _pauseAcks[id] = ack;
    final accepted = await FileDownloader().pause(task);
    if (!accepted) {
      _pauseRequested.remove(id);
      _requestedPauseKeys.remove(key);
      _pauseAcks.remove(id);
      return false;
    }
    try {
      final paused = await ack.future.timeout(const Duration(seconds: 8));
      if (!paused) {
        _pauseRequested.remove(id);
        _requestedPauseKeys.remove(key);
      }
      return paused;
    } on TimeoutException {
      _pauseAcks.remove(id);
      _pauseRequested.remove(id);
      _requestedPauseKeys.remove(key);
      return false;
    }
  }

  Future<bool> resumeDownload(String lessonId) async {
    final owner = _userId;
    if (owner == null) return false;
    final key = '$owner:$lessonId';
    _requestedPauseKeys.remove(key);
    final id = _downloadTasks[key];
    if (id == null) return true;
    _pauseRequested.remove(id);
    final task = await FileDownloader().taskForId(id);
    if (task is! DownloadTask) return true;
    final record = await FileDownloader().database.recordForId(id);
    if (record?.status != TaskStatus.paused) return true;
    final root = await getApplicationSupportDirectory();
    final pending = File(
      '${root.path}/lesson-videos/$owner/download-$lessonId.pending',
    );
    if (!await pending.exists()) return false;
    final data =
        jsonDecode(await pending.readAsString()) as Map<String, dynamic>;
    final created = DateTime.tryParse(data['authorizedAt'] as String? ?? '');
    var resumeTask = task;
    if (created == null ||
        DateTime.now().toUtc().difference(created.toUtc()) >
            const Duration(minutes: 50)) {
      final mediaPath = data['mediaPath'] as String?;
      if (mediaPath == null ||
          !(await mediaRepository.listForLesson(
            lessonId,
          )).any((item) => item.path == mediaPath && item.status == 'ready')) {
        throw StateError('This video is no longer available to download.');
      }
      final url = await mediaRepository.signedVideoUrl(mediaPath);
      resumeTask = task.copyWith(url: url.toString());
      data['authorizedAt'] = DateTime.now().toUtc().toIso8601String();
      await OfflineFileStore.writeJson(pending, data);
    }
    return FileDownloader().resume(resumeTask);
  }

  Future<void> cancelDownload(String lessonId) async {
    try {
      OfflineFileStore.requireId(lessonId);
    } on ArgumentError {
      return;
    }
    final ownerId = _userId;
    if (ownerId == null) return;
    _cancelRequestedKeys.add('$ownerId:$lessonId');
    var taskId = _downloadTasks['$ownerId:$lessonId'];
    if (taskId == null) {
      final root = await getApplicationSupportDirectory();
      final pending = File(
        '${root.path}/lesson-videos/$ownerId/download-$lessonId.pending',
      );
      taskId = await OfflineFileStore.pendingTaskId(pending);
    }
    if (taskId != null) await FileDownloader().cancelTaskWithId(taskId);
    if (!_downloadTasks.containsKey('$ownerId:$lessonId')) {
      final root = await getApplicationSupportDirectory();
      final dir = Directory('${root.path}/lesson-videos/$ownerId');
      final pending = File('${dir.path}/download-$lessonId.pending');
      await _discardPending(pending, dir, lessonId);
      if (await pending.exists()) await pending.delete();
    }
  }

  Future<T> _queueLock<T>(Future<T> Function() action) async {
    final previous = _queueTail;
    final done = Completer<void>();
    _queueTail = done.future;
    await previous;
    try {
      return await action();
    } finally {
      done.complete();
    }
  }

  String? get _userId => mediaRepository.client.auth.currentUser?.id;

  Future<Directory> _userDirectory() async {
    final id = _userId;
    if (id == null) throw StateError('Sign in to use downloads.');
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/lesson-videos/$id');
    await directory.create(recursive: true);
    final marker = File('${directory.path}/.nomedia');
    if (!await marker.exists()) await marker.writeAsString('');
    await _queueLock(
      () => OfflineFileStore.recoverDownloads(
        directory,
        activeLessonIds: _activeDownloads
            .where((key) => key.startsWith('$id:'))
            .map((key) => key.substring(id.length + 1))
            .toSet(),
      ),
    );
    return directory;
  }

  Future<OfflineLesson?> find(String lessonId, String mediaPath) async {
    final ownerId = _userId;
    if (ownerId == null) return null;
    OfflineFileStore.requireId(lessonId);
    final dir = await _userDirectory();
    final manifest = File('${dir.path}/$lessonId.json');
    if (!await manifest.exists()) {
      return null;
    }
    try {
      final data =
          jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
      if (!OfflineFileStore.isVideoFilename(data['filename'])) return null;
      final file = File('${dir.path}/${data['filename']}');
      if (data['mediaPath'] != mediaPath ||
          !await file.exists() ||
          await file.length() != data['byteSize'] ||
          !OfflineFileStore.authorizationIsCurrent(
            data['authorizedAt'] as String?,
          )) {
        return null;
      }
      if (_userId != ownerId) return null;
      return OfflineLesson(
        path: file.path,
        mediaPath: mediaPath,
        checkpoints: (data['checkpoints'] as List).cast<Map<String, dynamic>>(),
        segments: (data['segments'] as List).cast<Map<String, dynamic>>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<List<OfflineLessonEntry>> listDownloads() async {
    final ownerId = _userId;
    if (ownerId == null) return [];
    final dir = await _userDirectory();
    final entries = <OfflineLessonEntry>[];
    await for (final file in dir.list()) {
      if (file is! File ||
          !file.path.endsWith('.json') ||
          file.path.endsWith('pending-checkpoints.json')) {
        continue;
      }
      final lessonId = file.uri.pathSegments.last.replaceFirst(
        RegExp(r'\.json$'),
        '',
      );
      if (!RegExp(r'^[0-9a-f-]{36}$').hasMatch(lessonId)) continue;
      try {
        final data =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final mediaPath = data['mediaPath'] as String;
        final filename = data['filename'];
        final byteSize = (data['byteSize'] as num).toInt();
        if (!OfflineFileStore.isVideoFilename(filename) || byteSize <= 0) {
          continue;
        }
        final video = File('${dir.path}/$filename');
        if (!await video.exists() || await video.length() != byteSize) {
          continue;
        }
        entries.add(
          OfflineLessonEntry(
            lessonId: lessonId,
            title: data['title'] as String? ?? 'Lesson',
            durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 0,
            mediaPath: mediaPath,
            byteSize: byteSize,
            needsAccessRefresh: !OfflineFileStore.authorizationIsCurrent(
              data['authorizedAt'] as String?,
            ),
          ),
        );
      } catch (_) {
        continue;
      }
    }
    return _userId == ownerId ? entries : [];
  }

  /// Renew a retained video only after the current account can still read its
  /// exact published lesson media from the server.
  Future<void> refreshAccess(String lessonId, String mediaPath) async {
    OfflineFileStore.requireId(lessonId);
    final ownerId = _userId;
    if (ownerId == null) throw StateError('Sign in to refresh downloads.');
    final dir = await _userDirectory();
    final manifest = File('${dir.path}/$lessonId.json');
    final data =
        jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
    if (data['mediaPath'] != mediaPath ||
        !OfflineFileStore.isVideoFilename(data['filename'])) {
      throw StateError('This download is no longer available.');
    }
    final video = File('${dir.path}/${data['filename']}');
    if (!await video.exists() || await video.length() != data['byteSize']) {
      throw StateError('The saved video is incomplete. Download it again.');
    }
    final allowed = (await mediaRepository.listForLesson(
      lessonId,
    )).any((item) => item.path == mediaPath && item.status == 'ready');
    if (_userId != ownerId || !allowed) {
      throw StateError('This lesson is no longer available to your account.');
    }
    data['authorizedAt'] = DateTime.now().toUtc().toIso8601String();
    await OfflineFileStore.writeJson(manifest, data);
  }

  Future<OfflineLesson> download({
    required String lessonId,
    required String title,
    required int durationMinutes,
    required LessonMedia media,
    required List<Map<String, dynamic>> checkpoints,
    required bool wifiOnly,
    void Function(double)? onProgress,
  }) async {
    OfflineFileStore.requireId(lessonId);
    final startingOwner = _userId;
    if (startingOwner == null ||
        media.status != 'ready' ||
        media.lessonId != lessonId) {
      throw StateError('This lesson is not downloadable.');
    }
    final saved = await find(lessonId, media.path);
    if (_userId != startingOwner) {
      throw StateError('Account changed during download.');
    }
    if (saved != null) return saved;
    final ownerDirectory = await getApplicationSupportDirectory();
    final manifest = File(
      '${ownerDirectory.path}/lesson-videos/$startingOwner/$lessonId.json',
    );
    var retainedExpired = false;
    if (await manifest.exists()) {
      try {
        final data =
            jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
        if (data['mediaPath'] == media.path &&
            OfflineFileStore.isVideoFilename(data['filename']) &&
            !OfflineFileStore.authorizationIsCurrent(
              data['authorizedAt'] as String?,
            )) {
          final file = File('${manifest.parent.path}/${data['filename']}');
          retainedExpired =
              await file.exists() && await file.length() == data['byteSize'];
        }
      } on FormatException {
        // A corrupt manifest cannot renew access to a local video.
      } on TypeError {
        // An incomplete manifest cannot renew access to a local video.
      }
    }
    if (retainedExpired) {
      await refreshAccess(lessonId, media.path);
      final renewed = await find(lessonId, media.path);
      if (renewed == null) {
        throw StateError('Could not refresh this download. Try again.');
      }
      return renewed;
    }
    final ownerId = _userId;
    if (ownerId == null) throw StateError('Sign in to use downloads.');
    final key = '$ownerId:$lessonId';
    if (!_activeDownloads.add(key)) {
      throw StateError('This lesson is already downloading.');
    }
    try {
      return await _download(
        ownerId: ownerId,
        lessonId: lessonId,
        title: title,
        durationMinutes: durationMinutes,
        media: media,
        checkpoints: checkpoints,
        wifiOnly: wifiOnly,
        onProgress: onProgress,
      );
    } finally {
      _activeDownloads.remove(key);
    }
  }

  Future<OfflineLesson> _download({
    required String ownerId,
    required String lessonId,
    required String title,
    required int durationMinutes,
    required LessonMedia media,
    required List<Map<String, dynamic>> checkpoints,
    required bool wifiOnly,
    void Function(double)? onProgress,
  }) async {
    registerTransferCallbacks();
    final uri = await mediaRepository.signedVideoUrl(media.path, seconds: 3600);
    if (_userId != ownerId) {
      throw StateError('Account changed during download.');
    }
    final dir = await _userDirectory();
    final pending = File('${dir.path}/download-$lessonId.pending');
    DownloadTask? retainedTask;
    TaskStatus? retainedStatus;
    Map<String, dynamic>? retainedData;
    if (await pending.exists()) {
      try {
        final data =
            jsonDecode(await pending.readAsString()) as Map<String, dynamic>;
        final id = data['taskId'];
        if (data['mediaPath'] == media.path &&
            data['byteSize'] == media.byteSize &&
            OfflineFileStore.isVideoFilename(data['filename']) &&
            id is String) {
          final record = await FileDownloader().database.recordForId(id);
          if (record?.task is DownloadTask &&
              (record?.status == TaskStatus.paused ||
                  record?.status == TaskStatus.running ||
                  record?.status == TaskStatus.enqueued)) {
            final candidate = record!.task as DownloadTask;
            if (candidate.group == 'cboa-lesson-videos' &&
                candidate.filename == data['filename']) {
              retainedTask = candidate;
              retainedStatus = record.status;
              retainedData = data;
            }
          }
        }
      } on FormatException {
        // A malformed pending file cannot authorize a native transfer.
      } on TypeError {
        // The new transfer path discards invalid metadata below.
      }
    }
    final extension = media.path.split('.').last;
    final filename =
        retainedTask?.filename ?? '${media.id}_${const Uuid().v4()}.$extension';
    if (!OfflineFileStore.isVideoFilename(filename)) {
      throw StateError('Unsupported lesson video.');
    }
    final task =
        retainedTask?.copyWith(url: uri.toString()) ??
        DownloadTask(
          url: uri.toString(),
          filename: filename,
          directory: 'lesson-videos/$ownerId',
          baseDirectory: BaseDirectory.applicationSupport,
          updates: Updates.statusAndProgress,
          requiresWiFi: wifiOnly,
          retries: 2,
          allowPause: true,
          group: 'cboa-lesson-videos',
        );
    var committed = false;
    final key = '$ownerId:$lessonId';
    if (retainedTask == null) await _discardPending(pending, dir, lessonId);
    final data = {
      ...?retainedData,
      'filename': filename,
      'title': title,
      'durationMinutes': durationMinutes,
      'mediaPath': media.path,
      'byteSize': media.byteSize,
      'checkpoints': checkpoints,
      'segments': media.segments,
      'authorizedAt': DateTime.now().toUtc().toIso8601String(),
      'taskId': task.taskId,
    };
    _downloadTasks[key] = task.taskId;
    if (_requestedPauseKeys.contains(key)) _pauseRequested.add(task.taskId);
    try {
      await OfflineFileStore.writeJson(pending, data);
      _taskProgress[task.taskId] = (value) => onProgress?.call(value);
      var waiter = Completer<TaskStatusUpdate>();
      _taskResults[task.taskId] = waiter;
      if (retainedTask == null) {
        if (_cancelRequestedKeys.contains(key)) {
          throw StateError('Download cancelled.');
        }
        if (!await FileDownloader().enqueue(task)) {
          throw StateError('Could not start the download. Try again.');
        }
      } else if (retainedStatus == TaskStatus.paused) {
        if (!await FileDownloader().resume(task)) {
          throw StateError('The partial download is unavailable. Retry it.');
        }
      }
      var result = await waiter.future;
      while (result.status == TaskStatus.paused) {
        // The native partial file and task identity remain intact while paused.
        waiter = Completer<TaskStatusUpdate>();
        _taskResults[task.taskId] = waiter;
        result = await waiter.future;
      }
      if (result.status != TaskStatus.complete) {
        if (result.status == TaskStatus.canceled) {
          throw StateError('Download cancelled.');
        }
        throw StateError('Download failed. Check the connection and retry.');
      }
      final file = File(await task.filePath());
      if (_userId != ownerId ||
          !await file.exists() ||
          await file.length() != media.byteSize) {
        if (await file.exists()) await file.delete();
        throw StateError('Downloaded video did not match the uploaded file.');
      }
      final target = File('${dir.path}/$lessonId.json');
      String? previousFilename;
      if (await target.exists()) {
        try {
          previousFilename =
              (jsonDecode(await target.readAsString())
                      as Map<String, dynamic>)['filename']
                  as String?;
        } catch (_) {
          previousFilename = null;
        }
      }
      await OfflineFileStore.writeJson(target, data);
      committed = true;
      if (previousFilename != null &&
          previousFilename != filename &&
          OfflineFileStore.isVideoFilename(previousFilename)) {
        final previous = File('${dir.path}/$previousFilename');
        try {
          if (await previous.exists()) await previous.delete();
        } on FileSystemException {
          // A previous player may still hold this file open.
        }
      }
      return OfflineLesson(
        path: file.path,
        mediaPath: media.path,
        checkpoints: checkpoints,
        segments: media.segments,
      );
    } finally {
      _taskResults.remove(task.taskId);
      _pauseAcks.remove(task.taskId);
      _taskProgress.remove(task.taskId);
      _pauseRequested.remove(task.taskId);
      _downloadTasks.remove(key);
      _requestedPauseKeys.remove(key);
      _cancelRequestedKeys.remove(key);
      if (await pending.exists()) await pending.delete();
      if (!committed) {
        final file = File(await task.filePath());
        if (await file.exists()) await file.delete();
      }
    }
  }

  Future<void> _discardPending(
    File pending,
    Directory dir,
    String lessonId,
  ) async {
    if (!await pending.exists()) return;
    Map<String, dynamic> previous;
    try {
      previous =
          jsonDecode(await pending.readAsString()) as Map<String, dynamic>;
    } on FormatException {
      return;
    } on TypeError {
      return;
    }
    final taskId = previous['taskId'];
    if (taskId is String) await FileDownloader().cancelTaskWithId(taskId);
    final filename = previous['filename'];
    if (!OfflineFileStore.isVideoFilename(filename)) return;
    final manifest = File('${dir.path}/$lessonId.json');
    if (await manifest.exists()) {
      try {
        final current =
            jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
        if (current['filename'] == filename) return;
      } on FormatException {
        // A corrupt manifest cannot reference a playable download.
      } on TypeError {
        // A malformed manifest cannot reference a playable download.
      }
    }
    final file = File('${dir.path}/$filename');
    if (await file.exists()) await file.delete();
  }

  Future<void> delete(String lessonId, String mediaPath) async {
    OfflineFileStore.requireId(lessonId);
    final dir = await _userDirectory();
    await cancelDownload(lessonId);
    final manifest = File('${dir.path}/$lessonId.json');
    String? filename;
    if (await manifest.exists()) {
      try {
        final data =
            jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
        if (data['mediaPath'] != mediaPath) return;
        filename = data['filename'] as String?;
      } on FormatException {
        // A corrupt manifest is safe to discard.
      } on TypeError {
        // A corrupt manifest is safe to discard.
      }
    }
    if (filename != null && OfflineFileStore.isVideoFilename(filename)) {
      final video = File('${dir.path}/$filename');
      if (await video.exists()) await video.delete();
    }
    if (await manifest.exists()) await manifest.delete();
  }

  Future<void> queueAnswer(String checkpointId, int answerIndex) async {
    final dir = await _userDirectory();
    final queue = File('${dir.path}/pending-checkpoints.json');
    await _queueLock(() async {
      final items = await OfflineFileStore.readCheckpointQueue(queue);
      if (items.any((item) => item['id'] == checkpointId)) return;
      items.add({'id': checkpointId, 'answer': answerIndex});
      await OfflineFileStore.writeJson(queue, items);
    });
  }

  Future<Set<String>> pendingAnswerIds() async {
    final dir = await _userDirectory();
    final queue = File('${dir.path}/pending-checkpoints.json');
    return (await _queueLock(
      () => OfflineFileStore.readCheckpointQueue(queue),
    )).map((item) => item['id'] as String).toSet();
  }

  Future<void> syncAnswers() async {
    if (_userId == null || _syncing) return;
    final ownerId = _userId;
    _syncing = true;
    try {
      final dir = await _userDirectory();
      final queue = File('${dir.path}/pending-checkpoints.json');
      final snapshot = await _queueLock(
        () => OfflineFileStore.readCheckpointQueue(queue),
      );
      for (final item in snapshot.take(50)) {
        if (_userId != ownerId) break;
        try {
          await mediaRepository.answerCheckpoint(
            item['id'] as String,
            item['answer'] as int,
          );
          if (_userId != ownerId) break;
          await _queueLock(() async {
            final current = await OfflineFileStore.readCheckpointQueue(queue);
            current.removeWhere((entry) => entry['id'] == item['id']);
            await OfflineFileStore.writeJson(queue, current);
          });
        } catch (error) {
          if (error is SocketException ||
              error is TimeoutException ||
              error is ClientException) {
            break;
          }
          if (error is PostgrestException &&
              error.code == 'P0001' &&
              error.message == 'Checkpoint unavailable') {
            await _queueLock(
              () => OfflineFileStore.quarantineCheckpoint(dir, item),
            );
            developer.log(
              'A saved checkpoint is no longer available; its answer was retained for recovery.',
              name: 'CBOA.OfflineProgress',
              error: error,
            );
            continue;
          }
          // Unknown server/auth failures may recover; keep the queue intact.
          developer.log(
            'A saved checkpoint answer could not sync; it remains queued.',
            name: 'CBOA.OfflineProgress',
            error: error,
          );
          break;
        }
      }
    } finally {
      _syncing = false;
    }
  }

  static Future<void> purgeOtherUsers(String? currentUserId) async {
    for (final task in _downloadTasks.entries.toList()) {
      if (currentUserId == null || !task.key.startsWith('$currentUserId:')) {
        await FileDownloader().cancelTaskWithId(task.value);
      }
    }
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/lesson-videos');
    if (!await directory.exists()) return;
    await for (final entry in directory.list()) {
      if (entry is Directory &&
          entry.uri.pathSegments.where((s) => s.isNotEmpty).last !=
              currentUserId) {
        await for (final pending in entry.list()) {
          if (pending is! File || !pending.path.endsWith('.pending')) continue;
          final taskId = await OfflineFileStore.pendingTaskId(pending);
          if (taskId != null) await FileDownloader().cancelTaskWithId(taskId);
        }
        await entry.delete(recursive: true);
      }
    }
  }
}
