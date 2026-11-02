import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_store.dart';

void main() {
  test(
    'atomic outbox survives restart, concurrent appends and account changes',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'learning-evidence-test',
      );
      addTearDown(() => directory.delete(recursive: true));
      final store = LearningEvidenceStore(directory: () async => directory);
      const first = '11111111-1111-1111-1111-111111111111';
      const second = '22222222-2222-2222-2222-222222222222';
      await Future.wait(
        List.generate(
          10,
          (i) => store.transaction(first, (data) async {
            (data['events'] as List).add(i);
          }),
        ),
      );
      final restarted = LearningEvidenceStore(directory: () async => directory);
      expect(
        await restarted.transaction(
          first,
          (data) async => (data['events'] as List).length,
        ),
        10,
      );
      expect(
        await restarted.transaction(
          second,
          (data) async => (data['events'] as List).length,
        ),
        0,
      );
      await expectLater(
        store.transaction(first, (data) async {
          (data['events'] as List).clear();
          throw const SocketException('offline');
        }),
        throwsA(isA<SocketException>()),
      );
      expect(
        await restarted.transaction(
          first,
          (data) async => (data['events'] as List).length,
        ),
        10,
      );
    },
  );

  test('read-only evidence access does not rewrite the outbox', () async {
    final directory = await Directory.systemTemp.createTemp('evidence-read-');
    addTearDown(() => directory.delete(recursive: true));
    const owner = '11111111-1111-1111-1111-111111111111';
    final store = LearningEvidenceStore(directory: () async => directory);
    await store.transaction(owner, (data) async {
      (data['events'] as List).add({'sequence': 1});
    });
    final file = File('${directory.path}/learning-evidence/$owner/state.json');
    final before = await file.readAsString();
    await store.read(owner, (data) async {
      (data['events'] as List).clear();
    });
    expect(await file.readAsString(), before);
  });
}
