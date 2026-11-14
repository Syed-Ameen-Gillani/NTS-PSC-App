import 'dart:convert';
import 'dart:io';

import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'learning_evidence_repository.dart';
import 'offline_file_store.dart';
import 'offline_pdf_transfer.dart';

final offlineReadingStoreProvider = Provider<OfflineReadingStore>((ref) {
  return OfflineReadingStore(Supabase.instance.client);
});

class OfflineReadingSnapshot {
  const OfflineReadingSnapshot({
    required this.ticket,
    required this.text,
    this.pdfPath,
  });
  final Map<String, dynamic> ticket;
  final String text;
  final String? pdfPath;
}

class OfflineReadingEntry {
  const OfflineReadingEntry({
    required this.lessonId,
    required this.materialId,
    required this.title,
    required this.byteSize,
    required this.needsAccessRefresh,
  });
  final String lessonId;
  final String? materialId;
  final String title;
  final int byteSize;
  final bool needsAccessRefresh;
}

/// Explicit, account-private reading downloads use the existing evidence
/// ticket as a bounded offline access lease. Cached content never grants
/// entitlement or completion without the server accepting the evidence.
class OfflineReadingStore {
  OfflineReadingStore(
    this.client, {
    Future<Directory> Function()? directory,
    Future<void> Function(Uri, File)? pdfDownloader,
  }) : directory = directory ?? getApplicationSupportDirectory,
       pdfDownloader = pdfDownloader ?? _downloadPdf,
       _usesDefaultDownloader = pdfDownloader == null;

  final SupabaseClient client;
  final Future<Directory> Function() directory;
  final Future<void> Function(Uri, File) pdfDownloader;
  final bool _usesDefaultDownloader;
  static final _activeSaves = <String>{};
  static const maxPdfBytes = 25 * 1024 * 1024;
  static const maxTextBytes = 4 * 1024 * 1024;

  File _pendingFile(Directory folder, String lessonId, String? materialId) =>
      File('${folder.path}/${_base(lessonId, materialId)}.pending');

  Future<PendingPdfTransfer?> pending(
    String owner,
    String lessonId,
    String? materialId,
  ) async {
    if (client.auth.currentUser?.id != owner) return null;
    return OfflinePdfTransfer.pending(
      _pendingFile(await _folder(owner), lessonId, materialId),
    );
  }

  Future<bool> pause(String owner, String lessonId, String? materialId) async {
    if (client.auth.currentUser?.id != owner) return false;
    return OfflinePdfTransfer.pause(
      _pendingFile(await _folder(owner), lessonId, materialId),
    );
  }

  Future<bool> resume(String owner, String lessonId, String? materialId) async {
    if (client.auth.currentUser?.id != owner || materialId == null) {
      return false;
    }
    final marker = _pendingFile(await _folder(owner), lessonId, materialId);
    final data = await OfflinePdfTransfer.metadata(marker);
    if (data?['owner'] != owner ||
        data?['lessonId'] != lessonId ||
        data?['materialId'] != materialId ||
        data?['ticket'] is! Map ||
        !LearningEvidenceRepository.ticketIsCurrent(data!['ticket'] as Map)) {
      return false;
    }
    final response = await client.functions.invoke(
      'prepare-lesson-reading',
      body: {'materialId': materialId},
    );
    if (response.status != 200 || response.data is! Map) return false;
    final url = (response.data as Map)['url'];
    if (url is! String || Uri.tryParse(url)?.scheme != 'https') return false;
    return OfflinePdfTransfer.resume(marker, url: Uri.parse(url));
  }

  Future<void> cancel(String owner, String lessonId, String? materialId) async {
    if (client.auth.currentUser?.id != owner) return;
    final folder = await _folder(owner);
    final marker = _pendingFile(folder, lessonId, materialId);
    final data = await OfflinePdfTransfer.metadata(marker);
    await OfflinePdfTransfer.cancel(marker);
    if (await marker.exists()) await marker.delete();
    final filename = data?['filename'];
    if (filename is String &&
        RegExp(r'^[0-9a-fA-F-]{36}\.pdf$').hasMatch(filename)) {
      final file = File('${folder.path}/$filename');
      if (await file.exists()) await file.delete();
    }
  }

  Future<void> _validatePdf(File pdf) async {
    final size = await pdf.length();
    if (size > maxPdfBytes || size < 4) throw StateError('Invalid PDF file.');
    final input = await pdf.open();
    try {
      if (ascii.decode(await input.read(4)) != '%PDF') {
        throw StateError('Invalid PDF file.');
      }
    } finally {
      await input.close();
    }
  }

