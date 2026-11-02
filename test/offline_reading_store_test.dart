import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nts_psc_app/features/learn/data/offline_reading_store.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const owner = '00000000-0000-0000-0000-000000000001';
  const lesson = '00000000-0000-0000-0000-000000000002';
  const material = '00000000-0000-0000-0000-000000000003';
  late Directory directory;
  late SupabaseClient client;

  Map<String, dynamic> ticket() {
    final now = DateTime.now().toUtc();
    return {
      'id': material,
      'units': 1,
      'started_at': now.subtract(const Duration(minutes: 1)).toIso8601String(),
      'expires_at': now.add(const Duration(days: 6)).toIso8601String(),
      '_cached_at': now.toIso8601String(),
    };
  }

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cboa-reading-');
    client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        final claims = base64Url
            .encode(
              utf8.encode(
                jsonEncode({
                  'sub': owner,
                  'exp':
                      DateTime.now()
                          .add(const Duration(hours: 1))
                          .millisecondsSinceEpoch ~/
                      1000,
                }),
              ),
            )
            .replaceAll('=', '');
        return http.Response(
          jsonEncode({
            'access_token': 'eyJhbGciOiJIUzI1NiJ9.$claims.fixture',
            'refresh_token': 'fixture-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': owner,
              'aud': 'authenticated',
              'email': 'reader@example.invalid',
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-10-26T00:00:00Z',
            },
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    await client.auth.signInWithPassword(
      email: 'reader@example.invalid',
      password: 'fixture',
    );
  });
  tearDown(() async {
    await client.dispose();
    await directory.delete(recursive: true);
  });

  test(
    'saved lesson text survives a new store but expires with its ticket',
    () async {
      final store = OfflineReadingStore(
        client,
        directory: () async => directory,
      );
      await store.save(
        owner: owner,
        lessonId: lesson,
        materialId: null,
        ticket: ticket(),
        text: 'Read this lesson',
        title: 'Introduction',
      );
      final restored = await OfflineReadingStore(
        client,
        directory: () async => directory,
      ).read(owner: owner, lessonId: lesson);
      expect(restored?.text, 'Read this lesson');
      expect((await store.list(owner)).single.title, 'Introduction');
      expect(await store.read(owner: owner, lessonId: material), isNull);
      await client.auth.signOut();
      expect(await store.read(owner: owner, lessonId: lesson), isNull);
    },
  );

  test(
    'PDF replacement keeps the old reading if the new file is invalid',
    () async {
      final valid = OfflineReadingStore(
        client,
        directory: () async => directory,
        pdfDownloader: (_, file) => file.writeAsBytes(ascii.encode('%PDF-1.7')),
      );
      await valid.save(
        owner: owner,
        lessonId: lesson,
        materialId: material,
        ticket: ticket(),
        text: 'Document text',
        title: 'Handout',
        pdfUrl: 'https://example.invalid/document.pdf',
      );
      final first = await valid.read(
        owner: owner,
        lessonId: lesson,
        materialId: material,
      );
      expect(first?.pdfPath, isNotNull);
      expect(await File(first!.pdfPath!).readAsString(), '%PDF-1.7');

      final invalid = OfflineReadingStore(
        client,
        directory: () async => directory,
        pdfDownloader: (_, file) => file.writeAsString('not a PDF'),
      );
      await expectLater(
        invalid.save(
          owner: owner,
          lessonId: lesson,
          materialId: material,
          ticket: ticket(),
          text: 'Replacement',
          title: 'Handout',
          pdfUrl: 'https://example.invalid/document.pdf',
        ),
        throwsStateError,
      );
      final retained = await invalid.read(
        owner: owner,
        lessonId: lesson,
        materialId: material,
      );
      expect(retained?.text, 'Document text');
      expect(retained?.pdfPath, first.pdfPath);
      await invalid.remove(owner, lesson, material);
      expect(
        await invalid.read(
          owner: owner,
          lessonId: lesson,
          materialId: material,
        ),
        isNull,
      );
      expect(await File(first.pdfPath!).exists(), isFalse);
    },
  );
}
