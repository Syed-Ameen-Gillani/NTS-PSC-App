import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/data/course_download_ledger.dart';

void main() {
  late Directory directory;
  late CourseDownloadLedger ledger;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cboa-queue-');
    ledger = CourseDownloadLedger(directory: () async => directory);
  });
  tearDown(() => directory.delete(recursive: true));

  test(
    'remaining lessons and Wi-Fi choice survive a new store instance',
    () async {
      await ledger.write(
        const CourseDownloadQueue(
          owner: 'student-a',
          courseId: 'course-1',
          remainingLessonIds: ['lesson-2', 'lesson-3'],
          wifiOnly: true,
        ),
      );
      final restored = await CourseDownloadLedger(
        directory: () async => directory,
      ).read('student-a', 'course-1');
      expect(restored?.remainingLessonIds, ['lesson-2', 'lesson-3']);
      expect(restored?.wifiOnly, true);
      expect(await ledger.read('student-b', 'course-1'), isNull);
      await ledger.remove('student-a', 'course-1');
      expect(await ledger.read('student-a', 'course-1'), isNull);
    },
  );

  test('account cleanup removes another student’s queue', () async {
    for (final owner in ['student-a', 'student-b']) {
      await ledger.write(
        CourseDownloadQueue(
          owner: owner,
          courseId: 'course-1',
          remainingLessonIds: const ['lesson-1'],
          wifiOnly: false,
        ),
      );
    }
    await ledger.purgeOtherUsers('student-b');
    expect(await ledger.read('student-a', 'course-1'), isNull);
    expect(await ledger.read('student-b', 'course-1'), isNotNull);
  });
}