  Future<void> _recover(String owner) async {
    final folder = await _folder(owner);
    await for (final marker in folder.list()) {
      if (marker is! File || !marker.path.endsWith('.pending')) continue;
      if (OfflinePdfTransfer.isActive(marker)) continue;
      final data = await OfflinePdfTransfer.metadata(marker);
      if (data == null || data['owner'] != owner) continue;
      final transfer = await OfflinePdfTransfer.pending(marker);
      if (transfer != null && transfer.status != TaskStatus.complete) continue;
      final lessonId = data['lessonId'];
      final materialId = data['materialId'];
      final filename = data['filename'];
      if (lessonId is! String ||
          materialId is! String ||
          filename is! String ||
          !RegExp(r'^[0-9a-fA-F-]{36}\.pdf$').hasMatch(filename) ||
          data['expectedBytes'] is! int ||
          (data['expectedBytes'] as int) <= 0 ||
          data['ticket'] is! Map<String, dynamic> ||
          data['text'] is! String) {
        continue;
      }
      try {
        final pdf = File('${folder.path}/$filename');
        await _validatePdf(pdf);
        if (await pdf.length() != data['expectedBytes']) continue;
        String? oldPdf;
        final manifest = File(
          '${folder.path}/${_base(lessonId, materialId)}.json',
        );
        if (await manifest.exists()) {
          try {
            oldPdf =
                (jsonDecode(await manifest.readAsString()) as Map)['pdfFile']
                    as String?;
          } catch (_) {
            // A damaged previous manifest must not block recovery.
          }
        }
        await OfflineFileStore.writeJson(manifest, {
          'version': 1,
          'owner': owner,
          'lessonId': lessonId,
          'materialId': materialId,
          'ticket': data['ticket'],
          'text': data['text'],
          'title': data['title'],
          'pdfFile': filename,
          'pdfBytes': await pdf.length(),
        });
        await marker.delete();
        if (oldPdf != null &&
            oldPdf != filename &&
            RegExp(r'^[0-9a-fA-F-]{36}\.pdf$').hasMatch(oldPdf)) {
          final old = File('${folder.path}/$oldPdf');
          if (await old.exists()) await old.delete();
        }
      } catch (_) {
        // Leave the last valid manifest intact and retry recovery later.
      }
    }
  }

  Future<Directory> _folder(String owner) async {
    OfflineFileStore.requireId(owner);
    final root = await directory();
    final folder = Directory('${root.path}/lesson-readings/$owner');
    await folder.create(recursive: true);
    return folder;
  }

  String _base(String lessonId, String? materialId) {
    OfflineFileStore.requireId(lessonId);
    if (materialId != null) OfflineFileStore.requireId(materialId);
    return '${lessonId}_${materialId ?? 'notes'}';
  }

