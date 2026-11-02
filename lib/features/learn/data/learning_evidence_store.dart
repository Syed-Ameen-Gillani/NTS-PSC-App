import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'offline_file_store.dart';

/// A single atomic account-private document holds tickets, sequence and outbox.
/// Never allocate a sequence separately from persisting its sample.
class LearningEvidenceStore {
  LearningEvidenceStore({this.directory = getApplicationSupportDirectory});
  final Future<Directory> Function() directory;
  static Future<void> _tail = Future.value();

  Future<T> transaction<T>(
    String user,
    Future<T> Function(Map<String, dynamic>) action,
  ) => _run(user, action, persist: true);

  Future<T> read<T>(
    String user,
    Future<T> Function(Map<String, dynamic>) action,
  ) => _run(user, action, persist: false);

  Future<T> _run<T>(
    String user,
    Future<T> Function(Map<String, dynamic>) action, {
    required bool persist,
  }) async {
    OfflineFileStore.requireId(user);
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    await previous;
    try {
      final root = await directory();
      final folder = Directory('${root.path}/learning-evidence/$user');
      await folder.create(recursive: true);
      final file = File('${folder.path}/state.json');
      final data = await file.exists()
          ? Map<String, dynamic>.from(
              jsonDecode(await file.readAsString()) as Map,
            )
          : <String, dynamic>{
              'tickets': <String, dynamic>{},
              'events': <dynamic>[],
              'errors': <String, dynamic>{},
            };
      final result = await action(data);
      if (persist) await OfflineFileStore.writeJson(file, data);
      return result;
    } finally {
      done.complete();
    }
  }
}
