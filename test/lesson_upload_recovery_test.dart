import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/learn/data/lesson_upload_session_store.dart';
import 'package:nts_psc_app/features/learn/data/offline_file_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const id = '00000000-0000-0000-0000-000000000001';

  test(
    'upload retries only reuse a reservation for matching video bytes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'nts-upload-retry-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/lecture.mp4');
      final intent = File('${directory.path}/upload.json');
      await file.writeAsBytes([1, 2, 3, 4]);
      final original = await LessonUploadSessionStore.fingerprint(file);
      await OfflineFileStore.writeJson(intent, {
        'digest': original,
        'mediaId': id,
      });
      expect(
        (await LessonUploadSessionStore.read(intent, original))?['mediaId'],
        id,
      );
      await file.writeAsBytes([4, 3, 2, 1]);
      final changed = await LessonUploadSessionStore.fingerprint(file);
      expect(changed, isNot(original));
      expect(await LessonUploadSessionStore.read(intent, changed), isNull);
    },
  );

  test('finalization recovery skips an already finalized video', () async {
    var writes = 0;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        if (request.method == 'POST') writes++;
        return http.Response(
          '{"status":"transcribing"}',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    await LessonMediaRepository(client).finalizeUpload(id);
    expect(writes, 0);
  });

  test('an uploaded video can retry the finalization RPC', () async {
    var writes = 0;
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient((request) async {
        if (request.method == 'GET') {
          return http.Response(
            '{"status":"uploading"}',
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        expect(request.url.path, '/rest/v1/rpc/finalize_lesson_media');
        expect(request.body, contains(id));
        writes++;
        return http.Response('', 204, request: request);
      }),
    );
    addTearDown(client.dispose);
    await LessonMediaRepository(client).finalizeUpload(id);
    expect(writes, 1);
  });
}
