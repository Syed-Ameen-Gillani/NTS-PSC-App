import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';

final teacherLessonMediaProvider = FutureProvider.autoDispose
    .family<List<LessonMedia>, String>(
      (ref, lessonId) => ref
          .read(lessonMediaRepositoryProvider)
          .listForLesson(lessonId, includeUnreleased: true),
    );
