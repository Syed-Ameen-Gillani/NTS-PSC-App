import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_store.dart';

const owner = '11111111-1111-1111-1111-111111111111';
const lesson = '22222222-2222-2222-2222-222222222222';
const activity = '33333333-3333-3333-3333-333333333333';
const session = '44444444-4444-4444-4444-444444444444';

class _Repository extends LearningEvidenceRepository {
  _Repository(super.client, {required super.store});
  @override
  String? get user => owner;
}

void main() {
  late Directory directory;
  late LearningEvidenceStore store;
  final ticket = {
    'id': session,
    'lesson_id': lesson,
    'activity_id': activity,
    'next_sequence': 1,
  };
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cboa-evidence-replay-');
    store = LearningEvidenceStore(directory: () async => directory);
    await store.transaction(
      owner,
      (data) async =>
          (data['tickets'] as Map)['$lesson:$activity'] = {...ticket},
    );
  });
  tearDown(() async => directory.delete(recursive: true));
  Future<void> append(_Repository repository, int number) => repository.append(
    owner,
    ticket,
    start: number * 1000,
    end: (number + 1) * 1000,
    wallMs: 1000,
  );
  http.Response response(http.Request request, List events) => http.Response(
    jsonEncode([
      for (final _ in events)
        {
          'accepted': true,
          'lesson_id': lesson,
          'activity_completed': false,
          'lesson_completed': false,
        },
    ]),
    200,
    request: request,
    headers: {'content-type': 'application/json'},
  );

  test(
    'lost response replays exactly the original sample identities',
    () async {
      final bodies = <String>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          bodies.add(request.body);
          if (bodies.length == 1) {
            throw const SocketException('Response lost after server commit');
          }
          return response(
            request,
            (jsonDecode(request.body) as Map)['p_events'] as List,
          );
        }),
      );
      addTearDown(client.dispose);
      final repository = _Repository(client, store: store);
      for (var i = 0; i < 3; i++) {
        await append(repository, i);
      }
      await repository.sync();
      expect(
        await store.transaction(
          owner,
          (data) async => (data['events'] as List).length,
        ),
        3,
      );
      await repository.sync();
      expect(bodies, hasLength(2));
      expect(bodies[1], bodies[0]);
      expect(
        await store.transaction(
          owner,
          (data) async => (data['events'] as List).length,
        ),
        0,
      );
    },
  );
  test(
    'slow sync does not block capture and drains all bounded batches',
    () async {
      final started = Completer<void>();
      final release = Completer<void>();
      final counts = <int>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          final events = (jsonDecode(request.body) as Map)['p_events'] as List;
          counts.add(events.length);
          if (counts.length == 1) {
            started.complete();
            await release.future;
          }
          return response(request, events);
        }),
      );
      addTearDown(client.dispose);
      final repository = _Repository(client, store: store);
      for (var i = 0; i < 100; i++) {
        await append(repository, i);
      }
      final syncing = repository.sync();
      await started.future.timeout(const Duration(seconds: 3));
      await append(repository, 100).timeout(const Duration(seconds: 3));
      release.complete();
      await syncing;
      expect(counts, [50, 50, 1]);
      expect(
        await store.transaction(
          owner,
          (data) async => (data['events'] as List).length,
        ),
        0,
      );
    },
  );

  test('successful handout open refreshes the lesson outcome', () async {
    late Map<String, dynamic> body;
    final changed = LearningEvidenceRepository.changes.stream.first;
    final client = SupabaseClient(
      'https://example.invalid',
      'key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        body = Map<String, dynamic>.from(jsonDecode(request.body) as Map);
        return http.Response(
          jsonEncode({
            'activity_completed': true,
            'lesson_id': lesson,
            'lesson_completed': false,
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        );
      }),
    );
    addTearDown(client.dispose);
    final repository = _Repository(client, store: store);

    final result = await repository.confirmMaterialOpened(lesson, activity);

    expect(body, {'p_lesson_id': lesson, 'p_activity_id': activity});
    expect(result['activity_completed'], isTrue);
    expect(await changed.timeout(const Duration(seconds: 1)), lesson);
  });

  test(
    'offline PDF opens persist once and replay after reopening the app',
    () async {
      var online = false;
      final bodies = <Map>[];
      final client = SupabaseClient(
        'https://example.invalid',
        'key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          if (!online) throw const SocketException('Offline');
          bodies.add(jsonDecode(request.body) as Map);
          return http.Response(
            jsonEncode({'activity_completed': true}),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final now = DateTime.now().toUtc();
      final openTicket = {
        ...ticket,
        '_cached_at': now.toIso8601String(),
        'started_at': now.toIso8601String(),
        'expires_at': now.add(const Duration(days: 1)).toIso8601String(),
      };
      final repository = _Repository(client, store: store);
      await repository.recordMaterialOpened(owner, openTicket);
      await repository.recordMaterialOpened(owner, openTicket);
      expect(
        await store.read(
          owner,
          (data) async => (data['material_opens'] as Map).length,
        ),
        1,
      );
      expect(
        await repository.pendingMessage(lesson),
        contains('syncs when online'),
      );
      online = true;
      await _Repository(client, store: store).sync();
      expect(bodies, [
        {'p_session_id': session},
      ]);
      expect(
        await store.read(
          owner,
          (data) async => (data['material_opens'] as Map).length,
        ),
        0,
      );
    },
  );

  test(
    'stale or revoked PDF opens cannot complete and do not retry forever',
    () async {
      var requests = 0;
      final client = SupabaseClient(
        'https://example.invalid',
        'key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests++;
          return http.Response(
            jsonEncode({'code': '22023', 'message': 'Content changed'}),
            400,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      await store.transaction(owner, (data) async {
        data['material_opens'] = {
          session: {'lesson_id': lesson},
        };
      });
      final repository = _Repository(client, store: store);
      await repository.sync();
      await repository.sync();
      expect(requests, 1);
      expect(
        await repository.pendingMessage(lesson),
        contains('Reopen this handout online'),
      );
    },
  );

  test(
    'replaced reading content cannot reuse its previous cached session',
    () async {
      var requests = 0;
      final client = SupabaseClient(
        'https://example.invalid',
        'key',
        authOptions: const AuthClientOptions(autoRefreshToken: false),
        httpClient: MockClient((request) async {
          requests++;
          return http.Response(
            jsonEncode({...ticket, 'content_version': 'new'}),
            200,
            request: request,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      addTearDown(client.dispose);
      final now = DateTime.now().toUtc();
      await store.transaction(owner, (data) async {
        (data['tickets'] as Map)['$lesson:$activity'] = {
          ...ticket,
          'content_version': 'old',
          '_cached_at': now.toIso8601String(),
          'started_at': now.toIso8601String(),
          'expires_at': now.add(const Duration(days: 1)).toIso8601String(),
        };
      });
      final result = await _Repository(
        client,
        store: store,
      ).session(lesson, activity, expectedVersion: 'new');
      expect(requests, 1);
      expect(result['content_version'], 'new');
    },
  );
}
