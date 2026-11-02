import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/curriculum/data/course_request_identity.dart';

void main() {
  test('an owner response cannot survive an account switch', () async {
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final id = body['email'] == 'owner@example.invalid' ? 'owner' : 'other';
        final claims = base64Url
            .encode(
              utf8.encode(
                jsonEncode({
                  'sub': id,
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
              'id': id,
              'aud': 'authenticated',
              'email': body['email'],
              'app_metadata': {},
              'user_metadata': {},
              'created_at': '2026-10-26T00:00:00Z',
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    await client.auth.signInWithPassword(
      email: 'owner@example.invalid',
      password: 'fixture',
    );
    final identity = CourseRequestIdentity(client);
    expect(identity.check, returnsNormally);
    await client.auth.signInWithPassword(
      email: 'other@example.invalid',
      password: 'fixture',
    );
    expect(identity.check, throwsStateError);
  });
}
