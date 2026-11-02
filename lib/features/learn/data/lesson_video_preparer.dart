import 'dart:io';
import 'dart:developer' as developer;

import 'package:flutter_compress/flutter_compress.dart';
import 'package:flutter/services.dart';
import 'package:nts_psc_app/features/learn/data/lesson_upload_session_store.dart';
import 'package:nts_psc_app/features/learn/data/offline_file_store.dart';
import 'package:path_provider/path_provider.dart';
import 'lesson_video_encoding_profile.dart';

const maxLessonSourceBytes = 250 * 1024 * 1024;
const maxPreparedLessonBytes = 25 * 1024 * 1024;

class LessonVideoPreparationEstimate {
  const LessonVideoPreparationEstimate({
    required this.sourceBytes,
    required this.expectedBytes,
  });

  final int sourceBytes;
  final int expectedBytes;
}

typedef LessonVideoEncoder =
    Future<VideoCompressResult> Function(
      String path,
      VideoCompressConfig options,
      String outputPath,
      void Function(double)? onProgress,
    );

class PreparedLessonVideo {
  const PreparedLessonVideo(
    this.file,
    this.mimeType, {
    this.receipt,
    this.durationMs = 0,
  });

  final int durationMs;
  final File file;
  final String mimeType;
  final File? receipt;

  Future<void> release() async {
    if (receipt == null) return; // Never delete the teacher's original.
    for (final item in [file, receipt!]) {
      try {
        if (await item.exists()) await item.delete();
      } on FileSystemException catch (_) {
        // A completed upload must not fail because local cleanup failed.
      }
    }
  }
}

/// Encodes locally before reserving storage. Completed outputs survive failed
/// transfers so TUS retries use exactly the same bytes, not a new encode.
class LessonVideoPreparer {
  LessonVideoPreparer({
    Future<VideoInfo> Function(String)? probe,
    LessonVideoEncoder? encode,
    Future<Directory> Function()? supportDirectory,
  }) : _probe = probe ?? _native.getVideoInfo,
       _encode = encode,
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static final _native = FlutterCompress.instance;
  static bool _encoding = false;
  static const _profile = 'h264-adaptive-23mb-v2';
  final Future<VideoInfo> Function(String) _probe;
  final LessonVideoEncoder? _encode;
  final Future<Directory> Function() _supportDirectory;

  static Future<VideoCompressResult> _encodeNative(
    String path,
    VideoCompressConfig options,
    String outputPath,
    void Function(double)? onProgress,
    CancellationToken? cancellationToken,
  ) async {
    // The native Android engine owns one active Transformer at a time.
    if (_encoding) {
      throw ArgumentError('Another video is being prepared. Please wait.');
    }
    _encoding = true;
    try {
      developer.log(
        'Native encoder starting: source=$path, output=$outputPath, '
        'codec=${options.codec}, container=${options.container}, '
        'targetSizeMB=${options.targetSizeMB}, '
        'maxWidth=${options.maxWidth}, maxHeight=${options.maxHeight}, '
        'videoBitrateKbps=${options.videoBitrateKbps}, '
        'audioBitrateKbps=${options.audioBitrateKbps}, '
        'frameRate=${options.frameRate}.',
        name: 'CBOA.VideoUpload',
      );
      return await _native.compress(
        path,
        options,
        outputDirectory: File(outputPath).parent.path,
        outputName: File(outputPath).uri.pathSegments.last,
        cancellationToken: cancellationToken,
        onProgress: (event) => onProgress?.call(event.progress.clamp(0, 1)),
      );
    } finally {
      _encoding = false;
    }
  }

