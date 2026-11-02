import 'dart:io';
import 'package:flutter_compress/flutter_compress.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/core/networks/supabase_client.dart';
import 'package:nts_psc_app/features/learn/data/offline_file_store.dart';
import 'package:nts_psc_app/features/learn/data/lesson_upload_session_store.dart';
import 'package:nts_psc_app/features/learn/data/lesson_video_preparer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tusc/tusc.dart';

const maxLessonVideoBytes = maxPreparedLessonBytes;

final lessonMediaRepositoryProvider = Provider<LessonMediaRepository>((ref) {
  return LessonMediaRepository(Supabase.instance.client);
});

class LessonMedia {
  const LessonMedia({
    required this.id,
    required this.lessonId,
    required this.path,
    required this.status,
    required this.segments,
    required this.error,
    required this.byteSize,
  });

  final String id;
  final String lessonId;
  final String path;
  final String status;
  final List<Map<String, dynamic>> segments;
  final String? error;
  final int byteSize;

  factory LessonMedia.fromRow(Map<String, dynamic> row) => LessonMedia(
    id: row['id'] as String,
    lessonId: row['lesson_id'] as String,
    path: row['object_path'] as String,
    status: row['status'] as String,
    segments: (row['transcript_segments'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>(),
    error: row['processing_error'] as String?,
    byteSize: (row['byte_size'] as num).toInt(),
  );
}

class LessonMediaRepository {
  LessonMediaRepository(this.client, {LessonVideoPreparer? videoPreparer})
    : _videoPreparer = videoPreparer ?? LessonVideoPreparer();

  final SupabaseClient client;
  final LessonVideoPreparer _videoPreparer;
  static final _activeUploads = <String>{};

  Future<List<LessonMedia>> listForLesson(
    String lessonId, {
    bool includeUnreleased = false,
  }) async {
    if (!includeUnreleased) {
      final rows =
          await client.rpc(
                'get_student_lesson_media',
                params: {'p_lesson_id': lessonId},
              )
              as List;
      return rows
          .map(
            (row) => LessonMedia.fromRow(Map<String, dynamic>.from(row as Map)),
          )
          .toList();
    }
    final rows = await client
        .from('lesson_media')
        .select(
          'id, lesson_id, object_path, status, transcript_segments, processing_error, byte_size',
        )
        .eq('lesson_id', lessonId)
        .order('created_at', ascending: false);
    for (final row in rows.where((row) => row['status'] == 'archived')) {
      try {
        await client.storage.from('lesson-videos').remove([
          row['object_path'] as String,
        ]);
      } catch (_) {
        // The archived file stays private; retry cleanup on the next read.
      }
    }
    final lesson = rows.any((row) => row['status'] == 'ready')
        ? await client
              .from('lessons')
              .select('video_path, pending_video_removal')
              .eq('id', lessonId)
              .single()
        : null;
    final currentPath = lesson?['video_path'] as String?;
    final pendingRemoval = lesson?['pending_video_removal'] == true;
    return rows
        .where(
          (row) =>
              row['status'] != 'archived' &&
              (row['status'] != 'ready' ||
                  (includeUnreleased &&
                      (!pendingRemoval || row['object_path'] != currentPath)) ||
                  row['object_path'] == currentPath),
        )
        .map(LessonMedia.fromRow)
        .toList();
  }

  /// Hides the video and preserves its transcript/checkpoint answer history.
  /// Returns false when private storage cleanup must be retried later.
  Future<bool> deleteVideo(String mediaId) async {
    final path =
        await client.rpc(
              'archive_lesson_media',
              params: {'p_media_id': mediaId},
            )
            as String;
    if (path.isEmpty) return true;
    try {
      await client.storage.from('lesson-videos').remove([path]);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Uri> signedVideoUrl(String path, {int seconds = 3600}) async {
    final url = await client.storage
        .from('lesson-videos')
        .createSignedUrl(path, seconds);
    return Uri.parse(url);
  }

  Future<LessonMedia> uploadVideo({
    required String lessonId,
    required File file,
    required String mimeType,
    void Function(double)? onProgress,
    void Function(double)? onCompressionProgress,
    void Function(LessonVideoPreparationEstimate)? onPreparationEstimate,
    CancellationToken? preparationCancellation,
  }) async {
    final key = '${client.auth.currentUser?.id}:$lessonId';
    if (!_activeUploads.add(key)) {
      throw StateError('This lesson video is already uploading.');
    }
    try {
      final ownerId = client.auth.currentUser?.id;
      if (ownerId == null) throw StateError('Sign in again to upload.');
      final prepared = await _videoPreparer.prepare(
        source: file,
        mimeType: mimeType,
        ownerId: ownerId,
        lessonId: lessonId,
        onProgress: onCompressionProgress,
        onEstimate: onPreparationEstimate,
        cancellationToken: preparationCancellation,
      );
      if (preparationCancellation?.isCancelled ?? false) {
        await prepared.release();
        throw VideoCompressCancelledException();
      }
      if (client.auth.currentUser?.id != ownerId) {
        throw StateError('Account changed during video preparation.');
      }
      onPreparationEstimate?.call(
        LessonVideoPreparationEstimate(
          sourceBytes: await file.length(),
          expectedBytes: await prepared.file.length(),
        ),
      );
      if (preparationCancellation?.isCancelled ?? false) {
        await prepared.release();
        throw VideoCompressCancelledException();
      }
      onProgress?.call(0);
      final result = await _uploadVideo(
        lessonId: lessonId,
        file: prepared.file,
        mimeType: prepared.mimeType,
        onProgress: onProgress,
      );
      if (prepared.durationMs > 0) {
        await client.rpc(
          'confirm_learning_video',
          params: {
            'p_lesson_id': lessonId,
            'p_source': result.path,
            'p_duration_ms': prepared.durationMs,
          },
        );
      }
      await prepared.release();
      return result;
    } finally {
      _activeUploads.remove(key);
    }
  }

  Future<LessonMedia> _uploadVideo({
    required String lessonId,
    required File file,
    required String mimeType,
    void Function(double)? onProgress,
  }) async {
    final ownerId = client.auth.currentUser?.id;
    if (ownerId == null) throw StateError('Sign in again to upload.');
    final size = await file.length();
    if (size < 1 || size > maxLessonVideoBytes) {
      throw ArgumentError('Choose a video no larger than 25 MB.');
    }
    if (!{'video/mp4', 'video/webm', 'video/quicktime'}.contains(mimeType)) {
      throw ArgumentError('Choose an MP4, WebM, or MOV video.');
    }
    final digest = await LessonUploadSessionStore.fingerprint(file);
    final intentFile = await LessonUploadSessionStore.fileFor(
      ownerId,
      lessonId,
    );
    final intent = await LessonUploadSessionStore.read(intentFile, digest);
    Map<String, dynamic>? reservation;
    if (intent != null) {
      final existing = (await listForLesson(
        lessonId,
        includeUnreleased: true,
      )).where((media) => media.id == intent['mediaId']).firstOrNull;
      if (existing != null) {
        if (existing.status != 'uploading') {
          await intentFile.delete();
          return existing;
        }
        reservation = {'object_path': existing.path, 'media_id': existing.id};
      }
    }
    reservation ??=
        (await client.rpc(
                      'begin_lesson_media',
                      params: {
                        'p_lesson_id': lessonId,
                        'p_byte_size': size,
                        'p_mime_type': mimeType,
                      },
                    )
                    as List<dynamic>)
                .single
            as Map<String, dynamic>;
    final path = reservation['object_path'] as String;
    final mediaId = reservation['media_id'] as String;
    await OfflineFileStore.writeJson(intentFile, {
      'digest': digest,
      'mediaId': mediaId,
    });
    final session = client.auth.currentSession;
    if (session == null || session.user.id != ownerId) {
      throw StateError('Sign in again to upload.');
    }
    final origin = Uri.parse(AppConfig.supabaseUrl);
    final storageUri = origin.replace(
      host: origin.host.replaceFirst('.supabase.co', '.storage.supabase.co'),
      path: '/storage/v1/upload/resumable',
    );
    final support = await getApplicationSupportDirectory();
    final cacheDirectory = Directory(
      '${support.path}/lesson-uploads/$ownerId/$mediaId',
    );
    await cacheDirectory.create(recursive: true);
    final upload = TusStreamClient(
      url: storageUri.toString(),
      fileStreamGenerator: () => file.openRead(),
      fileSize: size,
      fileName: path.split('/').last,
      chunkSize: 6 * 1024 * 1024,
      cache: TusPersistentCache(cacheDirectory.path),
      headers: {'authorization': 'Bearer ${session.accessToken}'},
      metadata: {
        'bucketName': 'lesson-videos',
        'objectName': path,
        'contentType': mimeType,
        'cacheControl': '3600',
      },
    );
    try {
      await upload.startUpload(
        onProgress: (sent, total, _) {
          onProgress?.call(sent / total);
        },
      );
      if (client.auth.currentUser?.id != ownerId) {
        throw StateError('Account changed during upload.');
      }
      await finalizeUpload(mediaId);
      try {
        await client.functions.invoke(
          'transcribe-lesson',
          body: {'mediaId': mediaId},
        );
      } catch (_) {
        // The upload remains transcribing; the teacher can retry the job.
      }
      final result = (await listForLesson(
        lessonId,
        includeUnreleased: true,
      )).firstWhere((m) => m.id == mediaId);
      if (await intentFile.exists()) await intentFile.delete();
      return result;
    } finally {
      upload.close();
    }
  }

  /// Recovers an uploaded object after a lost finalize response without re-uploading.
  Future<void> finalizeUpload(String mediaId) async {
    final row = await client
        .from('lesson_media')
        .select('status')
        .eq('id', mediaId)
        .single();
    if (row['status'] != 'uploading') return;
    await client.rpc('finalize_lesson_media', params: {'p_media_id': mediaId});
  }

  Future<void> retryTranscript(String mediaId) async {
    final response = await client.functions.invoke(
      'transcribe-lesson',
      body: {'mediaId': mediaId},
    );
    if (response.status != 200 && response.status != 202) {
      throw StateError('Transcription service is unavailable.');
    }
  }

  Future<void> saveTranscript(
    String mediaId,
    List<Map<String, dynamic>> segments,
    String language,
  ) => client.rpc(
    'save_lesson_transcript',
    params: {
      'p_media_id': mediaId,
      'p_segments': segments,
      'p_language': language,
    },
  );

  Future<int> generateCheckpoints(String mediaId) async {
    final response = await client.functions.invoke(
      'generate-lesson-checkpoints',
      body: {'mediaId': mediaId},
    );
    if (response.status != 200) throw StateError('Could not generate checks.');
    return (response.data as Map<String, dynamic>)['created'] as int;
  }

  Future<List<Map<String, dynamic>>> teacherCheckpoints(String mediaId) async {
    final rows =
        await client.rpc(
              'get_teacher_lesson_checkpoints',
              params: {'p_media_id': mediaId},
            )
            as List<dynamic>;
    return rows.cast<Map<String, dynamic>>();
  }

  Future<void> reviewCheckpoint(
    Map<String, dynamic> checkpoint, {
    required bool approved,
  }) => client.rpc(
    'review_lesson_checkpoint',
    params: {
      'p_checkpoint_id': checkpoint['id'],
      'p_question': checkpoint['question'],
      'p_options': checkpoint['options'],
      'p_correct_index': checkpoint['correct_index'],
      'p_explanation': checkpoint['explanation'] ?? '',
      'p_approved': approved,
    },
  );

  Future<List<Map<String, dynamic>>> studentCheckpoints(String mediaId) async {
    final rows = await client
        .from('lesson_checkpoints')
        .select(
          'id, media_id, timestamp_seconds, question, options, source_start_seconds, source_end_seconds',
        )
        .eq('media_id', mediaId)
        .eq('status', 'approved')
        .order('timestamp_seconds');
    return rows.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> answerCheckpoint(
    String checkpointId,
    int answerIndex,
  ) async {
    final result = await client.rpc(
      'answer_lesson_checkpoint',
      params: {'p_checkpoint_id': checkpointId, 'p_answer_index': answerIndex},
    );
    return (result as Map<String, dynamic>);
  }

  Future<Set<String>> answeredCheckpointIds(List<String> checkpointIds) async {
    if (checkpointIds.isEmpty) return {};
    final rows = await client
        .from('lesson_checkpoint_attempts')
        .select('checkpoint_id')
        .inFilter('checkpoint_id', checkpointIds);
    return rows.map((row) => row['checkpoint_id'] as String).toSet();
  }

  Future<void> publish(String mediaId) =>
      client.rpc('publish_lesson_media', params: {'p_media_id': mediaId});
}
