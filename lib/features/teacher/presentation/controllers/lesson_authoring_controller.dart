import 'dart:io';

import 'package:flutter_riverpod/legacy.dart';
import 'package:nts_psc_app/core/models/app_models.dart';
import 'package:nts_psc_app/features/curriculum/domain/curriculum_models.dart';
import 'package:nts_psc_app/features/curriculum/data/curriculum_repository.dart';
import 'package:nts_psc_app/features/learn/data/lesson_media_repository.dart';
import 'package:nts_psc_app/features/teacher/presentation/controllers/teacher_controller.dart';
import 'package:nts_psc_app/features/teacher/presentation/widgets/draft_lesson_video_picker.dart';

typedef LessonAuthoringKey = ({
  String draftId,
  String courseId,
  String moduleId,
});

class LessonAuthoringState {
  const LessonAuthoringState({
    this.saved,
    this.busy = false,
    this.videoUploaded = false,
    this.files = const [],
    this.progress,
  });
  final LessonModel? saved;
  final bool busy;
  final bool videoUploaded;
  final List<PendingMaterial> files;
  final DraftVideoProgress? progress;
  LessonAuthoringState copyWith({
    LessonModel? saved,
    bool? busy,
    bool? videoUploaded,
    List<PendingMaterial>? files,
    DraftVideoProgress? progress,
  }) => LessonAuthoringState(
    saved: saved ?? this.saved,
    busy: busy ?? this.busy,
    videoUploaded: videoUploaded ?? this.videoUploaded,
    files: files ?? this.files,
    progress: progress,
  );
}

final lessonAuthoringProvider = StateNotifierProvider.autoDispose
    .family<
      LessonAuthoringController,
      LessonAuthoringState,
      LessonAuthoringKey
    >(
      (ref, key) => LessonAuthoringController(
        create: (lesson) => ref
            .read(teacherControllerProvider.notifier)
            .addLesson(key.courseId, key.moduleId, lesson),
        uploadVideo: (lesson, video, onProgress) => ref
            .read(lessonMediaRepositoryProvider)
            .uploadVideo(
              lessonId: lesson.id,
              file: File(video.path),
              mimeType: video.mimeType,
              onCompressionProgress: (value) =>
                  onProgress((label: 'Compressing video', value: value)),
              onProgress: (value) =>
                  onProgress((label: 'Uploading video', value: value)),
            )
            .then((_) {}),
        uploadMaterial: (lesson, file) => ref
            .read(curriculumRepositoryProvider)
            .upload(
              CurriculumScope(
                courseId: key.courseId,
                moduleId: key.moduleId,
                lessonId: lesson.id,
              ),
              file,
            ),
      ),
    );

class LessonAuthoringController extends StateNotifier<LessonAuthoringState> {
  LessonAuthoringController({
    required this.create,
    required this.uploadVideo,
    required this.uploadMaterial,
  }) : super(const LessonAuthoringState());
  final Future<LessonModel> Function(LessonModel) create;
  final Future<void> Function(
    LessonModel,
    DraftLessonVideo,
    void Function(DraftVideoProgress),
  )
  uploadVideo;
  final Future<void> Function(LessonModel, PendingMaterial) uploadMaterial;
  bool _alive = true;
  void selectFiles(List<PendingMaterial> files) {
    if (!state.busy) state = state.copyWith(files: List.unmodifiable(files));
  }

  Future<LessonModel> save(LessonModel input, DraftLessonVideo? video) async {
    if (state.busy) throw StateError('Lesson is already saving.');
    state = state.copyWith(busy: true);
    try {
      final lesson = state.saved ?? await create(input);
      if (!_alive) return lesson;
      state = state.copyWith(saved: lesson, busy: true);
      if (video != null && !state.videoUploaded) {
        await uploadVideo(lesson, video, (value) {
          if (_alive) state = state.copyWith(busy: true, progress: value);
        });
        if (!_alive) return lesson;
        state = state.copyWith(videoUploaded: true, busy: true);
      }
      while (state.files.isNotEmpty) {
        final file = state.files.first;
        await uploadMaterial(lesson, file);
        if (!_alive) return lesson;
        state = state.copyWith(
          files: List.unmodifiable(state.files.skip(1)),
          busy: true,
        );
      }
      return lesson;
    } finally {
      if (_alive) state = state.copyWith(busy: false);
    }
  }

  @override
  void dispose() {
    _alive = false;
    super.dispose();
  }
}
