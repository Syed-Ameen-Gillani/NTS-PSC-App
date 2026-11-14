import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

import 'offline_file_store.dart';

class PendingPdfTransfer {
  const PendingPdfTransfer(this.status, this.progress);
  final TaskStatus status;
  final double progress;
}

/// Native, account-private PDF transfers. The reading store owns validation
/// and commits the readable manifest only after a successful transfer.
class OfflinePdfTransfer {
  static const group = 'cboa-lesson-readings';
  static final _results = <String, Completer<TaskStatusUpdate>>{};
  static final _progress = <String, void Function(double)>{};
  static final _pauseAcks = <String, Completer<bool>>{};
  static final _active = <String, String>{};
  static final _pauseRequested = <String>{};
  static final _cancelRequested = <String>{};
  static bool _registered = false;

  static void registerCallbacks() {
    if (_registered) return;
    _registered = true;
    FileDownloader().registerCallbacks(
      group: group,
      taskStatusCallback: (update) {
        final id = update.task.taskId;
        if (update.status == TaskStatus.running &&
            _pauseRequested.contains(id)) {
          unawaited(FileDownloader().pause(update.task as DownloadTask));
        }
        if (update.status == TaskStatus.paused || update.status.isFinalState) {
          final ack = _pauseAcks.remove(id);
          if (ack != null && !ack.isCompleted) {
            ack.complete(update.status == TaskStatus.paused);
          }
          final waiter = _results.remove(id);
          if (waiter != null && !waiter.isCompleted) waiter.complete(update);
        }
      },
      taskProgressCallback: (update) {
        if (update.progress >= 0 && update.progress <= 1) {
          _progress[update.task.taskId]?.call(update.progress);
        }
      },
    );
  }

  static Future<PendingPdfTransfer?> pending(File marker) async {
    final id = await OfflineFileStore.pendingTaskId(marker);
    if (id == null) return null;
    final data = await metadata(marker);
    final record = await FileDownloader().database.recordForId(id);
    if (record?.task is! DownloadTask ||
        record?.task.group != group ||
        record?.task.filename != data?['filename']) {
      return null;
    }
    return PendingPdfTransfer(record!.status, record.progress);
  }

  static bool isActive(File marker) => _active.containsKey(marker.path);
  static void clearCancellation(File marker) =>
      _cancelRequested.remove(marker.path);

  static Future<DownloadTask?> _task(File marker) async {
    final id = await OfflineFileStore.pendingTaskId(marker);
    if (id == null) return null;
    final task = await FileDownloader().taskForId(id);
    return task is DownloadTask && task.group == group ? task : null;
  }

  static Future<bool> pause(File marker) async {
    final task = await _task(marker);
    if (task == null) return false;
    final record = await FileDownloader().database.recordForId(task.taskId);
    if (record?.status == TaskStatus.paused) return true;
    if (record?.status == TaskStatus.enqueued) {
      _pauseRequested.add(task.taskId);
      return true;
    }
    if (record?.status != TaskStatus.running ||
        !await FileDownloader().taskCanResume(task)) {
      return false;
    }
    final ack = Completer<bool>();
    _pauseAcks[task.taskId] = ack;
    if (!await FileDownloader().pause(task)) {
      _pauseAcks.remove(task.taskId);
      return false;
    }
    try {
      return await ack.future.timeout(const Duration(seconds: 8));
    } on TimeoutException {
      _pauseAcks.remove(task.taskId);
      return false;
    }
  }

  static Future<bool> resume(File marker, {required Uri url}) async {
    final task = await _task(marker);
    if (task == null) return false;
    _pauseRequested.remove(task.taskId);
    final record = await FileDownloader().database.recordForId(task.taskId);
    if (record?.status != TaskStatus.paused) return false;
    return FileDownloader().resume(task.copyWith(url: url.toString()));
  }

  static Future<void> cancel(File marker) async {
    _cancelRequested.add(marker.path);
    final id = await OfflineFileStore.pendingTaskId(marker);
    if (id == null) return;
    _pauseRequested.remove(id);
    await FileDownloader().cancelTaskWithId(id);
  }

  static Future<File> download({
    required File marker,
    required Map<String, dynamic> metadata,
    required Uri url,
    required String owner,
    required String filename,
    void Function(double)? onProgress,
  }) async {
    registerCallbacks();
    final old = await _task(marker);
    final record = old == null
        ? null
        : await FileDownloader().database.recordForId(old.taskId);
    final retainedMetadata = await OfflinePdfTransfer.metadata(marker);
    final retain =
        old != null &&
        metadata['filename'] == old.filename &&
        metadata['sourcePath'] == retainedMetadata?['sourcePath'] &&
        (record?.status == TaskStatus.paused ||
            record?.status == TaskStatus.running ||
            record?.status == TaskStatus.enqueued);
    if (!retain && old != null) {
      await cancel(marker);
      _cancelRequested.remove(marker.path);
    }
    final task = retain
        ? old.copyWith(url: url.toString())
        : DownloadTask(
            url: url.toString(),
            filename: filename,
            directory: 'lesson-readings/$owner',
            baseDirectory: BaseDirectory.applicationSupport,
            updates: Updates.statusAndProgress,
            retries: 2,
            allowPause: true,
            group: group,
          );
    final key = marker.path;
    if (_active.containsKey(key)) {
      throw StateError('This reading is already downloading.');
    }
    _active[key] = task.taskId;
    var completed = false;
    try {
      if (_cancelRequested.contains(key)) {
        throw StateError('Download cancelled.');
      }
      await OfflineFileStore.writeJson(marker, {
        ...metadata,
        'taskId': task.taskId,
        'filename': task.filename,
        'authorizedAt': DateTime.now().toUtc().toIso8601String(),
      });
      _progress[task.taskId] = (value) => onProgress?.call(value);
      var waiter = Completer<TaskStatusUpdate>();
      _results[task.taskId] = waiter;
      if (!retain) {
        if (_cancelRequested.contains(key)) {
          throw StateError('Download cancelled.');
        }
        if (!await FileDownloader().enqueue(task)) {
          throw StateError('Could not start the PDF download.');
        }
      } else if (record?.status == TaskStatus.paused) {
        if (!await FileDownloader().resume(task)) {
          throw StateError('The partial PDF cannot resume. Retry it.');
        }
      }
      var result = await waiter.future;
      while (result.status == TaskStatus.paused) {
        waiter = Completer<TaskStatusUpdate>();
        _results[task.taskId] = waiter;
        result = await waiter.future;
      }
      if (result.status != TaskStatus.complete) {
        throw StateError(
          result.status == TaskStatus.canceled
              ? 'Download cancelled.'
              : 'PDF download failed. Retry it.',
        );
      }
      completed = true;
      return File(await task.filePath());
    } finally {
      _active.remove(key);
      _results.remove(task.taskId);
      _progress.remove(task.taskId);
      _pauseAcks.remove(task.taskId);
      _pauseRequested.remove(task.taskId);
      _cancelRequested.remove(key);
      if (!completed) {
        if (await marker.exists()) await marker.delete();
        final file = File(await task.filePath());
        if (await file.exists()) await file.delete();
      }
    }
  }

  static Future<Map<String, dynamic>?> metadata(File marker) async {
    if (!await marker.exists()) return null;
    try {
      return jsonDecode(await marker.readAsString()) as Map<String, dynamic>;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
