import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  for (final missingDescription in [true, false]) {
    test(
      'publication identifies the missing ${missingDescription ? 'description' : 'cover'}',
      () async {
        var writes = 0;
        final client = SupabaseClient(
          'https://example.supabase.co',
          'test',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
            if (request.method == 'PATCH') writes++;
            return http.Response(
              jsonEncode({
                'description': missingDescription
                    ? ''
                    : 'Already saved description',
                'image_path': null,
              }),
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        addTearDown(client.dispose);
        await expectLater(
          SupabaseCourseRepository(client).publishChanges('course'),
          throwsA(
            isA<PostgrestException>().having(
              (error) => error.message,
              'message',
              missingDescription
                  ? 'Add a course description before publishing.'
                  : 'Upload a course cover before publishing.',
            ),
          ),
        );
        expect(writes, 0);
      },
    );
  }

  test(
    'publication keeps saved description and calls the release RPC',
    () async {
      var writes = 0;
      final client = SupabaseClient(
        'https://example.supabase.co',
        'test',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          final read = request.method == 'GET';
          if (!read) {
            writes++;
            expect(request.url.path, '/rest/v1/rpc/publish_course_changes');
            expect(jsonDecode(request.body), {'p_course_id': 'course'});
          }
          return http.Response(
            jsonEncode(
              read
                  ? {
                      'description': 'My original description',
                      'image_path': 'teacher/course/cover.jpg',
                    }
                  : true,
            ),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      expect(
        await SupabaseCourseRepository(client).publishChanges('course'),
        true,
      );
      expect(writes, 1);
    },
  );

  test('an up-to-date course returns no pending changes', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'test',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.method == 'POST') {
          expect(request.url.path, '/rest/v1/rpc/publish_course_changes');
          expect(jsonDecode(request.body), {'p_course_id': 'course'});
        }
        return http.Response(
          request.method == 'GET'
              ? '{"description":"Saved","image_path":"owner/course/cover.jpg"}'
              : 'false',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    expect(
      await SupabaseCourseRepository(client).publishChanges('course'),
      false,
    );
  });
}
