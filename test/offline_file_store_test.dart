import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/data/offline_file_store.dart';

void main() {
  const lesson = '00000000-0000-0000-0000-000000000001';
  const media = '00000000-0000-0000-0000-000000000002.mp4';
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('nts-offline-store-');
  });
  tearDown(() async => directory.delete(recursive: true));

  Map<String, dynamic> metadata({int size = 4}) => {
    'filename': media,
    'byteSize': size,
    'authorizedAt': DateTime.now().toUtc().toIso8601String(),
  };

  test('metadata replacement preserves a valid complete JSON file', () async {
    final target = File('${directory.path}/$lesson.json');
    await OfflineFileStore.writeJson(target, {'version': 1});
    await OfflineFileStore.writeJson(target, {'version': 2});
    expect(jsonDecode(await target.readAsString()), {'version': 2});
    expect(await File('${target.path}.tmp').exists(), isFalse);
  });

  test('rejected checkpoint is retained and no longer blocks later answers', () async {
    final pending = File('${directory.path}/pending-checkpoints.json');
    const rejected = {'id': 'first', 'answer': 1};
    const next = {'id': 'second', 'answer': 2};
    await OfflineFileStore.writeJson(pending, [rejected, next]);

    await OfflineFileStore.quarantineCheckpoint(directory, rejected);
    await OfflineFileStore.quarantineCheckpoint(directory, rejected);

    expect(await OfflineFileStore.readCheckpointQueue(pending), [next]);
    expect(
      await OfflineFileStore.readCheckpointQueue(
        File('${directory.path}/rejected-checkpoints.json'),
      ),
      [rejected],
    );
  });

  test(
    'reads a saved native task id and ignores broken pending records',
    () async {
      final pending = File('${directory.path}/download-$lesson.pending');
      await OfflineFileStore.writeJson(pending, {'taskId': 'native-task-1'});
      expect(await OfflineFileStore.pendingTaskId(pending), 'native-task-1');
      await pending.writeAsString('{broken');
      expect(await OfflineFileStore.pendingTaskId(pending), isNull);
    },
  );

  test('rejects path traversal in lesson IDs and media filenames', () {
    expect(() => OfflineFileStore.requireId('../private'), throwsArgumentError);
    expect(OfflineFileStore.isVideoFilename('../$media'), isFalse);
    expect(OfflineFileStore.isVideoFilename('/tmp/$media'), isFalse);
    expect(OfflineFileStore.isVideoFilename(media), isTrue);
    expect(
      OfflineFileStore.isVideoFilename(
        '${lesson}_00000000-0000-0000-0000-000000000002.mov',
      ),
      isTrue,
    );
  });

  test('offline authorization rejects expired and future timestamps', () {
    final now = DateTime.utc(2026, 10, 19);
    expect(
      OfflineFileStore.authorizationIsCurrent(
        now.subtract(const Duration(days: 7)).toIso8601String(),
        now: now,
      ),
      isFalse,
    );
    expect(
      OfflineFileStore.authorizationIsCurrent(
        now.add(const Duration(minutes: 1)).toIso8601String(),
        now: now,
      ),
      isFalse,
    );
    expect(
      OfflineFileStore.authorizationIsCurrent(
        now.subtract(const Duration(days: 6)).toIso8601String(),
        now: now,
      ),
      isTrue,
    );
  });

  test(
    'recovers a complete background download after a process restart',
    () async {
      await File('${directory.path}/$media').writeAsBytes([1, 2, 3, 4]);
      final pending = File('${directory.path}/download-$lesson.pending');
      await OfflineFileStore.writeJson(pending, metadata());
      await OfflineFileStore.recoverDownloads(directory);
      expect(await File('${directory.path}/$lesson.json').exists(), isTrue);
      expect(await pending.exists(), isFalse);
    },
  );

  test(
    'partial or active downloads never replace the saved manifest',
    () async {
      final manifest = File('${directory.path}/$lesson.json');
      await OfflineFileStore.writeJson(manifest, {'saved': true});
      await File('${directory.path}/$media').writeAsBytes([1, 2]);
      final pending = File('${directory.path}/download-$lesson.pending');
      await OfflineFileStore.writeJson(pending, metadata());
      await OfflineFileStore.recoverDownloads(directory);
      expect(jsonDecode(await manifest.readAsString()), {'saved': true});
      await File('${directory.path}/$media').writeAsBytes([1, 2, 3, 4]);
      await OfflineFileStore.recoverDownloads(
        directory,
        activeLessonIds: {lesson},
      );
      expect(jsonDecode(await manifest.readAsString()), {'saved': true});
    },
  );

  test(
    'expired transfers are retained but cannot authorize offline access',
    () async {
      await File('${directory.path}/$media').writeAsBytes([1, 2, 3, 4]);
      final pending = File('${directory.path}/download-$lesson.pending');
      await OfflineFileStore.writeJson(pending, {
        ...metadata(),
        'authorizedAt': '2020-01-01T00:00:00Z',
      });
      await OfflineFileStore.recoverDownloads(directory);
      final manifest = File('${directory.path}/$lesson.json');
      expect(await manifest.exists(), isTrue);
      final recovered = jsonDecode(await manifest.readAsString()) as Map;
      expect(
        OfflineFileStore.authorizationIsCurrent(
          recovered['authorizedAt'] as String?,
        ),
        isFalse,
      );
      await manifest.delete();
      await pending.writeAsString('{incomplete');
      await OfflineFileStore.recoverDownloads(directory);
      expect(await File('${directory.path}/$lesson.json').exists(), isFalse);
    },
  );
}
