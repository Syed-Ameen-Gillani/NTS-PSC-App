import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nts_psc_app/features/notifications/data/notification_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('unread badge counts beyond the bounded inbox page', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        if (request.url.path.endsWith('/token')) {
          final claims = base64Url
              .encode(
                utf8.encode(
                  jsonEncode({
                    'sub': 'student-1',
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
                'id': 'student-1',
                'aud': 'authenticated',
                'email': 'student@example.invalid',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': '2026-10-26T00:00:00Z',
              },
            }),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }
        return http.Response(
          '',
          200,
          request: request,
          headers: {'content-range': '*/73'},
        );
      }),
    );
    addTearDown(client.dispose);
    await client.auth.signInWithPassword(
      email: 'student@example.invalid',
      password: 'fixture',
    );

    expect(await NotificationRepository(client).unreadCount(), 73);
    final countRequest = requests.last;
    expect(countRequest.method, 'HEAD');
    expect(countRequest.url.queryParameters['read_at'], 'is.null');
    expect(countRequest.url.queryParameters['user_id'], 'eq.student-1');
  });
}
