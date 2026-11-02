import 'support/fake_learning_evidence_repository.dart';
import 'package:nts_psc_app/features/learn/data/learning_evidence_repository.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/learn/data/course_download_ledger.dart';
import 'package:nts_psc_app/features/learn/data/offline_lesson_library.dart';
import 'package:nts_psc_app/features/learn/presentation/controllers/course_download_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MediaRepository extends LessonMediaRepository {
  _MediaRepository(super.client);
  @override
  Future<List<LessonMedia>> listForLesson(
    String lessonId, {
    bool includeUnreleased = false,
  }) async => [
    LessonMedia(
      id: lessonId,
      lessonId: lessonId,
      path: '$lessonId.mp4',
      status: 'ready',
      segments: [],
      error: null,
      byteSize: 10,
    ),
  ];
}

class _Library extends OfflineLessonLibrary {
  _Library(super.mediaRepository);
  final saved = <String>{};
  final attempts = <String>[];
  final expired = <String>{};
  final refreshed = <String>[];
  String? failLesson;

  @override
  Future<List<OfflineLessonEntry>> listDownloads() async => [
    for (final id in saved)
      OfflineLessonEntry(
        lessonId: id,
        title: id,
        durationMinutes: 1,
        mediaPath: '$id.mp4',
        byteSize: 10,
        needsAccessRefresh: expired.contains(id),
      ),
  ];

  @override
  Future<void> refreshAccess(String lessonId, String mediaPath) async {
    refreshed.add(lessonId);
    expired.remove(lessonId);
  }

  @override
  Future<OfflineLesson?> find(String lessonId, String mediaPath) async =>
      saved.contains(lessonId) ? _lesson(mediaPath) : null;

  OfflineLesson _lesson(String path) => OfflineLesson(
    path: 'private/$path',
    mediaPath: path,
    checkpoints: [],
    segments: [],
  );

  @override
  Future<OfflineLesson> download({
    required String lessonId,
    required String title,
    required int durationMinutes,
    required LessonMedia media,
    required List<Map<String, dynamic>> checkpoints,
    required bool wifiOnly,
    void Function(double)? onProgress,
  }) async {
    attempts.add(lessonId);
    if (failLesson == lessonId) throw StateError('Network interrupted');
    saved.add(lessonId);
    return _lesson(media.path);
  }
}

void main() {
  late SupabaseClient client;
  late ProviderContainer container;
  late _Library library;
  late Directory temporaryDirectory;
  final course = CourseModel(
    id: 'course',
    title: 'Test',
    author: 'Teacher',
    rating: 0,
    price: 'Free',
    imagePath: '',
    modules: [
      CourseModuleModel(
        id: 'module',
        title: 'Module',
        lessons: [
          LessonModel(
            id: 'one',
            title: 'One',
            durationMinutes: 1,
            videoPath: 'one.mp4',
          ),
          LessonModel(
            id: 'two',
            title: 'Two',
            durationMinutes: 1,
            videoPath: 'two.mp4',
          ),
          LessonModel(id: 'external', title: 'External', durationMinutes: 1),
        ],
      ),
    ],
  );

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'cboa-course-queue-',
    );
    String encode(Object value) =>
        base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
    final expires = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600;
    final token =
        '${encode({'alg': 'HS256'})}.${encode({'exp': expires, 'sub': 'student'})}.test';
    client = SupabaseClient(
      'https://example.supabase.co',
      'test-key',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'access_token': token,
            'refresh_token': 'test-refresh',
            'token_type': 'bearer',
            'expires_in': 3600,
            'user': {
              'id': 'student',
              'aud': 'authenticated',
              'created_at': '2026-01-01T00:00:00Z',
              'email': 'test@example.com',
              'app_metadata': {},
              'user_metadata': {},
            },
          }),
          200,
          request: request,
          headers: {'content-type': 'application/json'},
        ),
      ),
    );
    await client.auth.signInWithPassword(
      email: 'test@example.com',
      password: 'test-password',
    );
    final repository = _MediaRepository(client);
    library = _Library(repository);
    container = ProviderContainer(
      overrides: [
        lessonMediaRepositoryProvider.overrideWithValue(repository),
        learningEvidenceRepositoryProvider.overrideWithValue(
          FakeLearningEvidenceRepository(),
        ),
        offlineLessonLibraryProvider.overrideWithValue(library),
        courseDownloadLedgerProvider.overrideWithValue(
          CourseDownloadLedger(directory: () async => temporaryDirectory),
        ),
      ],
    );
  });
  tearDown(() async {
    container.dispose();
    await client.dispose();
    await temporaryDirectory.delete(recursive: true);
  });

  test(
    'batch skips saved lessons and reports external lessons as unavailable',
    () async {
      library.saved.add('one');
      await container
          .read(courseDownloadProvider(course.id).notifier)
          .download(course, wifiOnly: true);
      final result = container.read(courseDownloadProvider(course.id));
      expect(library.attempts, ['two']);
      expect(result.saved, 2);
      expect(result.unavailable, 1);
      expect(result.failed, 0);
      expect(result.running, isFalse);
    },
  );

  test(
    'expired saved lesson renews access without downloading again',
    () async {
      library.saved.add('one');
      library.expired.add('one');
      await container
          .read(courseDownloadProvider(course.id).notifier)
          .download(course, wifiOnly: true);
      expect(library.refreshed, ['one']);
      expect(library.attempts, ['two']);
    },
  );

  test(
    'retry preserves successful lessons and only downloads the failed lesson',
    () async {
      library.failLesson = 'two';
      final controller = container.read(
        courseDownloadProvider(course.id).notifier,
      );
      await controller.download(course, wifiOnly: false);
      expect(container.read(courseDownloadProvider(course.id)).failed, 1);
      library.failLesson = null;
      await controller.download(course, wifiOnly: false);
      expect(library.attempts, ['one', 'two', 'two']);
      expect(container.read(courseDownloadProvider(course.id)).saved, 2);
      expect(container.read(courseDownloadProvider(course.id)).failed, 0);
    },
  );

  test(
    'cancelling the batch stops before starting the next transfer',
    () async {
      final controller = container.read(
        courseDownloadProvider(course.id).notifier,
      );
      final pending = controller.download(course, wifiOnly: true);
      await controller.cancel();
      await pending;
      final result = container.read(courseDownloadProvider(course.id));
      expect(result.cancelled, isTrue);
      expect(result.running, isFalse);
      expect(library.attempts, isEmpty);
    },
  );
}
