import 'dart:io';

import 'package:flutter_compress/flutter_compress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nts_psc_app/features/learn/data/lesson_video_preparer.dart';
import 'package:nts_psc_app/features/learn/data/lesson_video_encoding_profile.dart';

void main() {
  const owner = '11111111-1111-4111-8111-111111111111';
  const lesson = '22222222-2222-4222-8222-222222222222';
  late Directory directory;
  late File source;

  VideoInfo info({int duration = 10000}) => VideoInfo(
    path: 'video.mp4',
    durationMs: duration,
    width: 1280,
    height: 720,
    sizeBytes: 10,
    codec: 'h264',
    bitrateKbps: 2500,
    frameRate: 30,
  );

  VideoCompressResult encoded(String path) => VideoCompressResult(
    id: 'test',
    outputPath: path,
    originalSizeBytes: 100,
    compressedSizeBytes: 50,
    width: 1280,
    height: 720,
    durationMs: 10000,
    codec: 'h264',
    skipped: false,
    hasAudio: true,
  );

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('lesson-compression-');
    source = await File(
      '${directory.path}/original.mov',
    ).writeAsBytes(List.filled(100, 1));
  });

  tearDown(() async => directory.delete(recursive: true));

  Future<PreparedLessonVideo> prepare(LessonVideoPreparer preparer) =>
      preparer.prepare(
        source: source,
        mimeType: 'video/quicktime',
        ownerId: owner,
        lessonId: lesson,
      );

  test(
    'uses compatible profile, retains audio and original, cleans output',
    () async {
      final preparer = LessonVideoPreparer(
        supportDirectory: () async => directory,
        probe: (_) async => info(),
        encode: (path, options, output, progress) async {
          expect(options.maxWidth, 1280);
          expect(options.maxHeight, 720);
          expect(options.codec, VideoCodec.h264);
          expect(options.container, VideoContainer.mp4);
          expect(options.removeAudio, false);
          expect(options.frameRate, 30);
          expect(options.trim, isNull);
          await File(output).writeAsBytes(List.filled(50, 2));
          return encoded(output);
        },
      );
      final result = await prepare(preparer);
      expect(result.mimeType, 'video/mp4');
      expect(await result.file.length(), 50);
      await result.release();
      expect(await result.file.exists(), false);
      expect(await source.length(), 100);
    },
  );

  test(
    'retries reuse identical completed bytes without another encode',
    () async {
      var encodes = 0;
      final preparer = LessonVideoPreparer(
        supportDirectory: () async => directory,
        probe: (_) async => info(),
        encode: (_, options, output, _) async {
          encodes++;
          await File(output).writeAsBytes(List.filled(50, 2));
          return encoded(output);
        },
      );
      final first = await prepare(preparer);
      final second = await prepare(preparer);
      expect(second.file.path, first.file.path);
      expect(encodes, 1);
      await first.file.writeAsBytes([9]);
      await prepare(preparer);
      expect(encodes, 2, reason: 'Corrupt prepared files must not be resumed');
      await source.writeAsBytes(List.filled(100, 3));
      final changed = await prepare(preparer);
      expect(changed.file.path, isNot(first.file.path));
      expect(encodes, 3);
    },
  );

  test('no savings uploads original with original MIME', () async {
    final preparer = LessonVideoPreparer(
      supportDirectory: () async => directory,
      probe: (_) async => info(),
      encode: (path, _, _, _) async => encoded(path),
    );
    final result = await prepare(preparer);
    expect(result.file.path, source.path);
    expect(result.mimeType, 'video/quicktime');
    await result.release();
    expect(await source.exists(), true);
  });

  test(
    'reports source and estimated compressed sizes before encoding',
    () async {
      LessonVideoPreparationEstimate? estimate;
      final preparer = LessonVideoPreparer(
        supportDirectory: () async => directory,
        probe: (_) async => info(),
        encode: (path, _, _, _) async => encoded(path),
      );

      await preparer.prepare(
        source: source,
        mimeType: 'video/quicktime',
        ownerId: owner,
        lessonId: lesson,
        onEstimate: (value) => estimate = value,
      );

      expect(estimate, isNotNull);
      expect(estimate!.sourceBytes, await source.length());
      expect(estimate!.expectedBytes, greaterThan(0));
      expect(estimate!.expectedBytes, lessThanOrEqualTo(estimate!.sourceBytes));
    },
  );

  test('rejects truncated output', () async {
    final preparer = LessonVideoPreparer(
      supportDirectory: () async => directory,
      probe: (path) async =>
          path == source.path ? info() : info(duration: 5000),
      encode: (_, options, output, _) async {
        await File(output).writeAsBytes([1]);
        return encoded(output);
      },
    );
    await expectLater(prepare(preparer), throwsArgumentError);
    expect(await source.exists(), true);
  });

  test(
    'rejects oversized compressed result before storage reservation',
    () async {
      await source.open(mode: FileMode.write).then((file) async {
        await file.truncate(maxPreparedLessonBytes + 10);
        await file.close();
      });
      final preparer = LessonVideoPreparer(
        supportDirectory: () async => directory,
        probe: (_) async => info(),
        encode: (path, _, _, _) async => encoded(path),
      );
      await expectLater(prepare(preparer), throwsArgumentError);
    },
  );

  test('native errors are concise and incomplete output is removed', () async {
    String? output;
    final preparer = LessonVideoPreparer(
      supportDirectory: () async => directory,
      probe: (_) async => info(),
      encode: (_, options, destination, _) async {
        output = destination;
        await File(output!).writeAsBytes([1]);
        throw VideoCompressException('interrupted', 'Internal encoder details');
      },
    );
    await expectLater(prepare(preparer), throwsArgumentError);
    expect(await File(output!).exists(), false);
    expect(await source.exists(), true);
  });

  test(
    '264 second source uses 23 MB budget and 480p without source fallback',
    () {
      final options = LessonVideoEncodingProfile.build(
        info(duration: 264035),
        targetMB: 23,
      );
      expect(options.targetSizeMB, 23);
      expect(options.maxHeight, 480);
      expect(options.videoBitrateKbps, isNull);
      expect(options.keepOriginalIfLarger, false);
    },
  );

  test('rejects impractically low bitrate before starting encoder', () {
    expect(
      () => LessonVideoEncodingProfile.build(
        info(duration: 3600000),
        targetMB: 23,
      ),
      throwsArgumentError,
    );
  });

  test('cancellation removes partial output and preserves source', () async {
    final token = CancellationToken();
    String? destination;
    final preparer = LessonVideoPreparer(
      supportDirectory: () async => directory,
      probe: (_) async => info(),
      encode: (_, options, output, _) async {
        destination = output;
        await File(output).writeAsBytes([1]);
        await token.cancel();
        return encoded(output);
      },
    );
    await expectLater(
      preparer.prepare(
        source: source,
        mimeType: 'video/quicktime',
        ownerId: owner,
        lessonId: lesson,
        cancellationToken: token,
      ),
      throwsA(isA<CompressCancelled>()),
    );
    expect(await File(destination!).exists(), false);
    expect(await source.exists(), true);
  });

  test('oversized encode gets only one retry from original', () async {
    final handle = await source.open(mode: FileMode.write);
    await handle.truncate(38106244);
    await handle.close();
    var calls = 0;
    final preparer = LessonVideoPreparer(
      supportDirectory: () async => directory,
      probe: (_) async => info(duration: 264035),
      encode: (path, options, output, _) async {
        expect(path, source.path);
        expect(options.targetSizeMB, calls == 0 ? 23 : 20);
        final file = await File(output).open(mode: FileMode.write);
        await file.truncate(
          calls++ == 0 ? maxPreparedLessonBytes + 1 : 20 * 1024 * 1024,
        );
        await file.close();
        return encoded(output);
      },
    );
    final result = await prepare(preparer);
    expect(calls, 2);
    expect(await result.file.length(), lessThan(maxPreparedLessonBytes));
  });
}