  Future<PreparedLessonVideo> prepare({
    required File source,
    required String mimeType,
    required String ownerId,
    required String lessonId,
    void Function(double)? onProgress,
    void Function(LessonVideoPreparationEstimate)? onEstimate,
    CancellationToken? cancellationToken,
  }) async {
    void checkCancelled() {
      if (cancellationToken?.isCancelled ?? false) {
        throw VideoCompressCancelledException();
      }
    }

    checkCancelled();
    developer.log(
      'Preparing video: source=${source.path}, mime=$mimeType, '
      'lesson=$lessonId.',
      name: 'CBOA.VideoUpload',
    );
    OfflineFileStore.requireId(ownerId);
    OfflineFileStore.requireId(lessonId);
    if (!{'video/mp4', 'video/webm', 'video/quicktime'}.contains(mimeType)) {
      throw ArgumentError('Choose an MP4, WebM, or MOV video.');
    }
    final sourceSize = await source.length();
    developer.log(
      'Source video file: exists=${await source.exists()}, bytes=$sourceSize.',
      name: 'CBOA.VideoUpload',
    );
    if (sourceSize < 1 || sourceSize > maxLessonSourceBytes) {
      throw ArgumentError('Choose a video smaller than 250 MB.');
    }
    final digest = await LessonUploadSessionStore.fingerprint(source);
    checkCancelled();
    final support = await _supportDirectory();
    final directory = Directory(
      '${support.path}/lesson-uploads/$ownerId/prepared/$lessonId',
    );
    await directory.create(recursive: true);
    final output = File('${directory.path}/$digest-$_profile.mp4');
    final receipt = File('${output.path}.json');
    try {
      // A receipt is written only after validation; partial encodes are ignored.
      final cached = await LessonUploadSessionStore.read(receipt, digest);
      if (cached != null &&
          await output.exists() &&
          cached['outputDigest'] ==
              await LessonUploadSessionStore.fingerprint(output)) {
        _validateSize(await output.length());
        developer.log(
          'Using validated prepared-video cache: output=${output.path}, '
          'bytes=${await output.length()}.',
          name: 'CBOA.VideoUpload',
        );
        onProgress?.call(1);
        final cachedInfo = await _probe(output.path);
        checkCancelled();
        developer.log(
          'Cached video probe: durationMs=${cachedInfo.durationMs}, '
          'width=${cachedInfo.width}, height=${cachedInfo.height}, '
          'bitrateKbps=${cachedInfo.bitrateKbps}.',
          name: 'CBOA.VideoUpload',
        );
        return PreparedLessonVideo(
          output,
          'video/mp4',
          receipt: receipt,
          durationMs: cachedInfo.durationMs,
        );
      }
      if (await output.exists()) await output.delete();
      if (await receipt.exists()) await receipt.delete();
      final before = await _probe(source.path);
      developer.log(
        'Source video probe: durationMs=${before.durationMs}, '
        'width=${before.width}, height=${before.height}, '
        'bitrateKbps=${before.bitrateKbps}.',
        name: 'CBOA.VideoUpload',
      );
      if (before.durationMs <= 0 || before.width <= 0 || before.height <= 0) {
        developer.log(
          'Source video rejected because probe returned invalid metadata: '
          'durationMs=${before.durationMs}, width=${before.width}, '
          'height=${before.height}, path=${source.path}.',
          name: 'CBOA.VideoUpload',
          level: 1000,
        );
        throw ArgumentError('This video cannot be read. Choose another file.');
      }
      checkCancelled();
      if (sourceSize <= maxPreparedLessonBytes &&
          mimeType == 'video/mp4' &&
          (before.codec?.toLowerCase().contains('264') ?? false) &&
          before.width <= (before.width >= before.height ? 1280 : 720) &&
          before.height <= (before.width >= before.height ? 720 : 1280)) {
        onEstimate?.call(
          LessonVideoPreparationEstimate(
            sourceBytes: sourceSize,
            expectedBytes: sourceSize,
          ),
        );
        onProgress?.call(1);
        return PreparedLessonVideo(
          source,
          mimeType,
          durationMs: before.durationMs,
        );
      }
      final targetMB = sourceSize > maxPreparedLessonBytes
          ? LessonVideoEncodingProfile.targetMegabytes
          : null;
      var options = LessonVideoEncodingProfile.build(
        before,
        targetMB: targetMB,
      );
      final estimatedEncodedBytes = targetMB == null
          ? sourceSize
          : (options.targetSizeMB! * 1024 * 1024 * .95).ceil();
      onEstimate?.call(
        LessonVideoPreparationEstimate(
          sourceBytes: sourceSize,
          expectedBytes: estimatedEncodedBytes,
        ),
      );
      onProgress?.call(0);
      Future<VideoCompressResult> encode() async {
        checkCancelled();
        return _encode != null
            ? _encode(source.path, options, output.path, onProgress)
            : _encodeNative(
                source.path,
                options,
                output.path,
                onProgress,
                cancellationToken,
              );
      }

      var encoded = await encode();
      checkCancelled();
      if (await File(encoded.outputPath).length() > maxPreparedLessonBytes &&
          targetMB != null) {
        // One bounded retry, always from the original to avoid generational loss.
        if (await output.exists()) await output.delete();
        options = LessonVideoEncodingProfile.build(before, targetMB: 20);
        onEstimate?.call(
          LessonVideoPreparationEstimate(
            sourceBytes: sourceSize,
            expectedBytes: (options.targetSizeMB! * 1024 * 1024 * .95).ceil(),
          ),
        );
        onProgress?.call(0);
        encoded = await encode();
        checkCancelled();
      }
      final path = encoded.outputPath;
      final result = File(path);
      final after = await _probe(path);
      checkCancelled();
      developer.log(
        'Prepared video probe: output=$path, durationMs=${after.durationMs}, '
        'width=${after.width}, height=${after.height}, '
        'bitrateKbps=${after.bitrateKbps}.',
        name: 'CBOA.VideoUpload',
      );
      if ((after.durationMs - before.durationMs).abs() > 1000 ||
          after.width <= 0 ||
          after.height <= 0) {
        throw ArgumentError('Video preparation failed. Please try again.');
      }
      final resultSize = await result.length();
      developer.log(
        'Prepared video size comparison: sourceBytes=$sourceSize, '
        'outputBytes=$resultSize, encoderReturnedSource=${path == source.path}.',
        name: 'CBOA.VideoUpload',
      );
      // The native encoder may return the original when encoding saves no space.
      if (path == source.path || resultSize >= sourceSize) {
        _validateSize(sourceSize);
        if (await output.exists()) await output.delete();
        return PreparedLessonVideo(
          source,
          mimeType,
          durationMs: before.durationMs,
        );
      }
      _validateSize(resultSize);
      await OfflineFileStore.writeJson(receipt, {
        'digest': digest,
        'mediaId': lessonId,
        'outputDigest': await LessonUploadSessionStore.fingerprint(result),
      });
      return PreparedLessonVideo(
        result,
        'video/mp4',
        receipt: receipt,
        durationMs: after.durationMs,
      );
    } on CompressCancelled {
      if (await output.exists()) await output.delete();
      if (await receipt.exists()) await receipt.delete();
      rethrow;
    } on CompressException catch (error, stackTrace) {
      developer.log(
        'Native video compression failed.',
        name: 'CBOA.VideoUpload',
        error: error,
        stackTrace: stackTrace,
      );
      if (await output.exists()) await output.delete();
      throw ArgumentError('Could not prepare this video. Please try again.');
    } on MissingPluginException catch (error, stackTrace) {
      developer.log(
        'Video compression plugin is unavailable.',
        name: 'CBOA.VideoUpload',
        error: error,
        stackTrace: stackTrace,
      );
      throw ArgumentError('Video uploads require the Android or iOS app.');
    } on ArgumentError catch (error, stackTrace) {
      developer.log(
        'Video preparation validation failed.',
        name: 'CBOA.VideoUpload',
        error: error,
        stackTrace: stackTrace,
      );
      if (await output.exists()) await output.delete();
      rethrow;
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected video preparation failure.',
        name: 'CBOA.VideoUpload',
        error: error,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  static void _validateSize(int bytes) {
    if (bytes < 1 || bytes > maxPreparedLessonBytes) {
      throw ArgumentError(
        'Video exceeds 25 MB after compression. Choose a shorter video.',
      );
    }
  }
}
