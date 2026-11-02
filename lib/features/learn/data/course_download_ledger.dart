import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'offline_file_store.dart';

final courseDownloadLedgerProvider = Provider<CourseDownloadLedger>(
  (ref) => CourseDownloadLedger(),
);

/// Records a course queue, never an entitlement or a signed media URL.
class CourseDownloadLedger {
  CourseDownloadLedger({Future<Directory> Function()? directory})
    : directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() directory;

  String _safeName(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  Future<File> _file(String owner, String courseId) async {
    if (owner.isEmpty || courseId.isEmpty) {
      throw ArgumentError('A signed-in account and course are required.');
    }
    final root = await directory();
    final folder = Directory(
      '${root.path}/course-downloads/${_safeName(owner)}',
    );
    await folder.create(recursive: true);
    return File('${folder.path}/${_safeName(courseId)}.json');
  }

  Future<CourseDownloadQueue?> read(String owner, String courseId) async {
    final file = await _file(owner, courseId);
    if (!await file.exists()) return null;
    try {
      final data = jsonDecode(await file.readAsString());
      if (data is! Map<String, dynamic> ||
          data['owner'] != owner ||
          data['course'] != courseId ||
          data['wifiOnly'] is! bool ||
          data['remaining'] is! List) {
        return null;
      }
      final remaining = (data['remaining'] as List).cast<String>();
      return CourseDownloadQueue(
        owner: owner,
        courseId: courseId,
        remainingLessonIds: remaining,
        wifiOnly: data['wifiOnly'] as bool,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  Future<void> write(CourseDownloadQueue queue) async {
    final file = await _file(queue.owner, queue.courseId);
    await OfflineFileStore.writeJson(file, {
      'version': 1,
      'owner': queue.owner,
      'course': queue.courseId,
      'wifiOnly': queue.wifiOnly,
      'remaining': queue.remainingLessonIds,
    });
  }

  Future<void> remove(String owner, String courseId) async {
    final file = await _file(owner, courseId);
    if (await file.exists()) await file.delete();
  }

  Future<void> purgeOtherUsers(String? currentUser) async {
    final root = await directory();
    final parent = Directory('${root.path}/course-downloads');
    if (!await parent.exists()) return;
    final allowed = currentUser == null ? null : _safeName(currentUser);
    await for (final entry in parent.list()) {
      if (entry is Directory &&
          entry.uri.pathSegments.where((s) => s.isNotEmpty).last != allowed) {
        await entry.delete(recursive: true);
      }
    }
  }
}

class CourseDownloadQueue {
  const CourseDownloadQueue({
    required this.owner,
    required this.courseId,
    required this.remainingLessonIds,
    required this.wifiOnly,
  });

  final String owner;
  final String courseId;
  final List<String> remainingLessonIds;
  final bool wifiOnly;
}
