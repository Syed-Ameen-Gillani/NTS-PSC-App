import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:nts_psc_app/features/learn/data/offline_file_store.dart';
import 'package:path_provider/path_provider.dart';

/// Fingerprint the actual file bytes so a retry cannot resume a different video.
class LessonUploadSessionStore {
  static Future<String> fingerprint(File video) async =>
      (await sha256.bind(video.openRead()).first).toString();

  static Future<File> fileFor(String ownerId, String lessonId) async {
    OfflineFileStore.requireId(ownerId);
    OfflineFileStore.requireId(lessonId);
    final support = await getApplicationSupportDirectory();
    final directory = Directory('${support.path}/lesson-uploads/$ownerId');
    await directory.create(recursive: true);
    return File('${directory.path}/$lessonId.json');
  }

  static Future<Map<String, dynamic>?> read(File file, String digest) async {
    try {
      if (!await file.exists()) return null;
      final data =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      if (data['digest'] != digest) return null;
      OfflineFileStore.requireId(data['mediaId'] as String);
      return data;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }
}