  Future<OfflineReadingSnapshot?> read({
    required String owner,
    required String lessonId,
    String? materialId,
  }) async {
    if (client.auth.currentUser?.id != owner) return null;
    await _recover(owner);
    final folder = await _folder(owner);
    final manifest = File('${folder.path}/${_base(lessonId, materialId)}.json');
    if (!await manifest.exists()) return null;
    try {
      final data = jsonDecode(await manifest.readAsString());
      if (data is! Map<String, dynamic> ||
          data['owner'] != owner ||
          data['lessonId'] != lessonId ||
          data['materialId'] != materialId ||
          data['text'] is! String ||
          data['ticket'] is! Map<String, dynamic>) {
        return null;
      }
      final ticket = Map<String, dynamic>.from(data['ticket'] as Map);
      if (!LearningEvidenceRepository.ticketIsCurrent(ticket)) return null;
      final filename = data['pdfFile'];
      String? pdfPath;
      if (filename != null) {
        if (filename is! String ||
            !RegExp(r'^[0-9a-fA-F-]{36}\.pdf$').hasMatch(filename)) {
          return null;
        }
        final pdf = File('${folder.path}/$filename');
        if (!await pdf.exists() || await pdf.length() != data['pdfBytes']) {
          return null;
        }
        pdfPath = pdf.path;
      }
      if (client.auth.currentUser?.id != owner) return null;
      return OfflineReadingSnapshot(
        ticket: ticket,
        text: data['text'] as String,
        pdfPath: pdfPath,
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on FileSystemException {
      // A file removed by storage cleanup must not leave an unusable reader.
      return null;
    }
  }

  Future<void> save({
    required String owner,
    required String lessonId,
    required String? materialId,
    required Map<String, dynamic> ticket,
    required String text,
    required String title,
    String? pdfUrl,
    void Function(double)? onProgress,
  }) async {
    if (client.auth.currentUser?.id != owner ||
        !LearningEvidenceRepository.ticketIsCurrent(ticket)) {
      throw StateError('Reconnect to save this reading.');
    }
    if (utf8.encode(text).length > maxTextBytes) {
      throw StateError('This reading is too large to save offline.');
    }
    final key = '$owner:${_base(lessonId, materialId)}';
    if (!_activeSaves.add(key)) {
      throw StateError('This reading is already downloading.');
    }
    try {
      await _saveReading(
        owner: owner,
        lessonId: lessonId,
        materialId: materialId,
        ticket: ticket,
        text: text,
        title: title,
        pdfUrl: pdfUrl,
        onProgress: onProgress,
      );
    } finally {
      _activeSaves.remove(key);
    }
  }

  Future<void> _saveReading({
    required String owner,
    required String lessonId,
    required String? materialId,
    required Map<String, dynamic> ticket,
    required String text,
    required String title,
    String? pdfUrl,
    void Function(double)? onProgress,
  }) async {
    final folder = await _folder(owner);
    final manifest = File('${folder.path}/${_base(lessonId, materialId)}.json');
    final pending = _pendingFile(folder, lessonId, materialId);
    OfflinePdfTransfer.clearCancellation(pending);
    final previous = await OfflinePdfTransfer.metadata(pending);
    final retainedFilename =
        previous?['owner'] == owner &&
            previous?['lessonId'] == lessonId &&
            previous?['materialId'] == materialId &&
            previous?['filename'] is String &&
            RegExp(
              r'^[0-9a-fA-F-]{36}\.pdf$',
            ).hasMatch(previous!['filename'] as String)
        ? previous['filename'] as String
        : null;
    final pdfFile = pdfUrl == null
        ? null
        : retainedFilename ?? '${const Uuid().v4()}.pdf';
    final pdf = pdfFile == null ? null : File('${folder.path}/$pdfFile');
    try {
      if (pdf != null) {
        final url = Uri.parse(pdfUrl!);
        if (url.scheme != 'https') throw StateError('Invalid document link.');
        if (_usesDefaultDownloader) {
          if (materialId == null) throw StateError('Reading access changed.');
          final material = await client
              .from('curriculum_materials')
              .select('size_bytes')
              .eq('id', materialId)
              .eq('lesson_id', lessonId)
              .eq('status', 'ready')
              .single();
          final expectedBytes = (material['size_bytes'] as num).toInt();
          if (expectedBytes <= 0 || expectedBytes > maxPdfBytes) {
            throw StateError('This PDF is too large to save offline.');
          }
          var transferUrl = url;
          if (retainedFilename != null) {
            final response = await client.functions.invoke(
              'prepare-lesson-reading',
              body: {'materialId': materialId},
            );
            if (response.status != 200 || response.data is! Map) {
              throw StateError('Reading access changed. Reopen this reading.');
            }
            final fresh = (response.data as Map)['url'];
            if (fresh is! String) throw StateError('Reading access changed.');
            transferUrl = Uri.parse(fresh);
          }
          await OfflinePdfTransfer.download(
            marker: pending,
            metadata: {
              'owner': owner,
              'lessonId': lessonId,
              'materialId': materialId,
              'filename': pdfFile,
              'sourcePath': transferUrl.path,
              'expectedBytes': expectedBytes,
              'ticket': ticket,
              'text': text,
              'title': title,
            },
            url: transferUrl,
            owner: owner,
            filename: pdfFile!,
            onProgress: onProgress,
          );
          if (await pdf.length() != expectedBytes) {
            throw StateError('Downloaded PDF was incomplete. Retry it.');
          }
        } else {
          await pdfDownloader(url, pdf);
        }
        await _validatePdf(pdf);
      }
      if (client.auth.currentUser?.id != owner) {
        throw StateError('Account changed while saving the reading.');
      }
      String? oldPdf;
      if (await manifest.exists()) {
        try {
          oldPdf =
              (jsonDecode(await manifest.readAsString()) as Map)['pdfFile']
                  as String?;
        } catch (_) {
          // Replace an unreadable manifest only after the new file is ready.
        }
      }
      await OfflineFileStore.writeJson(manifest, {
        'version': 1,
        'owner': owner,
        'lessonId': lessonId,
        'materialId': materialId,
        'ticket': ticket,
        'text': text,
        'title': title,
        'pdfFile': pdfFile,
        'pdfBytes': pdf == null ? null : await pdf.length(),
      });
      if (await pending.exists()) await pending.delete();
      if (oldPdf != null &&
          oldPdf != pdfFile &&
          RegExp(r'^[0-9a-fA-F-]{36}\.pdf$').hasMatch(oldPdf)) {
        final old = File('${folder.path}/$oldPdf');
        if (await old.exists()) await old.delete();
      }
    } catch (_) {
      if (pdf != null && await pdf.exists()) await pdf.delete();
      rethrow;
    }
  }

  Future<List<OfflineReadingEntry>> list(String owner) async {
    if (client.auth.currentUser?.id != owner) return [];
    await _recover(owner);
    final folder = await _folder(owner);
    final entries = <OfflineReadingEntry>[];
    await for (final file in folder.list()) {
      if (file is! File || !file.path.endsWith('.json')) continue;
      try {
        final data = jsonDecode(await file.readAsString());
        if (data is! Map<String, dynamic> ||
            data['owner'] != owner ||
            data['lessonId'] is! String ||
            data['ticket'] is! Map<String, dynamic> ||
            data['text'] is! String) {
          continue;
        }
        final lessonId = data['lessonId'] as String;
        final materialId = data['materialId'] as String?;
        if (file.uri.pathSegments.last !=
            '${_base(lessonId, materialId)}.json') {
          continue;
        }
        var bytes = utf8.encode(data['text'] as String).length;
        final pdfFile = data['pdfFile'];
        if (pdfFile != null) {
          if (pdfFile is! String ||
              !RegExp(r'^[0-9a-fA-F-]{36}\.pdf$').hasMatch(pdfFile)) {
            continue;
          }
          final pdf = File('${folder.path}/$pdfFile');
          if (!await pdf.exists() || await pdf.length() != data['pdfBytes']) {
            continue;
          }
          bytes += await pdf.length();
        }
        entries.add(
          OfflineReadingEntry(
            lessonId: lessonId,
            materialId: materialId,
            title: data['title'] as String? ?? 'Lesson reading',
            byteSize: bytes,
            needsAccessRefresh: !LearningEvidenceRepository.ticketIsCurrent(
              data['ticket'] as Map,
            ),
          ),
        );
      } catch (_) {
        // Corrupt entries remain on disk for recovery and never become readable.
      }
    }
    return client.auth.currentUser?.id == owner ? entries : [];
  }

  Future<void> remove(String owner, String lessonId, String? materialId) async {
    if (client.auth.currentUser?.id != owner) return;
    await cancel(owner, lessonId, materialId);
    final folder = await _folder(owner);
    final manifest = File('${folder.path}/${_base(lessonId, materialId)}.json');
    if (!await manifest.exists()) return;
    try {
      final data = jsonDecode(await manifest.readAsString()) as Map;
      if (data['owner'] != owner ||
          data['lessonId'] != lessonId ||
          data['materialId'] != materialId) {
        return;
      }
      final pdfFile = data['pdfFile'];
      if (pdfFile is String &&
          RegExp(r'^[0-9a-fA-F-]{36}\.pdf$').hasMatch(pdfFile)) {
        final pdf = File('${folder.path}/$pdfFile');
        if (await pdf.exists()) await pdf.delete();
      }
    } catch (_) {
      // A malformed manifest cannot name a file to delete.
    }
    await manifest.delete();
  }

  static Future<void> _downloadPdf(
    Uri url,
    File target, {
    void Function(double)? onProgress,
  }) async {
    const timeout = Duration(seconds: 30);
    final http = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await http.getUrl(url).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok ||
          response.contentLength > maxPdfBytes) {
        throw StateError('Could not save this PDF.');
      }
      final expectedBytes = response.contentLength;
      final output = await target.open(mode: FileMode.write);
      try {
        var bytes = 0;
        await for (final chunk in response.timeout(timeout)) {
          bytes += chunk.length;
          if (bytes > maxPdfBytes) {
            throw StateError('This PDF is too large to save offline.');
          }
          await output.writeFrom(chunk);
          if (expectedBytes > 0) {
            onProgress?.call((bytes / expectedBytes).clamp(0.0, 1.0));
          }
        }
        if (expectedBytes > 0 && bytes != expectedBytes) {
          throw StateError('Downloaded PDF was incomplete. Retry it.');
        }
      } finally {
        await output.close();
      }
    } finally {
      http.close(force: true);
    }
  }

  Future<void> purgeOtherUsers(String? currentUser) async {
    final root = await directory();
    final parent = Directory('${root.path}/lesson-readings');
    if (!await parent.exists()) return;
    await for (final entry in parent.list()) {
      if (entry is Directory &&
          entry.uri.pathSegments.where((s) => s.isNotEmpty).last !=
              currentUser) {
        await entry.delete(recursive: true);
      }
    }
  }
}
