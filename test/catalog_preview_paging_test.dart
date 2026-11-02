import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nts_psc_app/core/repositories/supabase_course_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('landing previews request bounded Supabase ranges', () async {
    final requests = <http.Request>[];
    final client = SupabaseClient(
      'https://example.supabase.co',
      'public-test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        requests.add(request);
        return http.Response(
          '[]',
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final repository = SupabaseCourseRepository(client);

    expect(await repository.getNewCoursesPage(offset: 20, limit: 12), isEmpty);
    expect(await repository.getFeaturedCoursesPreview(), isEmpty);
    expect(await repository.getPublicTeachers(limit: 4), isEmpty);
    expect(await repository.getPublicTeachers(limit: 20, offset: 20), isEmpty);

    expect(requests.length, 4);
    expect(requests[0].url.queryParameters['offset'], '20');
    expect(requests[0].url.queryParameters['limit'], '12');
    expect(requests[1].url.queryParameters['offset'], '0');
    expect(requests[1].url.queryParameters['limit'], '4');
    expect(requests[2].url.queryParameters['offset'], '0');
    expect(requests[2].url.queryParameters['limit'], '4');
    expect(requests[3].url.queryParameters['offset'], '20');
    expect(requests[3].url.queryParameters['limit'], '20');
    expect(requests[1].url.queryParameters['is_featured'], 'eq.true');
  });
}
