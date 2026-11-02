import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nts_psc_app/features/learn/data/offline_file_store.dart';
import 'package:nts_psc_app/features/learn/domain/video_study_state.dart';

final videoStudyRepositoryProvider = Provider(
  (ref) => VideoStudyRepository(() async {
    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}/video-study');
  }),
);

/// App-private, account/revision-scoped state. Writes for each file are serialized
/// so a pause/dispose save cannot overwrite newer personal notes out of order.
class VideoStudyRepository {
  VideoStudyRepository(this.directory);
  final Future<Directory> Function() directory;
  final _writes = <String, Future<void>>{};

  String _id(VideoStudyKey key) => sha256
      .convert(utf8.encode(jsonEncode([key.userId, key.lessonId, key.source])))
      .toString();

  Future<File> _file(String id) async {
    final folder = await directory();
    await folder.create(recursive: true);
    return File('${folder.path}/$id.json');
  }

  Future<VideoStudyState> read(VideoStudyKey key) async {
    final id = _id(key);
    await _writes[id];
    final file = await _file(id);
    if (!await file.exists()) return const VideoStudyState();
    try {
      final value = jsonDecode(await file.readAsString());
      return value is Map<String, dynamic>
          ? VideoStudyState.fromJson(value)
          : const VideoStudyState();
    } on FormatException {
      return const VideoStudyState();
    }
  }

  Future<void> write(VideoStudyKey key, VideoStudyState state) {
    return _queue(
      key,
      (file) => OfflineFileStore.writeJson(file, state.toJson()),
    );
  }

  Future<void> writePlayback(VideoStudyKey key, VideoStudyState playback) {
    return _queue(key, (file) async {
      var saved = const VideoStudyState();
      if (await file.exists()) {
        try {
          final value = jsonDecode(await file.readAsString());
          if (value is Map<String, dynamic>) {
            saved = VideoStudyState.fromJson(value);
          }
        } on FormatException {
          // A corrupt file must not prevent the next valid playback save.
        }
      }
      await OfflineFileStore.writeJson(
        file,
        saved
            .copyWith(
              positionMs: playback.positionMs,
              speed: playback.speed,
              captions: playback.captions,
              volume: playback.volume,
            )
            .toJson(),
      );
    });
  }

  Future<void> _queue(VideoStudyKey key, Future<void> Function(File) action) {
    final id = _id(key);
    final previous = _writes[id] ?? Future<void>.value();
    final next = previous.catchError((Object _) {}).then((_) async {
      await action(await _file(id));
    });
    _writes[id] = next;
    // Keep a handled tail without hiding errors from the caller.
    unawaitedCleanup(id, next);
    return next;
  }

  void unawaitedCleanup(String id, Future<void> next) {
    next.then(
      (_) {
        if (identical(_writes[id], next)) _writes.remove(id);
      },
      onError: (Object _, StackTrace __) {
        if (identical(_writes[id], next)) _writes.remove(id);
      },
    );
  }
}
