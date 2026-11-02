import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nts_psc_app/features/learn/data/offline_progress_queue.dart';

void main() {
  const learner = '11111111-1111-4111-8111-111111111111';
  const lesson = '33333333-3333-4333-8333-333333333333';
  late Directory root;
  late SupabaseClient client;
  String? user;
  var online = false;
  final sent = <String>[];
  setUp(() async {
    root = await Directory.systemTemp.createTemp('offline-progress-');
    client = SupabaseClient(
      'https://example.invalid',
      'test-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
    );
    user = learner;
    online = false;
    sent.clear();
  });
  tearDown(() async {
    await client.dispose();
    await root.delete(recursive: true);
  });
  OfflineProgressQueue queue() => OfflineProgressQueue(
    client,
    directory: () async => root,
    currentUserId: () => user,
    record: (id) async {
      if (!online) throw const SocketException('offline');
      sent.add(id);
    },
  );
  test('offline completion survives restart and syncs only once', () async {
    expect(await queue().complete(lesson), false);
    expect(await queue().complete(lesson), false);
    expect(await queue().completionStatus(lesson),false);
    online = true;
    await queue().sync();
    await queue().sync();
    expect(sent, [lesson]);
  });
  test('another account cannot replay pending completions', () async {
    await queue().complete(lesson);
    user = '22222222-2222-4222-8222-222222222222';
    online = true;
    await queue().sync();
    expect(sent, isEmpty);
    user = learner;
    await queue().sync();
    expect(sent, [lesson]);
  });
}
