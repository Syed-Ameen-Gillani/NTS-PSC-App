import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'learning_evidence_repository.dart';
import 'offline_file_store.dart';

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
       pdfDownloader = pdfDownloader ?? _downloadPdf;

  final SupabaseClient client;
  final Future<Directory> Function() directory;
  final Future<void> Function(Uri, File) pdfDownloader;
  static const maxPdfBytes = 25 * 1024 * 1024;
  static const maxTextBytes = 4 * 1024 * 1024;

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
  }) async {
    if (client.auth.currentUser?.id != owner ||
        !LearningEvidenceRepository.ticketIsCurrent(ticket)) {
      throw StateError('Reconnect to save this reading.');
    }
    if (utf8.encode(text).length > maxTextBytes) {
      throw StateError('This reading is too large to save offline.');
    }
    final folder = await _folder(owner);
    final manifest = File('${folder.path}/${_base(lessonId, materialId)}.json');
    final pdfFile = pdfUrl == null ? null : '${const Uuid().v4()}.pdf';
    final pdf = pdfFile == null ? null : File('${folder.path}/$pdfFile');
    try {
      if (pdf != null) {
        final url = Uri.parse(pdfUrl!);
        if (url.scheme != 'https') throw StateError('Invalid document link.');
        await pdfDownloader(url, pdf);
        if (await pdf.length() > maxPdfBytes || await pdf.length() < 4) {
          throw StateError('Invalid PDF file.');
        }
        final input = await pdf.open();
        try {
          if (ascii.decode(await input.read(4)) != '%PDF') {
            throw StateError('Invalid PDF file.');
          }
        } finally {
          await input.close();
        }
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

  static Future<void> _downloadPdf(Uri url, File target) async {
    const timeout = Duration(seconds: 30);
    final http = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await http.getUrl(url).timeout(timeout);
      final response = await request.close().timeout(timeout);
      if (response.statusCode != HttpStatus.ok ||
          response.contentLength > maxPdfBytes) {
        throw StateError('Could not save this PDF.');
      }
      final output = await target.open(mode: FileMode.write);
      try {
        var bytes = 0;
        await for (final chunk in response.timeout(timeout)) {
          bytes += chunk.length;
          if (bytes > maxPdfBytes) {
            throw StateError('This PDF is too large to save offline.');
          }
          await output.writeFrom(chunk);
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
