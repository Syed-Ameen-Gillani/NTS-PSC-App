import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/learn/data/offline_file_store.dart';

final offlineProgressQueueProvider = Provider(
  (ref) => OfflineProgressQueue(Supabase.instance.client),
);

class PendingLessonCompletion implements Exception {}

/// Account-scoped outbox in application support storage. Replay is idempotent;
/// permission failures are discarded rather than applying to another account.
class OfflineProgressQueue {
  OfflineProgressQueue(
    this.client, {
    Future<Directory> Function()? directory,
    String? Function()? currentUserId,
    Future<void> Function(String)? record,
  }) : directory = directory ?? getApplicationSupportDirectory,
       _currentUserId = currentUserId,
       _recordOverride = record;
  final SupabaseClient client;
  final Future<Directory> Function() directory;
  final String? Function()? _currentUserId;
  final Future<void> Function(String)? _recordOverride;
  String? get _userId =>
      _currentUserId != null ? _currentUserId() : client.auth.currentUser?.id;
  Future<void> _record(String id) async {
    if (_recordOverride != null) return _recordOverride(id);
    await client
        .rpc('record_offline_lesson_completion', params: {'p_lesson_id': id})
        .timeout(const Duration(seconds: 15));
  }

  static Future<void> _tail = Future.value();

  Future<T> _locked<T>(Future<T> Function() operation) async {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    await previous;
    try {
      return await operation();
    } finally {
      done.complete();
    }
  }

  Future<File> _file(String user) async {
    final root = await directory();
    final folder = Directory('${root.path}/lesson-videos/$user');
    await folder.create(recursive: true);
    return File('${folder.path}/pending-completions.json');
  }

  Future<Set<String>> _read(File file) async {
    if (!await file.exists()) return {};
    // A malformed queue is surfaced; never silently discard pending progress.
    return (jsonDecode(await file.readAsString()) as List)
        .cast<String>()
        .toSet();
  }

  Future<void> enqueue(String lessonId) async {
    OfflineFileStore.requireId(lessonId);
    final user = _userId;
    if (user == null) throw StateError('Sign in required');
    await _locked(() async {
      final file = await _file(user);
      final pending = (await _read(file))..add(lessonId);
      if (_userId != user) {
        throw StateError('Account changed');
      }
      await OfflineFileStore.writeJson(file, pending.toList());
    });
  }

  Future<bool> complete(String lessonId) async {
    if (_recordOverride == null) {
      throw StateError('Progress updates automatically. Reopen this lesson.');
    }
    final user = _userId;
    if (user == null) throw StateError('Sign in required');
    Future<void> retain() async {
      if (_userId != user) {
        throw StateError('Account changed');
      }
      await enqueue(lessonId);
    }

    try {
      await _record(lessonId);
      if (_userId != user) {
        throw StateError('Account changed');
      }
      try {
        await _locked(() async {
          final file = await _file(user);
          final pending = await _read(file);
          if (pending.remove(lessonId)) {
            await OfflineFileStore.writeJson(file, pending.toList());
          }
        });
      } catch (_) {
        /* Remote completion is already durable. */
      }
      return true;
    } on SocketException {
      await retain();
    } on ClientException {
      await retain();
    } on TimeoutException {
      await retain();
    }
    return false;
  }

  Future<bool?> completionStatus(String lessonId) async {
    final user = _userId;
    if (user == null) return null;
    final pending = await _locked(() async => _read(await _file(user)));
    if (_userId != user) return null;
    if (pending.contains(lessonId)) return false;
    try {
      final rows = await client
          .from('lesson_progress')
          .select('completed_at,enrollments!inner(student_id)')
          .eq('lesson_id', lessonId)
          .eq('enrollments.student_id', user)
          .not('completed_at', 'is', null)
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return _userId == user && rows.isNotEmpty ? true : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> sync() async {
    if (_recordOverride == null) return; // Legacy IDs are not verified evidence.
    final user = _userId;
    if (user == null) return;
    try {
      await _locked(() async {
        final file = await _file(user);
        final pending = await _read(file);
        for (final id in pending.toList()) {
          if (_userId != user) break;
          try {
            await _record(id);
          } on PostgrestException catch (error) {
            if (error.code != '42501') break;
          } catch (_) {
            break;
          }
          if (_userId != user) break;
          pending.remove(id);
          await OfflineFileStore.writeJson(file, pending.toList());
        }
      });
    } catch (_) {
      // Startup/reconnect must remain usable if local storage is unavailable.
    }
  }
}
