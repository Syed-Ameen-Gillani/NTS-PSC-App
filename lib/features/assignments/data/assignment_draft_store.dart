import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:nts_psc_app/features/assignments/domain/models/assignment_models.dart';
import 'package:nts_psc_app/features/learn/data/offline_file_store.dart';

class AssignmentDraft {
  const AssignmentDraft(this.response, this.attachments);
  final String response;
  final List<AssignmentAttachmentModel> attachments;
}

/// Private, account-scoped drafts survive an interrupted submission or app kill.
/// The manifest is replaced only after all attachment bytes have been written.
class AssignmentDraftStore {
  AssignmentDraftStore({Future<Directory> Function()? directory})
    : directory = directory ?? getApplicationSupportDirectory;
  final Future<Directory> Function() directory;
  static Future<void> _tail = Future.value();
  final _hashes = Expando<String>();

  Future<T> _locked<T>(Future<T> Function() action) async {
    final previous = _tail;
    final done = Completer<void>();
    _tail = done.future;
    await previous;
    try {
      return await action();
    } finally {
      done.complete();
    }
  }

  Future<Directory> _folder(String user, String assignment) async {
    OfflineFileStore.requireId(user);
    OfflineFileStore.requireId(assignment);
    final root = await directory();
    return Directory('${root.path}/assignment-drafts/$user/$assignment');
  }

  Future<AssignmentDraft?> read(String user, String assignment) =>
      _locked(() async {
        final folder = await _folder(user, assignment);
        final manifest = File('${folder.path}/draft.json');
        if (!await manifest.exists()) return null;
        final data =
            jsonDecode(await manifest.readAsString()) as Map<String, dynamic>;
        final attachments = <AssignmentAttachmentModel>[];
        for (final item in (data['files'] as List)) {
          final hash = item['hash'] as String;
          if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(hash)) {
            throw const FormatException('Invalid draft file');
          }
          final bytes = await File('${folder.path}/$hash').readAsBytes();
          if (bytes.length != item['size'] ||
              sha256.convert(bytes).toString() != hash) {
            throw const FormatException('Draft file changed');
          }
          _hashes[bytes] = hash;
          attachments.add(
            AssignmentAttachmentModel(
              name: item['name'] as String,
              sizeBytes: bytes.length,
              bytes: bytes,
            ),
          );
        }
        return AssignmentDraft(data['response'] as String, attachments);
      });

  Future<void> write(String user, String assignment, AssignmentDraft draft) =>
      _locked(() async {
        final folder = await _folder(user, assignment);
        await folder.create(recursive: true);
        final files = <Map<String, Object>>[];
        if (draft.attachments.length > 3) throw ArgumentError('Too many files');
        for (final item in draft.attachments) {
          final bytes = item.bytes;
          if (bytes == null ||
              bytes.isEmpty ||
              bytes.length > 25 * 1024 * 1024) {
            throw ArgumentError('Invalid draft file');
          }
          final hash = _hashes[bytes] ??= sha256.convert(bytes).toString();
          final file = File('${folder.path}/$hash');
          if (!await file.exists()) await file.writeAsBytes(bytes, flush: true);
          files.add({'hash': hash, 'name': item.name, 'size': bytes.length});
        }
        await OfflineFileStore.writeJson(File('${folder.path}/draft.json'), {
          'response': draft.response,
          'files': files,
        });
        final retained = files.map((item) => item['hash']).toSet();
        await for (final entry in folder.list()) {
          if (entry is File &&
              RegExp(r'^[a-f0-9]{64}$').hasMatch(entry.uri.pathSegments.last) &&
              !retained.contains(entry.uri.pathSegments.last)) {
            await entry.delete();
          }
        }
      });

  Future<void> clear(String user, String assignment) => _locked(() async {
    final folder = await _folder(user, assignment);
    if (await folder.exists()) await folder.delete(recursive: true);
  });
}
