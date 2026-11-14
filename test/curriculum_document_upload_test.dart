import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nts_psc_app/core/networks/upload_progress_client.dart';
import 'package:nts_psc_app/features/curriculum/data/curriculum_repository.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test(
    'progress preserves multipart headers, bytes and server errors',
    () async {
      final percentages = <double>[];
      final inner = MockClient((request) async {
        expect(request.headers['authorization'], 'Bearer teacher-token');
        expect(request.headers['content-type'], contains('boundary='));
        expect(utf8.decode(request.bodyBytes), contains('document contents'));
        return http.Response('Denied', 403);
      });
      final client = UploadProgressClient(inner, percentages.add);
      addTearDown(client.close);
      final request =
          http.MultipartRequest('POST', Uri.parse('https://test.invalid'))
            ..headers['authorization'] = 'Bearer teacher-token'
            ..files.add(
              http.MultipartFile.fromString('file', 'document contents'),
            );
      final response = await client.send(request);
      expect(response.statusCode, 403);
      expect(percentages, isNotEmpty);
      expect(percentages.last, 1);
      expect(percentages, orderedEquals([...percentages]..sort()));
    },
  );

  for (final fail in [false, true]) {
    test(
      fail
          ? 'failed upload cleans reservation without announcing a document'
          : 'ready document is announced before slow reading preparation',
      () async {
        final directory = await Directory.systemTemp.createTemp(
          'cboa-document-',
        );
        addTearDown(() => directory.delete(recursive: true));
        final file = await File(
          '${directory.path}/notes.txt',
        ).writeAsString('Study notes');
        final processing = Completer<void>();
        final announced = Completer<CurriculumMaterial>();
        final calls = <String>[];
        final transport = MockClient((request) async {
          http.Response response(String body, int status) => http.Response(
            body,
            status,
            request: request,
            headers: {'content-type': 'application/json'},
          );
          final path = request.url.path;
          calls.add('${request.method} $path');
          if (path.endsWith('/begin_curriculum_material')) {
            return response(
              jsonEncode({
                'id': 'material',
                'object_path': 'teacher/course/material.txt',
                'mime_type': 'text/plain',
              }),
              200,
            );
          }
          if (path.contains('/storage/v1/object/') &&
              request.method == 'POST') {
            return fail
                ? response(
                    '{"message":"Upload failed","statusCode":"500","error":"Server error"}',
                    500,
                  )
                : response(
                    '{"Key":"course-materials/teacher/course/material.txt"}',
                    200,
                  );
          }
          if (path.endsWith('/prepare-lesson-reading')) {
            await processing.future;
          }
          if (request.method == 'DELETE' && path.startsWith('/storage/')) {
            return response('[]', 200);
          }
          return response('{}', 200);
        });
        final supabase = SupabaseClient(
          'https://example.supabase.co',
          'test-key',
          httpClient: transport,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        addTearDown(supabase.dispose);
        final repository = CurriculumRepository(
          supabase,
          uploadClientFactory: () => transport,
        );
        final percentages = <double>[];
        var completed = false;
        final upload = repository
            .upload(
              const CurriculumScope(
                courseId: 'course',
                moduleId: 'module',
                lessonId: 'lesson',
              ),
              (
                path: file.path,
                name: 'notes.txt',
                sizeBytes: await file.length(),
              ),
              onProgress: percentages.add,
              onUploaded: announced.complete,
            )
            .then((_) => completed = true);
        if (fail) {
          await expectLater(upload, throwsA(isA<StorageException>()));
          expect(announced.isCompleted, false);
          expect(calls, contains('DELETE /storage/v1/object/course-materials'));
          expect(calls, contains('DELETE /rest/v1/curriculum_materials'));
          expect(
            calls.any((call) => call.endsWith('/finish_curriculum_material')),
            false,
          );
        } else {
          final material = await announced.future;
          expect(material.title, 'notes.txt');
          expect(material.id, 'material');
          expect(percentages.last, 1);
          expect(
            calls,
            contains('POST /rest/v1/rpc/finish_curriculum_material'),
          );
          expect(completed, false);
          processing.complete();
          await upload;
          expect(completed, true);
        }
      },
    );
  }
}
