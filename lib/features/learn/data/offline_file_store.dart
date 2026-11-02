import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

/// App-private metadata commits never remove the last valid manifest first.
class OfflineFileStore {
  static final _id = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );
  static final _video = RegExp(
    r'^[0-9a-fA-F-]{36}(?:_[0-9a-fA-F-]{36})?\.(mp4|webm|mov)$',
  );

  static void requireId(String value) {
    if (!_id.hasMatch(value)) throw ArgumentError('Invalid lesson identifier.');
  }

  static bool isVideoFilename(Object? value) =>
      value is String && _video.hasMatch(value);

  static Future<String?> pendingTaskId(File pending) async {
    if (!await pending.exists()) return null;
    try {
      final data = jsonDecode(await pending.readAsString());
      if (data is! Map<String, dynamic>) return null;
      final id = data['taskId'];
      return id is String && id.isNotEmpty ? id : null;
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> readCheckpointQueue(
    File file,
  ) async {
    if (!await file.exists()) return [];
    try {
      final value = jsonDecode(await file.readAsString());
      if (value is! List) {
        throw const FormatException('Invalid checkpoint queue');
      }
      return value.map((item) {
        if (item is! Map<String, dynamic> ||
            item['id'] is! String ||
            item['answer'] is! int) {
          throw const FormatException('Invalid checkpoint entry');
        }
        return item;
      }).toList();
    } on FormatException catch (error) {
      final backup = File(
        '${file.path}.corrupt-${DateTime.now().toUtc().microsecondsSinceEpoch}',
      );
      await file.rename(backup.path);
      developer.log(
        'Saved checkpoint answers need recovery; the original file was retained.',
        name: 'CBOA.OfflineProgress',
        error: error,
      );
      return [];
    }
  }

  static Future<void> quarantineCheckpoint(
    Directory directory,
    Map<String, dynamic> item,
  ) async {
    final rejected = File('${directory.path}/rejected-checkpoints.json');
    final entries = await readCheckpointQueue(rejected);
    if (!entries.any((entry) => entry['id'] == item['id'])) {
      entries.add(item);
      // Commit the recovery copy before clearing the retry queue.
      await writeJson(rejected, entries);
    }
    final queue = File('${directory.path}/pending-checkpoints.json');
    final pending = await readCheckpointQueue(queue);
    pending.removeWhere((entry) => entry['id'] == item['id']);
    await writeJson(queue, pending);
  }

  static Future<void> writeJson(File target, Object value) async {
    final staging = File('${target.path}.tmp');
    await staging.writeAsString(jsonEncode(value), flush: true);
    // rename replaces the destination on supported Android/iOS filesystems.
    await staging.rename(target.path);
  }

  /// Finalize a background transfer that finished while the Dart process was gone.
  static Future<void> recoverDownloads(
    Directory directory, {
    Set<String> activeLessonIds = const {},
  }) async {
    await for (final entry in directory.list()) {
      if (entry is! File) continue;
      final name = entry.uri.pathSegments.last;
      if (!name.startsWith('download-') || !name.endsWith('.pending')) continue;
      final lessonId = name.substring(9, name.length - 8);
      if (!_id.hasMatch(lessonId) || activeLessonIds.contains(lessonId)) {
        continue;
      }
      try {
        final data =
            jsonDecode(await entry.readAsString()) as Map<String, dynamic>;
        if (!isVideoFilename(data['filename'])) continue;
        final video = File('${directory.path}/${data['filename']}');
        if (!await video.exists() || await video.length() != data['byteSize']) {
          continue;
        }
        // Keep a finished transfer even when its access lease expired while
        // the app was closed. The player still checks the lease before use.
        await writeJson(File('${directory.path}/$lessonId.json'), data);
        await entry.delete();
      } on FileSystemException {
        // An active native transfer may still be opening or renaming its file.
      } on FormatException {
        // Ignore incomplete metadata; it must never become a playable download.
      } on TypeError {
        // Malformed metadata is not trusted.
      }
    }
  }

  static bool authorizationIsCurrent(String? value, {DateTime? now}) {
    final authorized = DateTime.tryParse(value ?? '')?.toUtc();
    final current = (now ?? DateTime.now()).toUtc();
    if (authorized == null || authorized.isAfter(current)) return false;
    return current.difference(authorized) < const Duration(days: 7);
  }
}
